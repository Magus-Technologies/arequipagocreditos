import 'package:flutter/material.dart';
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
      // Refrescar datos de usuario desde cache/remote para sincronizar
      await checkAuthStatus();
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
