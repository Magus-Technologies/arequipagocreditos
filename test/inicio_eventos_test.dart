import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/data/models/evento_models.dart';
import 'package:arequipagocreditos/data/models/notification_model.dart';
import 'package:arequipagocreditos/data/models/resumen_crediticio_model.dart';
import 'package:arequipagocreditos/domain/entities/nivel_taller_entity.dart';
import 'package:arequipagocreditos/domain/entities/conductor_entity.dart';
import 'package:arequipagocreditos/presentation/components/header.dart';
import 'package:arequipagocreditos/presentation/components/main_modules.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/evento_provider.dart';
import 'package:arequipagocreditos/presentation/providers/notification_provider.dart';
import 'package:arequipagocreditos/presentation/providers/nivel_taller_provider.dart';
import 'package:arequipagocreditos/presentation/providers/resumen_crediticio_provider.dart';
import 'helpers/evento_fakes.dart';

// «Eventos» en el inicio: ya NO es un botón de la cuadrícula de módulos. Sale como un chip chico en el encabezado, bajo el saludo, y
// solo cuando hay un evento disponible (o tickets que ver). La lista completa sigue en «Más».

class _Usuario extends Fake implements ConductorEntity {
  @override
  int get tipo => 3;
}

class _Auth extends Fake implements AuthProvider {
  @override
  ConductorEntity? get currentUser => _Usuario();
}

// El encabezado también muestra el resumen crediticio, el nivel y las notificaciones: aquí no importan, solo que no pidan nada.
class _Resumen extends Fake implements ResumenCrediticioProvider {
  @override
  ResumenCrediticio? resumen;

  @override
  bool loading = false;

  @override
  String? error;

  @override
  Future<void> fetchResumen(int conductorId, int tipo) async {}
}

class _Nivel extends Fake implements NivelTallerProvider {
  @override
  NivelTallerEntity? get nivel => null;

  @override
  bool get isLoading => false;

  @override
  Future<void> cargarNivel(int clienteConductorId) async {}
}

class _Notificaciones extends Fake implements NotificationProvider {
  @override
  List<NotificationModel> get notifications => const [];

  @override
  int get unreadCount => 0;

  @override
  Future<void> init(String userId, int tipo) async {}

  @override
  Future<void> refreshNotifications() async {}
}

const _conductor = ConductorModel(
  idConductor: 601,
  nombres: 'Rodrigo Perez',
  nroDocumento: '43373493',
  telefono: '987654321',
  direccion: 'Calle 1',
  correo: 'r@correo.pe',
  flag: 1,
  tipo: 3,
  fotoPerfilCambiada: false,
  afiliacionFirmada: false,
);

Future<void> _montar(WidgetTester tester, Widget hijo, {EventoModel? evento}) async {
  // La fuente de prueba dibuja cuadros más anchos que Roboto: los textos largos de las tarjetas «se desbordan» solo en la prueba.
  final original = FlutterError.onError;
  FlutterError.onError = (detalles) {
    if (detalles.exceptionAsString().contains('overflowed')) return;
    original?.call(detalles);
  };
  addTearDown(() => FlutterError.onError = original);

  tester.view.physicalSize = const Size(412, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repo = FakeEventoRepository()..activo = [activo(evento)];
  final provider = EventoProvider(repository: repo, ahora: () => ahoraDePrueba);
  await tester.runAsync(() => provider.cargarActivo(clienteConductorId: 601, nroDocumento: '43373493'));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EventoProvider>.value(value: provider),
        Provider<AuthProvider>.value(value: _Auth()),
        Provider<ResumenCrediticioProvider>.value(value: _Resumen()),
        Provider<NivelTallerProvider>.value(value: _Nivel()),
        Provider<NotificationProvider>.value(value: _Notificaciones()),
      ],
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: hijo))),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  // Los proveedores falsos se dan con `Provider.value` y son ChangeNotifier en la app real: provider lo advierte.
  setUpAll(() => Provider.debugCheckInvalidValueType = null);

  group('cuadrícula de módulos', () {
    testWidgets('ya no trae «Eventos» (ni con un evento disponible); los demás módulos siguen', (tester) async {
      await _montar(tester, const MainModules(), evento: EventoModel.fromJson(eventoJson()));

      expect(find.text('Eventos'), findsNothing);
      expect(find.text('Próximos y realizados'), findsNothing);
      expect(find.text('Beneficios'), findsOneWidget);
      expect(find.text('Mis Documentos'), findsOneWidget);
    });
  });

  group('encabezado del inicio', () {
    testWidgets('con un evento disponible muestra el chip «Eventos» bajo el saludo', (tester) async {
      await _montar(tester, const Header(conductor: _conductor), evento: EventoModel.fromJson(eventoJson()));

      expect(find.byKey(const Key('evento_acceso_chip')), findsOneWidget);
      expect(find.text('Eventos'), findsOneWidget);
      // Bajo el saludo, no al costado: no le quita lugar a los íconos de soporte y notificaciones.
      final saludo = tester.getBottomLeft(find.text('Hola, Rodrigo 👋'));
      final chip = tester.getTopLeft(find.byKey(const Key('evento_acceso_chip')));
      expect(chip.dy, greaterThanOrEqualTo(saludo.dy));
      expect(chip.dx, saludo.dx);
    });

    testWidgets('sin evento disponible no hay chip ni lugar reservado para él', (tester) async {
      await _montar(tester, const Header(conductor: _conductor));

      expect(find.byKey(const Key('evento_acceso_chip')), findsNothing);
      expect(find.text('Eventos'), findsNothing);
      expect(find.text('Hola, Rodrigo 👋'), findsOneWidget);
    });
  });
}
