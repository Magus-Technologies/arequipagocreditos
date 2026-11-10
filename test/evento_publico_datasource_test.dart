import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:arequipagocreditos/core/errors/exceptions.dart';
import 'package:arequipagocreditos/data/datasources/evento_remote_datasource.dart';
import 'package:arequipagocreditos/data/models/evento_invitado.dart';
import 'helpers/evento_fakes.dart';

// TK-0450: lo que el app manda y cómo lee las respuestas de los endpoints de quien NO tiene cuenta (evento público completo, compra como
// invitado, sus compras, captura y ticket PDF), y que la lista y «activo» piden eventos según haya sesión o no.

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

const _invitado = EventoInvitado(nombre: 'Ana Pérez', documento: '43373493', telefono: '959123456', correo: 'ana@correo.pe');

void main() {
  late Directory carpeta;
  late File captura;

  setUp(() {
    carpeta = Directory.systemTemp.createTempSync('evento_pub_');
    captura = File('${carpeta.path}${Platform.pathSeparator}pago.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);
  });

  tearDown(() => carpeta.deleteSync(recursive: true));

  group('lista y evento activo: sesión o no', () {
    test('la lista CON persona manda su id y su documento (ve también los privados) y no manda solo_publicos', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': {'proximos': [], 'anteriores': []}}), vistas: vistas);

      await fuente.getEventos(clienteConductorId: 601, nroDocumento: '43373493');

      expect(vistas.single.url.path, endsWith('/app/eventos'));
      expect(vistas.single.url.queryParameters, {'cliente_conductor_id': '601', 'nro_documento': '43373493'});
    });

    test('la lista SIN sesión manda siempre solo_publicos=1', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': {'proximos': [], 'anteriores': []}}), vistas: vistas);

      await fuente.getEventos();

      expect(vistas.single.url.queryParameters, {'solo_publicos': '1'});
    });

    test('con un solo dato de la persona (id sin documento, o documento vacío) cuenta como sin sesión', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': null}), vistas: vistas);

      await fuente.getEventos(clienteConductorId: 601);
      await fuente.getEventoActivo(clienteConductorId: 601, nroDocumento: '');

      expect(vistas.map((v) => v.url.queryParameters), [
        {'solo_publicos': '1'},
        {'solo_publicos': '1'},
      ]);
    });

    test('el evento activo sin sesión manda solo_publicos=1', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': null}), vistas: vistas);

      await fuente.getEventoActivo();

      expect(vistas.single.url.queryParameters, {'solo_publicos': '1'});
    });
  });

  group('evento público completo', () {
    test('GET /app/eventos/{id}/publico lee el evento con su QR de pago, términos y visibilidad', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente(
        (_) => _json({
          'success': true,
          'data': {...eventoJson(mis: null), 'qr_url': 'https://credigo.test/storage/eventos/qr/qr.png', 'visibilidad': 'publico'},
        }),
        vistas: vistas,
      );

      final e = await fuente.getEventoPublico(7);

      expect(vistas.single.method, 'GET');
      expect(vistas.single.url.path, endsWith('/app/eventos/7/publico'));
      expect(e?.qrUrl, 'https://credigo.test/storage/eventos/qr/qr.png');
      expect(e?.terminos, 'Primera línea.\nSegunda línea.');
      expect(e?.esPrivado, isFalse);
      expect(e?.misTickets, isNull);
    });

    test('un 404 (ya no está disponible, es privado o no existe) es «no hay evento», no un error', () async {
      final fuente = _fuente((_) => _json({'success': false, 'message': 'No encontrado'}, 404));

      expect(await fuente.getEventoPublico(7), isNull);
    });

    test('un error del servidor o sin conexión sale como ServerException con un mensaje que se puede mostrar', () async {
      final caido = _fuente((_) => _json({'success': false, 'message': 'Error interno'}, 500));
      expect(() => caido.getEventoPublico(7), throwsA(isA<ServerException>()));

      final sinRed = EventoRemoteDataSourceImpl(client: MockClient((_) async => throw const SocketException('sin red')));
      expect(
        () => sinRed.getEventoPublico(7),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', contains('Revisa tu conexión'))),
      );
    });
  });

  group('compra como invitado', () {
    test('manda nombre, documento, teléfono, correo, cantidad, acepta_terminos y la CAPTURA como multipart', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': compraJson()}, 201), vistas: vistas);

      final c = await fuente.registrarCompraInvitado(eventoId: 7, invitado: _invitado, cantidad: 2, captura: captura);

      final peticion = vistas.single;
      expect(peticion.method, 'POST');
      expect(peticion.url.path, endsWith('/app/eventos/7/compras-invitado'));
      expect(peticion.headers['content-type'], startsWith('multipart/form-data; boundary='));
      expect(peticion.headers['Accept'], 'application/json');

      // Los bytes del JPEG no son UTF-8 válido: se tolera, y el nombre (con tilde) se lee como UTF-8.
      final cuerpo = utf8.decode(peticion.bodyBytes, allowMalformed: true);
      expect(cuerpo, contains('name="nombre"'));
      expect(cuerpo, contains('Ana Pérez'));
      expect(cuerpo, contains('name="nro_documento"'));
      expect(cuerpo, contains('43373493'));
      expect(cuerpo, contains('name="telefono"'));
      expect(cuerpo, contains('959123456'));
      expect(cuerpo, contains('name="correo"'));
      expect(cuerpo, contains('ana@correo.pe'));
      expect(cuerpo, contains('name="cantidad"'));
      expect(cuerpo, contains('name="acepta_terminos"'));
      expect(cuerpo, contains('name="captura"; filename="pago.jpg"'));
      // Un invitado NO manda id de cliente: no tiene cuenta.
      expect(cuerpo, isNot(contains('cliente_conductor_id')));
      expect(c.codigo, 'EV-K7M2QX');
    });

    test('sin correo no manda el campo', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': compraJson()}, 201), vistas: vistas);

      await fuente.registrarCompraInvitado(
        eventoId: 7,
        invitado: const EventoInvitado(nombre: 'Ana Pérez', documento: '43373493', telefono: '959123456'),
        cantidad: 1,
        captura: captura,
      );

      expect(latin1.decode(vistas.single.bodyBytes), isNot(contains('name="correo"')));
    });

    test('un 422 (evento privado, tope por DNI, evento vencido) sale con el mensaje del servidor', () async {
      final fuente = _fuente(
        (_) => _json({'success': false, 'message': 'Este evento es solo para clientes de Arequipa Go. Inicia sesión.'}, 422),
      );

      expect(
        () => fuente.registrarCompraInvitado(eventoId: 7, invitado: _invitado, cantidad: 1, captura: captura),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('solo para clientes de Arequipa Go'))),
      );
    });

    test('los errores de validación de Laravel (errors) también salen con su primer texto', () async {
      final fuente = _fuente(
        (_) => _json({
          'success': false,
          'errors': {
            'telefono': ['El celular no es válido']
          }
        }, 422),
      );

      expect(
        () => fuente.registrarCompraInvitado(eventoId: 7, invitado: _invitado, cantidad: 1, captura: captura),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'El celular no es válido')),
      );
    });
  });

  group('compras, captura y ticket del invitado', () {
    test('mis compras: GET con el documento y el teléfono, y lee la lista', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente(
        (_) => _json({
          'success': true,
          'data': [compraJson(), compraJson(estado: 'confirmado')]
        }),
        vistas: vistas,
      );

      final compras = await fuente.getMisComprasInvitado(nroDocumento: '43373493', telefono: '959123456');

      expect(vistas.single.method, 'GET');
      expect(vistas.single.url.path, endsWith('/app/eventos/mis-compras-invitado'));
      expect(vistas.single.url.queryParameters, {'nro_documento': '43373493', 'telefono': '959123456'});
      expect(compras, hasLength(2));
    });

    test('mis compras con una respuesta sin lista da una lista vacía', () async {
      final fuente = _fuente((_) => _json({'success': true, 'data': null}));

      expect(await fuente.getMisComprasInvitado(nroDocumento: '43373493', telefono: '959123456'), isEmpty);
    });

    test('subir captura: multipart a compras-invitado/{id}/captura con el documento, el teléfono y la captura', () async {
      final vistas = <http.Request>[];
      final fuente = _fuente((_) => _json({'success': true, 'data': compraJson()}), vistas: vistas);

      await fuente.subirCapturaInvitado(compraId: 31, nroDocumento: '43373493', telefono: '959123456', captura: captura);

      final peticion = vistas.single;
      expect(peticion.method, 'POST');
      expect(peticion.url.path, endsWith('/app/eventos/compras-invitado/31/captura'));
      final cuerpo = latin1.decode(peticion.bodyBytes);
      expect(cuerpo, contains('name="nro_documento"'));
      expect(cuerpo, contains('43373493'));
      expect(cuerpo, contains('name="telefono"'));
      expect(cuerpo, contains('959123456'));
      expect(cuerpo, contains('name="captura"; filename="pago.jpg"'));
    });

    test('subir captura de una compra ajena (403) sale con el mensaje del servidor', () async {
      final fuente = _fuente((_) => _json({'success': false, 'message': 'Esta compra no te pertenece.'}, 403));

      expect(
        () => fuente.subirCapturaInvitado(compraId: 31, nroDocumento: '1', telefono: '2', captura: captura),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'Esta compra no te pertenece.')),
      );
    });

    test('ticket PDF: GET con el documento y el teléfono y devuelve los bytes', () async {
      final vistas = <http.Request>[];
      final pdf = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 1, 2, 3]);
      final fuente = _fuente((_) => http.Response.bytes(pdf, 200, headers: {'content-type': 'application/pdf'}), vistas: vistas);

      final bytes = await fuente.descargarTicketPdfInvitado(compraId: 31, nroDocumento: '43373493', telefono: '959123456');

      expect(vistas.single.method, 'GET');
      expect(vistas.single.url.path, endsWith('/app/eventos/compras-invitado/31/ticket.pdf'));
      expect(vistas.single.url.queryParameters, {'nro_documento': '43373493', 'telefono': '959123456'});
      expect(vistas.single.headers['Accept'], contains('application/pdf'));
      expect(bytes, pdf);
    });

    test('ticket PDF con la compra todavía sin confirmar (422) sale con el mensaje del servidor', () async {
      final fuente = _fuente((_) => _json({'success': false, 'message': 'El ticket se habilita cuando confirmemos tu pago.'}, 422));

      expect(
        () => fuente.descargarTicketPdfInvitado(compraId: 31, nroDocumento: '1', telefono: '2'),
        throwsA(isA<ValidationException>().having((e) => e.message, 'message', contains('cuando confirmemos tu pago'))),
      );
    });
  });
}
