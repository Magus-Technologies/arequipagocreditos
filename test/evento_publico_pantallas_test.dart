import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/core/utils/evento_gate.dart';
import 'package:arequipagocreditos/data/models/evento_invitado.dart';
import 'package:arequipagocreditos/data/models/evento_models.dart';
import 'package:arequipagocreditos/domain/entities/conductor_entity.dart';
import 'package:arequipagocreditos/presentation/components/evento_invitado_aviso.dart';
import 'package:arequipagocreditos/presentation/pages/evento_compra_page.dart';
import 'package:arequipagocreditos/presentation/pages/evento_detalle_page.dart';
import 'package:arequipagocreditos/presentation/pages/evento_invitado_datos_page.dart';
import 'package:arequipagocreditos/presentation/pages/evento_mis_tickets_page.dart';
import 'package:arequipagocreditos/presentation/pages/evento_terminos_page.dart';
import 'package:arequipagocreditos/presentation/pages/welcome_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/evento_provider.dart';
import 'helpers/evento_fakes.dart';

// TK-0450: las pantallas de quien NO tiene cuenta (o no inició sesión): entra desde «EVENTOS» en la bienvenida, ve el evento público,
// da sus datos, compra, y ve «Mis tickets» con su documento y su celular. Todo contra un repositorio falso y SIN sesión.

/// Sin sesión: nadie en `currentUser`, así que las pantallas funcionan como invitado.
class _AuthSinSesion extends Fake implements AuthProvider {
  @override
  ConductorEntity? get currentUser => null;
}

const _ana = EventoInvitado(nombre: 'Ana Pérez', documento: '43373493', telefono: '959123456', correo: 'ana@correo.pe');

/// Monta `pagina` SIN sesión. `cargarEvento` deja ya abierto el evento público (como cuando se llega desde el detalle) y `datos` deja ya
/// identificado al invitado (como cuando ya compró antes en este celular).
Future<EventoProvider> _abrir(
  WidgetTester tester,
  Widget pagina,
  FakeEventoRepository repo, {
  AlmacenInvitadoEnMemoria? almacen,
  bool cargarEvento = false,
  EventoInvitado? datos,
  Size pantalla = const Size(412, 2000),
}) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final provider = EventoProvider(
    repository: repo,
    ahora: () => ahoraDePrueba,
    almacenInvitado: almacen ?? AlmacenInvitadoEnMemoria(),
  );
  if (cargarEvento) await tester.runAsync(() => provider.cargarEventoPublico(7));
  if (datos != null) await tester.runAsync(() => provider.identificarInvitado(datos));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EventoProvider>.value(value: provider),
        Provider<AuthProvider>.value(value: _AuthSinSesion()),
      ],
      child: MaterialApp(home: pagina),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

String? _texto(WidgetTester tester, String clave) => tester.widget<TextFormField>(find.byKey(Key(clave))).controller?.text;

Future<void> _escribir(WidgetTester tester, String clave, String texto) async {
  await tester.enterText(find.byKey(Key(clave)), texto);
  await tester.pump();
}

/// Un evento público sin imágenes de red (así «asentar» no espera a que carguen).
EventoModel _publico({String? visibilidad}) => evento(conBanner: false, conQr: false, visibilidad: visibilidad);

