import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/models/evento_models.dart';
import 'package:arequipagocreditos/domain/entities/conductor_entity.dart';
import 'package:arequipagocreditos/presentation/components/evento_ticket_card.dart';
import 'package:arequipagocreditos/presentation/components/evento_widgets.dart';
import 'package:arequipagocreditos/presentation/pages/evento_detalle_page.dart';
import 'package:arequipagocreditos/presentation/pages/evento_pago_page.dart';
import 'package:arequipagocreditos/presentation/pages/evento_terminos_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/evento_provider.dart';
import 'helpers/evento_fakes.dart';

// «Cómo llegar» (6-nov, Yessenia: «¿se puede incluir la ubicación de Google Maps?»): el evento trae el enlace del mapa (`mapa_url`) y las
// pantallas del evento lo ofrecen. El enlace SOLO se acepta si es http o https; el botón no lanza nada de verdad en las pruebas.

const _mapa = 'https://maps.app.goo.gl/Xy7ZabC123';

class _Usuario extends Fake implements ConductorEntity {
  @override
  int get idConductor => 601;

  @override
  String get nroDocumento => '43373493';
}

class _Auth extends Fake implements AuthProvider {
  @override
  ConductorEntity? get currentUser => _Usuario();
}

EventoModel _conMapa(Object? mapa, {int id = 7}) =>
    EventoModel.fromJson({...eventoJson(), 'id': id, 'mapa_url': mapa});

