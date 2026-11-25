import 'dart:io';

import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/domain/entities/conductor_entity.dart';
import 'package:arequipagocreditos/domain/repositories/auth_repository.dart';
import 'package:arequipagocreditos/domain/usecases/auth_usecases.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TK-0473 (Gian, 24-nov): «con el PIN sale un error ("No se pudo verificar tu sesión") y al segundo intento recién ingresa».
// Causa: «Cerrar sesión» borra el DNI y la contraseña guardados pero deja el PIN; al volver a entrar con la contraseña solo se ofrecía
// guardarlos por la huella/Face ID, así que el PIN quedaba activo SIN credenciales y cada PIN correcto terminaba en ese mensaje (que
// además era el mismo para CUALQUIER fallo del servidor). Ahora el login con contraseña las deja guardadas cuando hay PIN y el login
// con PIN dice por qué falló y repite una vez los fallos pasajeros.

/// Repositorio falso: cada llamada a `login` devuelve lo siguiente de la cola (o lo último si ya no hay) y se anotan las credenciales usadas.
class _RepoFalso implements AuthRepository {
  _RepoFalso(this.respuestas);

  final List<Either<Failure, ConductorEntity>> respuestas;
  final List<String> llamadas = [];

  @override
  Future<Either<Failure, ConductorEntity>> login(String nroDocumento, String password) async {
    llamadas.add('$nroDocumento:$password');
    return respuestas.length > 1 ? respuestas.removeAt(0) : respuestas.first;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

const _conductor = ConductorEntity(
  idConductor: 304,
  nombres: 'CONDUCTOR DE PRUEBA',
  nroDocumento: '72856944',
  telefono: '959000000',
  direccion: 'Arequipa',
  correo: 'x@example.com',
  flag: 0,
  tipo: 1,
  fotoPerfilCambiada: false,
);

Either<Failure, ConductorEntity> _ok() => Either.right(_conductor);
Either<Failure, ConductorEntity> _falla(Failure f) => Either.left(f);

AuthProvider _provider(_RepoFalso repo) => AuthProvider(
      loginUseCase: LoginUseCase(repo),
      logoutUseCase: LogoutUseCase(repo),
      getLoggedUserUseCase: GetLoggedUserUseCase(repo),
      changePasswordUseCase: ChangePasswordUseCase(repo),
      validateDniForPasswordRecoveryUseCase: ValidateDniForPasswordRecoveryUseCase(repo),
      updateVehicleDataUseCase: UpdateVehicleDataUseCase(repo),
      refreshUserDataUseCase: RefreshUserDataUseCase(repo),
      preRegisterUseCase: PreRegisterUseCase(repo),
      conductorPreRegisterUseCase: ConductorPreRegisterUseCase(repo),
      deleteAccountUseCase: DeleteAccountUseCase(repo),
    );

const _almacen = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

/// Deja el celular como lo tiene quien configuró el PIN `1234`: [conCredenciales] dice si el DNI y la contraseña siguen guardados.
Future<void> _celularConPin({bool conCredenciales = true, bool pinActivo = true}) async {
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({'access_pin_enabled': pinActivo});

  final provider = _provider(_RepoFalso([_ok()]));
  await provider.createPin('1234');
  if (conCredenciales) {
    await provider.saveBiometricCredentials('72856944', 'clave-guardada');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('login con contraseña (la causa del ticket)', () {
    test('con el PIN activo y sin credenciales guardadas (tras cerrar sesión), el login con contraseña las vuelve a guardar', () async {
      await _celularConPin(conCredenciales: false);
      final provider = _provider(_RepoFalso([_ok()]));

      await provider.login('72856944', 'mi-clave');

      expect(provider.isAuthenticated, isTrue);
      expect(await _almacen.read(key: 'biometric_dni'), '72856944');
      expect(await _almacen.read(key: 'biometric_password'), 'mi-clave');
      expect(provider.hasBiometricCredentials, isTrue);
      // Ya quedaron guardadas: no se vuelve a ofrecer guardarlas (huella/Face ID).
      expect(provider.needsBiometricSetupOffer, isFalse);
    });

    test('y entonces el PIN correcto entra sin error', () async {
      await _celularConPin(conCredenciales: false);
      await _provider(_RepoFalso([_ok()])).login('72856944', 'mi-clave');

      final repo = _RepoFalso([_ok()]);
      final provider = _provider(repo);
      final resultado = await provider.loginWithPin('1234');

      expect(resultado, PinLoginResult.success);
      expect(repo.llamadas, ['72856944:mi-clave']);
    });

    test('si cambió su contraseña, el login con la nueva reemplaza la guardada', () async {
      await _celularConPin();
      final provider = _provider(_RepoFalso([_ok()]));

      await provider.login('72856944', 'clave-nueva');

      expect(await _almacen.read(key: 'biometric_password'), 'clave-nueva');
    });

    test('sin PIN ni credenciales guardadas no se guarda nada solo: eso lo ofrece el diálogo de huella/Face ID', () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final provider = _provider(_RepoFalso([_ok()]));

      await provider.login('72856944', 'mi-clave');

      expect(await _almacen.read(key: 'biometric_dni'), isNull);
      expect(provider.needsBiometricSetupOffer, isTrue);
    });

    test('con el PIN apagado en Configuración tampoco se guarda nada solo', () async {
      await _celularConPin(conCredenciales: false, pinActivo: false);
      final provider = _provider(_RepoFalso([_ok()]));

      await provider.login('72856944', 'mi-clave');

      expect(await _almacen.read(key: 'biometric_dni'), isNull);
    });
  });

  group('login con PIN', () {
    test('PIN correcto con credenciales guardadas: entra y la sesión queda iniciada', () async {
      await _celularConPin();
      final repo = _RepoFalso([_ok()]);
      final provider = _provider(repo);

      expect(await provider.loginWithPin('1234'), PinLoginResult.success);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.isLocked, isFalse);
      expect(repo.llamadas, ['72856944:clave-guardada']);
    });

    test('PIN correcto SIN credenciales guardadas: no es un PIN equivocado ni cuenta como intento fallido', () async {
      await _celularConPin(conCredenciales: false);
      final provider = _provider(_RepoFalso([_ok()]));

      expect(await provider.loginWithPin('1234'), PinLoginResult.noCredentials);
      expect((await SharedPreferences.getInstance()).getInt('pin_failed_attempts'), 0);
    });

    test('PIN incorrecto sigue siendo PIN incorrecto y a los 5 intentos se bloquea', () async {
      await _celularConPin();
      final provider = _provider(_RepoFalso([_ok()]));

      for (var i = 0; i < 4; i++) {
        expect(await provider.loginWithPin('0000'), PinLoginResult.wrongPin);
      }
      expect(await provider.loginWithPin('0000'), PinLoginResult.lockedOut);
    });

    test('un fallo pasajero del servidor se repite UNA vez y entra (el «al segundo intento sí» del ticket)', () async {
      await _celularConPin();
      final repo = _RepoFalso([_falla(const ServerFailure('Error al iniciar sesión: FormatException')), _ok()]);
      final provider = _provider(repo);

      expect(await provider.loginWithPin('1234'), PinLoginResult.success);
      expect(repo.llamadas.length, 2);
      expect(provider.isAuthenticated, isTrue);
    });

    test('sin internet ni en el reintento: se queda en el teclado con el motivo real y la sesión NO cambia de estado', () async {
      await _celularConPin();
      final repo = _RepoFalso([_falla(const NetworkFailure('No hay conexión a internet'))]);
      final provider = _provider(repo);
      final estados = <AuthStatus>[];
      provider.addListener(() => estados.add(provider.status));

      expect(await provider.loginWithPin('1234'), PinLoginResult.unreachable);
      expect(provider.pinLoginMessage, contains('Sin conexión a internet'));
      expect(repo.llamadas.length, 2); // el intento y su reintento
      // Antes el login ponía el estado en «error» y la pantalla del PIN era reemplazada por la de bienvenida.
      expect(estados, isNot(contains(AuthStatus.error)));
      expect(estados, isNot(contains(AuthStatus.loading)));
    });

    test('el servidor tardó demasiado: lo dice, no dice que la sesión no se pudo verificar', () async {
      await _celularConPin();
      final provider = _provider(_RepoFalso([_falla(const ServerFailure('Error al iniciar sesión: TimeoutException after 0:00:30'))]));

      expect(await provider.loginWithPin('1234'), PinLoginResult.unreachable);
      expect(provider.pinLoginMessage, contains('tardó demasiado'));
    });

    test('«Credenciales incorrectas.»: la contraseña guardada ya no sirve → se dice, NO se reintenta y se borra para guardar la nueva', () async {
      await _celularConPin();
      final repo = _RepoFalso([_falla(const AuthenticationFailure('Credenciales incorrectas.'))]);
      final provider = _provider(repo);

      expect(await provider.loginWithPin('1234'), PinLoginResult.rejected);
      expect(provider.pinLoginMessage, contains('contraseña guardada ya no es válida'));
      expect(repo.llamadas.length, 1);
      expect(await _almacen.read(key: 'biometric_password'), isNull);

      // Al entrar con la contraseña nueva queda guardada y el PIN vuelve a servir.
      await _provider(_RepoFalso([_ok()])).login('72856944', 'clave-nueva');
      final repo2 = _RepoFalso([_ok()]);
      expect(await _provider(repo2).loginWithPin('1234'), PinLoginResult.success);
      expect(repo2.llamadas, ['72856944:clave-nueva']);
    });

    test('un motivo del servidor que no es la contraseña (registro sin aprobar) se muestra tal cual y no borra las credenciales', () async {
      await _celularConPin();
      final provider = _provider(_RepoFalso([_falla(const AuthenticationFailure('Tu registro aún no ha sido aprobado.'))]));

      expect(await provider.loginWithPin('1234'), PinLoginResult.rejected);
      expect(provider.pinLoginMessage, 'Tu registro aún no ha sido aprobado.');
      expect(await _almacen.read(key: 'biometric_password'), 'clave-guardada');
    });
  });
}
