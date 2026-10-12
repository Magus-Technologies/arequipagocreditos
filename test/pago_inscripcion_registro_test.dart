import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/models/conductor_estado_model.dart';
import 'package:arequipagocreditos/data/models/izipay_models.dart';
import 'package:arequipagocreditos/domain/repositories/catalogos_repository.dart';
import 'package:arequipagocreditos/presentation/components/pago_inscripcion_registro.dart';
import 'package:arequipagocreditos/presentation/pages/conductor_estado_page.dart';
import 'package:arequipagocreditos/presentation/pages/conductor_register_success_page.dart';
import 'package:arequipagocreditos/presentation/providers/catalogos_provider.dart';

/// El conductor paga su inscripción ANTES de enviar la solicitud: elige Caja Arequipa (recibe el código al enviar) o QR IziPay
/// (adjunta la captura). La aprobación sigue siendo del asesor aunque el pago ya esté hecho.
const _conCajaEIzipay = InscripcionPagoInfoModel(monto: 100, izipayDisponible: true, qrUrl: 'https://credigo.test/qr.png');
const _soloCaja = InscripcionPagoInfoModel(monto: 100);

Widget _paso({
  InscripcionPagoInfoModel? info = _conCajaEIzipay,
  bool cargando = false,
  String? error,
  String? metodo,
  ValueChanged<String>? onMetodo,
  VoidCallback? onReintentar,
  VoidCallback? onCaptura,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PagoInscripcionRegistro(
            info: info,
            cargando: cargando,
            error: error,
            metodo: metodo,
            captura: null,
            operacionController: TextEditingController(),
            onMetodo: onMetodo ?? (_) {},
            onElegirCaptura: onCaptura ?? () {},
            onReintentar: onReintentar ?? () {},
          ),
        ),
      ),
    );

/// Repositorio que solo sabe contestar el estado de la solicitud (lo único que usa esta pantalla al abrir).
class _RepoEstado extends Fake implements CatalogosRepository {
  _RepoEstado(this.estado);
  final ConductorEstadoModel estado;

  @override
  Future<Either<Failure, ConductorEstadoModel>> getConductorEstado(int conductorId) async => Either.right(estado);
}

