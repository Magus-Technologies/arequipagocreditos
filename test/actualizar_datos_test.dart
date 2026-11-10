import 'dart:convert';
import 'dart:io';
import 'package:arequipagocreditos/core/errors/exceptions.dart';
import 'package:arequipagocreditos/data/datasources/documentos_pendientes_remote_datasource.dart';
import 'package:arequipagocreditos/domain/entities/conductor_entity.dart';
import 'package:arequipagocreditos/presentation/pages/actualizar_datos_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

/// Arequipa Go Central (10-nov): la alerta «Datos por actualizar» no se quitaba porque el app no dejaba subir el DNI/CE ni el recibo.
/// Ahora «Actualizar ahora» abre «Actualizar mis datos»: ahí se sube el documento, que queda «En revisión» hasta que el personal lo
/// apruebe en el dashboard; si lo rechaza, se muestra el motivo y se sube otro.

const _dniAnverso = {
  'codigo': 'doc_identidad_anverso',
  'mensaje': 'Falta el DNI/CE (anverso)',
  'corto': 'DNI/CE (anverso)',
  'descripcion': 'Debe subir la foto del anverso de su documento de identidad.',
  'subible_desde_app': true,
  'envio': null,
};

const _recibo = {
  'codigo': 'recibo_servicios',
  'mensaje': 'Falta el Recibo de Servicios (Luz/Agua)',
  'corto': 'Recibo de Servicios (Luz/Agua)',
  'descripcion': 'Debe subir un recibo de luz o agua.',
  'subible_desde_app': true,
  'envio': null,
};

const _telefono = {
  'codigo': 'telefono',
  'mensaje': 'Falta el teléfono',
  'corto': 'teléfono',
  'descripcion': 'Debe registrar un número de teléfono.',
  'subible_desde_app': false,
  'envio': null,
};

const _foto = {
  'codigo': 'foto_perfil',
  'mensaje': 'Falta la foto de perfil',
  'corto': 'foto de perfil',
  'descripcion': 'Debe subir una foto de perfil.',
  'subible_desde_app': false,
  'envio': null,
};

ConductorEntity _conductor(List<Map<String, dynamic>> pendientes) => ConductorEntity(
      idConductor: 82,
      nombres: 'Juan Perez',
      nroDocumento: '12345678',
      telefono: '999888777',
      direccion: 'Calle 1',
      correo: 'juan@example.com',
      flag: 1,
      tipo: 3,
      fotoPerfilCambiada: false,
      datosPendientes: pendientes,
    );

/// La sesión reducida a lo que lee la pantalla; al refrescar, el «servidor» devuelve lo que se haya programado.
class _AuthFalso extends ChangeNotifier implements AuthProvider {
  _AuthFalso(this._usuario, {this.alRefrescar});

  ConductorEntity _usuario;
  final List<Map<String, dynamic>> Function()? alRefrescar;
  int refrescos = 0;

  @override
  ConductorEntity? get currentUser => _usuario;

