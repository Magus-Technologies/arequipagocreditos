import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/presentation/components/evento_ticket_acciones.dart';
import 'package:arequipagocreditos/presentation/components/evento_ticket_card.dart';
import 'package:arequipagocreditos/presentation/providers/evento_provider.dart';
import 'helpers/evento_fakes.dart';

// El ticket para llevarlo: PDF (descargar y compartir) e imagen (compartir). El PDF lo ARMA EL SERVIDOR (aquí se reemplaza por bytes
// falsos); la hoja de compartir y el «Guardar como» del sistema se reemplazan por funciones falsas (en pruebas no existen).

final Uint8List _pdfFalso = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 1, 2, 3, 4]); // «%PDF-…»

void main() {
  group('descargar y compartir', () {
    late Directory temporal;
    final llave = GlobalKey();

    setUp(() => temporal = Directory.systemTemp.createTempSync('evento_ticket_'));
    tearDown(() => temporal.deleteSync(recursive: true));

    Future<void> montar(
      WidgetTester tester, {
      CompartirArchivo? compartir,
      GuardarArchivo? guardar,
      ObtenerPdfTicket? obtenerPdf,
      EventoProvider? provider,
    }) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final c = compra(estado: 'confirmado');
      final cuerpo = MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              RepaintBoundary(
                key: llave,
                child: Container(color: Colors.white, padding: const EdgeInsets.all(8), child: EventoTicketCard(compra: c, conEstado: true)),
              ),
              EventoTicketAcciones(
                compra: c,
                capturaKey: llave,
                compartir: compartir,
                guardar: guardar,
                obtenerPdf: obtenerPdf ?? (provider == null ? () async => _pdfFalso : null),
                carpetaTemporal: () async => temporal,
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        provider == null ? cuerpo : ChangeNotifierProvider<EventoProvider>.value(value: provider, child: cuerpo),
      );
      await tester.pump();
    }

    Future<void> tocar(WidgetTester tester, String llaveBoton, {int ms = 600}) async {
      await tester.runAsync(() async {
        await tester.tap(find.byKey(Key(llaveBoton)));
        await Future<void>.delayed(Duration(milliseconds: ms));
      });
      await tester.pump();
    }

    testWidgets('muestra las tres acciones: descargar PDF, compartir PDF y compartir imagen', (tester) async {
      await montar(tester);

      expect(find.text('Descargar PDF'), findsOneWidget);
      expect(find.text('Compartir PDF'), findsOneWidget);
      expect(find.text('Compartir imagen'), findsOneWidget);
    });

    testWidgets('«Descargar PDF» abre el «Guardar como» con el PDF DEL SERVIDOR y avisa cuando se guardó', (tester) async {
      String? nombre;
      Uint8List? bytes;
      await montar(tester, guardar: (n, b) async {
        nombre = n;
        bytes = b;
        return '/descargas/$n';
      });

      await tocar(tester, 'evento_ticket_descargar_pdf');

      expect(nombre, 'ticket-EV-K7M2QX.pdf');
      expect(bytes, _pdfFalso); // el mismo archivo que armó el servidor, sin tocarlo
      expect(find.text('Ticket guardado en PDF.'), findsOneWidget);
    });

    testWidgets('si la persona cancela el «Guardar como» no se avisa nada', (tester) async {
      var llamadas = 0;
      await montar(tester, guardar: (n, b) async {
        llamadas++;
        return null; // canceló
      });

      await tocar(tester, 'evento_ticket_descargar_pdf');

      expect(llamadas, 1);
      expect(find.text('Ticket guardado en PDF.'), findsNothing);
      expect(find.text('No pudimos preparar el ticket. Inténtalo de nuevo.'), findsNothing);
    });

    testWidgets('«Compartir PDF» entrega a la hoja de compartir el PDF del servidor, con un texto', (tester) async {
      File? archivo;
      String? texto;
      List<int>? contenido;
      await montar(tester, compartir: (f, t) async {
        archivo = f;
        texto = t;
        contenido = f.readAsBytesSync();
      });

      await tocar(tester, 'evento_ticket_compartir_pdf');

      expect(archivo!.path, endsWith('ticket-EV-K7M2QX.pdf'));
      expect(contenido, _pdfFalso);
      expect(texto, contains('3er Aniversario Arequipa Go'));
      expect(texto, contains('EV-K7M2QX'));
    });

    testWidgets('«Compartir imagen» saca una foto del ticket (PNG) y no necesita pedirle nada al servidor', (tester) async {
      File? archivo;
      List<int>? contenido;
      var pedidos = 0;
      await montar(
        tester,
        obtenerPdf: () async {
          pedidos++;
          return _pdfFalso;
        },
        compartir: (f, t) async {
          archivo = f;
          contenido = f.readAsBytesSync();
        },
      );

      await tocar(tester, 'evento_ticket_compartir_imagen', ms: 1200);

      expect(archivo!.path, endsWith('ticket-EV-K7M2QX.png'));
      expect(contenido!.sublist(1, 4), [0x50, 0x4E, 0x47]); // firma de un PNG
      expect(contenido!.length, greaterThan(2000));
      expect(pedidos, 0);
    });

    testWidgets('si el servidor no entrega el ticket, se muestra su mensaje tal cual y los botones se liberan', (tester) async {
      await montar(
        tester,
        obtenerPdf: () async => throw const ErrorDeTicket('El ticket se habilita cuando confirmemos tu pago.'),
      );

      await tocar(tester, 'evento_ticket_descargar_pdf');

      expect(find.text('El ticket se habilita cuando confirmemos tu pago.'), findsOneWidget);
      expect(find.text('No pudimos preparar el ticket. Inténtalo de nuevo.'), findsNothing);
    });

    testWidgets('un fallo inesperado (p. ej. la hoja de compartir) avisa con un mensaje general', (tester) async {
      await montar(tester, compartir: (f, t) async => throw StateError('sin hoja de compartir'));

      await tocar(tester, 'evento_ticket_compartir_pdf');

      expect(find.text('No pudimos preparar el ticket. Inténtalo de nuevo.'), findsOneWidget);
    });

    group('con el provider real (la persona de la sesión pide el PDF al servidor)', () {
      testWidgets('pide el PDF de ESA compra y lo entrega al «Guardar como»', (tester) async {
        final repo = FakeEventoRepository()..misCompras = Either.right([compra(estado: 'confirmado')]);
        final provider = EventoProvider(repository: repo);
        await tester.runAsync(() => provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493'));
        Uint8List? bytes;
        await montar(tester, provider: provider, guardar: (n, b) async {
          bytes = b;
          return '/x';
        });

        await tocar(tester, 'evento_ticket_descargar_pdf');

        expect(repo.llamadasTicketPdf, 1);
        expect(repo.ultimaCompraDelTicket, 31);
        expect(latin1.decode(bytes!.sublist(0, 5)), '%PDF-');
      });

      testWidgets('si el servidor responde con un error, la persona ve su mensaje', (tester) async {
        final repo = FakeEventoRepository()
          ..misCompras = Either.right([compra(estado: 'confirmado')])
          ..ticketPdf = Either.left(const ServerFailure('No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.'));
        final provider = EventoProvider(repository: repo);
        await tester.runAsync(() => provider.cargarMisCompras(clienteConductorId: 601, nroDocumento: '43373493'));
        await montar(tester, provider: provider, guardar: (n, b) async => '/x');

        await tocar(tester, 'evento_ticket_descargar_pdf');

        expect(find.textContaining('Revisa tu conexión'), findsOneWidget);
      });
    });
  });
}
