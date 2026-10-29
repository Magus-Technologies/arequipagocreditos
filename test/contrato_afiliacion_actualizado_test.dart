import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arequipagocreditos/core/constants/app_constants.dart';
import 'package:arequipagocreditos/data/datasources/auth_remote_datasource.dart';
import 'package:arequipagocreditos/data/models/conductor_model.dart';

/// TK-0401: cuando se publica un contrato de afiliación nuevo, el servidor manda `afiliacion_firmada = false` y
/// `afiliacion_actualizada = true`. El app NO debe aplicar su regla de siempre («una vez firmado, siempre firmado»): tiene
/// que bloquear hasta que la persona firme la versión nueva.
Map<String, dynamic> _sesion({required bool firmada}) => {
      'success': true,
      'flag': 0,
      'conductor': {
        'id_conductor': 82,
        'nro_documento': '43373493',
        'nombres': 'JUAN AGUSTO',
        'tipo': 1,
        'foto_perfil_cambiada': 0,
        'afiliacion_firmada': firmada,
        'contrato_afiliacion_url': 'https://credigo.test/conductor/82/contrato-registro/pdf',
      },
    };

/// Lo que responde el servidor al refrescar el perfil.
http.Client _servidor(Map<String, dynamic> perfil) =>
    MockClient((request) async => http.Response(jsonEncode({'success': true, 'conductor': perfil}), 200, headers: {'content-type': 'application/json'}));

Future<void> _iniciar({required bool localFirmada}) async {
  SharedPreferences.setMockInitialValues({
    AppConstants.userStorageKey: jsonEncode(_sesion(firmada: localFirmada)),
    AppConstants.afiliacionFirmadaKey: localFirmada,
  });
}

void main() {
  group('afiliacion_actualizada', () {
    test('se lee del JSON del servidor y por defecto es falso', () {
      final nueva = ConductorModel.fromJson({
        'conductor': {'id_conductor': 82, 'tipo': 1, 'afiliacion_firmada': false, 'afiliacion_actualizada': true},
      });
      final comun = ConductorModel.fromJson(_sesion(firmada: true));

      expect(nueva.afiliacionActualizada, isTrue);
      expect(nueva.afiliacionFirmada, isFalse);
      expect(comun.afiliacionActualizada, isFalse);
      expect(ConductorModel.fromJson(nueva.toJson()).afiliacionActualizada, isTrue);
      expect(nueva.toEntity().afiliacionActualizada, isTrue);
    });

    test('un contrato nuevo anula la firma guardada en el celular: queda sin firmar y se olvida la marca local', () async {
      await _iniciar(localFirmada: true);
      final fuente = AuthRemoteDataSourceImpl(
        client: _servidor({'id_conductor': 82, 'tipo': 1, 'afiliacion_firmada': false, 'afiliacion_actualizada': true}),
      );

      final usuario = await fuente.refreshUserData();

      expect(usuario!.afiliacionFirmada, isFalse);
      expect(usuario.afiliacionActualizada, isTrue);
      expect((await SharedPreferences.getInstance()).getBool(AppConstants.afiliacionFirmadaKey), isFalse);
    });

    test('sin contrato nuevo se mantiene la regla de siempre: una vez firmado, firmado aunque el servidor tarde', () async {
      await _iniciar(localFirmada: true);
      final fuente = AuthRemoteDataSourceImpl(
        client: _servidor({'id_conductor': 82, 'tipo': 1, 'afiliacion_firmada': false}),
      );

      final usuario = await fuente.refreshUserData();

      expect(usuario!.afiliacionFirmada, isTrue);
      expect(usuario.afiliacionActualizada, isFalse);
    });

    test('al firmar la versión nueva, el servidor deja de pedirla y el app la da por firmada', () async {
      await _iniciar(localFirmada: false);
      final fuente = AuthRemoteDataSourceImpl(
        client: _servidor({'id_conductor': 82, 'tipo': 1, 'afiliacion_firmada': true, 'afiliacion_actualizada': false}),
      );

      final usuario = await fuente.refreshUserData();

      expect(usuario!.afiliacionFirmada, isTrue);
      expect(usuario.afiliacionActualizada, isFalse);
    });
  });
}
