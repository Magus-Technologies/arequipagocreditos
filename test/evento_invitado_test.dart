import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/presentation/components/evento_banner_dialog.dart';
import 'package:arequipagocreditos/presentation/components/evento_invitado_aviso.dart';
import 'package:arequipagocreditos/presentation/components/evento_widgets.dart';
import 'package:arequipagocreditos/presentation/providers/evento_provider.dart';
import 'helpers/evento_fakes.dart';

// El aviso del evento para quien NO inició sesión (pantalla de bienvenida) y el botón nuevo de «Comprar tickets».

/// La bienvenida reducida a lo que toca al aviso: una pantalla con el disparador y, aparte, una pantalla encima para comprobar que
/// «Iniciar sesión» se abrió.
Future<int> _montarBienvenida(
  WidgetTester tester,
  FakeEventoRepository repo, {
  required void Function() alIniciarSesion,
}) async {
  tester.view.physicalSize = const Size(412, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final provider = EventoProvider(repository: repo, ahora: () => ahoraDePrueba);
  await tester.pumpWidget(
    ChangeNotifierProvider<EventoProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Text('Bienvenida'),
              EventoInvitadoAviso(onIniciarSesion: alIniciarSesion),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump(); // el primer cuadro dispara la carga
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 350)); // la ventana termina de abrirse
  return repo.llamadasActivo;
}