void main() {
  group('monto e IziPay del paso de pago', () {
    test('se leen de la respuesta del servidor', () {
      final info = InscripcionPagoInfoModel.fromJson({
        'monto': '50.00',
        'caja_arequipa': {'disponible': true},
        'izipay': {'disponible': true, 'qr_url': 'https://credigo.test/qr.png'},
      });

      expect(info.monto, 50.0);
      expect(info.cajaDisponible, isTrue);
      expect(info.izipayDisponible, isTrue);
      expect(info.qrUrl, 'https://credigo.test/qr.png');
    });

    test('sin QR cargado IziPay no se ofrece', () {
      final info = InscripcionPagoInfoModel.fromJson({
        'monto': 100,
        'caja_arequipa': {'disponible': true},
        'izipay': {'disponible': false, 'qr_url': null},
      });

      expect(info.izipayDisponible, isFalse);
      expect(info.qrUrl, isNull);
    });
  });

  group('paso de pago', () {
    testWidgets('muestra el monto y los dos métodos', (tester) async {
      await tester.pumpWidget(_paso());

      expect(find.text('S/ 100.00'), findsOneWidget);
      expect(find.byKey(const Key('pago_metodo_caja')), findsOneWidget);
      expect(find.byKey(const Key('pago_metodo_izipay')), findsOneWidget);
    });

    testWidgets('sin IziPay solo se ofrece Caja Arequipa', (tester) async {
      await tester.pumpWidget(_paso(info: _soloCaja));

      expect(find.byKey(const Key('pago_metodo_caja')), findsOneWidget);
      expect(find.byKey(const Key('pago_metodo_izipay')), findsNothing);
    });

    testWidgets('elegir un método avisa cuál', (tester) async {
      final elegidos = <String>[];
      await tester.pumpWidget(_paso(onMetodo: elegidos.add));

      await tester.tap(find.byKey(const Key('pago_metodo_caja')));
      await tester.tap(find.byKey(const Key('pago_metodo_izipay')));

      expect(elegidos, [PagoInscripcionRegistro.metodoCaja, PagoInscripcionRegistro.metodoIzipay]);
    });

    testWidgets('con Caja avisa que el código vale 24 horas y no pide captura', (tester) async {
      await tester.pumpWidget(_paso(metodo: PagoInscripcionRegistro.metodoCaja));

      expect(find.byKey(const Key('pago_nota_caja')), findsOneWidget);
      expect(find.textContaining('24 horas'), findsWidgets);
      expect(find.byKey(const Key('pago_captura')), findsNothing);
    });

    testWidgets('con IziPay pide la captura del pago y el número de operación es opcional', (tester) async {
      var capturas = 0;
      await tester.pumpWidget(_paso(metodo: PagoInscripcionRegistro.metodoIzipay, onCaptura: () => capturas++));
      await tester.pump();

      expect(find.byKey(const Key('pago_izipay')), findsOneWidget);
      expect(find.text('Adjuntar captura del pago'), findsOneWidget);
      expect(find.textContaining('Número de operación (opcional)'), findsOneWidget);
      expect(find.textContaining('S/ 100.00'), findsWidgets);

      await tester.ensureVisible(find.byKey(const Key('pago_captura')));
      await tester.tap(find.byKey(const Key('pago_captura')));
      expect(capturas, 1);
    });

    testWidgets('una inscripción sin costo no pide pagar', (tester) async {
      await tester.pumpWidget(_paso(info: const InscripcionPagoInfoModel(monto: 0)));

      expect(find.byKey(const Key('pago_sin_costo')), findsOneWidget);
      expect(find.byKey(const Key('pago_metodo_caja')), findsNothing);
    });

    testWidgets('mientras calcula el monto muestra un indicador', (tester) async {
      await tester.pumpWidget(_paso(info: null, cargando: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('pago_metodo_caja')), findsNothing);
    });

    testWidgets('si no pudo calcular el monto ofrece reintentar', (tester) async {
      var reintentos = 0;
      await tester.pumpWidget(_paso(info: null, error: 'Sin conexión', onReintentar: () => reintentos++));

      expect(find.text('Sin conexión'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      expect(reintentos, 1);
    });
  });

  group('pantalla «se envió tu solicitud»', () {
    Future<void> pintar(WidgetTester tester, {Map<String, dynamic>? inscripcion}) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: ConductorRegisterSuccessPage(conductorId: 7, inscripcion: inscripcion)));
      await tester.pump();
    }

    testWidgets('con Caja Arequipa muestra el código de pago y cuánto vale', (tester) async {
      await pintar(tester, inscripcion: {
        'metodo': 'caja_arequipa',
        'monto': 100,
        'orden_pago': {'codigo': '48213', 'fecha_expiracion': '2026-10-11T10:00:00-05:00'},
        'captura_izipay': null,
      });

      expect(find.text('48213'), findsOneWidget);
      expect(find.textContaining('Vale 24 horas'), findsOneWidget);
      expect(find.text('En revisión'), findsOneWidget);
    });

    testWidgets('con IziPay avisa que la captura quedó recibida', (tester) async {
      await pintar(tester, inscripcion: {
        'metodo': 'izipay',
        'monto': 100,
        'orden_pago': null,
        'captura_izipay': {'estado': 'pendiente'},
      });

      expect(find.textContaining('Captura recibida'), findsOneWidget);
      expect(find.byKey(const Key('exito_codigo_caja')), findsNothing);
    });

    testWidgets('sin pago al registrarse queda como siempre', (tester) async {
      await pintar(tester);

      expect(find.byKey(const Key('exito_pago')), findsNothing);
      expect(find.text('En revisión'), findsOneWidget);
    });
  });

  group('pantalla de estado de la solicitud', () {
    Future<void> abrir(WidgetTester tester, Map<String, dynamic> json) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final provider = CatalogosProvider(catalogosRepository: _RepoEstado(ConductorEstadoModel.fromJson(json)));
      await tester.pumpWidget(
        ChangeNotifierProvider<CatalogosProvider>.value(
          value: provider,
          child: const MaterialApp(home: ConductorEstadoPage(conductorId: 7)),
        ),
      );
      await tester.pumpAndSettle();
    }

    Map<String, dynamic> base(String estado, {Map<String, dynamic>? extra}) => {
          'id': 7,
          'nro_documento': '00445566',
          'estado_aprobacion': estado,
          ...?extra,
        };

    testWidgets('en revisión con el código de Caja todavía sin pagar lo muestra', (tester) async {
      await abrir(tester, base('pendiente', extra: {
        'orden_pago': {'codigo': '48213', 'estado': 'pendiente', 'monto_total': 100},
        'inscripcion_pagada': false,
      }));

      expect(find.text('Tu solicitud está\nen revisión'), findsOneWidget);
      expect(find.text('48213'), findsOneWidget);
      expect(find.text('Aún no registramos tu pago.'), findsOneWidget);
    });

    testWidgets('en revisión con el pago ya hecho lo dice', (tester) async {
      await abrir(tester, base('pendiente', extra: {'inscripcion_pagada': true}));

      expect(find.byKey(const Key('estado_pago_pagado')), findsOneWidget);
    });

    testWidgets('en revisión con la captura de IziPay avisa que se valida junto con la solicitud', (tester) async {
      await abrir(tester, base('pendiente', extra: {
        'pago_inscripcion': {
          'tipo_pago': 'contado',
          'monto_total': 100,
          'estado': 'activo',
          'cuotas': [],
          'captura_izipay': {'estado': 'pendiente'},
        },
      }));

      expect(find.byKey(const Key('estado_captura')), findsOneWidget);
    });

    testWidgets('una solicitud anterior, sin pago al registrarse, queda como siempre', (tester) async {
      await abrir(tester, base('pendiente'));

      expect(find.text('Tu solicitud está\nen revisión'), findsOneWidget);
      expect(find.byKey(const Key('estado_pago_pagado')), findsNothing);
      expect(find.byKey(const Key('estado_codigo_caja')), findsNothing);
    });

    testWidgets('aprobada y ya pagada: no se le vuelven a ofrecer los métodos de pago', (tester) async {
      await abrir(tester, base('aprobado', extra: {'inscripcion_pagada': true}));

      expect(find.byKey(const Key('estado_aprobado_pagado')), findsOneWidget);
      expect(find.text('Selecciona tu método de pago'), findsNothing);
    });

    testWidgets('aprobada sin haber pagado sigue ofreciendo los métodos de pago', (tester) async {
      await abrir(tester, base('aprobado', extra: {'inscripcion_pagada': false}));

      expect(find.text('Selecciona tu método de pago'), findsOneWidget);
      expect(find.byKey(const Key('estado_aprobado_pagado')), findsNothing);
    });
  });
}
