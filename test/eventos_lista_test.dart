import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/core/errors/exceptions.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/core/utils/evento_gate.dart';
import 'package:arequipagocreditos/data/datasources/evento_remote_datasource.dart';
import 'package:arequipagocreditos/data/models/evento_models.dart';
import 'package:arequipagocreditos/domain/entities/conductor_entity.dart';
import 'package:arequipagocreditos/presentation/pages/evento_detalle_page.dart';
import 'package:arequipagocreditos/presentation/pages/eventos_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/evento_provider.dart';
import 'helpers/evento_fakes.dart';

// La pantalla «Eventos» (próximos y ya realizados) y el detalle de cada evento. Contra un repositorio falso: lo que se prueba es lo
// que la persona ve y puede tocar, no el servidor.

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

/// Evento de la lista (sin banner, para no depender de la red).
EventoModel _ev(int id, String nombre, String fecha, {String? lugar = 'Local de la empresa', Object? precio = 50.0}) {
  return EventoModel.fromJson({
    'id': id,
    'nombre': nombre,
    'descripcion': 'Descripción de $nombre',
    'lugar': lugar,
    'fecha_hora': fecha,
    'banner_url': null,
    'precio_ticket': precio,
  });
}

final _proximo = _ev(7, '3er Aniversario Arequipa Go', '2026-11-14T14:00:00-05:00');
final _otroProximo = _ev(9, 'Fiesta de fin de año', '2026-12-20T20:00:00-05:00');
final _pasado = _ev(3, 'Bingo del 2do Aniversario', '2025-11-14T15:00:00-05:00');