void main() {
  setUp(EventoInvitadoAviso.reiniciarSesion);

  group('aviso flotante del evento sin sesión', () {
    testWidgets('con evento activo sale una ventana flotante con el banner, el nombre, la fecha y «Ver más detalle»', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(conBanner: false))];
      await _montarBienvenida(tester, repo, alIniciarSesion: () {});

      expect(find.byType(EventoBannerDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget); // flotante, no incrustado en la pantalla
      expect(find.text('NUEVO EVENTO'), findsOneWidget);
      expect(find.text('3er Aniversario Arequipa Go'), findsOneWidget);
      expect(find.textContaining('Sábado 14 de noviembre'), findsOneWidget);
      expect(find.text('Ver más detalle'), findsOneWidget);
      expect(find.text('Inicia sesión para continuar'), findsOneWidget);
      expect(find.text('Ahora no'), findsOneWidget);
    });

    testWidgets('antes de iniciar sesión NO muestra el lugar ni el precio (eso queda detrás del login)', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(conBanner: false))];
      await _montarBienvenida(tester, repo, alIniciarSesion: () {});

      expect(find.text('Local de la empresa'), findsNothing);
      expect(find.textContaining('S/ 50.00'), findsNothing);
      expect(find.text('Comprar tickets'), findsNothing);
    });

    testWidgets('muestra el banner del evento (entero, sin recortarlo)', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento())]; // con banner
      await _montarBienvenida(tester, repo, alIniciarSesion: () {});

      final imagen = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(imagen.imageUrl, 'https://credigo.test/storage/eventos/banners/aniversario.webp');
      expect(imagen.fit, BoxFit.contain);
    });

    testWidgets('el botón cierra la ventana y lleva a «Iniciar sesión»', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(conBanner: false))];
      var entradas = 0;
      await _montarBienvenida(tester, repo, alIniciarSesion: () => entradas++);

      await tester.tap(find.byKey(const Key('evento_invitado_boton')));
      await tester.pumpAndSettle();

      expect(entradas, 1);
      expect(find.byType(EventoBannerDialog), findsNothing);
    });

    testWidgets('tocar el banner hace lo mismo que el botón', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(conBanner: false))];
      var entradas = 0;
      await _montarBienvenida(tester, repo, alIniciarSesion: () => entradas++);

      await tester.tap(find.byKey(const Key('evento_banner')));
      await tester.pumpAndSettle();

      expect(entradas, 1);
      expect(find.byType(EventoBannerDialog), findsNothing);
    });

    testWidgets('«Ahora no» solo la cierra, sin ir a iniciar sesión', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(conBanner: false))];
      var entradas = 0;
      await _montarBienvenida(tester, repo, alIniciarSesion: () => entradas++);

      await tester.tap(find.byKey(const Key('evento_banner_ahora_no')));
      await tester.pumpAndSettle();

      expect(find.byType(EventoBannerDialog), findsNothing);
      expect(entradas, 0);
    });

    testWidgets('sale una sola vez por evento: al volver a la bienvenida no se repite', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(conBanner: false))];
      await _montarBienvenida(tester, repo, alIniciarSesion: () {});
      await tester.tap(find.byKey(const Key('evento_banner_ahora_no')));
      await tester.pumpAndSettle();

      // Otra bienvenida en la misma apertura del app (p. ej. tras cerrar sesión).
      final repo2 = FakeEventoRepository()..activo = [activo(evento(conBanner: false))];
      await _montarBienvenida(tester, repo2, alIniciarSesion: () {});

      expect(find.byType(EventoBannerDialog), findsNothing);
    });

    testWidgets('pide el evento SIN identificar a nadie (no hay sesión)', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(conBanner: false))];
      await _montarBienvenida(tester, repo, alIniciarSesion: () {});

      expect(repo.llamadasActivo, 1);
      expect(repo.ultimaPersonaId, isNull);
      expect(repo.ultimoDocumento, isNull);
    });

    testWidgets('no dibuja nada en la pantalla de bienvenida: ni tarjeta ni espacio debajo del logo', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(conBanner: false))];
      await _montarBienvenida(tester, repo, alIniciarSesion: () {});
      await tester.tap(find.byKey(const Key('evento_banner_ahora_no')));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(EventoInvitadoAviso)), Size.zero);
    });

    testWidgets('sin evento activo no sale nada', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(null)];
      await _montarBienvenida(tester, repo, alIniciarSesion: () {});

      expect(find.byType(EventoBannerDialog), findsNothing);
    });

    testWidgets('sin conexión no sale nada ni lanza', (tester) async {
      final repo = FakeEventoRepository()..activo = [Either.left(const ServerFailure('sin conexión'))];
      await _montarBienvenida(tester, repo, alIniciarSesion: () {});

      expect(find.byType(EventoBannerDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('provider: evento público', () {
    test('no toca el evento de la persona ni su cupo', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento())];
      final provider = EventoProvider(repository: repo);

      await provider.cargarActivoPublico();

      expect(provider.eventoPublico?.nombre, '3er Aniversario Arequipa Go');
      expect(provider.evento, isNull);
      expect(provider.hayAccesoFijo, isFalse);
    });

    test('un error de red no borra el que ya tenía y un «no hay evento» sí', () async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento()), Either.left(const ServerFailure('sin conexión')), activo(null)];
      final provider = EventoProvider(repository: repo);

      await provider.cargarActivoPublico();
      await provider.cargarActivoPublico();
      expect(provider.eventoPublico, isNotNull);

      await provider.cargarActivoPublico();
      expect(provider.eventoPublico, isNull);
    });

    test('dos pedidos a la vez comparten una sola llamada', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento())];
      final provider = EventoProvider(repository: repo);

      await Future.wait([provider.cargarActivoPublico(), provider.cargarActivoPublico()]);

      expect(repo.llamadasActivo, 1);
    });

    test('cerrar sesión (limpiar) no lo borra: es información pública', () async {
      final repo = FakeEventoRepository()..activo = [activo(evento())];
      final provider = EventoProvider(repository: repo);
      await provider.cargarActivoPublico();

      provider.limpiar();

      expect(provider.eventoPublico, isNotNull);
    });
  });

  group('botón «Comprar tickets»', () {
    Future<void> montar(WidgetTester tester, Widget boton) => tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: boton))),
        );

    testWidgets('muestra el texto y el precio, y responde al toque', (tester) async {
      var toques = 0;
      await montar(
        tester,
        EventoBotonComprar(key: const Key('b'), subtexto: 'S/ 50.00 por ticket', onPressed: () => toques++),
      );

      expect(find.text('Comprar tickets'), findsOneWidget);
      expect(find.text('S/ 50.00 por ticket'), findsOneWidget);

      await tester.tap(find.byKey(const Key('b')));
      expect(toques, 1);
    });

    testWidgets('deshabilitado no responde', (tester) async {
      await montar(tester, const EventoBotonComprar(key: Key('b'), onPressed: null));

      await tester.tap(find.byKey(const Key('b')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('el aviso del evento lo usa y lo muestra con el precio del ticket', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: EventoBannerDialog(evento: evento(conBanner: false)))));
      await tester.pump();

      expect(find.byType(EventoBotonComprar), findsOneWidget);
      expect(find.text('S/ 50.00 por ticket'), findsOneWidget);
    });
  });
}
