import 'dart:convert';
import 'dart:io';
import 'package:arequipagocreditos/data/datasources/documentos_pendientes_remote_datasource.dart';
import 'package:arequipagocreditos/domain/entities/conductor_entity.dart';
import 'package:arequipagocreditos/presentation/components/mis_documentos_card.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

/// «Mis documentos» del perfil (10-nov): en la web, Conductores → Editar muestra todos los documentos del cliente (recibo, DNI, licencia,
/// tarjeta de propiedad, SOAT…). El perfil del app lista los mismos documentos con su estado, pero solo deja SUBIR lo que falta, lo
/// rechazado o lo que su aviso pide (SOAT vencido): uno ya guardado no se cambia a voluntad (podría subir uno errado). Lo que sube queda
/// «En revisión» hasta que el personal lo apruebe en el dashboard.

Map<String, dynamic> _doc(
  String codigo,
  String etiqueta, {
  bool guardado = false,
  String? fecha,
  Map<String, dynamic>? envio,
  bool enAlerta = false,
}) =>
    {
      // La regla es del servidor: se sube lo que falta o lo que el aviso pide (uno ya guardado, no).
      'puede_subir': !guardado || enAlerta,
      'codigo': codigo,
      'etiqueta': etiqueta,
      'guardado': guardado,
      'guardado_nombre': guardado ? '$codigo.jpg' : null,
      'guardado_fecha': fecha,
      'envio': envio,
      'en_alerta': enAlerta,
    };

ConductorEntity _conductor() => const ConductorEntity(
      idConductor: 802,
      nombres: 'JUAN PEREZ',
      nroDocumento: '77425200',
      telefono: '999888777',
      direccion: 'Calle 1',
      correo: 'juan@example.com',
      flag: 1,
      tipo: 1,
      fotoPerfilCambiada: false,
    );

class _AuthFalso extends ChangeNotifier implements AuthProvider {
  int refrescos = 0;

  @override
  ConductorEntity? get currentUser => _conductor();

