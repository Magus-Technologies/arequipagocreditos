import 'package:arequipagocreditos/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
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
  final PreRegisterUseCase _preRegisterUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  
  AuthProvider({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetLoggedUserUseCase getLoggedUserUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    required ValidateDniForPasswordRecoveryUseCase validateDniForPasswordRecoveryUseCase,
    required UpdateVehicleDataUseCase updateVehicleDataUseCase,
    required RefreshUserDataUseCase refreshUserDataUseCase,
    required PreRegisterUseCase preRegisterUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _getLoggedUserUseCase = getLoggedUserUseCase,
        _changePasswordUseCase = changePasswordUseCase,
        _validateDniForPasswordRecoveryUseCase = validateDniForPasswordRecoveryUseCase,
        _updateVehicleDataUseCase = updateVehicleDataUseCase,
        _refreshUserDataUseCase = refreshUserDataUseCase,
        _preRegisterUseCase = preRegisterUseCase,
        _deleteAccountUseCase = deleteAccountUseCase;

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _biometricDniKey = 'biometric_dni';
  static const _biometricPasswordKey = 'biometric_password';

  AuthStatus _status = AuthStatus.initial;
  ConductorEntity? _currentUser;
  String? _errorMessage;
  bool _hasBiometricCredentials = false;
  String? _pendingBiometricDni;
  String? _pendingBiometricPassword;

  // Getters
  AuthStatus get status => _status;
  ConductorEntity? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get hasBiometricCredentials => _hasBiometricCredentials;
  bool get needsBiometricSetupOffer => _pendingBiometricDni != null && !_hasBiometricCredentials;

  // Métodos públicos
  Future<void> login(String nroDocumento, String password) async {
    _setStatus(AuthStatus.loading);
    
    final result = await _loginUseCase(nroDocumento, password);
    
    result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _setStatus(AuthStatus.error);
      },
      (conductor) async {
        _currentUser = conductor;
        _errorMessage = null;
        if (!_hasBiometricCredentials) {
          _pendingBiometricDni = nroDocumento;
          _pendingBiometricPassword = password;
        }
        _setStatus(AuthStatus.authenticated);

        // Sincronizar token FCM inmediatamente después del login exitoso
        try {
          final notificationService = NotificationService();
          await notificationService.initializeFCM();
        } catch (e) {
          debugPrint('Error al sincronizar FCM después del login: $e');
        }
      },
    );
  }

  Future<void> logout({bool clearBiometric = true}) async {
    _setStatus(AuthStatus.loading);

    if (clearBiometric) {
      await clearBiometricCredentials();
    }

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

  Future<void> acceptBiometricSetup() async {
    if (_pendingBiometricDni == null || _pendingBiometricPassword == null) return;
    await saveBiometricCredentials(_pendingBiometricDni!, _pendingBiometricPassword!);
    _pendingBiometricDni = null;
    _pendingBiometricPassword = null;
  }

  void declineBiometricSetup() {
    _pendingBiometricDni = null;
    _pendingBiometricPassword = null;
    notifyListeners();
  }

  Future<void> loadBiometricCredentialsStatus() async {
    final dni = await _secureStorage.read(key: _biometricDniKey);
    _hasBiometricCredentials = dni != null;
    notifyListeners();
  }

  Future<void> saveBiometricCredentials(String dni, String password) async {
    await _secureStorage.write(key: _biometricDniKey, value: dni);
    await _secureStorage.write(key: _biometricPasswordKey, value: password);
    _hasBiometricCredentials = true;
    notifyListeners();
  }

  Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: _biometricDniKey);
    await _secureStorage.delete(key: _biometricPasswordKey);
    _hasBiometricCredentials = false;
    notifyListeners();
  }

  Future<bool> loginWithBiometrics(LocalAuthentication localAuth) async {
    try {
      final canAuth = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
      if (!canAuth) return false;

      final didAuth = await localAuth.authenticate(
        localizedReason: 'Autentícate para ingresar a la aplicación',
      );
      if (!didAuth) return false;

      final dni = await _secureStorage.read(key: _biometricDniKey);
      final password = await _secureStorage.read(key: _biometricPasswordKey);
      if (dni == null || password == null) return false;

      await login(dni, password);
      return _status == AuthStatus.authenticated;
    } catch (e) {
      debugPrint('Error en login biométrico: $e');
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _setStatus(AuthStatus.loading);

    final result = await _deleteAccountUseCase.call();

    return result.fold((failure) {
      _errorMessage = _mapFailureToMessage(failure);
      _setStatus(AuthStatus.authenticated); // Mantener autenticado si falla
      return false;
    }, (response) {
      _currentUser = null;
      _errorMessage = null;
      _setStatus(AuthStatus.unauthenticated);
      return true;
    });
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

  Future<Map<String, dynamic>?> preRegister(
    Map<String, dynamic> data,
    Map<String, File> files,
  ) async {
    _setStatus(AuthStatus.loading);

    final result = await _preRegisterUseCase(data, files);

    return result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _setStatus(AuthStatus.unauthenticated);
        return null;
      },
      (response) {
        _errorMessage = null;
        _setStatus(AuthStatus.unauthenticated);
        return response;
      },
    );
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
    if (failure.message.isNotEmpty && 
        failure is! ServerFailure && 
        failure is! NetworkFailure && 
        failure is! CacheFailure) {
      return failure.message;
    }

    switch (failure) {
      case ValidationFailure _:
        return failure.message;
      case AuthenticationFailure _:
        return failure.message;
      case ServerFailure _:
        return 'Error del servidor. Intenta nuevamente.';
      case NetworkFailure _:
        return 'Sin conexión a internet. Verifica tu conexión.';
      case CacheFailure _:
        return 'Error de cache. Reinicia la aplicación.';
      default:
        return failure.message.isNotEmpty ? failure.message : 'Ha ocurrido un error inesperado.';
    }
  }
}
