import 'package:local_auth/local_auth.dart';

/// TK-0420 — qué biometría tiene REALMENTE el celular.
///
/// `canCheckBiometrics` solo dice que el equipo trae el sensor (huella o rostro), aunque la persona no haya registrado ninguna;
/// `isDeviceSupported()` es verdadero con solo tener PIN/patrón de pantalla. Con cualquiera de los dos, el app dejaba activar el
/// ingreso biométrico y después fallaba en silencio (`authenticate(biometricOnly: true)` lanza «sin biometría registrada») y la
/// persona terminaba otra vez en el teclado del PIN. Lo que cuenta es lo que ya dejó registrado en Ajustes del celular
/// (`getAvailableBiometrics`).
///
/// Android no distingue huella de rostro: solo informa `strong`/`weak`, y es el sistema quien decide cuál usar al pedir la
/// autenticación. iOS sí informa `face` (Face ID) o `fingerprint` (Touch ID).
class BiometriaCelular {
  const BiometriaCelular({required this.hayHardware, required this.tipos});

  /// El equipo trae sensor de huella o de rostro, aunque no haya nada registrado.
  final bool hayHardware;

  /// Lo que la persona SÍ tiene registrado en el celular.
  final List<BiometricType> tipos;

  bool get tieneRostro => tipos.contains(BiometricType.face);

  bool get tieneHuella => tipos.contains(BiometricType.fingerprint);

  /// Android: hay biometría registrada pero no dice de qué clase.
  bool get _sinDetalle => tipos.contains(BiometricType.strong) || tipos.contains(BiometricType.weak);

  /// Hay al menos una biometría registrada: solo así tiene sentido ofrecer o intentar el ingreso biométrico.
  bool get hayConfigurada => tieneRostro || tieneHuella || _sinDetalle;

  bool get rostroDisponible => tieneRostro || _sinDetalle;

  bool get huellaDisponible => tieneHuella || _sinDetalle;

  /// Lo que se le dice a la persona bajo el interruptor cuando no puede usarlo, o null si puede.
  String? motivoNoDisponible({required bool rostro}) {
    if (!hayHardware && !hayConfigurada) return 'No disponible en este dispositivo';
    if (!hayConfigurada) {
      return 'No tienes ${rostro ? 'rostro' : 'huella'} registrado en tu celular. Regístralo en Ajustes del celular para usar esta opción.';
    }
    if (rostro && !rostroDisponible) return 'Tu celular no tiene reconocimiento facial';
    if (!rostro && !huellaDisponible) return 'Tu celular no tiene lector de huella';
    return null;
  }

  /// Texto bajo el interruptor cuando SÍ se puede usar.
  String descripcion({required bool rostro}) {
    if (_sinDetalle && !tieneRostro && !tieneHuella) {
      return 'Usa la huella o el rostro que tengas registrados en tu celular';
    }
    return rostro ? 'Usa el reconocimiento facial de tu celular' : 'Usa tu huella dactilar';
  }

  /// Consulta el celular. Nunca lanza: si algo falla se asume que no hay nada registrado.
  static Future<BiometriaCelular> consultar(LocalAuthentication localAuth) async {
    var hayHardware = false;
    var tipos = <BiometricType>[];
    try {
      hayHardware = await localAuth.canCheckBiometrics;
    } catch (_) {}
    try {
      tipos = await localAuth.getAvailableBiometrics();
    } catch (_) {}
    return BiometriaCelular(hayHardware: hayHardware || tipos.isNotEmpty, tipos: tipos);
  }
}

/// Mensaje para la persona cuando la biometría falla, o null si no hace falta decir nada (canceló ella misma o el sistema).
String? mensajeErrorBiometria(LocalAuthExceptionCode codigo) {
  switch (codigo) {
    case LocalAuthExceptionCode.userCanceled:
    case LocalAuthExceptionCode.userRequestedFallback:
    case LocalAuthExceptionCode.systemCanceled:
    case LocalAuthExceptionCode.authInProgress:
      return null;
    case LocalAuthExceptionCode.noBiometricsEnrolled:
      return 'Tu celular no tiene huella ni rostro registrados. Regístralos en Ajustes del celular y vuelve a intentar.';
    case LocalAuthExceptionCode.noBiometricHardware:
      return 'Este celular no tiene lector de huella ni reconocimiento facial.';
    case LocalAuthExceptionCode.noCredentialsSet:
      return 'Tu celular no tiene bloqueo de pantalla (PIN, patrón o contraseña). Configúralo en Ajustes del celular y vuelve a intentar.';
    case LocalAuthExceptionCode.temporaryLockout:
      return 'Demasiados intentos fallidos. Espera unos segundos e inténtalo otra vez.';
    case LocalAuthExceptionCode.biometricLockout:
      return 'La biometría quedó bloqueada por demasiados intentos. Desbloquea el celular con su PIN o patrón y vuelve a intentar.';
    case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
      return 'El sensor no está disponible por ahora. Inténtalo de nuevo en unos segundos.';
    case LocalAuthExceptionCode.timeout:
      return 'Se acabó el tiempo. Inténtalo de nuevo.';
    case LocalAuthExceptionCode.uiUnavailable:
    case LocalAuthExceptionCode.deviceError:
    case LocalAuthExceptionCode.unknownError:
      return 'No se pudo usar la biometría del celular. Inténtalo de nuevo.';
  }
}