  @override
  Future<void> refreshUserDataSilently() async => refrescos++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

http.Response _json(int codigo, Map<String, dynamic> cuerpo) =>
    http.Response(jsonEncode(cuerpo), codigo, headers: {'content-type': 'application/json; charset=utf-8'});

late File _archivo;

Future<void> _pintar(
  WidgetTester tester, {
  required _AuthFalso auth,
  required MockClient cliente,
  ElegirDocumentoDePrueba? elegir,
}) async {
  tester.view.physicalSize = const Size(780, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: Scaffold(
          body: SingleChildScrollView(
            child: MisDocumentosCard(
              servicio: DocumentosPendientesRemoteDataSource(client: cliente),
              elegirDocumento: elegir ?? (context, titulo) async => _archivo,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(); // el primer cuadro dispara la consulta
  await tester.pump(const Duration(milliseconds: 50));
}

typedef ElegirDocumentoDePrueba = Future<File?> Function(BuildContext context, String titulo);

/// La subida lee el archivo del disco (E/S real): dentro de un testWidgets solo avanza con `runAsync`.
Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  }
}

void main() {
  setUpAll(() {
    _archivo = File('${Directory.systemTemp.path}/doc_prueba_${DateTime.now().microsecondsSinceEpoch}.jpg')
      ..writeAsBytesSync(List<int>.filled(2048, 7));
  });

  tearDownAll(() {
    if (_archivo.existsSync()) _archivo.deleteSync();
  });

  final lista = [
    _doc('doc_identidad_anverso', 'DNI/CE (anverso)', guardado: true, fecha: '2026-03-02'),
    _doc('doc_identidad_reverso', 'DNI/CE (reverso)', enAlerta: true),
    _doc('recibo_servicios', 'Recibo de Servicios (Luz/Agua)', envio: {'estado': 'pendiente', 'motivo': null}),
    _doc('licencia', 'Licencia de conducir (anverso)', envio: {'estado': 'rechazado', 'motivo': 'Se ve borroso, tómalo de nuevo'}),
    _doc('tarjeta_propiedad', 'Tarjeta de propiedad'),
    // Lo tiene guardado, pero su aviso (SOAT vencido) pide uno nuevo.
    _doc('soat', 'SOAT', guardado: true, fecha: '2025-01-11', enAlerta: true),
  ];

  group('tarjeta «Mis documentos»', () {
    testWidgets('lista cada documento con su estado: guardado, falta, en revisión y rechazado con su motivo', (tester) async {
      final peticiones = <http.BaseRequest>[];
      final cliente = MockClient((request) async {
        peticiones.add(request);
        return _json(200, {'success': true, 'data': lista});
      });

      await _pintar(tester, auth: _AuthFalso(), cliente: cliente);

      // Pide la lista con el id Y el número de documento de la cuenta.
      expect(peticiones, hasLength(1));
      expect(peticiones.single.url.path, endsWith('/app/mis-documentos'));
      expect(peticiones.single.url.queryParameters, {'idConductor': '802', 'nro_documento': '77425200'});

      expect(find.text('Mis documentos'), findsOneWidget);
      // Guardado: con su fecha y SIN opción de cambiarlo (no se cambia a voluntad desde el app).
      expect(find.text('Guardado el 02/03/2026'), findsOneWidget);
      expect(find.byKey(const Key('doc_subir_doc_identidad_anverso')), findsNothing);
      expect(find.text('Cambiar'), findsNothing);
      // Guardado, pero su aviso (SOAT vencido) pide uno nuevo: ahí sí puede subir.
      expect(find.text('Tu aviso pide subir uno vigente.'), findsOneWidget);
      expect(find.byKey(const Key('doc_subir_soat')), findsOneWidget);
      expect(find.text('Subir nuevo'), findsOneWidget);
      // Falta: y este lo pide su aviso de datos por actualizar.
      expect(find.text('Falta: lo pide tu aviso de datos por actualizar.'), findsOneWidget);
      expect(find.text('Aún no lo has subido.'), findsOneWidget); // la tarjeta de propiedad
      // En revisión: no se puede volver a subir mientras lo revisan.
      expect(find.textContaining('En revisión'), findsOneWidget);
      expect(find.byKey(const Key('doc_subir_recibo_servicios')), findsNothing);
      // Rechazado: el motivo y subir otro.
      expect(find.text('Rechazado: Se ve borroso, tómalo de nuevo'), findsOneWidget);
      expect(find.text('Subir otro'), findsOneWidget);
    });

    testWidgets('al subir o cambiar uno manda el archivo con su tipo y la cuenta, y la lista pasa a «En revisión»', (tester) async {
      final peticiones = <http.BaseRequest>[];
      var enviado = false;
      final cliente = MockClient((request) async {
        peticiones.add(request);
        if (request.method == 'POST') {
          enviado = true;
          return _json(201, {'success': true, 'datos_pendientes': <Object>[]});
        }
        // Después de enviar, el servidor ya marca el SOAT como pendiente de revisión.
        return _json(200, {
          'success': true,
          'data': enviado
              ? [_doc('soat', 'SOAT', envio: {'estado': 'pendiente', 'motivo': null})]
              : [_doc('soat', 'SOAT')],
        });
      });
      final auth = _AuthFalso();

      await _pintar(tester, auth: auth, cliente: cliente);
      expect(find.byKey(const Key('doc_subir_soat')), findsOneWidget);

      await tester.tap(find.byKey(const Key('doc_subir_soat')));
      await _esperar(tester);

      final envio = peticiones.firstWhere((p) => p.method == 'POST') as http.Request;
      expect(envio.url.path, endsWith('/app/documentos-pendientes'));
      expect(envio.headers['content-type'], contains('multipart/form-data'));
      expect(envio.body, contains('name="idConductor"'));
      expect(envio.body, contains('802'));
      expect(envio.body, contains('name="nro_documento"'));
      expect(envio.body, contains('77425200'));
      expect(envio.body, contains('name="tipo_documento"'));
      expect(envio.body, contains('soat'));
      expect(envio.body, contains('name="archivo"'));

      // Vuelve a pedir la lista, avisa y actualiza su alerta de datos por actualizar.
      expect(peticiones.where((p) => p.method == 'GET'), hasLength(2));
      expect(auth.refrescos, 1);
      expect(find.textContaining('Documento enviado'), findsOneWidget);
      expect(find.byKey(const Key('doc_subir_soat')), findsNothing);
      expect(find.text('En revisión: lo está revisando nuestro equipo.'), findsOneWidget);
    });

    testWidgets('si el servidor rechaza el envío se muestra su mensaje y se puede reintentar', (tester) async {
      final cliente = MockClient((request) async {
        if (request.method == 'POST') {
          return _json(422, {'success': false, 'message': 'Ese documento no se puede subir desde el app.'});
        }
        return _json(200, {'success': true, 'data': [_doc('soat', 'SOAT')]});
      });

      await _pintar(tester, auth: _AuthFalso(), cliente: cliente);
      await tester.tap(find.byKey(const Key('doc_subir_soat')));
      await _esperar(tester);

      expect(find.text('Ese documento no se puede subir desde el app.'), findsOneWidget);
      expect(find.byKey(const Key('doc_subir_soat')), findsOneWidget);
    });

    testWidgets('si la persona cancela la selección no se envía nada', (tester) async {
      final peticiones = <http.BaseRequest>[];
      final cliente = MockClient((request) async {
        peticiones.add(request);
        return _json(200, {'success': true, 'data': [_doc('soat', 'SOAT')]});
      });

      await _pintar(tester, auth: _AuthFalso(), cliente: cliente, elegir: (context, titulo) async => null);
      await tester.tap(find.byKey(const Key('doc_subir_soat')));
      await _esperar(tester);

      expect(peticiones.where((p) => p.method == 'POST'), isEmpty);
    });

    testWidgets('si su tipo de cliente no tiene lista de documentos, la tarjeta no se dibuja', (tester) async {
      await _pintar(tester, auth: _AuthFalso(), cliente: MockClient((_) async => _json(200, {'success': true, 'data': <Object>[]})));

      expect(find.byKey(const Key('mis_documentos')), findsNothing);
      expect(find.text('Mis documentos'), findsNothing);
    });

    testWidgets('si no se puede cargar la lista avisa y permite reintentar', (tester) async {
      var intentos = 0;
      final cliente = MockClient((request) async {
        intentos++;
        if (intentos == 1) return _json(403, {'success': false, 'message': 'No se pudo validar tu cuenta. Cierra sesión y vuelve a entrar.'});
        return _json(200, {'success': true, 'data': [_doc('soat', 'SOAT')]});
      });

      await _pintar(tester, auth: _AuthFalso(), cliente: cliente);

      expect(find.byKey(const Key('mis_documentos_error')), findsOneWidget);
      expect(find.text('No se pudo validar tu cuenta. Cierra sesión y vuelve a entrar.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mis_documentos_reintentar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('mis_documentos_error')), findsNothing);
      expect(find.byKey(const Key('doc_subir_soat')), findsOneWidget);
    });
  });

  group('DocumentosPendientesRemoteDataSource.listarMisDocumentos', () {
    test('devuelve la lista que manda el servidor', () async {
      final servicio = DocumentosPendientesRemoteDataSource(client: MockClient((_) async => _json(200, {'success': true, 'data': lista})));

      final documentos = await servicio.listarMisDocumentos(clienteId: 802, nroDocumento: '77425200');

      expect(documentos, hasLength(6));
      expect(documentos.first['codigo'], 'doc_identidad_anverso');
    });

    test('un cuerpo sin lista da una lista vacía y los errores salen con el mensaje del servidor', () async {
      final vacia = DocumentosPendientesRemoteDataSource(client: MockClient((_) async => _json(200, {'success': true})));
      expect(await vacia.listarMisDocumentos(clienteId: 1, nroDocumento: '1'), isEmpty);

      final rechazada = DocumentosPendientesRemoteDataSource(
        client: MockClient((_) async => _json(403, {'success': false, 'message': 'Sin acceso'})),
      );
      expect(
        () => rechazada.listarMisDocumentos(clienteId: 1, nroDocumento: '1'),
        throwsA(predicate((e) => e.toString().contains('Sin acceso'))),
      );
    });
  });
}
