import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:arequipagocreditos/core/utils/biometria_celular.dart';

/// TK-0420 — Configuración de acceso: huella / reconocimiento facial solo con lo que el celular tiene REGISTRADO.
void main() {
  group('BiometriaCelular', () {
    test('con sensor pero nada registrado no se puede activar ni rostro ni huella, y se dice por qué', () {
      const bio = BiometriaCelular(hayHardware: true, tipos: []);

      expect(bio.hayConfigurada, isFalse);
      expect(bio.motivoNoDisponible(rostro: true), contains('No tienes rostro registrado'));
      expect(bio.motivoNoDisponible(rostro: false), contains('No tienes huella registrado'));
    });

    test('sin sensor ni nada registrado: no disponible en este dispositivo', () {
      const bio = BiometriaCelular(hayHardware: false, tipos: []);

      expect(bio.motivoNoDisponible(rostro: true), 'No disponible en este dispositivo');
      expect(bio.motivoNoDisponible(rostro: false), 'No disponible en este dispositivo');
    });

    test('Android informa solo strong/weak: rostro y huella se pueden activar y decide el celular', () {
      for (final tipo in [BiometricType.strong, BiometricType.weak]) {
        final bio = BiometriaCelular(hayHardware: true, tipos: [tipo]);

        expect(bio.hayConfigurada, isTrue, reason: '$tipo');
        expect(bio.motivoNoDisponible(rostro: true), isNull);
        expect(bio.motivoNoDisponible(rostro: false), isNull);
        expect(bio.descripcion(rostro: true), contains('huella o el rostro'));
      }
    });

    test('iOS con Face ID: solo el rostro; con Touch ID: solo la huella', () {
      const faceId = BiometriaCelular(hayHardware: true, tipos: [BiometricType.face]);
      expect(faceId.motivoNoDisponible(rostro: true), isNull);
      expect(faceId.motivoNoDisponible(rostro: false), 'Tu celular no tiene lector de huella');
      expect(faceId.descripcion(rostro: true), 'Usa el reconocimiento facial de tu celular');

      const touchId = BiometriaCelular(hayHardware: true, tipos: [BiometricType.fingerprint]);
      expect(touchId.motivoNoDisponible(rostro: false), isNull);
      expect(touchId.motivoNoDisponible(rostro: true), 'Tu celular no tiene reconocimiento facial');
      expect(touchId.descripcion(rostro: false), 'Usa tu huella dactilar');
    });
  });

  group('mensajeErrorBiometria', () {
    test('cuando la persona cancela (o el sistema) no se muestra nada', () {
      for (final codigo in [
        LocalAuthExceptionCode.userCanceled,
        LocalAuthExceptionCode.userRequestedFallback,
        LocalAuthExceptionCode.systemCanceled,
        LocalAuthExceptionCode.authInProgress,
      ]) {
        expect(mensajeErrorBiometria(codigo), isNull, reason: '$codigo');
      }
    });

    test('el resto de fallos dicen qué hacer', () {
      expect(mensajeErrorBiometria(LocalAuthExceptionCode.noBiometricsEnrolled), contains('Ajustes del celular'));
      expect(mensajeErrorBiometria(LocalAuthExceptionCode.noCredentialsSet), contains('bloqueo de pantalla'));
      expect(mensajeErrorBiometria(LocalAuthExceptionCode.temporaryLockout), contains('Espera'));
      expect(mensajeErrorBiometria(LocalAuthExceptionCode.biometricLockout), contains('bloqueada'));
      expect(mensajeErrorBiometria(LocalAuthExceptionCode.unknownError), contains('No se pudo usar la biometría'));

      for (final codigo in LocalAuthExceptionCode.values) {
        final esCancelacion = [
          LocalAuthExceptionCode.userCanceled,
          LocalAuthExceptionCode.userRequestedFallback,
          LocalAuthExceptionCode.systemCanceled,
          LocalAuthExceptionCode.authInProgress,
        ].contains(codigo);
        if (!esCancelacion) {
          expect(mensajeErrorBiometria(codigo), isNotNull, reason: '$codigo debe explicar qué pasó');
        }
      }
    });
  });
}