Future<void> _abrir(
  WidgetTester tester,
  Widget pagina,
  FakeEventoRepository repo, {
  bool cargarEvento = false,
}) async {
  tester.view.physicalSize = const Size(412, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final provider = EventoProvider(repository: repo, ahora: () => ahoraDePrueba);
  if (cargarEvento) {
    await tester.runAsync(
      () => provider.cargarActivo(
        clienteConductorId: 601,
        nroDocumento: '43373493',
      ),
    );
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EventoProvider>.value(value: provider),
        Provider<AuthProvider>.value(value: _Auth()),
      ],
      child: MaterialApp(home: pagina),
    ),
  );
  // El ticket confirmado trae imágenes de red: se avanzan unos cuadros en vez de esperar a que «asienten».
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() => Provider.debugCheckInvalidValueType = null);

  final original = EventoBotonMapa.abridor;
  late List<Uri> abiertos;

  setUp(() {
    abiertos = [];
    EventoBotonMapa.abridor = (uri) async {
      abiertos.add(uri);
      return true;
    };
  });
  tearDown(() => EventoBotonMapa.abridor = original);

  group('el modelo', () {
    test('lee mapa_url y sabe que tiene mapa', () {
      final e = _conMapa('  $_mapa  ');

      expect(e.mapaUrl, _mapa);
      expect(e.tieneMapa, isTrue);
    });

    test('un evento sin enlace no tiene mapa', () {
      expect(_conMapa(null).tieneMapa, isFalse);
      expect(
        EventoModel.fromJson(eventoJson()).mapaUrl,
        isNull,
      ); // el servidor viejo ni manda la clave
    });

    test('solo acepta enlaces http o https: lo demás es «sin mapa»', () {
      for (final raro in [
        'javascript:alert(1)',
        'maps.app.goo.gl/Xy7ZabC123',
        'cerca del estadio',
        '',
        '   ',
        'ftp://servidor.com/mapa',
        'https://',
        42,
      ]) {
        expect(
          _conMapa(raro).mapaUrl,
          isNull,
          reason: 'no debe aceptar: $raro',
        );
      }
      expect(
        _conMapa('http://maps.google.com/?q=las+pampas').mapaUrl,
        'http://maps.google.com/?q=las+pampas',
      );
    });

    test(
      'la compra también lee el enlace del mapa de su evento (y descarta los que no son http/https)',
      () {
        expect(
          EventoCompraModel.fromJson({
            ...compraJson(),
            'mapa_url': _mapa,
          }).mapaUrl,
          _mapa,
        );
        expect(EventoCompraModel.fromJson(compraJson()).mapaUrl, isNull);
        expect(
          EventoCompraModel.fromJson({
            ...compraJson(),
            'mapa_url': 'javascript:alert(1)',
          }).mapaUrl,
          isNull,
        );
      },
    );

    test('copyWith conserva el enlace', () {
      final e = _conMapa(_mapa).copyWith(
        misTickets: const MisTicketsModel(comprados: 1, disponibles: 3),
      );

      expect(e.mapaUrl, _mapa);
    });
  });

  group('el botón «Cómo llegar»', () {
    testWidgets('abre el enlace del mapa', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EventoBotonMapa(url: _mapa)),
        ),
      );

      await tester.tap(find.byKey(const Key('evento_boton_mapa')));
      await tester.pump();

      expect(abiertos, [Uri.parse(_mapa)]);
      expect(find.text('Cómo llegar'), findsOneWidget);
    });

    testWidgets('en versión compacta también abre el enlace', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EventoBotonMapa(url: _mapa, compacto: true)),
        ),
      );

      await tester.tap(find.byKey(const Key('evento_mapa_compacto')));
      await tester.pump();

      expect(abiertos, [Uri.parse(_mapa)]);
    });

    testWidgets('si no se puede abrir avisa en vez de quedarse mudo', (
      tester,
    ) async {
      EventoBotonMapa.abridor = (uri) async => false;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EventoBotonMapa(url: _mapa)),
        ),
      );

      await tester.tap(find.byKey(const Key('evento_boton_mapa')));
      await tester.pump();

      expect(
        find.text('No se pudo abrir el mapa. Inténtalo de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('si abrirlo lanza un error también avisa', (tester) async {
      EventoBotonMapa.abridor = (uri) async => throw Exception('sin navegador');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EventoBotonMapa(url: _mapa)),
        ),
      );

      await tester.tap(find.byKey(const Key('evento_boton_mapa')));
      await tester.pump();

      expect(
        find.text('No se pudo abrir el mapa. Inténtalo de nuevo.'),
        findsOneWidget,
      );
    });
  });

  group('las pantallas', () {
    testWidgets('el detalle del evento ofrece «Cómo llegar» debajo del lugar', (
      tester,
    ) async {
      await _abrir(
        tester,
        EventoDetallePage(evento: _conMapa(_mapa), realizado: true),
        FakeEventoRepository(),
      );

      expect(find.text('Local de la empresa'), findsOneWidget);
      expect(find.byKey(const Key('evento_mapa_compacto')), findsOneWidget);

      await tester.tap(find.byKey(const Key('evento_mapa_compacto')));
      await tester.pump();
      expect(abiertos, [Uri.parse(_mapa)]);
    });

    testWidgets('el detalle de un evento sin enlace no muestra el botón', (
      tester,
    ) async {
      await _abrir(
        tester,
        EventoDetallePage(evento: _conMapa(null), realizado: true),
        FakeEventoRepository(),
      );

      expect(find.text('Local de la empresa'), findsOneWidget);
      expect(find.byKey(const Key('evento_mapa_compacto')), findsNothing);
      expect(find.text('Cómo llegar'), findsNothing);
    });

    testWidgets(
      'un enlace raro no muestra el botón (nunca abre algo que no sea http)',
      (tester) async {
        await _abrir(
          tester,
          EventoDetallePage(
            evento: _conMapa('javascript:alert(1)'),
            realizado: true,
          ),
          FakeEventoRepository(),
        );

        expect(find.byKey(const Key('evento_mapa_compacto')), findsNothing);
      },
    );

    testWidgets('los términos de la compra también lo ofrecen', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(_conMapa(_mapa))];
      await _abrir(
        tester,
        const EventoTerminosPage(),
        repo,
        cargarEvento: true,
      );

      expect(find.byKey(const Key('evento_mapa_compacto')), findsOneWidget);
    });

    testWidgets(
      'el ticket CONFIRMADO ofrece «Cómo llegar» fuera de la imagen que se comparte',
      (tester) async {
        final c = compra(estado: 'confirmado');
        final repo = FakeEventoRepository()
          ..activo = [activo(_conMapa(_mapa))]
          ..misCompras = Either.right([c]);
        await _abrir(
          tester,
          EventoPagoPage(compra: c),
          repo,
          cargarEvento: true,
        );

        expect(find.byKey(const Key('evento_boton_mapa')), findsOneWidget);
        // No está dentro del ticket: el RepaintBoundary del ticket (el que se convierte en la imagen que se comparte) no lo contiene.
        final delTicket = find
            .ancestor(
              of: find.byType(EventoTicketCard),
              matching: find.byType(RepaintBoundary),
            )
            .first;
        expect(
          find.descendant(
            of: delTicket,
            matching: find.byKey(const Key('evento_boton_mapa')),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'una compra PENDIENTE (el paso final tras comprar) también ofrece «Cómo llegar»',
      (tester) async {
        final c = compra();
        final repo = FakeEventoRepository()
          ..activo = [activo(_conMapa(_mapa))]
          ..misCompras = Either.right([c]);
        await _abrir(
          tester,
          EventoPagoPage(compra: c),
          repo,
          cargarEvento: true,
        );

        expect(find.byKey(const Key('evento_boton_mapa')), findsOneWidget);

        await tester.ensureVisible(find.byKey(const Key('evento_boton_mapa')));
        await tester.tap(find.byKey(const Key('evento_boton_mapa')));
        await tester.pump();
        expect(abiertos, [Uri.parse(_mapa)]);
      },
    );

    testWidgets(
      'el enlace sale de la propia compra: sirve aunque el app no tenga cargado el evento activo',
      (tester) async {
        final c = EventoCompraModel.fromJson({
          ...compraJson(),
          'mapa_url': _mapa,
        });
        final repo = FakeEventoRepository()..misCompras = Either.right([c]);
        // Sin `cargarEvento`: el provider no tiene evento (como al abrir el ticket desde «Mis tickets» sin pasar por el aviso del inicio).
        await _abrir(tester, EventoPagoPage(compra: c), repo);

        expect(find.byKey(const Key('evento_boton_mapa')), findsOneWidget);
      },
    );

    testWidgets(
      'una compra rechazada o anulada no muestra «Cómo llegar» (ya no hay ticket)',
      (tester) async {
        for (final estado in ['rechazado', 'anulado']) {
          final c = EventoCompraModel.fromJson({
            ...compraJson(
              estado: estado,
              puedeSubir: false,
              puedeCancelar: false,
              motivo: 'x',
            ),
            'mapa_url': _mapa,
          });
          final repo = FakeEventoRepository()
            ..activo = [activo(_conMapa(_mapa))]
            ..misCompras = Either.right([c]);
          await _abrir(
            tester,
            EventoPagoPage(compra: c),
            repo,
            cargarEvento: true,
          );

          expect(
            find.byKey(const Key('evento_boton_mapa')),
            findsNothing,
            reason: estado,
          );
        }
      },
    );

    testWidgets('sin enlace en la compra ni en el evento no hay botón', (
      tester,
    ) async {
      final c = compra(estado: 'confirmado');
      final repo = FakeEventoRepository()
        ..activo = [activo(_conMapa(null))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo, cargarEvento: true);

      expect(find.byKey(const Key('evento_boton_mapa')), findsNothing);
    });
  });
}
