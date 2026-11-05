import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:arequipagocreditos/core/errors/exceptions.dart';
import 'package:arequipagocreditos/data/datasources/evento_remote_datasource.dart';
import 'helpers/evento_fakes.dart';

// Lo que el app le manda al servidor y cómo lee sus respuestas, contra el contrato de «Eventos»: id + DNI en todo, `acepta_terminos`
// en la compra, y los errores de negocio (422, 403, 404) salen con el mensaje del servidor listo para mostrarse.

/// La compra exige captura: el multipart la lee del disco al armar la petición, así que tiene que existir (se crea en `main`).
late File _capturaFalsa;

http.Response _json(Object body, [int status = 200]) =>
    http.Response(json.encode(body), status, headers: {'content-type': 'application/json'});

EventoRemoteDataSourceImpl _fuente(http.Response Function(http.Request) responder, {List<http.Request>? vistas}) {
  return EventoRemoteDataSourceImpl(
    client: MockClient((request) async {
      vistas?.add(request);
      return responder(request);
    }),
  );
}

void main() {
  late Directory carpetaGlobal;
  setUpAll(() {
    carpetaGlobal = Directory.systemTemp.createTempSync('evento_ds_');
    _capturaFalsa = File('${carpetaGlobal.path}${Platform.pathSeparator}captura.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);
  });
  tearDownAll(() => carpetaGlobal.deleteSync(recursive: true));

  group('evento activo', () {
    test('manda id y DNI en la consulta y lee el evento', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': eventoJson()}), vistas: vistas);

      final e = await fuente.getEventoActivo(clienteConductorId: 601, nroDocumento: '43373493');

      expect(vistas.single.method, 'GET');
      expect(vistas.single.url.path, endsWith('/app/eventos/activo'));
      expect(vistas.single.url.queryParameters, {'cliente_conductor_id': '601', 'nro_documento': '43373493'});
      expect(e?.nombre, '3er Aniversario Arequipa Go');
      expect(e?.precioTicket, 50.0); // llegó como texto "50.00"
    });

    test('sin evento activo el servidor manda data:null y el resultado es null', () async {
      final fuente = _fuente((_) => _json({'success': true, 'data': null}));

      expect(await fuente.getEventoActivo(clienteConductorId: 601, nroDocumento: '43373493'), isNull);
    });

    test('sin persona no manda parámetros', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': null}), vistas: vistas);

      await fuente.getEventoActivo();

      expect(vistas.single.url.queryParameters, isEmpty);
    });
  });

  group('registrar compra', () {
    late Directory carpeta;
    late File captura;

    setUp(() {
      carpeta = Directory.systemTemp.createTempSync('evento_compra_');
      captura = File('${carpeta.path}${Platform.pathSeparator}pago.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);
    });

    tearDown(() => carpeta.deleteSync(recursive: true));

    test('manda cantidad, acepta_terminos y la CAPTURA como multipart, pide JSON y lee la compra', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': compraJson()}, 201), vistas: vistas);

      final c = await fuente.registrarCompra(
        eventoId: 7,
        clienteConductorId: 601,
        nroDocumento: '43373493',
        cantidad: 2,
        captura: captura,
      );

      final peticion = vistas.single;
      expect(peticion.method, 'POST');
      expect(peticion.url.path, endsWith('/app/eventos/7/compras'));
      expect(peticion.headers['content-type'], startsWith('multipart/form-data; boundary='));
      // Sin esto Laravel contesta los errores de validación con una redirección HTML en vez de un 422 en JSON.
      expect(peticion.headers['Accept'], 'application/json');

      // Los bytes del JPEG no son UTF-8 válido: se lee el multipart como latin1, que acepta cualquier byte.
      final cuerpo = latin1.decode(peticion.bodyBytes);
      expect(cuerpo, contains('name="cliente_conductor_id"'));
      expect(cuerpo, contains('601'));
      expect(cuerpo, contains('name="nro_documento"'));
      expect(cuerpo, contains('43373493'));
      expect(cuerpo, contains('name="cantidad"'));
      expect(cuerpo, contains('name="acepta_terminos"'));
      expect(cuerpo, contains('name="captura"; filename="pago.jpg"')); // la compra viaja CON la captura
      expect(c.codigo, 'EV-K7M2QX');
      expect(c.montoTotal, 100.0);
    });

    test('un 422 por falta de captura sale con el mensaje del servidor', () async {
      final fuente = _fuente(
        (_) => _json({'success': false, 'message': 'Debes adjuntar la captura del pago para registrar la compra'}, 422),
      );

      expect(
        () => fuente.registrarCompra(eventoId: 7, clienteConductorId: 601, nroDocumento: '43373493', cantidad: 1, captura: captura),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('captura del pago'))),
      );
    });

    test('un 422 sale como ValidationException con el mensaje del servidor', () async {
      final fuente = _fuente(
        (_) => _json({'success': false, 'message': 'Ya tienes 4 de 4 tickets para este evento.'}, 422),
      );

      expect(
        () => fuente.registrarCompra(eventoId: 7, clienteConductorId: 601, nroDocumento: '43373493', cantidad: 1, captura: captura),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'Ya tienes 4 de 4 tickets para este evento.')),
      );
    });

    test('403 y 404 también son errores de negocio con su mensaje', () async {
      final prohibido = _fuente((_) => _json({'success': false, 'message': 'Cuenta no habilitada.'}, 403));
      final noExiste = _fuente((_) => _json({'success': false, 'message': 'El evento ya no está disponible.'}, 404));

      expect(
        () => prohibido.registrarCompra(eventoId: 7, clienteConductorId: 1, nroDocumento: 'x', cantidad: 1, captura: captura),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'Cuenta no habilitada.')),
      );
      expect(
        () => noExiste.registrarCompra(eventoId: 7, clienteConductorId: 1, nroDocumento: 'x', cantidad: 1, captura: captura),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'El evento ya no está disponible.')),
      );
    });

    test('un 500 o una respuesta que no es JSON sale como ServerException', () async {
      final caido = _fuente((_) => http.Response('<html>error</html>', 500));

      expect(
        () => caido.registrarCompra(eventoId: 7, clienteConductorId: 1, nroDocumento: 'x', cantidad: 1, captura: captura),
        throwsA(isA<ServerException>()),
      );
    });

    test('sin conexión sale como ServerException con un mensaje claro, no el error crudo', () async {
      final fuente = EventoRemoteDataSourceImpl(
        client: MockClient((_) async => throw http.ClientException('Connection refused')),
      );

      expect(
        () => fuente.registrarCompra(eventoId: 7, clienteConductorId: 1, nroDocumento: 'x', cantidad: 1, captura: captura),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', contains('Revisa tu conexión'))),
      );
    });

    test('demasiados intentos (429) avisa que espere', () async {
      final fuente = _fuente((_) => _json({'message': 'Too Many Attempts.'}, 429));

      expect(
        () => fuente.registrarCompra(eventoId: 7, clienteConductorId: 1, nroDocumento: 'x', cantidad: 1, captura: captura),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('Demasiados intentos'))),
      );
    });
  });

  group('ticket en PDF (lo arma el servidor)', () {
    test('pide el PDF con el id y el DNI, acepta PDF o JSON y devuelve los bytes', () async {
      final vistas = <http.Request>[];
      final pdf = [0x25, 0x50, 0x44, 0x46, 0x2D, 1, 2, 3, 255];
      final fuente = _fuente((_) => http.Response.bytes(pdf, 200, headers: {'content-type': 'application/pdf'}), vistas: vistas);

      final bytes = await fuente.descargarTicketPdf(compraId: 31, clienteConductorId: 601, nroDocumento: '43373493');

      expect(vistas.single.method, 'GET');
      expect(vistas.single.url.path, endsWith('/app/eventos/compras/31/ticket.pdf'));
      expect(vistas.single.url.queryParameters, {'cliente_conductor_id': '601', 'nro_documento': '43373493'});
      expect(vistas.single.headers['Accept'], contains('application/pdf'));
      expect(vistas.single.headers['Accept'], contains('application/json')); // así Laravel contesta los errores en JSON
      expect(bytes, pdf);
    });

    test('«todavía no confirmado» (422) sale como ValidationException con el mensaje del servidor', () async {
      final fuente = _fuente(
        (_) => _json({'success': false, 'message': 'El ticket se habilita cuando confirmemos tu pago.'}, 422),
      );

      expect(
        () => fuente.descargarTicketPdf(compraId: 31, clienteConductorId: 601, nroDocumento: '43373493'),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'El ticket se habilita cuando confirmemos tu pago.')),
      );
    });

    test('403 y 404 también salen con su mensaje', () async {
      final ajena = _fuente((_) => _json({'success': false, 'message': 'Esta compra no te pertenece.'}, 403));
      final noExiste = _fuente((_) => _json({'success': false, 'message': 'Compra no encontrada'}, 404));

      expect(
        () => ajena.descargarTicketPdf(compraId: 31, clienteConductorId: 601, nroDocumento: 'x'),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'Esta compra no te pertenece.')),
      );
      expect(
        () => noExiste.descargarTicketPdf(compraId: 31, clienteConductorId: 601, nroDocumento: 'x'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('un 200 que no es PDF (o vacío) no se entrega como ticket', () async {
      final html = _fuente((_) => http.Response('<html>login</html>', 200, headers: {'content-type': 'text/html'}));
      final vacio = _fuente((_) => http.Response.bytes(const [], 200, headers: {'content-type': 'application/pdf'}));

      expect(() => html.descargarTicketPdf(compraId: 31, clienteConductorId: 601, nroDocumento: 'x'), throwsA(isA<ServerException>()));
      expect(() => vacio.descargarTicketPdf(compraId: 31, clienteConductorId: 601, nroDocumento: 'x'), throwsA(isA<ServerException>()));
    });

    test('sin conexión sale con un mensaje claro, no el error crudo', () async {
      final fuente = EventoRemoteDataSourceImpl(client: MockClient((_) async => throw http.ClientException('Connection refused')));

      expect(
        () => fuente.descargarTicketPdf(compraId: 31, clienteConductorId: 601, nroDocumento: 'x'),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', contains('Revisa tu conexión'))),
      );
    });
  });

  group('errores de validación (422 de Laravel)', () {
    Future<void> Function() comprar(EventoRemoteDataSourceImpl fuente) =>
        () => fuente.registrarCompra(eventoId: 7, clienteConductorId: 601, nroDocumento: '43373493', cantidad: 1, captura: _capturaFalsa);

    test('con `errors` y `message`, la persona ve el `message` del servidor', () async {
      final fuente = _fuente(
        (_) => _json({
          'success': false,
          'message': 'Ya tienes 4 de 4 tickets para este evento.',
          'errors': {
            'cantidad': ['Ya tienes 4 de 4 tickets para este evento.'],
          },
        }, 422),
      );

      expect(
        comprar(fuente),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'Ya tienes 4 de 4 tickets para este evento.')),
      );
    });

    test('con varios errores y el `message` genérico de Laravel, igual llega el del servidor', () async {
      final fuente = _fuente(
        (_) => _json({
          'message': 'La captura debe ser una imagen. (y 1 error más)',
          'errors': {
            'captura': ['La captura debe ser una imagen.', 'La captura no debe pesar más de 5 MB.'],
            'nro_documento': ['El DNI no coincide.'],
          },
        }, 422),
      );

      expect(
        comprar(fuente),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', startsWith('La captura debe ser una imagen'))),
      );
    });

    test('sin `message`, usa el primer texto de `errors`', () async {
      final fuente = _fuente(
        (_) => _json({
          'errors': {
            'cantidad': ['La cantidad debe ser al menos 1.'],
            'acepta_terminos': ['Debes aceptar los términos.'],
          },
        }, 422),
      );

      expect(
        comprar(fuente),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'La cantidad debe ser al menos 1.')),
      );
    });

    test('`errors` con un texto suelto en vez de una lista también sirve', () async {
      final fuente = _fuente((_) => _json({'errors': {'cantidad': 'Cantidad inválida.'}}, 422));

      expect(
        comprar(fuente),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'Cantidad inválida.')),
      );
    });

    test('un 422 sin nada legible da un mensaje genérico en español', () async {
      final fuente = _fuente((_) => http.Response('', 422));

      expect(
        comprar(fuente),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'No se pudo completar la operación.')),
      );
    });

    test('un 404 técnico de Laravel (modelo inexistente) no le muestra el texto en inglés a la persona', () async {
      final fuente = _fuente((_) => _json({'message': 'No query results for model [App\\Models\\Evento] 99'}, 404));

      expect(
        comprar(fuente),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'El evento o la compra ya no está disponible.')),
      );
    });
  });

  group('subir captura (multipart)', () {
    late Directory carpeta;
    late File captura;

    setUp(() {
      carpeta = Directory.systemTemp.createTempSync('evento_captura_');
      captura = File('${carpeta.path}${Platform.pathSeparator}pago.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);
    });

    tearDown(() => carpeta.deleteSync(recursive: true));

    test('manda captura, cliente_conductor_id y nro_documento como multipart, y pide JSON', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente(
        (_) => _json({'success': true, 'data': compraJson(capturaUrl: 'https://credigo.test/storage/eventos/capturas/c.jpg')}),
        vistas: vistas,
      );

      final c = await fuente.subirCaptura(
        compraId: 31,
        clienteConductorId: 601,
        nroDocumento: '43373493',
        captura: captura,
      );

      final peticion = vistas.single;
      expect(peticion.method, 'POST');
      expect(peticion.url.path, endsWith('/app/eventos/compras/31/captura'));
      expect(peticion.headers['content-type'], startsWith('multipart/form-data; boundary='));
      // Sin esto Laravel contesta los errores de validación con una redirección HTML en vez de un 422 en JSON.
      expect(peticion.headers['Accept'], 'application/json');

      // Los bytes del JPEG no son UTF-8 válido: se lee el multipart como latin1, que acepta cualquier byte.
      final cuerpo = latin1.decode(peticion.bodyBytes);
      expect(cuerpo, contains('name="cliente_conductor_id"'));
      expect(cuerpo, contains('601'));
      expect(cuerpo, contains('name="nro_documento"'));
      expect(cuerpo, contains('43373493'));
      expect(cuerpo, contains('name="captura"; filename="pago.jpg"'));
      expect(c.tieneCaptura, isTrue);
      expect(c.etiquetaEstado, 'En revisión');
    });

    test('el archivo viaja entero dentro del multipart', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': compraJson()}), vistas: vistas);

      await fuente.subirCaptura(compraId: 31, clienteConductorId: 601, nroDocumento: '43373493', captura: captura);

      final bytes = vistas.single.bodyBytes;
      final firma = [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3];
      var encontrada = false;
      for (var i = 0; i <= bytes.length - firma.length && !encontrada; i++) {
        encontrada = List.generate(firma.length, (j) => bytes[i + j] == firma[j]).every((igual) => igual);
      }
      expect(encontrada, isTrue);
    });

    test('un 422 al subir la captura llega con el mensaje del servidor', () async {
      final fuente = _fuente(
        (_) => _json({
          'success': false,
          'message': 'La compra ya no admite captura.',
          'errors': {
            'captura': ['La compra ya no admite captura.'],
          },
        }, 422),
      );

      expect(
        () => fuente.subirCaptura(compraId: 31, clienteConductorId: 601, nroDocumento: '43373493', captura: captura),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'La compra ya no admite captura.')),
      );
    });

    test('sin conexión al subir sale como ServerException con un mensaje claro', () async {
      final fuente = EventoRemoteDataSourceImpl(
        client: MockClient((_) async => throw http.ClientException('Connection reset')),
      );

      expect(
        () => fuente.subirCaptura(compraId: 31, clienteConductorId: 601, nroDocumento: '43373493', captura: captura),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', contains('Revisa tu conexión'))),
      );
    });
  });

  group('mis compras y cancelar', () {
    test('mis-compras manda id y DNI y lee la lista', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente(
        (_) => _json({'success': true, 'data': [compraJson(), compraJson(estado: 'confirmado')]}),
        vistas: vistas,
      );

      final lista = await fuente.getMisCompras(clienteConductorId: 601, nroDocumento: '43373493');

      expect(vistas.single.url.path, endsWith('/app/eventos/mis-compras'));
      expect(vistas.single.url.queryParameters['cliente_conductor_id'], '601');
      expect(lista, hasLength(2));
      expect(lista.last.etiquetaEstado, 'Confirmado');
    });

    test('mis-compras sin compras devuelve una lista vacía', () async {
      final fuente = _fuente((_) => _json({'success': true, 'data': []}));

      expect(await fuente.getMisCompras(clienteConductorId: 601, nroDocumento: '43373493'), isEmpty);
    });

    test('cancelar manda id y DNI a la compra y lee el resultado', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': compraJson(estado: 'anulado')}), vistas: vistas);

      final c = await fuente.cancelarCompra(compraId: 31, clienteConductorId: 601, nroDocumento: '43373493');

      expect(vistas.single.method, 'POST');
      expect(vistas.single.url.path, endsWith('/app/eventos/compras/31/cancelar'));
      expect(json.decode(vistas.single.body), {'cliente_conductor_id': 601, 'nro_documento': '43373493'});
      expect(c.etiquetaEstado, 'Anulado');
    });
  });
}
