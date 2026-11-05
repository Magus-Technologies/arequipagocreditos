import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/core/utils/evento_gate.dart';
import 'package:arequipagocreditos/domain/entities/conductor_entity.dart';
import 'package:arequipagocreditos/presentation/components/evento_acceso_card.dart';
import 'package:arequipagocreditos/presentation/components/evento_widgets.dart';
import 'package:arequipagocreditos/presentation/pages/evento_compra_page.dart';
import 'package:arequipagocreditos/presentation/pages/evento_mis_tickets_page.dart';
import 'package:arequipagocreditos/presentation/pages/evento_pago_page.dart';
import 'package:arequipagocreditos/presentation/pages/evento_terminos_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/evento_provider.dart';
import 'helpers/evento_fakes.dart';

// Las pantallas de «Eventos»: términos → cantidad → pago → mis tickets, y el aviso al entrar. Todo contra un repositorio falso: lo que
// se prueba es lo que la persona ve y puede tocar en cada estado, no el servidor.

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

/// El inicio del app, reducido a lo que toca a «Eventos»: al abrirse precarga el evento y las compras (como `DashboardPage`) y muestra
/// la entrada fija.
class _InicioSimulado extends StatefulWidget {
  const _InicioSimulado();

  @override
  State<_InicioSimulado> createState() => _InicioSimuladoState();
}

class _InicioSimuladoState extends State<_InicioSimulado> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => EventoGate.precargar(context));
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: EventoAccesoCard());
}

/// Monta `pagina` con el provider ya cargado con el evento activo (si el repositorio tiene uno).
Future<EventoProvider> _abrir(
  WidgetTester tester,
  Widget pagina,
  FakeEventoRepository repo, {
  bool cargarEvento = true,
  // Con una imagen de red en pantalla el indicador de carga nunca termina de animar: ahí se avanzan unos cuadros, no hasta «asentar».
  bool asentar = true,
}) async {
  // Pantalla alta: el pago es una lista larga (QR, captura, cancelar) y una lista solo construye lo que se ve.
  tester.view.physicalSize = const Size(412, 2000);
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
  if (asentar) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }
  return provider;
}

bool _habilitado(WidgetTester tester, Finder boton) => tester.widget<ButtonStyleButton>(boton).onPressed != null;

Finder _boton(String texto) => find.widgetWithText(ElevatedButton, texto);

/// «Enviar compra» (botón amarillo de comprar): ¿responde al toque?
bool _envioHabilitado(WidgetTester tester) => tester.widget<EventoBotonComprar>(find.byKey(const Key('evento_enviar_compra'))).onPressed != null;