Future<EventoProvider> _abrir(
  WidgetTester tester,
  Widget pagina,
  FakeEventoRepository repo, {
  bool cargarEvento = false,
}) async {
  tester.view.physicalSize = const Size(412, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final provider = EventoProvider(repository: repo, ahora: () => ahoraDePrueba);
  if (cargarEvento) {
    await tester.runAsync(() => provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493'));
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
  await tester.pumpAndSettle();
  return provider;
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(json.encode(body), status, headers: {'content-type': 'application/json'});

void main() {
  setUpAll(() => Provider.debugCheckInvalidValueType = null);
  setUp(EventoGate.reiniciarSesion);

  group('contrato de la lista', () {
    test('GET /app/eventos sin parámetros y lee próximos y anteriores', () async {
      final vistas = <http.Request>[];
      final fuente = EventoRemoteDataSourceImpl(
        client: MockClient((request) async {
          vistas.add(request);
          return _json({
            'success': true,
            'data': {
              'proximos': [
                {'id': 7, 'nombre': 'Próximo', 'fecha_hora': '2026-11-14T14:00:00-05:00', 'precio_ticket': '50.00'},
              ],
              'anteriores': [
                {'id': 3, 'nombre': 'Pasado', 'fecha_hora': '2025-11-14T15:00:00-05:00', 'banner_url': null},
                {'id': 2, 'nombre': 'Más viejo', 'lugar': null},
              ],
            },
          });
        }),
      );

      final lista = await fuente.getEventos();

      expect(vistas.single.method, 'GET');
      expect(vistas.single.url.path, endsWith('/app/eventos'));
      expect(vistas.single.url.queryParameters, isEmpty);
      expect(lista.proximos.map((e) => e.nombre), ['Próximo']);
      expect(lista.proximos.single.precioTicket, 50.0);
      expect(lista.anteriores.map((e) => e.nombre), ['Pasado', 'Más viejo']);
      expect(lista.anteriores.last.lugar, isNull);
    });

    test('una respuesta sin listas o con basura se lee como vacía, sin lanzar', () async {
      for (final data in [null, <String, dynamic>{}, {'proximos': 'x', 'anteriores': null}]) {
        final fuente = EventoRemoteDataSourceImpl(client: MockClient((_) async => _json({'success': true, 'data': data})));
        expect((await fuente.getEventos()).vacia, isTrue);
      }
    });

    test('un error del servidor sale como ServerException', () async {
      final fuente = EventoRemoteDataSourceImpl(client: MockClient((_) async => _json({'message': 'boom'}, 500)));

      expect(fuente.getEventos(), throwsA(isA<ServerException>()));
    });
  });

  group('provider: lista', () {
    test('carga la lista y no la borra al cerrar sesión (es pública)', () async {
      final repo = FakeEventoRepository()..lista = Either.right(EventosListaModel(proximos: [_proximo], anteriores: [_pasado]));
      final provider = EventoProvider(repository: repo);

      await provider.cargarLista();
      provider.limpiar();

      expect(provider.lista?.proximos.single.id, 7);
      expect(provider.lista?.anteriores.single.id, 3);
      expect(provider.errorLista, isNull);
      expect(provider.cargandoLista, isFalse);
    });

    test('un error no borra la lista que ya tenía y deja el mensaje', () async {
      final repo = FakeEventoRepository()..lista = Either.right(EventosListaModel(proximos: [_proximo]));
      final provider = EventoProvider(repository: repo);
      await provider.cargarLista();

      repo.lista = Either.left(const ServerFailure('Sin conexión'));
      await provider.cargarLista();

      expect(provider.lista?.proximos, hasLength(1));
      expect(provider.errorLista, 'Sin conexión');

      repo.lista = Either.right(EventosListaModel(proximos: [_proximo, _otroProximo]));
      await provider.cargarLista();
      expect(provider.lista?.proximos, hasLength(2));
      expect(provider.errorLista, isNull);
    });

    test('dos pedidos a la vez comparten una sola llamada', () async {
      final repo = FakeEventoRepository();
      final provider = EventoProvider(repository: repo);

      await Future.wait([provider.cargarLista(), provider.cargarLista()]);

      expect(repo.llamadasLista, 1);
    });
  });

  group('pantalla «Eventos»', () {
    testWidgets('muestra los próximos y, en la otra pestaña, los realizados con su marca', (tester) async {
      final repo = FakeEventoRepository()..lista = Either.right(EventosListaModel(proximos: [_proximo, _otroProximo], anteriores: [_pasado]));
      await _abrir(tester, const EventosPage(), repo);

      expect(find.text('Próximos'), findsOneWidget);
      expect(find.text('Realizados'), findsOneWidget);
      expect(find.text('3er Aniversario Arequipa Go'), findsOneWidget);
      expect(find.text('Fiesta de fin de año'), findsOneWidget);
      expect(find.text('S/ 50.00 por ticket'), findsNWidgets(2));
      expect(find.text('Bingo del 2do Aniversario'), findsNothing);

      await tester.tap(find.byKey(const Key('eventos_tab_realizados')));
      await tester.pumpAndSettle();

      expect(find.text('Bingo del 2do Aniversario'), findsOneWidget);
      expect(find.text('REALIZADO'), findsOneWidget);
      expect(find.text('S/ 50.00 por ticket'), findsNothing); // un evento pasado ya no ofrece precio
      expect(find.text('3er Aniversario Arequipa Go'), findsNothing);
    });

    testWidgets('la tarjeta lleva la fecha en una insignia (día y mes de Lima)', (tester) async {
      final repo = FakeEventoRepository()..lista = Either.right(EventosListaModel(proximos: [_proximo]));
      await _abrir(tester, const EventosPage(), repo);

      expect(find.text('14'), findsOneWidget);
      expect(find.text('NOV'), findsOneWidget);
      expect(find.textContaining('Sábado 14 de noviembre'), findsOneWidget);
      expect(find.text('Local de la empresa'), findsOneWidget);
    });

    testWidgets('sin próximos ni realizados dice qué pasa en cada pestaña', (tester) async {
      final repo = FakeEventoRepository();
      await _abrir(tester, const EventosPage(), repo);

      expect(find.byKey(const Key('eventos_vacio_proximos')), findsOneWidget);
      expect(find.text('No hay próximos eventos por ahora'), findsOneWidget);

      await tester.tap(find.byKey(const Key('eventos_tab_realizados')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('eventos_vacio_realizados')), findsOneWidget);
      expect(find.text('Aún no hay eventos realizados'), findsOneWidget);
    });

    testWidgets('sin conexión y sin nada cargado muestra el error y «Reintentar» lo vuelve a pedir', (tester) async {
      final repo = FakeEventoRepository()..lista = Either.left(const ServerFailure('No pudimos conectar con el servidor.'));
      await _abrir(tester, const EventosPage(), repo);

      expect(find.byKey(const Key('eventos_error')), findsOneWidget);
      expect(find.text('No pudimos conectar con el servidor.'), findsOneWidget);

      repo.lista = Either.right(EventosListaModel(proximos: [_proximo]));
      await tester.tap(find.byKey(const Key('eventos_reintentar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('eventos_error')), findsNothing);
      expect(find.text('3er Aniversario Arequipa Go'), findsOneWidget);
      expect(repo.llamadasLista, 2);
    });

    testWidgets('tocar un evento abre su detalle; el acceso de arriba lleva a «Mis tickets»', (tester) async {
      final repo = FakeEventoRepository()..lista = Either.right(EventosListaModel(proximos: [_proximo]));
      await _abrir(tester, const EventosPage(), repo);

      await tester.tap(find.byKey(const Key('evento_lista_7')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('evento_detalle_nombre')), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('eventos_mis_tickets')));
      await tester.pumpAndSettle();
      expect(find.text('Mis tickets'), findsWidgets);
    });
  });

  group('detalle del evento', () {
    testWidgets('el evento en venta ofrece «Comprar tickets» y lleva a los términos', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0))];
      await _abrir(tester, EventoDetallePage(evento: _proximo, realizado: false), repo);

      expect(find.text('PRÓXIMO EVENTO'), findsOneWidget);
      expect(find.text('Descripción de 3er Aniversario Arequipa Go'), findsOneWidget);
      expect(find.text('S/ 50.00 por persona'), findsOneWidget);
      expect(find.byKey(const Key('evento_detalle_comprar')), findsOneWidget);

      await tester.tap(find.byKey(const Key('evento_detalle_comprar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('evento_terminos_texto')), findsOneWidget);
    });

    testWidgets('un próximo que NO es el evento en venta no ofrece comprar', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0))]; // el activo es el id 7
      await _abrir(tester, EventoDetallePage(evento: _otroProximo, realizado: false), repo);

      expect(find.text('PRÓXIMO EVENTO'), findsOneWidget);
      expect(find.byKey(const Key('evento_detalle_comprar')), findsNothing);
    });

    testWidgets('con el tope alcanzado no ofrece comprar y lo dice', (tester) async {
      // El cupo sale de la lista completa de compras de la persona: 4 tickets confirmados = el máximo.
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 4))]
        ..misCompras = Either.right([compra(estado: 'confirmado', cantidad: 4)]);
      await _abrir(tester, EventoDetallePage(evento: _proximo, realizado: false), repo);

      expect(find.byKey(const Key('evento_detalle_comprar')), findsNothing);
      expect(find.text('Ya tienes el máximo de 4 tickets por persona'), findsOneWidget);
    });

    testWidgets('si ya compró tickets de este evento queda el acceso a «Mis tickets»', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([compra()]);
      await _abrir(tester, EventoDetallePage(evento: _proximo, realizado: false), repo);

      expect(find.byKey(const Key('evento_detalle_mis_tickets')), findsOneWidget);
    });

    testWidgets('un evento realizado se ve como recuerdo: sin precio, sin comprar y sin consultar el evento en venta', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0))];
      await _abrir(tester, EventoDetallePage(evento: _pasado, realizado: true), repo);

      expect(find.text('EVENTO REALIZADO'), findsOneWidget);
      expect(find.text('Bingo del 2do Aniversario'), findsOneWidget);
      expect(find.textContaining('por persona'), findsNothing);
      expect(find.byKey(const Key('evento_detalle_comprar')), findsNothing);
      expect(repo.llamadasActivo, 0);
    });

    testWidgets('sin lugar ni descripción no deja filas vacías', (tester) async {
      final sinNada = EventoModel.fromJson({'id': 5, 'nombre': 'Solo nombre', 'fecha_hora': '2025-01-10T10:00:00-05:00'});
      final repo = FakeEventoRepository();
      await _abrir(tester, EventoDetallePage(evento: sinNada, realizado: true), repo);

      expect(find.text('Solo nombre'), findsOneWidget);
      expect(find.text('Lugar'), findsNothing);
      expect(find.byKey(const Key('evento_detalle_descripcion')), findsNothing);
    });
  });
}