void main() {
  // AuthProvider es un ChangeNotifier y aquí se da con `Provider.value` (las pantallas solo lo leen): provider lo advierte.
  setUpAll(() => Provider.debugCheckInvalidValueType = null);
  setUp(() {
    EventoGate.reiniciarSesion();
    EventoInvitadoAviso.reiniciarSesion();
    SharedPreferences.setMockInitialValues({});
  });

  group('bienvenida: chip «Eventos»', () {
    // Con un evento público disponible sale la ventana flotante del aviso: se cierra con «Ahora no» y queda la pantalla.
    Future<void> abrirBienvenida(WidgetTester tester, FakeEventoRepository repo) async {
      await _abrir(tester, const WelcomePage(), repo, pantalla: const Size(412, 1200));
      if (find.text('Ahora no').evaluate().isNotEmpty) {
        await tester.tap(find.text('Ahora no'));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('con un evento público disponible hay un chip «Eventos» ARRIBA (chico), no un botón debajo de «INICIAR SESIÓN»', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(_publico())]
        ..lista = Either.right(EventosListaModel(proximos: [_publico()], anteriores: const []));
      await abrirBienvenida(tester, repo);

      final chip = find.byKey(const Key('welcome_eventos'));
      expect(chip, findsOneWidget);
      expect(find.text('Eventos'), findsOneWidget);
      expect(find.text('EVENTOS'), findsNothing); // ya no existe el botón grande

      // Arriba de todo: por encima de «INICIAR SESIÓN» y de «REGISTRAR CONDUCTOR», y chico.
      final iniciarSesion = tester.getTopLeft(find.text('INICIAR SESIÓN'));
      final registrar = tester.getTopLeft(find.text('REGISTRAR CONDUCTOR'));
      expect(tester.getBottomLeft(chip).dy, lessThan(registrar.dy));
      expect(tester.getBottomLeft(chip).dy, lessThan(iniciarSesion.dy));
      final tamano = tester.getSize(chip);
      expect(tamano.height, lessThan(32));
      expect(tamano.width, lessThan(165)); // con la fuente de prueba (cuadros anchos); con Roboto mide ~80
    });

    testWidgets('el chip abre la lista de eventos y la pide SIN sesión (solo públicos)', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(_publico())]
        ..lista = Either.right(EventosListaModel(proximos: [_publico()], anteriores: const []));
      await abrirBienvenida(tester, repo);

      await tester.tap(find.byKey(const Key('welcome_eventos')));
      await tester.pumpAndSettle();

      expect(find.text('Eventos'), findsOneWidget);
      expect(find.byKey(const Key('evento_lista_7')), findsOneWidget);
      expect(repo.llamadasLista, 1);
      expect(repo.ultimaListaPersonaId, isNull);
      expect(repo.ultimaListaDocumento, isNull);
    });

    testWidgets('sin un evento público disponible no hay chip ni botón de eventos', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(null)]
        ..lista = Either.right(EventosListaModel(proximos: const [], anteriores: [_publico()]));
      await abrirBienvenida(tester, repo);

      expect(find.byKey(const Key('welcome_eventos')), findsNothing);
      expect(find.text('EVENTOS'), findsNothing);
      expect(find.text('Eventos'), findsNothing);
      // El resto de la bienvenida sigue como siempre.
      expect(find.text('REGISTRAR CONDUCTOR'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    });

    testWidgets('un evento privado no se anuncia a quien no inició sesión', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(_publico(visibilidad: 'privado'))];
      await abrirBienvenida(tester, repo);

      expect(find.byKey(const Key('welcome_eventos')), findsNothing);
    });
  });

  group('términos → tus datos', () {
    testWidgets('sin sesión, tras aceptar los términos se piden los datos (no se salta a la compra)', (tester) async {
      final repo = FakeEventoRepository()..publico = [Either.right(_publico())];
      await _abrir(tester, const EventoTerminosPage(), repo, cargarEvento: true);

      expect(tester.widget<Text>(find.byKey(const Key('evento_terminos_texto'))).data, 'Primera línea.\nSegunda línea.');

      await tester.tap(find.byKey(const Key('evento_acepta_terminos')));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Tus datos'), findsOneWidget);
      expect(find.text('Para comprar sin cuenta'), findsOneWidget);
      expect(find.byKey(const Key('invitado_nombre')), findsOneWidget);
    });
  });

  group('tus datos (formulario del invitado)', () {
    testWidgets('sin escribir nada marca los tres campos obligatorios y no sigue; el correo es opcional', (tester) async {
      final repo = FakeEventoRepository()..publico = [Either.right(_publico())];
      await _abrir(tester, const EventoInvitadoDatosPage(), repo, cargarEvento: true);

      await tester.tap(find.byKey(const Key('invitado_continuar')));
      await tester.pumpAndSettle();

      expect(find.text('Escribe tu nombre completo.'), findsOneWidget);
      expect(find.text('Escribe tu DNI o carné de extranjería.'), findsOneWidget);
      expect(find.text('Escribe tu número de celular.'), findsOneWidget);
      expect(find.textContaining('correo válido'), findsNothing);
      expect(find.text('Tus datos'), findsOneWidget);
      expect(repo.llamadasMisComprasInvitado, 0);
    });

    testWidgets('un correo mal escrito se marca y no deja seguir', (tester) async {
      final repo = FakeEventoRepository()..publico = [Either.right(_publico())];
      await _abrir(tester, const EventoInvitadoDatosPage(), repo, cargarEvento: true);

      await _escribir(tester, 'invitado_nombre', 'Ana Pérez');
      await _escribir(tester, 'invitado_documento', '43373493');
      await _escribir(tester, 'invitado_telefono', '959123456');
      await _escribir(tester, 'invitado_correo', 'ana@correo');
      await tester.tap(find.byKey(const Key('invitado_continuar')));
      await tester.pumpAndSettle();

      expect(find.text('Escribe un correo válido (o déjalo vacío).'), findsOneWidget);
      expect(find.text('Tus datos'), findsOneWidget);
    });

    testWidgets('el documento admite solo letras y números, y el celular solo dígitos, +, espacios y guiones', (tester) async {
      final repo = FakeEventoRepository()..publico = [Either.right(_publico())];
      await _abrir(tester, const EventoInvitadoDatosPage(), repo, cargarEvento: true);

      await _escribir(tester, 'invitado_documento', '43 37-3493');
      await _escribir(tester, 'invitado_telefono', 'cel +51 959-123');

      expect(_texto(tester, 'invitado_documento'), '43373493');
      expect(_texto(tester, 'invitado_telefono'), ' +51 959-123');
    });

    testWidgets('con datos válidos los guarda en el celular, consulta lo que ya compró y pasa a «Comprar tickets»', (tester) async {
      final repo = FakeEventoRepository()..publico = [Either.right(_publico())];
      final almacen = AlmacenInvitadoEnMemoria();
      final provider = await _abrir(tester, const EventoInvitadoDatosPage(), repo, almacen: almacen, cargarEvento: true);

      await _escribir(tester, 'invitado_nombre', '  ana   pérez ');
      await _escribir(tester, 'invitado_documento', '43373493');
      await _escribir(tester, 'invitado_telefono', '959 123 456');
      await _escribir(tester, 'invitado_correo', 'ana@correo.pe');
      await tester.tap(find.byKey(const Key('invitado_continuar')));
      await tester.pumpAndSettle();

      expect(provider.invitado?.nombre, 'ana pérez');
      expect(provider.invitado?.telefono, '959123456');
      expect(almacen.guardado?.documento, '43373493');
      expect(repo.ultimoDocumentoInvitado, '43373493');
      expect(repo.ultimoTelefonoInvitado, '959123456');
      // Reemplaza la pantalla de datos por la de la compra.
      expect(find.text('Tus datos'), findsNothing);
      expect(find.byKey(const Key('evento_cantidad_mas')), findsOneWidget);
    });

    testWidgets('si el celular ya conoce a la persona, sus datos salen escritos', (tester) async {
      final repo = FakeEventoRepository()..publico = [Either.right(_publico())];
      await _abrir(tester, const EventoInvitadoDatosPage(), repo, almacen: AlmacenInvitadoEnMemoria(_ana), cargarEvento: true);

      expect(_texto(tester, 'invitado_nombre'), 'Ana Pérez');
      expect(_texto(tester, 'invitado_documento'), '43373493');
      expect(_texto(tester, 'invitado_telefono'), '959123456');
      expect(_texto(tester, 'invitado_correo'), 'ana@correo.pe');
    });

    testWidgets('quien ya llegó a su tope no sigue: se le avisa y se le ofrece «Ver mis tickets»', (tester) async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(evento(max: 4, conBanner: false, conQr: false))]
        ..misComprasInvitado = Either.right([compra(cantidad: 4)]);
      await _abrir(tester, const EventoInvitadoDatosPage(), repo, almacen: AlmacenInvitadoEnMemoria(_ana), cargarEvento: true);

      await tester.tap(find.byKey(const Key('invitado_continuar')));
      await tester.pumpAndSettle();

      expect(find.text('Tus datos'), findsOneWidget);
      expect(find.text('Ya tienes el máximo de 4 tickets por persona'), findsOneWidget);

      await tester.tap(find.byKey(const Key('invitado_ver_mis_tickets')));
      await tester.pumpAndSettle();

      expect(find.text('Mis tickets'), findsOneWidget);
      expect(find.text('Tickets de Ana Pérez'), findsOneWidget);
    });
  });

  group('detalle del evento sin cuenta', () {
    testWidgets('un evento público próximo se puede comprar sin sesión: pide el evento completo y sigue a los términos', (tester) async {
      final repo = FakeEventoRepository()..publico = [Either.right(_publico())];
      await _abrir(tester, EventoDetallePage(evento: _publico(), realizado: false), repo);

      expect(repo.llamadasPublico, 1);
      expect(repo.ultimoEventoPublico, 7);
      expect(find.byKey(const Key('evento_detalle_comprar')), findsOneWidget);
      expect(find.byKey(const Key('evento_detalle_privado')), findsNothing);

      await tester.tap(find.byKey(const Key('evento_detalle_comprar')));
      await tester.pumpAndSettle();

      expect(find.text('Términos y condiciones'), findsWidgets);
      expect(find.byKey(const Key('evento_terminos_texto')), findsOneWidget);
    });

    testWidgets('un evento privado se marca «solo clientes GO» y no ofrece comprar ni pide nada al servidor', (tester) async {
      final repo = FakeEventoRepository()..publico = [Either.right(_publico())];
      await _abrir(tester, EventoDetallePage(evento: _publico(visibilidad: 'privado'), realizado: false), repo);

      expect(find.byKey(const Key('evento_detalle_privado')), findsOneWidget);
      expect(find.text('PRIVADO · SOLO CLIENTES GO'), findsOneWidget);
      expect(find.byKey(const Key('evento_detalle_comprar')), findsNothing);
      expect(repo.llamadasPublico, 0);
    });

    testWidgets('un evento ya realizado se ve como recuerdo, sin compra', (tester) async {
      final repo = FakeEventoRepository()..publico = [Either.right(_publico())];
      await _abrir(tester, EventoDetallePage(evento: _publico(), realizado: true), repo);

      expect(tester.widget<Text>(find.byKey(const Key('evento_detalle_etiqueta'))).data, 'EVENTO REALIZADO');
      expect(find.byKey(const Key('evento_detalle_comprar')), findsNothing);
      expect(repo.llamadasPublico, 0);
    });

    testWidgets('quien ya compró en este celular ve «Ver mis tickets» y entra a los suyos', (tester) async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(_publico())]
        ..misComprasInvitado = Either.right([compra()]);
      await _abrir(tester, EventoDetallePage(evento: _publico(), realizado: false), repo, almacen: AlmacenInvitadoEnMemoria(_ana));

      expect(repo.ultimoDocumentoInvitado, '43373493');
      expect(find.byKey(const Key('evento_detalle_mis_tickets')), findsOneWidget);

      await tester.tap(find.byKey(const Key('evento_detalle_mis_tickets')));
      await tester.pumpAndSettle();

      expect(find.text('Mis tickets'), findsOneWidget);
      expect(find.text('Tickets de Ana Pérez'), findsOneWidget);
      expect(find.byKey(const Key('evento_compra_31')), findsOneWidget);
    });
  });

  group('comprar y pagar como invitado', () {
    testWidgets('la compra se manda por el camino del invitado (con sus datos y la captura) y pasa al pago', (tester) async {
      final repo = FakeEventoRepository()
        ..publico = [Either.right(_publico())]
        ..compraInvitado = Either.right(compra(id: 50, cantidad: 2))
        ..misComprasInvitado = Either.right([compra(id: 50, cantidad: 2)]);
      final elegida = File('captura_pago.jpg');
      await _abrir(
        tester,
        EventoCompraPage(elegirCaptura: () async => elegida),
        repo,
        cargarEvento: true,
        datos: _ana,
      );

      await tester.tap(find.byKey(const Key('evento_cantidad_mas')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('evento_elegir_captura')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_enviar_compra')));
      await tester.pumpAndSettle();

      expect(repo.llamadasRegistrarInvitado, 1);
      expect(repo.llamadasRegistrar, 0);
      expect(repo.ultimoInvitado, _ana);
      expect(repo.ultimaCantidadInvitado, 2);
      expect(repo.ultimaCapturaInvitado?.path, 'captura_pago.jpg');
      expect(find.text('Pago de tickets'), findsOneWidget);
      expect(find.text(codigoCompra), findsOneWidget);
    });

    testWidgets('un evento privado no se compra sin sesión: sale el aviso y no se llama al servidor', (tester) async {
      final repo = FakeEventoRepository()..publico = [Either.right(_publico(visibilidad: 'privado'))];
      await _abrir(
        tester,
        EventoCompraPage(elegirCaptura: () async => File('captura_pago.jpg')),
        repo,
        cargarEvento: true,
        datos: _ana,
      );

      await tester.tap(find.byKey(const Key('evento_elegir_captura')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_enviar_compra')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_error_compra')), findsOneWidget);
      expect(find.textContaining('solo para clientes de Arequipa Go'), findsOneWidget);
      expect(repo.llamadasRegistrarInvitado, 0);
    });
  });

  group('mis tickets sin cuenta', () {
    testWidgets('sin datos guardados pide documento y celular, y los valida antes de buscar', (tester) async {
      final repo = FakeEventoRepository();
      await _abrir(tester, const EventoMisTicketsPage(), repo);

      expect(find.text('Consulta tus tickets'), findsOneWidget);

      await tester.tap(find.byKey(const Key('consulta_buscar')));
      await tester.pumpAndSettle();

      expect(find.text('Escribe tu DNI o carné de extranjería.'), findsOneWidget);
      expect(find.text('Escribe tu número de celular.'), findsOneWidget);
      expect(repo.llamadasMisComprasInvitado, 0);
    });

    testWidgets('con un documento y celular que SÍ tienen tickets los muestra y deja esos datos guardados', (tester) async {
      final repo = FakeEventoRepository()..misComprasInvitado = Either.right([compra(), compra(id: 32, cantidad: 1)]);
      final almacen = AlmacenInvitadoEnMemoria();
      await _abrir(tester, const EventoMisTicketsPage(), repo, almacen: almacen);

      await _escribir(tester, 'consulta_documento', '43373493');
      await _escribir(tester, 'consulta_telefono', '959123456');
      await tester.tap(find.byKey(const Key('consulta_buscar')));
      await tester.pumpAndSettle();

      expect(find.text('Consulta tus tickets'), findsNothing);
      expect(find.text('Tickets del documento 43373493'), findsOneWidget);
      expect(find.byKey(const Key('evento_compra_31')), findsOneWidget);
      expect(find.byKey(const Key('evento_compra_32')), findsOneWidget);
      expect(almacen.guardado?.documento, '43373493');
      expect(almacen.guardado?.telefono, '959123456');
    });

    testWidgets('si no hay tickets con esos datos lo dice y no guarda nada', (tester) async {
      final repo = FakeEventoRepository()..misComprasInvitado = Either.right(const []);
      final almacen = AlmacenInvitadoEnMemoria();
      await _abrir(tester, const EventoMisTicketsPage(), repo, almacen: almacen);

      await _escribir(tester, 'consulta_documento', '43373493');
      await _escribir(tester, 'consulta_telefono', '959123456');
      await tester.tap(find.byKey(const Key('consulta_buscar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consulta_error')), findsOneWidget);
      expect(find.textContaining('No encontramos tickets'), findsOneWidget);
      expect(find.text('Consulta tus tickets'), findsOneWidget);
      expect(almacen.guardado, isNull);
    });

    testWidgets('con sus datos guardados salen sus tickets sin pedir nada, y «No soy yo» los borra del celular', (tester) async {
      final repo = FakeEventoRepository()..misComprasInvitado = Either.right([compra()]);
      final almacen = AlmacenInvitadoEnMemoria(_ana);
      await _abrir(tester, const EventoMisTicketsPage(), repo, almacen: almacen);

      expect(find.text('Tickets de Ana Pérez'), findsOneWidget);
      expect(find.text('Documento 43373493 · celular 959123456'), findsOneWidget);
      expect(find.byKey(const Key('evento_compra_31')), findsOneWidget);
      expect(find.text('Consulta tus tickets'), findsNothing);

      // «Volver» deja todo como estaba.
      await tester.tap(find.byKey(const Key('evento_invitado_olvidar')));
      await tester.pumpAndSettle();
      expect(find.text('¿Borrar tus datos de este celular?'), findsOneWidget);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Tickets de Ana Pérez'), findsOneWidget);
      expect(almacen.guardado, _ana);

      // Confirmar los borra y vuelve la consulta.
      await tester.tap(find.byKey(const Key('evento_invitado_olvidar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_invitado_olvidar_confirmar')));
      await tester.pumpAndSettle();

      expect(almacen.guardado, isNull);
      expect(find.text('Consulta tus tickets'), findsOneWidget);
      expect(find.byKey(const Key('evento_compra_31')), findsNothing);
    });
  });
}