  @override
  Future<void> refreshUserDataSilently() async {
    refrescos++;
    if (alRefrescar != null) {
      _usuario = _conductor(alRefrescar!());
      notifyListeners();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lo que el servidor contesta a `POST /app/documentos-pendientes`.
http.Response _respuesta(int codigo, Map<String, dynamic> cuerpo) => http.Response(
      jsonEncode(cuerpo),
      codigo,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

late File _archivo;

Future<void> _pintar(
  WidgetTester tester, {
  required _AuthFalso auth,
  required MockClient cliente,
  ElegirDocumento? elegir,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: ActualizarDatosPage(
          servicio: DocumentosPendientesRemoteDataSource(client: cliente),
          elegirDocumento: elegir ?? (context, titulo) async => _archivo,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// La subida lee el archivo del disco (E/S real): dentro de un testWidgets solo avanza con `runAsync`. No se usa pumpAndSettle porque
/// el indicador de «Enviando…» anima sin parar.
Future<void> _esperarEnvio(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  }
}

MockClient _clienteQue(http.Response Function(http.BaseRequest) responder, {List<http.BaseRequest>? peticiones}) {
  return MockClient((request) async {
    peticiones?.add(request);
    return responder(request);
  });
}

void main() {
  setUpAll(() {
    _archivo = File('${Directory.systemTemp.path}/dni_prueba_${DateTime.now().microsecondsSinceEpoch}.jpg')
      ..writeAsBytesSync(List<int>.filled(2048, 7));
  });

  tearDownAll(() {
    if (_archivo.existsSync()) _archivo.deleteSync();
  });

  group('pantalla «Actualizar mis datos»', () {
    testWidgets('el DNI y el recibo se pueden subir; teléfono y foto llevan a su asesor o al perfil', (tester) async {
      final auth = _AuthFalso(_conductor([_dniAnverso, _recibo, _telefono, _foto]));

      await _pintar(tester, auth: auth, cliente: _clienteQue((_) => _respuesta(500, {})));

      expect(find.byKey(const Key('subir_doc_identidad_anverso')), findsOneWidget);
      expect(find.byKey(const Key('subir_recibo_servicios')), findsOneWidget);
      // Lo que no se puede subir desde aquí: el teléfono lo cambia su asesor; la foto se cambia desde el perfil.
      expect(find.byKey(const Key('subir_telefono')), findsNothing);
      expect(find.byKey(const Key('asesor_telefono')), findsOneWidget);
      expect(find.byKey(const Key('ir_perfil_foto_perfil')), findsOneWidget);
    });

    testWidgets('al subir manda el archivo con su tipo y el cliente; queda «En revisión» y se refrescan sus datos', (tester) async {
      final peticiones = <http.BaseRequest>[];
      final auth = _AuthFalso(
        _conductor([_dniAnverso, _recibo]),
        // Tras subir, el servidor ya marca el DNI como enviado.
        alRefrescar: () => [
          {..._dniAnverso, 'envio': {'estado': 'pendiente', 'motivo': null}},
          _recibo,
        ],
      );
      final cliente = _clienteQue(
        (_) => _respuesta(201, {'success': true, 'message': 'Documento enviado.', 'datos_pendientes': <Object>[]}),
        peticiones: peticiones,
      );

      await _pintar(tester, auth: auth, cliente: cliente);
      await tester.tap(find.byKey(const Key('subir_doc_identidad_anverso')));
      await _esperarEnvio(tester);

      expect(peticiones, hasLength(1));
      // MockClient entrega la petición ya armada (cuerpo multipart en texto): se mira lo que viaja.
      final peticion = peticiones.single as http.Request;
      expect(peticion.url.path, endsWith('/app/documentos-pendientes'));
      expect(peticion.headers['content-type'], contains('multipart/form-data'));
      expect(peticion.body, contains('name="idConductor"'));
      expect(peticion.body, contains('82'));
      expect(peticion.body, contains('name="nro_documento"'));
      expect(peticion.body, contains('12345678'));
      expect(peticion.body, contains('name="tipo_documento"'));
      expect(peticion.body, contains('doc_identidad_anverso'));
      expect(peticion.body, contains('name="archivo"'));
      expect(auth.refrescos, 1);

      expect(find.byKey(const Key('en_revision_doc_identidad_anverso')), findsOneWidget);
      expect(find.text('En revisión'), findsOneWidget);
      // Ya no se puede volver a subir mientras lo revisan; el otro documento sigue pidiéndose.
      expect(find.byKey(const Key('subir_doc_identidad_anverso')), findsNothing);
      expect(find.byKey(const Key('subir_recibo_servicios')), findsOneWidget);
      expect(find.textContaining('Documento enviado'), findsOneWidget);
    });

    testWidgets('un documento rechazado muestra el motivo y deja subir otro', (tester) async {
      final auth = _AuthFalso(_conductor([
        {
          ..._recibo,
          'envio': {'estado': 'rechazado', 'motivo': 'Se ve borroso, tómalo de nuevo'},
        },
      ]));

      await _pintar(tester, auth: auth, cliente: _clienteQue((_) => _respuesta(500, {})));

      expect(find.byKey(const Key('rechazado_recibo_servicios')), findsOneWidget);
      expect(find.text('Se ve borroso, tómalo de nuevo'), findsOneWidget);
      expect(find.text('Subir otro'), findsOneWidget);
      expect(find.byKey(const Key('subir_recibo_servicios')), findsOneWidget);
    });

    testWidgets('si el servidor rechaza el envío se muestra su mensaje y no se marca como enviado', (tester) async {
      final auth = _AuthFalso(_conductor([_dniAnverso]));
      final cliente = _clienteQue(
        (_) => _respuesta(422, {'success': false, 'message': 'Ese documento ya está al día: no necesitas subirlo.'}),
      );

      await _pintar(tester, auth: auth, cliente: cliente);
      await tester.tap(find.byKey(const Key('subir_doc_identidad_anverso')));
      await _esperarEnvio(tester);

      expect(find.text('Ese documento ya está al día: no necesitas subirlo.'), findsOneWidget);
      expect(find.byKey(const Key('en_revision_doc_identidad_anverso')), findsNothing);
      // Se puede volver a intentar.
      expect(find.byKey(const Key('subir_doc_identidad_anverso')), findsOneWidget);
    });

    testWidgets('si la persona cancela la selección no se envía nada', (tester) async {
      final peticiones = <http.BaseRequest>[];
      final auth = _AuthFalso(_conductor([_dniAnverso]));

      await _pintar(
        tester,
        auth: auth,
        cliente: _clienteQue((_) => _respuesta(201, {'success': true}), peticiones: peticiones),
        elegir: (context, titulo) async => null,
      );
      await tester.tap(find.byKey(const Key('subir_doc_identidad_anverso')));
      await _esperarEnvio(tester);

      expect(peticiones, isEmpty);
      expect(auth.refrescos, 0);
    });

    testWidgets('sin pendientes dice que sus datos están al día', (tester) async {
      await _pintar(tester, auth: _AuthFalso(_conductor(const [])), cliente: _clienteQue((_) => _respuesta(500, {})));

      expect(find.byKey(const Key('actualizar_datos_al_dia')), findsOneWidget);
      expect(find.text('¡Tus datos están al día!'), findsOneWidget);
    });
  });

  group('DocumentosPendientesRemoteDataSource', () {
    DocumentosPendientesRemoteDataSource servicio(MockClient c) => DocumentosPendientesRemoteDataSource(client: c);

    test('devuelve los datos pendientes que manda el servidor', () async {
      final lista = await servicio(_clienteQue((_) => _respuesta(201, {
            'success': true,
            'datos_pendientes': [
              {'codigo': 'recibo_servicios', 'envio': null},
            ],
          }))).subir(clienteId: 82, nroDocumento: '12345678', tipoDocumento: 'doc_identidad_anverso', archivo: _archivo);

      expect(lista.single['codigo'], 'recibo_servicios');
    });

    test('los errores de negocio salen como ValidationException con el mensaje del servidor', () async {
      for (final codigo in [403, 404, 422, 503]) {
        expect(
          () => servicio(_clienteQue((_) => _respuesta(codigo, {'success': false, 'message': 'Mensaje $codigo'})))
              .subir(clienteId: 82, nroDocumento: '12345678', tipoDocumento: 'recibo_servicios', archivo: _archivo),
          throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'Mensaje $codigo')),
        );
      }
    });

    test('un 413 (archivo demasiado pesado para el servidor) y un 429 se explican en español', () async {
      expect(
        () => servicio(_clienteQue((_) => http.Response('<html>413</html>', 413)))
            .subir(clienteId: 82, nroDocumento: '12345678', tipoDocumento: 'recibo_servicios', archivo: _archivo),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('pesa demasiado'))),
      );
      expect(
        () => servicio(_clienteQue((_) => http.Response('', 429)))
            .subir(clienteId: 82, nroDocumento: '12345678', tipoDocumento: 'recibo_servicios', archivo: _archivo),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('Demasiados intentos'))),
      );
    });

    test('un archivo de más de 6 MB ni siquiera se envía', () async {
      final peticiones = <http.BaseRequest>[];
      final grande = File('${Directory.systemTemp.path}/grande_${DateTime.now().microsecondsSinceEpoch}.jpg')
        ..writeAsBytesSync(List<int>.filled(DocumentosPendientesRemoteDataSource.maxBytes + 1, 1));
      addTearDown(() => grande.existsSync() ? grande.deleteSync() : null);

      await expectLater(
        servicio(_clienteQue((_) => _respuesta(201, {'success': true}), peticiones: peticiones))
            .subir(clienteId: 82, nroDocumento: '12345678', tipoDocumento: 'recibo_servicios', archivo: grande),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('6 MB'))),
      );
      expect(peticiones, isEmpty);
    });

    test('sin conexión sale un ServerException con un mensaje que se puede mostrar', () async {
      final sinRed = MockClient((_) async => throw const SocketException('sin red'));

      await expectLater(
        servicio(sinRed).subir(clienteId: 82, nroDocumento: '12345678', tipoDocumento: 'recibo_servicios', archivo: _archivo),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', contains('Revisa tu conexión'))),
      );
    });
  });
}