void main() {
  // AuthProvider es un ChangeNotifier y aquí se da con `Provider.value` (las pantallas solo lo leen): provider lo advierte.
  setUpAll(() => Provider.debugCheckInvalidValueType = null);
  setUp(EventoGate.reiniciarSesion);

  group('términos', () {
    testWidgets('muestra los términos y la política con sus saltos de línea', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0))];
      await _abrir(tester, const EventoTerminosPage(), repo);

      expect(tester.widget<Text>(find.byKey(const Key('evento_terminos_texto'))).data, 'Primera línea.\nSegunda línea.');
      expect(find.text('Tus datos se usan solo para el evento.'), findsOneWidget);
      expect(find.text('3er Aniversario Arequipa Go'), findsOneWidget);
      expect(find.textContaining('Sábado 14 de noviembre'), findsOneWidget);
    });

    testWidgets('«Continuar» no se habilita hasta marcar la casilla, y entonces pasa a la cantidad', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0))];
      await _abrir(tester, const EventoTerminosPage(), repo);

      expect(find.text('He leído y acepto los términos y condiciones y la política de privacidad'), findsOneWidget);
      expect(_habilitado(tester, _boton('Continuar')), isFalse);

      await tester.tap(find.byKey(const Key('evento_acepta_terminos')));
      await tester.pump();
      expect(_habilitado(tester, _boton('Continuar')), isTrue);

      await tester.tap(find.byKey(const Key('evento_acepta_terminos')));
      await tester.pump();
      expect(_habilitado(tester, _boton('Continuar')), isFalse); // desmarcar la vuelve a bloquear

      await tester.tap(find.byKey(const Key('evento_acepta_terminos')));
      await tester.pump();
      await tester.tap(_boton('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cuántos tickets?'), findsOneWidget);
    });

    testWidgets('con el tope alcanzado no deja comprar y ofrece «Ver mis tickets»', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 4))];
      await _abrir(tester, const EventoTerminosPage(), repo);

      expect(find.text('Ya tienes el máximo de 4 tickets por persona'), findsOneWidget);
      expect(find.byKey(const Key('evento_acepta_terminos')), findsNothing);
      expect(_boton('Continuar'), findsNothing);
      expect(_boton('Ver mis tickets'), findsOneWidget);

      await tester.tap(_boton('Ver mis tickets'));
      await tester.pumpAndSettle();
      expect(find.text('Mis tickets'), findsOneWidget);
    });

    testWidgets('muestra la descripción del evento en el encabezado', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0))];
      await _abrir(tester, const EventoTerminosPage(), repo);

      expect(tester.widget<Text>(find.byKey(const Key('evento_descripcion'))).data, 'Música, sorteos y bingo');
    });

    testWidgets('sin descripción no deja un hueco ni un texto vacío', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 0, descripcion: null)), activo(evento(comprados: 0, descripcion: '   '))];
      await _abrir(tester, const EventoTerminosPage(), repo);

      expect(find.byKey(const Key('evento_descripcion')), findsNothing);
    });

    testWidgets('sin evento activo avisa que ya no está disponible', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(null)];
      await _abrir(tester, const EventoTerminosPage(), repo);

      expect(find.text('Este evento ya no está disponible.'), findsOneWidget);
    });
  });

  group('cantidad', () {
    testWidgets('el selector va de 1 a lo que le queda y el total se actualiza en vivo', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 2))]; // le quedan 2
      await _abrir(tester, const EventoCompraPage(), repo);

      expect(find.text('Máximo 4 por persona · te quedan 2'), findsOneWidget);
      expect(find.text('Precio por ticket'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('evento_cantidad'))).data, '1');
      expect(tester.widget<Text>(find.byKey(const Key('evento_total'))).data, 'S/ 50.00');
      expect(tester.widget<IconButton>(find.byKey(const Key('evento_cantidad_menos'))).onPressed, isNull);

      await tester.tap(find.byKey(const Key('evento_cantidad_mas')));
      await tester.pump();

      expect(tester.widget<Text>(find.byKey(const Key('evento_cantidad'))).data, '2');
      expect(tester.widget<Text>(find.byKey(const Key('evento_total'))).data, 'S/ 100.00');
      expect(tester.widget<IconButton>(find.byKey(const Key('evento_cantidad_mas'))).onPressed, isNull); // llegó a su tope

      await tester.tap(find.byKey(const Key('evento_cantidad_menos')));
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('evento_cantidad'))).data, '1');
    });

    testWidgets('el total usa el precio con decimales', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 0, precio: '35.50'))];
      await _abrir(tester, const EventoCompraPage(), repo);

      await tester.tap(find.byKey(const Key('evento_cantidad_mas')));
      await tester.tap(find.byKey(const Key('evento_cantidad_mas')));
      await tester.pump();

      expect(tester.widget<Text>(find.byKey(const Key('evento_total'))).data, 'S/ 106.50');
    });

    testWidgets('SIN captura el botón «Enviar compra» está bloqueado: avisa que sin captura no se registra y no manda nada', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 0))];
      await _abrir(tester, const EventoCompraPage(), repo);

      expect(_envioHabilitado(tester), isFalse);
      expect(find.text('Sin la captura de tu pago no se registra la compra.'), findsOneWidget);
      expect(find.byKey(const Key('evento_captura_elegida')), findsNothing);

      await tester.tap(find.byKey(const Key('evento_enviar_compra')), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(repo.llamadasRegistrar, 0); // sin captura no hay compra
    });

    testWidgets('el QR de pago se ve en la misma pantalla y sigue el total a pagar', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 0))];
      await _abrir(tester, const EventoCompraPage(), repo);

      expect(find.byKey(const Key('evento_qr_pagar')), findsOneWidget);
      expect(find.text('Paga el monto exacto de S/ 50.00.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('evento_cantidad_mas')));
      await tester.pump();
      expect(find.text('Paga el monto exacto de S/ 100.00.'), findsOneWidget);
    });

    testWidgets('si el QR no llegó lo dice y «Reintentar» vuelve a pedir el evento', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 0, conQr: false)), activo(evento(max: 4, comprados: 0))];
      await _abrir(tester, const EventoCompraPage(), repo);

      expect(find.byKey(const Key('evento_sin_qr')), findsOneWidget);
      expect(find.byKey(const Key('evento_qr_pagar')), findsNothing);

      await tester.tap(find.byKey(const Key('evento_reintentar_qr')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_sin_qr')), findsNothing);
      expect(find.byKey(const Key('evento_qr_pagar')), findsOneWidget);
    });

    testWidgets('con la captura elegida se habilita y la compra se registra CON esa captura y la cantidad, y pasa al detalle', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 0))]
        ..compra = Either.right(compra(id: 50, cantidad: 2, captura: 'https://credigo.test/storage/eventos/capturas/c.jpg'))
        ..misCompras = Either.right([compra(id: 50, cantidad: 2, captura: 'https://credigo.test/storage/eventos/capturas/c.jpg')]);
      final elegida = File('captura_pago.jpg');
      await _abrir(tester, EventoCompraPage(elegirCaptura: () async => elegida), repo);

      await tester.tap(find.byKey(const Key('evento_cantidad_mas')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('evento_elegir_captura')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_captura_elegida')), findsOneWidget);
      expect(find.text('Cambiar captura'), findsOneWidget);
      expect(_envioHabilitado(tester), isTrue);

      await tester.tap(find.byKey(const Key('evento_enviar_compra')));
      // El detalle de la compra con captura muestra una imagen de red: su indicador de carga no deja «asentar», se avanzan unos cuadros.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(repo.llamadasRegistrar, 1);
      expect(repo.ultimaCantidad, 2);
      expect(repo.ultimaCapturaDeCompra?.path, 'captura_pago.jpg');
      expect(find.text('Pago de tickets'), findsOneWidget);
      expect(find.text('EV-K7M2QX'), findsOneWidget);
      expect(find.text('En revisión'), findsOneWidget); // ya llegó con captura
    });

    testWidgets('cambiar la captura reemplaza a la anterior: se manda la última', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 0))]
        ..compra = Either.right(compra(id: 50, cantidad: 1, captura: 'https://credigo.test/storage/eventos/capturas/c.jpg'))
        ..misCompras = Either.right([compra(id: 50, cantidad: 1, captura: 'https://credigo.test/storage/eventos/capturas/c.jpg')]);
      final archivos = [File('primera.jpg'), File('segunda.jpg')];
      var n = 0;
      await _abrir(tester, EventoCompraPage(elegirCaptura: () async => archivos[n++]), repo);

      await tester.tap(find.byKey(const Key('evento_elegir_captura')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_elegir_captura')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_enviar_compra')));
      // El detalle de la compra con captura muestra una imagen de red: su indicador de carga no deja «asentar», se avanzan unos cuadros.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(repo.ultimaCapturaDeCompra?.path, 'segunda.jpg');
    });

    testWidgets('si la persona cancela la elección, la captura anterior se conserva', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 0))];
      final respuestas = <File?>[File('buena.jpg'), null];
      var n = 0;
      await _abrir(tester, EventoCompraPage(elegirCaptura: () async => respuestas[n++]), repo);

      await tester.tap(find.byKey(const Key('evento_elegir_captura')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_elegir_captura')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_captura_elegida')), findsOneWidget);
      expect(_envioHabilitado(tester), isTrue);
    });

    testWidgets('un 422 del servidor se muestra tal cual, la captura elegida se conserva y la persona puede corregir', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 0)), activo(evento(max: 4, comprados: 3))]
        ..compra = Either.left(const ValidationFailure('Ya tienes 3 de 4 tickets para este evento.'));
      await _abrir(tester, EventoCompraPage(elegirCaptura: () async => File('captura_pago.jpg')), repo);

      await tester.tap(find.byKey(const Key('evento_cantidad_mas')));
      await tester.tap(find.byKey(const Key('evento_cantidad_mas')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('evento_elegir_captura')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_enviar_compra')));
      await tester.pumpAndSettle();

      expect(find.text('Ya tienes 3 de 4 tickets para este evento.'), findsOneWidget);
      expect(find.text('Pago de tickets'), findsNothing);
      // El cupo se refrescó: ahora le queda 1, así que la cantidad elegida baja sola y puede volver a enviar sin volver a elegir la captura.
      expect(find.text('Máximo 4 por persona · te quedan 1'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('evento_cantidad'))).data, '1');
      expect(find.byKey(const Key('evento_captura_elegida')), findsOneWidget);
      expect(_envioHabilitado(tester), isTrue);
    });

    testWidgets('si se pierde la respuesta avisa que no se sabe si se registró y ofrece ir a «Mis tickets»', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 0))]
        ..compra = Either.left(const ServerFailure('No pudimos conectar con el servidor.'));
      await _abrir(tester, EventoCompraPage(elegirCaptura: () async => File('captura_pago.jpg')), repo);

      await tester.tap(find.byKey(const Key('evento_elegir_captura')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_enviar_compra')));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos confirmar si tu compra se registró. Revisa «Mis tickets» antes de intentar de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('No pudimos conectar con el servidor.'), findsNothing);
      expect(repo.llamadasMisCompras, 1); // ya miró en el servidor cómo quedó

      await tester.tap(find.byKey(const Key('evento_error_ver_mis_tickets')));
      await tester.pumpAndSettle();
      expect(find.text('Mis tickets'), findsOneWidget);
    });

    testWidgets('un error de validación no ofrece «Ver mis tickets»: el servidor dijo que no', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 0))]
        ..compra = Either.left(const ValidationFailure('El evento ya no está disponible.'));
      await _abrir(tester, EventoCompraPage(elegirCaptura: () async => File('captura_pago.jpg')), repo);

      await tester.tap(find.byKey(const Key('evento_elegir_captura')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_enviar_compra')));
      await tester.pumpAndSettle();

      expect(find.text('El evento ya no está disponible.'), findsOneWidget);
      expect(find.byKey(const Key('evento_error_ver_mis_tickets')), findsNothing);
    });

    testWidgets('con el cupo agotado el botón queda bloqueado aunque ya haya captura', (tester) async {
      // El cupo sale de la lista completa de compras: 4 tickets confirmados = el máximo.
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 4))]
        ..misCompras = Either.right([compra(estado: 'confirmado', cantidad: 4)]);
      await _abrir(tester, EventoCompraPage(elegirCaptura: () async => File('captura_pago.jpg')), repo);

      await tester.tap(find.byKey(const Key('evento_elegir_captura')));
      await tester.pumpAndSettle();

      expect(_envioHabilitado(tester), isFalse);
    });
  });

  group('pago', () {
    testWidgets('pendiente sin captura: QR, monto, código, subir captura y cancelar', (tester) async {
      final c = compra();
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo);

      expect(find.text('Falta subir captura'), findsOneWidget);
      expect(find.text('Paga con el QR y sube la captura del pago.'), findsOneWidget);
      expect(find.byKey(const Key('evento_qr')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('evento_monto'))).data, 'S/ 100.00');
      expect(find.text('EV-K7M2QX'), findsOneWidget);
      expect(find.byKey(const Key('evento_subir_captura')), findsOneWidget);
      expect(find.text('Subir captura del pago'), findsWidgets);
      expect(find.byKey(const Key('evento_cancelar_compra')), findsOneWidget);
    });

    testWidgets('pendiente con captura: «En revisión», vista previa de la captura y «Cambiar captura»', (tester) async {
      final c = compra(captura: 'https://credigo.test/storage/eventos/capturas/c.jpg');
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo, asentar: false);

      expect(find.text('En revisión'), findsOneWidget);
      expect(find.byKey(const Key('evento_captura_vista_previa')), findsOneWidget);
      expect(find.text('Cambiar captura del pago'), findsOneWidget);
      expect(find.text('Subir captura del pago'), findsNothing);
    });

    testWidgets('«Cancelar compra» solo aparece si el servidor lo permite', (tester) async {
      final c = compra(puedeCancelar: false, puedeSubir: true);
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo);

      expect(find.byKey(const Key('evento_cancelar_compra')), findsNothing);
      expect(find.byKey(const Key('evento_subir_captura')), findsOneWidget);
    });

    testWidgets('sin permiso para subir captura no ofrece el botón', (tester) async {
      final c = compra(puedeSubir: false);
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo);

      expect(find.byKey(const Key('evento_subir_captura')), findsNothing);
    });

    testWidgets('rechazada: muestra el motivo, avisa que puede volver a comprar y no ofrece pagar', (tester) async {
      final c = compra(estado: 'rechazado', motivo: 'El monto no coincide', puedeCancelar: false, puedeSubir: false);
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 0))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo);

      expect(find.text('Rechazado'), findsOneWidget);
      expect(find.text('Motivo: El monto no coincide'), findsOneWidget);
      expect(find.text('Puedes comprar tus tickets de nuevo.'), findsOneWidget);
      expect(find.byKey(const Key('evento_qr')), findsNothing);
      expect(find.byKey(const Key('evento_subir_captura')), findsNothing);
      expect(find.byKey(const Key('evento_cancelar_compra')), findsNothing);
      expect(_boton('Comprar de nuevo'), findsOneWidget);

      await tester.tap(_boton('Comprar de nuevo'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('evento_terminos_texto')), findsOneWidget);
    });

    for (final (estado, etiqueta) in [('confirmado', 'Confirmado'), ('anulado', 'Anulado')]) {
      testWidgets('$estado: solo el estado, sin QR ni acciones', (tester) async {
        final c = compra(estado: estado, puedeCancelar: false, puedeSubir: false);
        final repo = FakeEventoRepository()
          ..activo = [activo(evento(comprados: 2))]
          ..misCompras = Either.right([c]);
        await _abrir(tester, EventoPagoPage(compra: c), repo);

        expect(find.text(etiqueta), findsOneWidget);
        expect(find.byKey(const Key('evento_qr')), findsNothing);
        expect(find.byKey(const Key('evento_subir_captura')), findsNothing);
        expect(find.byKey(const Key('evento_cancelar_compra')), findsNothing);
        expect(find.text('Monto'), findsOneWidget); // ya no es «Monto a pagar»
      });
    }

    testWidgets('confirmada: se ve como ticket de entrada, con su QR, el lugar y el código', (tester) async {
      final c = compra(estado: 'confirmado', puedeCancelar: false, puedeSubir: false);
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo);

      expect(find.byKey(const Key('evento_ticket')), findsOneWidget);
      expect(find.text('TICKET DE ENTRADA'), findsOneWidget);
      expect(find.text('Local de la empresa'), findsOneWidget); // el lugar sale del evento activo
      expect(find.byKey(const Key('evento_ticket_qr')), findsOneWidget);
      expect(tester.widget<QrImageView>(find.byType(QrImageView)).semanticsLabel, 'QR de entrada EV-K7M2QX'); // el QR se arma con el código de la compra
      expect(find.text('EV-K7M2QX'), findsOneWidget);
      expect(find.text('Presenta este QR o tu código en la entrada.'), findsOneWidget);
    });

    testWidgets('confirmada: ofrece descargar el PDF y compartir (PDF o imagen); el estado va dentro del ticket', (tester) async {
      final c = compra(estado: 'confirmado', puedeCancelar: false, puedeSubir: false);
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo);

      expect(find.byKey(const Key('evento_ticket_acciones')), findsOneWidget);
      expect(find.text('Descargar PDF'), findsOneWidget);
      expect(find.text('Compartir PDF'), findsOneWidget);
      expect(find.text('Compartir imagen'), findsOneWidget);
      // Sin tarjeta de estado aparte: el chip está dentro del ticket (una sola vez) y no hay vista previa de captura.
      expect(find.byKey(const Key('evento_mensaje_estado')), findsNothing);
      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.byKey(const Key('evento_captura_vista_previa')), findsNothing);
    });

    testWidgets('pendiente, rechazada y anulada NO ofrecen descargar ni compartir el ticket', (tester) async {
      for (final estado in ['pendiente', 'rechazado', 'anulado']) {
        final c = compra(estado: estado, puedeCancelar: false, puedeSubir: false);
        final repo = FakeEventoRepository()
          ..activo = [activo(evento(comprados: 2))]
          ..misCompras = Either.right([c]);
        await _abrir(tester, EventoPagoPage(compra: c), repo);

        expect(find.byKey(const Key('evento_ticket_acciones')), findsNothing, reason: estado);
      }
    });

    testWidgets('una compra nueva (ya con captura) no vuelve a pedir pagar: no sale el QR de pago', (tester) async {
      final c = compra(captura: 'https://credigo.test/storage/eventos/capturas/c.jpg');
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo, asentar: false);

      expect(find.text('En revisión'), findsOneWidget);
      expect(find.byKey(const Key('evento_qr')), findsNothing);
    });

    testWidgets('tocar el QR del ticket lo amplía', (tester) async {
      final c = compra(estado: 'confirmado', puedeCancelar: false, puedeSubir: false);
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo);

      await tester.tap(find.byKey(const Key('evento_ticket_qr')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_ticket_qr_grande')), findsOneWidget);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('evento_ticket_qr_grande')), findsNothing);
    });

    testWidgets('pendiente: el ticket aún no tiene QR de entrada (el QR que se ve es el de pagar)', (tester) async {
      final c = compra();
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo);

      expect(find.byKey(const Key('evento_ticket')), findsOneWidget);
      expect(find.byKey(const Key('evento_ticket_qr')), findsNothing);
      expect(find.text('Tu QR de entrada se activa al confirmar tu pago.'), findsOneWidget);
      expect(find.byKey(const Key('evento_qr')), findsOneWidget); // el de pagar
      expect(find.byType(QrImageView), findsNothing);
    });

    for (final estado in ['rechazado', 'anulado']) {
      testWidgets('$estado: no hay ticket de entrada', (tester) async {
        final c = compra(estado: estado, puedeCancelar: false, puedeSubir: false);
        final repo = FakeEventoRepository()
          ..activo = [activo(evento(comprados: 2))]
          ..misCompras = Either.right([c]);
        await _abrir(tester, EventoPagoPage(compra: c), repo);

        expect(find.byKey(const Key('evento_ticket')), findsNothing);
        expect(find.byType(QrImageView), findsNothing);
      });
    }

    testWidgets('cancelar pide confirmación y deja la compra anulada', (tester) async {
      final c = compra();
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([c])
        ..cancelar = Either.right(compra(estado: 'anulado', puedeCancelar: false, puedeSubir: false));
      await _abrir(tester, EventoPagoPage(compra: c), repo);

      await tester.tap(find.byKey(const Key('evento_cancelar_compra')));
      await tester.pumpAndSettle();
      expect(find.text('¿Cancelar la compra?'), findsOneWidget);

      // «Volver» no cancela nada.
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(repo.llamadasCancelar, 0);

      await tester.tap(find.byKey(const Key('evento_cancelar_compra')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, cancelar'));
      await tester.pumpAndSettle();

      expect(repo.llamadasCancelar, 1);
      expect(find.text('Anulado'), findsOneWidget);
      expect(find.byKey(const Key('evento_cancelar_compra')), findsNothing);
    });

    testWidgets('el código se puede copiar', (tester) async {
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copiado = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      final c = compra();
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 2))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, EventoPagoPage(compra: c), repo);

      await tester.tap(find.byKey(const Key('evento_copiar_codigo')));
      await tester.pump();

      expect(copiado, 'EV-K7M2QX');
      expect(find.text('Código copiado'), findsOneWidget);
    });
  });

  group('mis tickets', () {
    testWidgets('sin compras lo dice y ofrece comprar si le quedan tickets', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 0))];
      await _abrir(tester, const EventoMisTicketsPage(), repo);

      expect(find.text('Aún no has comprado tickets'), findsOneWidget);
      expect(find.byKey(const Key('evento_comprar_tickets')), findsOneWidget);
    });

    testWidgets('lista cada compra con evento, cantidad, monto, código y estado', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 3))]
        ..misCompras = Either.right([
          compra(id: 32, cantidad: 1, estado: 'pendiente'),
          compra(id: 31, cantidad: 2, estado: 'confirmado', puedeCancelar: false),
          compra(id: 30, cantidad: 1, estado: 'rechazado', motivo: 'Captura ilegible'),
        ]);
      await _abrir(tester, const EventoMisTicketsPage(), repo);

      expect(find.text('Falta subir captura'), findsOneWidget);
      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.text('Rechazado'), findsOneWidget);
      expect(find.text('1 ticket'), findsNWidgets(2));
      expect(find.text('2 tickets'), findsOneWidget);
      expect(find.text('Motivo: Captura ilegible'), findsOneWidget);
      expect(find.text('Máximo 4 por persona · te quedan 1'), findsOneWidget);
    });

    testWidgets('con el tope alcanzado no ofrece «Comprar tickets» y dice el máximo', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 4))]
        ..misCompras = Either.right([compra(cantidad: 4, estado: 'confirmado', puedeCancelar: false)]);
      await _abrir(tester, const EventoMisTicketsPage(), repo);

      expect(find.byKey(const Key('evento_comprar_tickets')), findsNothing);
      expect(find.text('Ya tienes el máximo de 4 tickets por persona'), findsOneWidget);
    });

    testWidgets('sin evento activo funciona: lista las compras y no ofrece comprar', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(null)]
        ..misCompras = Either.right([compra(estado: 'confirmado', puedeCancelar: false)]);
      await _abrir(tester, const EventoMisTicketsPage(), repo);

      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.text('Código: $codigoCompra'), findsOneWidget);
      expect(find.byKey(const Key('evento_comprar_tickets')), findsNothing);
      expect(find.byKey(const Key('evento_tope_alcanzado')), findsNothing); // tampoco el aviso de tope, que no viene al caso
    });

    testWidgets('tocar una compra pendiente abre su pago', (tester) async {
      final c = compra(id: 31);
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 2))]
        ..misCompras = Either.right([c]);
      await _abrir(tester, const EventoMisTicketsPage(), repo);

      await tester.tap(find.byKey(const Key('evento_compra_31')));
      await tester.pumpAndSettle();

      expect(find.text('Pago de tickets'), findsOneWidget);
      expect(find.byKey(const Key('evento_qr')), findsOneWidget);
    });

    testWidgets('«Comprar tickets» lleva a los términos', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 0))];
      await _abrir(tester, const EventoMisTicketsPage(), repo);

      await tester.tap(find.byKey(const Key('evento_comprar_tickets')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_terminos_texto')), findsOneWidget);
    });

    testWidgets('si no se pudo cargar muestra el error con «Reintentar»', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 0))]
        ..misCompras = Either.left(const ServerFailure('No pudimos conectar con el servidor.'));
      await _abrir(tester, const EventoMisTicketsPage(), repo);

      expect(find.text('No pudimos conectar con el servidor.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('entrada fija del inicio', () {
    testWidgets('con evento activo muestra su nombre y abre «Mis tickets»', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0))];
      await _abrir(tester, const Scaffold(body: EventoAccesoCard()), repo);

      expect(find.text('3er Aniversario Arequipa Go'), findsOneWidget);

      await tester.tap(find.byKey(const Key('evento_acceso_card')));
      await tester.pumpAndSettle();
      expect(find.text('Mis tickets'), findsOneWidget);
    });

    testWidgets('sin evento activo ni compras no se ve nada', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(null)];
      await _abrir(tester, const _InicioSimulado(), repo, cargarEvento: false);

      expect(find.byKey(const Key('evento_acceso_card')), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('el evento ya empezó (sin activo) pero hay una compra confirmada: aparece y abre «Mis tickets»', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(null)] // pasadas las 2:00 p. m. el servidor ya no lo manda como activo
        ..misCompras = Either.right([compra(estado: 'confirmado', puedeCancelar: false)]);
      await _abrir(tester, const _InicioSimulado(), repo, cargarEvento: false);

      expect(find.byKey(const Key('evento_acceso_card')), findsOneWidget);
      expect(find.text('Mis tickets · 3er Aniversario Arequipa Go'), findsOneWidget);
      expect(find.text('Revisa tu compra y tu código'), findsOneWidget);

      await tester.tap(find.byKey(const Key('evento_acceso_card')));
      await tester.pumpAndSettle();

      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.text('Código: $codigoCompra'), findsOneWidget); // el código que muestra en la puerta
      expect(find.byKey(const Key('evento_comprar_tickets')), findsNothing); // sin evento activo no se ofrece comprar
    });

    testWidgets('sin evento activo y con una compra pendiente también aparece (para terminar de subir la captura)', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(null)]
        ..misCompras = Either.right([compra()]);
      await _abrir(tester, const _InicioSimulado(), repo, cargarEvento: false);

      expect(find.byKey(const Key('evento_acceso_card')), findsOneWidget);
    });

    testWidgets('sin evento activo y con compras solo rechazadas o anuladas no se ve nada', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(null)]
        ..misCompras = Either.right([
          compra(id: 1, estado: 'rechazado', motivo: 'Monto incorrecto', puedeCancelar: false, puedeSubir: false),
          compra(id: 2, estado: 'anulado', puedeCancelar: false, puedeSubir: false),
        ]);
      await _abrir(tester, const _InicioSimulado(), repo, cargarEvento: false);

      expect(find.byKey(const Key('evento_acceso_card')), findsNothing);
    });

    testWidgets('con evento activo la tarjeta ofrece comprar aunque ya haya compras', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(max: 4, comprados: 2))]
        ..misCompras = Either.right([compra(cantidad: 2)]);
      await _abrir(tester, const _InicioSimulado(), repo, cargarEvento: false);

      expect(find.text('3er Aniversario Arequipa Go'), findsOneWidget); // sin el prefijo «Mis tickets ·»
      expect(find.text('Compra tus tickets o revisa tu compra'), findsOneWidget);
    });
  });

  group('aviso al entrar', () {
    Future<void> abrirAviso(WidgetTester tester, FakeEventoRepository repo) async {
      await _abrir(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => EventoGate.checkOnDashboard(context),
                child: const Text('entrar'),
              ),
            ),
          ),
        ),
        repo,
        cargarEvento: false,
      );
    }

    testWidgets('con evento activo muestra el aviso; «Ahora no» lo cierra sin abrir nada', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0, conBanner: false))];
      await abrirAviso(tester, repo);

      await tester.tap(find.text('entrar'));
      await tester.pumpAndSettle();
      expect(find.text('3er Aniversario Arequipa Go'), findsOneWidget);
      expect(find.textContaining('Sábado 14 de noviembre'), findsOneWidget);

      await tester.tap(find.byKey(const Key('evento_banner_ahora_no')));
      await tester.pumpAndSettle();

      expect(find.text('3er Aniversario Arequipa Go'), findsNothing);
      expect(find.byKey(const Key('evento_terminos_texto')), findsNothing);
    });

    testWidgets('solo sale una vez por sesión y por evento', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0, conBanner: false))];
      await abrirAviso(tester, repo);

      await tester.tap(find.text('entrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_banner_ahora_no')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('entrar')); // vuelve a entrar al inicio en la misma sesión
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_banner_ahora_no')), findsNothing);
    });

    testWidgets('quien ya llegó a su tope de tickets no recibe el aviso de entrada', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 4, conBanner: false))];
      await abrirAviso(tester, repo);

      await tester.tap(find.text('entrar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_banner_ahora_no')), findsNothing);
      // Y no se gastó el aviso de la sesión: la regla es de «tope», no de «ya lo vio».
      expect(EventoGate.debeMostrar(evento(max: 4, comprados: 1, conBanner: false), 601), isTrue);
    });

    testWidgets('si todavía le queda al menos un ticket sí recibe el aviso', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(max: 4, comprados: 3, conBanner: false))];
      await abrirAviso(tester, repo);

      await tester.tap(find.text('entrar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_banner_ahora_no')), findsOneWidget);
    });

    testWidgets('un evento distinto vuelve a avisar', (tester) async {
      final repo = FakeEventoRepository()
        ..activo = [activo(evento(comprados: 0, conBanner: false, id: 7)), activo(evento(comprados: 0, conBanner: false, id: 8))];
      await abrirAviso(tester, repo);

      await tester.tap(find.text('entrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_banner_ahora_no')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('entrar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_banner_ahora_no')), findsOneWidget);
    });

    testWidgets('tocar «Comprar tickets» del aviso abre los términos', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0, conBanner: false))];
      await abrirAviso(tester, repo);

      await tester.tap(find.text('entrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('evento_banner_comprar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_terminos_texto')), findsOneWidget);
    });

    testWidgets('con banner de red: tocar el banner abre los términos', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(evento(comprados: 0))]; // con banner_url
      await abrirAviso(tester, repo);

      await tester.tap(find.text('entrar'));
      // El indicador de carga del banner no termina de animar: se avanzan cuadros en vez de «asentar».
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('evento_banner')), findsOneWidget);
      expect(find.text('3er Aniversario Arequipa Go'), findsOneWidget);

      await tester.tap(find.byKey(const Key('evento_banner')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const Key('evento_terminos_texto')), findsOneWidget);
    });

    testWidgets('sin evento activo no avisa', (tester) async {
      final repo = FakeEventoRepository()..activo = [activo(null)];
      await abrirAviso(tester, repo);

      await tester.tap(find.text('entrar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_banner_ahora_no')), findsNothing);
    });

    testWidgets('un error de red se traga en silencio: no avisa ni lanza', (tester) async {
      final repo = FakeEventoRepository()..activo = [Either.left(const ServerFailure('sin conexión'))];
      await abrirAviso(tester, repo);

      await tester.tap(find.text('entrar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('evento_banner_ahora_no')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
