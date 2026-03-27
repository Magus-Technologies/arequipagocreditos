import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arequipagocreditos/core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/conductor_entity.dart';
import '../../domain/usecases/auth_usecases.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetLoggedUserUseCase _getLoggedUserUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final ValidateDniForPasswordRecoveryUseCase _validateDniForPasswordRecoveryUseCase;
  final UpdateVehicleDataUseCase _updateVehicleDataUseCase;
  final RefreshUserDataUseCase _refreshUserDataUseCase;
  
  AuthProvider({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetLoggedUserUseCase getLoggedUserUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    required ValidateDniForPasswordRecoveryUseCase validateDniForPasswordRecoveryUseCase,
    required UpdateVehicleDataUseCase updateVehicleDataUseCase,
    required RefreshUserDataUseCase refreshUserDataUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _getLoggedUserUseCase = getLoggedUserUseCase,
        _changePasswordUseCase = changePasswordUseCase,
        _validateDniForPasswordRecoveryUseCase = validateDniForPasswordRecoveryUseCase,
        _updateVehicleDataUseCase = updateVehicleDataUseCase,
        _refreshUserDataUseCase = refreshUserDataUseCase;

  AuthStatus _status = AuthStatus.initial;
  ConductorEntity? _currentUser;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  ConductorEntity? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;

  // Métodos públicos
  Future<void> login(String nroDocumento, String password) async {
    _setStatus(AuthStatus.loading);
    
    final result = await _loginUseCase(nroDocumento, password);
    
    result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _setStatus(AuthStatus.error);
      },
      (conductor) {
        _currentUser = conductor;
        _errorMessage = null;
        _setStatus(AuthStatus.authenticated);
      },
    );
  }

  Future<void> logout() async {
    _setStatus(AuthStatus.loading);
    
    final result = await _logoutUseCase();
    
    result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _setStatus(AuthStatus.error);
      },
      (_) {
        _currentUser = null;
        _errorMessage = null;
        _setStatus(AuthStatus.unauthenticated);
      },
    );
  }

  Future<void> checkAuthStatus() async {
    _setStatus(AuthStatus.loading);
    
    final result = await _getLoggedUserUseCase();
    
    result.fold(
      (failure) {
        _currentUser = null;
        _setStatus(AuthStatus.unauthenticated);
      },
      (conductor) {
        if (conductor != null) {
          _currentUser = conductor;
          _setStatus(AuthStatus.authenticated);
        } else {
          _setStatus(AuthStatus.unauthenticated);
        }
      },
    );
  }

  Future<bool> changePassword(String newPassword) async {
    _setStatus(AuthStatus.loading);
    
    final result = await _changePasswordUseCase(newPassword);
    
    return result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _setStatus(AuthStatus.authenticated); // Mantener autenticado en caso de error
        return false;
      },
      (_) {
        _errorMessage = null;
        _setStatus(AuthStatus.authenticated);
        return true;
      },
    );
  }

  Future<bool> validateDniForPasswordRecovery(String dni) async {
    _setStatus(AuthStatus.loading);
    
    final result = await _validateDniForPasswordRecoveryUseCase(dni);
    
    return result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _setStatus(AuthStatus.unauthenticated);
        return false;
      },
      (_) {
        _errorMessage = null;
        _setStatus(AuthStatus.unauthenticated);
        return true;
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Actualiza los datos del vehículo usando la capa de dominio (UseCase)
  Future<bool> updateVehicleData(Map<String, dynamic> data) async {
    _setStatus(AuthStatus.loading);

    final result = await _updateVehicleDataUseCase.call(data);

    return result.fold((failure) {
      _errorMessage = _mapFailureToMessage(failure);
      // mantener autenticado si ya estaba
      _setStatus(AuthStatus.authenticated);
      return false;
    }, (response) async {
      _errorMessage = null;
      // Primero, intentar sincronizar el usuario en memoria a partir del cache local
      final getResult = await _getLoggedUserUseCase.call();
      getResult.fold((_) {}, (conductor) {
        if (conductor != null) {
          _currentUser = conductor;
        }
      });

      // Notificar inmediatamente que ya estamos autenticados y que el usuario pudo cambiar
      _errorMessage = null;
      _setStatus(AuthStatus.authenticated);

      // Lanzar una sincronización remota en background para garantizar consistencia con el servidor
      () async {
        try {
          await refreshUserDataFromRemote();
        } catch (_) {}
      }();

      return true;
    });
  }

  /// Refresca los datos del usuario desde el servidor remoto (usecase dedicado).
  /// Retorna true si se actualizaron los datos correctamente.
  Future<bool> refreshUserDataFromRemote() async {
    _setStatus(AuthStatus.loading);

    final result = await _refreshUserDataUseCase.call();

    return result.fold((failure) {
      _errorMessage = _mapFailureToMessage(failure);
      // mantener estado autenticado si ya lo estaba
      _setStatus(AuthStatus.authenticated);
      return false;
    }, (conductor) {
      if (conductor != null) {
        _currentUser = conductor;
        _errorMessage = null;
        _setStatus(AuthStatus.authenticated);
        return true;
      }
      _setStatus(AuthStatus.unauthenticated);
      return false;
    });
  }

  /// Devuelve una lista con los nombres de los documentos de vehículo que
  /// ya están vencidos según las fechas almacenadas en el usuario actual.
  /// Las fechas se esperan en formato ISO (yyyy-MM-dd o parseable por DateTime).
  List<String> getExpiredVehicleDocuments() {
    final List<String> expired = [];
    final now = DateTime.now();

    DateTime? tryParseDate(String? s) {
      if (s == null) return null;
      // Try ISO first
      final iso = DateTime.tryParse(s);
      if (iso != null) return iso;
      // Try dd/MM/yyyy
      try {
        final parts = s.split('/');
        if (parts.length == 3) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          return DateTime(y, m, d);
        }
      } catch (_) {}
      return null;
    }

    final soatDate = tryParseDate(_currentUser?.soat);
    final revisionDate = tryParseDate(_currentUser?.revisionTecnica);
    final seguroDate = tryParseDate(_currentUser?.seguroVehicular);

    if (soatDate != null && !soatDate.isAfter(now)) {
      expired.add('SOAT');
    }
    if (revisionDate != null && !revisionDate.isAfter(now)) {
      expired.add('Revisión técnica');
    }
    if (seguroDate != null && !seguroDate.isAfter(now)) {
      expired.add('Seguro vehicular');
    }

    return expired;
  }

  /// Helper rápido
  bool hasAnyExpiredVehicleDocument() {
    return getExpiredVehicleDocuments().isNotEmpty;
  }

  /// Devuelve la lista de documentos que vencen en los próximos [days] días
  /// (excluye los ya vencidos). Si la fecha está en el pasado, no la incluye.
  List<String> getNearExpiryVehicleDocuments(int days) {
    final List<String> near = [];
    final now = DateTime.now();
    final limit = now.add(Duration(days: days));

    DateTime? tryParseDate(String? s) {
      if (s == null) return null;
      final iso = DateTime.tryParse(s);
      if (iso != null) return iso;
      try {
        final parts = s.split('/');
        if (parts.length == 3) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          return DateTime(y, m, d);
        }
      } catch (_) {}
      return null;
    }

    final soatDate = tryParseDate(_currentUser?.soat);
    final revisionDate = tryParseDate(_currentUser?.revisionTecnica);
    final seguroDate = tryParseDate(_currentUser?.seguroVehicular);

    if (soatDate != null && soatDate.isAfter(now) && !soatDate.isAfter(limit)) {
      near.add('SOAT');
    }
    if (revisionDate != null && revisionDate.isAfter(now) && !revisionDate.isAfter(limit)) {
      near.add('Revisión técnica');
    }
    if (seguroDate != null && seguroDate.isAfter(now) && !seguroDate.isAfter(limit)) {
      near.add('Seguro vehicular');
    }

    return near;
  }

  /// Intenta leer desde SharedPreferences listas que el servidor haya
  /// calculado. Devuelve un mapa con dos claves: 'expired' y 'near', cada una
  /// con una lista de strings. Si el servidor no proporcionó nada, retorna
  /// listas vacías.
  Future<Map<String, List<String>>> getServerDocumentAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
      if (conductorJson == null) return {'expired': [], 'near': []};

      final data = jsonDecode(conductorJson) as Map<String, dynamic>;

      List<String> toList(dynamic value) {
        if (value == null) return [];
        if (value is List) return value.map((e) => e.toString()).toList();
        return [];
      }

      final expired = toList(data['expired_documents']);
      final near = toList(data['near_expiry_documents']);
      return {'expired': expired, 'near': near};
    } catch (_) {
      return {'expired': [], 'near': []};
    }
  }

  // Métodos privados
  void _setStatus(AuthStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure) {
      case ValidationFailure _:
        return failure.message;
      case ServerFailure _:
        return 'Error del servidor. Intenta nuevamente.';
      case NetworkFailure _:
        return 'Sin conexión a internet. Verifica tu conexión.';
      case CacheFailure _:
        return 'Error de cache. Reinicia la aplicación.';
      default:
        return 'Ha ocurrido un error inesperado.';
    }
  }
}
