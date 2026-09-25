import 'package:arequipagocreditos/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arequipagocreditos/core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/conductor_entity.dart';
import '../../domain/usecases/auth_usecases.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Resultado de intentar entrar con el PIN propio de la app.
enum PinLoginResult {
  success,
  wrongPin,
  // Se supero el limite de intentos: el PIN se borro por seguridad y hay
  // que volver al login normal (DNI + contraseña).
  lockedOut,
  // El PIN era correcto pero no hay credenciales guardadas para completar
  // el login real (caso raro: se corrompio el storage). Tambien exige
  // volver al login normal.
  noCredentials,
}

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetLoggedUserUseCase _getLoggedUserUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final ValidateDniForPasswordRecoveryUseCase _validateDniForPasswordRecoveryUseCase;
  final UpdateVehicleDataUseCase _updateVehicleDataUseCase;
  final RefreshUserDataUseCase _refreshUserDataUseCase;
  final PreRegisterUseCase _preRegisterUseCase;
  final ConductorPreRegisterUseCase _conductorPreRegisterUseCase;
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
    required ConductorPreRegisterUseCase conductorPreRegisterUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _getLoggedUserUseCase = getLoggedUserUseCase,
        _changePasswordUseCase = changePasswordUseCase,
        _validateDniForPasswordRecoveryUseCase = validateDniForPasswordRecoveryUseCase,
        _updateVehicleDataUseCase = updateVehicleDataUseCase,
        _refreshUserDataUseCase = refreshUserDataUseCase,
        _preRegisterUseCase = preRegisterUseCase,
        _conductorPreRegisterUseCase = conductorPreRegisterUseCase,
        _deleteAccountUseCase = deleteAccountUseCase;

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _biometricDniKey = 'biometric_dni';
  static const _biometricPasswordKey = 'biometric_password';
  static const _sessionPausedAtKey = 'session_paused_at';
  static const sessionTimeoutMinutes = 15;

  // Preferencias de "Configuración de acceso" (Más > Configuración de
  // acceso): cuales metodos puede usar la persona para el login rapido.
  // "PIN" es un PIN PROPIO de la app (ver createPin/loginWithPin), no el
  // PIN del celular — eso no se puede leer desde ninguna app. Face/huella
  // siguen usando local_auth, que delega en la biometria que el celular ya
  // tenga configurada.
  static const _accessPinKey = 'access_pin_enabled';
  static const _accessFaceKey = 'access_face_enabled';
  static const _accessFingerprintKey = 'access_fingerprint_enabled';

  // PIN propio de la app: hash + salt (nunca el PIN en texto plano) en
  // FlutterSecureStorage, y un contador de intentos fallidos en
  // SharedPreferences para bloquear tras varios intentos.
  static const _pinHashKey = 'app_pin_hash';
  static const _pinSaltKey = 'app_pin_salt';
  static const _pinFailedAttemptsKey = 'pin_failed_attempts';
  static const maxPinAttempts = 5;

  AuthStatus _status = AuthStatus.initial;
  ConductorEntity? _currentUser;
  String? _errorMessage;
  bool _hasBiometricCredentials = false;
  String? _pendingBiometricDni;
  String? _pendingBiometricPassword;
  bool _biometricReloginDeclined = false;
  bool _accessPinEnabled = true;
  bool _accessFaceEnabled = true;
  bool _accessFingerprintEnabled = true;
  bool _hasPinConfigured = false;

  /// Bloqueo de acceso (estilo Yape): al abrir el app o volver del segundo
  /// plano después de [lockAfterSeconds], se pide el método de acceso aunque
  /// la sesión siga válida.
  bool _locked = false;

  // Getters
  AuthStatus get status => _status;
  ConductorEntity? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get hasBiometricCredentials => _hasBiometricCredentials;
  bool get hasPinConfigured => _hasPinConfigured;
  bool get accessPinEnabled => _accessPinEnabled;
  bool get accessFaceEnabled => _accessFaceEnabled;
  bool get accessFingerprintEnabled => _accessFingerprintEnabled;
  bool get hasAnyAccessMethodEnabled => _accessPinEnabled || _accessFaceEnabled || _accessFingerprintEnabled;

  /// ¿Hay un método de acceso realmente utilizable para desbloquear?
  /// (`_accessPinEnabled` ya incluye que el PIN esté creado; la biometría
  /// necesita credenciales guardadas y su toggle activo.)
  bool get hasUsableAccessMethod =>
      _accessPinEnabled ||
      (_hasBiometricCredentials && (_accessFaceEnabled || _accessFingerprintEnabled));

  bool get isLocked => _locked;

  /// Segundos en segundo plano a partir de los cuales se bloquea el acceso.
  static const lockAfterSeconds = 60;

  /// Bloquea el acceso (pide PIN/biometría para volver a entrar).
  void lock() {
    if (_locked) return;
    _locked = true;
    notifyListeners();
  }

  /// Desbloquea el acceso sin cerrar la sesión.
  void unlock() {
    if (!_locked) return;
    _locked = false;
    notifyListeners();
  }
  // Tiene credenciales pendientes de login manual → se puede guardar directamente
  bool get needsBiometricSetupOffer => _pendingBiometricDni != null && !_hasBiometricCredentials;
  // Auto-login sin biométrico configurado → pedir al usuario que cierre e inicie sesión
  bool get needsBiometricSetupViaRelogin => _pendingBiometricDni == null && !_hasBiometricCredentials && !_biometricReloginDeclined && _status == AuthStatus.authenticated;

  /// Verifica la contraseña actual SIN tocar el AuthStatus global.
  ///
  /// `login()` cambia `_status` (loading/authenticated/error), y ese estado
  /// lo escucha el router raíz en `main.dart` para decidir qué pantalla
  /// mostrar en TODA la app. Si se reutiliza `login()` para confirmar la
  /// contraseña desde un diálogo de configuración, una contraseña
  /// incorrecta dispara AuthStatus.error y el router raíz reemplaza la
  /// pantalla completa por la de login — el diálogo (y su mensaje de error)
  /// desaparecen antes de que la persona los vea. Este método hace el mismo
  /// llamado al backend pero solo devuelve true/false.
  Future<bool> verifyPasswordAndPrepareBiometric(String nroDocumento, String password) async {
    final result = await _loginUseCase(nroDocumento, password);

    return result.fold(
      (failure) => false,
      (conductor) {
        _currentUser = conductor;
        if (!_hasBiometricCredentials) {
          _pendingBiometricDni = nroDocumento;
          _pendingBiometricPassword = password;
        }
        return true;
      },
    );
  }

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
        // Login manual: la sesión recién empieza, no hay nada que desbloquear.
        _locked = false;
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
        _biometricReloginDeclined = false;
        _locked = false;
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
    _biometricReloginDeclined = true;
    notifyListeners();
  }

  /// Consulta si hay credenciales guardadas para el login biométrico.
  ///
  /// Nunca propaga el error: el keystore de Android puede fallar o quedar
  /// corrupto, y eso no debe impedir que la persona entre al app. Si no se
  /// puede leer, simplemente se asume que no hay biometría configurada.
  Future<void> loadBiometricCredentialsStatus() async {
    try {
      final dni = await _secureStorage
          .read(key: _biometricDniKey)
          .timeout(const Duration(seconds: 5));
      _hasBiometricCredentials = dni != null;
    } catch (_) {
      _hasBiometricCredentials = false;
    }
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

  /// Lee las preferencias de "Configuración de acceso" (PIN / reconocimiento
  /// facial / huella) guardadas en el dispositivo, y de paso el estado del
  /// PIN (loadPinStatus) — asi los que ya llamaban a este metodo no tienen
  /// que acordarse de llamar a uno nuevo.
  ///
  /// Face/huella arrancan activos por defecto (aprovechan lo que el celular
  /// ya tenga configurado). PIN arranca en falso SIEMPRE que no exista un
  /// PIN creado — no tendria sentido mostrar el toggle prendido sin que la
  /// persona haya elegido un PIN todavia.
  Future<void> loadAccessMethodPrefs() async {
    await loadPinStatus();
    final prefs = await SharedPreferences.getInstance();
    _accessPinEnabled = (prefs.getBool(_accessPinKey) ?? false) && _hasPinConfigured;
    _accessFaceEnabled = prefs.getBool(_accessFaceKey) ?? true;
    _accessFingerprintEnabled = prefs.getBool(_accessFingerprintKey) ?? true;
    notifyListeners();
  }

  /// Activa/desactiva uno o mas metodos de acceso. Si al terminar ninguno
  /// queda activo, no tiene sentido seguir guardando las credenciales del
  /// login rapido, asi que se limpian automaticamente.
  Future<void> setAccessMethodEnabled({bool? pin, bool? face, bool? fingerprint}) async {
    final prefs = await SharedPreferences.getInstance();
    if (pin != null) {
      _accessPinEnabled = pin;
      await prefs.setBool(_accessPinKey, pin);
      if (!pin) await clearPin();
    }
    if (face != null) {
      _accessFaceEnabled = face;
      await prefs.setBool(_accessFaceKey, face);
    }
    if (fingerprint != null) {
      _accessFingerprintEnabled = fingerprint;
      await prefs.setBool(_accessFingerprintKey, fingerprint);
    }
    if (!hasAnyAccessMethodEnabled && _hasBiometricCredentials) {
      await clearBiometricCredentials();
    }
    notifyListeners();
  }

  Future<bool> loginWithBiometrics(LocalAuthentication localAuth) async {
    try {
      if (!hasAnyAccessMethodEnabled) return false;

      final canAuth = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
      if (!canAuth) return false;

      // biometricOnly: true siempre — ahora el PIN es propio de la app
      // (ver loginWithPin), no hace falta pedirle al SO que ofrezca su
      // PIN/patron como alternativa aca.
      final didAuth = await localAuth.authenticate(
        localizedReason: 'Autentícate para ingresar a la aplicación',
        biometricOnly: true,
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

  static String _generatePinSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  /// Consulta si ya existe un PIN propio de la app creado en este
  /// dispositivo (no el estado del toggle — eso es accessPinEnabled).
  Future<void> loadPinStatus() async {
    try {
      final hash = await _secureStorage.read(key: _pinHashKey).timeout(const Duration(seconds: 5));
      _hasPinConfigured = hash != null;
    } catch (_) {
      _hasPinConfigured = false;
    }
  }

  /// Crea (o reemplaza) el PIN propio de la app. Solo se guarda el hash +
  /// salt, nunca el PIN en texto plano.
  Future<void> createPin(String pin) async {
    final salt = _generatePinSalt();
    final hash = _hashPin(pin, salt);
    await _secureStorage.write(key: _pinSaltKey, value: salt);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pinFailedAttemptsKey, 0);
    _hasPinConfigured = true;
    notifyListeners();
  }

  Future<bool> _verifyPinOnly(String pin) async {
    final salt = await _secureStorage.read(key: _pinSaltKey);
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    if (salt == null || storedHash == null) return false;
    return _hashPin(pin, salt) == storedHash;
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinFailedAttemptsKey);
    _hasPinConfigured = false;
    notifyListeners();
  }

  /// Verifica el PIN y, si es correcto, reutiliza las credenciales
  /// guardadas para completar un login real — igual que loginWithBiometrics
  /// pero verificando el PIN propio en vez de pedirle biometria al SO.
  ///
  /// Tras [maxPinAttempts] intentos fallidos, el PIN se borra por seguridad
  /// y hay que volver al login normal con DNI + contraseña.
  Future<PinLoginResult> loginWithPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final valid = await _verifyPinOnly(pin);

    if (!valid) {
      final attempts = (prefs.getInt(_pinFailedAttemptsKey) ?? 0) + 1;
      await prefs.setInt(_pinFailedAttemptsKey, attempts);
      if (attempts >= maxPinAttempts) {
        await clearPin();
        await setAccessMethodEnabled(pin: false);
        return PinLoginResult.lockedOut;
      }
      return PinLoginResult.wrongPin;
    }

    await prefs.setInt(_pinFailedAttemptsKey, 0);

    final dni = await _secureStorage.read(key: _biometricDniKey);
    final password = await _secureStorage.read(key: _biometricPasswordKey);
    if (dni == null || password == null) return PinLoginResult.noCredentials;

    await login(dni, password);
    return _status == AuthStatus.authenticated ? PinLoginResult.success : PinLoginResult.noCredentials;
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

    // Si el app fue cerrado mientras estaba en background, verificar si la sesión expiró
    final prefs = await SharedPreferences.getInstance();
    final savedPause = prefs.getString(_sessionPausedAtKey);
    if (savedPause != null) {
      await prefs.remove(_sessionPausedAtKey);
      final pausedAt = DateTime.tryParse(savedPause);
      if (pausedAt != null) {
        final elapsed = DateTime.now().difference(pausedAt);
        if (elapsed.inMinutes >= sessionTimeoutMinutes) {
          await _logoutUseCase();
          _currentUser = null;
          _setStatus(AuthStatus.unauthenticated);
          return;
        }
      }
    }

    // El estado SIEMPRE tiene que terminar resuelto. Antes el callback de
    // `fold` era async y `fold` no lo espera: si algo fallaba adentro, el
    // status quedaba en `loading` y el splash se congelaba en "Validando
    // sesión..." sin manera de salir.
    try {
      final result = await _getLoggedUserUseCase();

      final conductor = result.fold(
        (failure) => null,
        (conductor) => conductor,
      );

      if (conductor == null) {
        _currentUser = null;
        _setStatus(AuthStatus.unauthenticated);
        return;
      }

      _currentUser = conductor;
      await loadBiometricCredentialsStatus();
      await loadAccessMethodPrefs();
      // Bloqueo al abrir (estilo Yape): con la sesión restaurada, si hay un
      // método de acceso configurado se pide desbloquear antes de entrar.
      _locked = hasUsableAccessMethod;
      _setStatus(AuthStatus.authenticated);
    } catch (_) {
      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<void> persistSessionPause() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionPausedAtKey, DateTime.now().toIso8601String());
  }

  Future<void> clearSessionPause() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionPausedAtKey);
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

  /// Refresca datos del servidor SIN cambiar a AuthStatus.loading.
  /// Usar tras operaciones exitosas (firma, etc.) para evitar flash de SplashPage.
  Future<void> refreshUserDataSilently() async {
    final result = await _refreshUserDataUseCase.call();
    result.fold((_) {}, (conductor) {
      if (conductor != null) {
        _currentUser = conductor;
        _errorMessage = null;
        notifyListeners();
      }
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

  Future<Map<String, dynamic>?> conductorPreRegister(
    Map<String, dynamic> data,
    Map<String, File> files,
  ) async {
    _setStatus(AuthStatus.loading);

    final result = await _conductorPreRegisterUseCase(data, files);

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
