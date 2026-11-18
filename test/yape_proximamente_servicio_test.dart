import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/domain/entities/beneficio_servicio_entity.dart';
import 'package:arequipagocreditos/domain/repositories/beneficios_comercial_repository.dart';
import 'package:arequipagocreditos/domain/usecases/create_financiamiento_usecase.dart';
import 'package:arequipagocreditos/domain/usecases/get_beneficios_servicios_usecase.dart';
import 'package:arequipagocreditos/domain/usecases/get_documentos_firmados_usecase.dart';
import 'package:arequipagocreditos/presentation/components/yape_widgets.dart';
import 'package:arequipagocreditos/presentation/pages/calculo_financiamiento_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/financiamiento_servicio_provider.dart';

/// «Cálculo de Pago» de un servicio (taller, beneficio): avisa «Yape – Próximamente» junto al método de pago. La compra de servicios
/// todavía NO se cobra con Yape de GMoney (solo la inscripción), así que es solo un aviso: no se puede elegir ni cambia el método.

class _Repo extends Fake implements BeneficiosComercialRepository {}

class _SinUsar extends Fake implements GetBeneficiosServiciosUseCase {}

class _SinUsar2 extends Fake implements CreateFinanciamientoUseCase {}

class _SinUsar3 extends Fake implements GetDocumentosFirmadosUseCase {}

class _Auth extends Fake implements AuthProvider {
  @override
  get currentUser => null;
}

BeneficioServicioEntity _servicio({String moneda = 'S/.', List<String> metodos = const ['CAJA_AREQUIPA']}) => BeneficioServicioEntity(
      id: 7,
      nombre: 'GRATIFICACIÓN GO',
      descripcion: '¡ACTIVA HOY TU GRATIFICACIÓN CON CREDIGO!',
      tallerId: 0,
      precioServicio: 1200,
      cuotaInicialTipo: 1,
      cuotaInicialPorcentaje: 0,
      tipoPago: 2,
      cuotaInicial: 0,
      cantidadCuotas: 30,
      cuotaMensual: 40,
      moneda: moneda,
      metodosPago: metodos,
    );

void main() {
  setUpAll(() => Provider.debugCheckInvalidValueType = null);

  group('cuándo se avisa que Yape viene pronto', () {
    test('en soles y sin Yape propio: sí', () {
      expect(mostrarYapeProximamenteEnServicio(simbolo: 'S/', metodos: const ['CAJA_AREQUIPA']), isTrue);
      expect(mostrarYapeProximamenteEnServicio(simbolo: 'S/.', metodos: const ['CAJA_AREQUIPA', 'EFECTIVO']), isTrue);
    });

    test('en dólares no: Yape solo cobra soles', () {
      expect(mostrarYapeProximamenteEnServicio(simbolo: r'$', metodos: const ['CAJA_AREQUIPA']), isFalse);
      expect(mostrarYapeProximamenteEnServicio(simbolo: 'USD', metodos: const ['CAJA_AREQUIPA']), isFalse);
    });

    test('si el servicio ya trae su Yape (el manual, con número de operación) no se muestra un segundo', () {
      expect(mostrarYapeProximamenteEnServicio(simbolo: 'S/', metodos: const ['CAJA_AREQUIPA', 'YAPE']), isFalse);
      expect(mostrarYapeProximamenteEnServicio(simbolo: 'S/', metodos: const ['yape_manual']), isFalse);
    });
  });

  group('pantalla «Cálculo de Pago»', () {
    Future<void> abrir(WidgetTester tester, BeneficioServicioEntity servicio) async {
      tester.view.physicalSize = const Size(900, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final provider = FinanciamientoServicioProvider(
        getBeneficiosServiciosUseCase: _SinUsar(),
        createFinanciamientoUseCase: _SinUsar2(),
        getDocumentosFirmadosUseCase: _SinUsar3(),
        beneficiosRepository: _Repo(),
      )..selectService(servicio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FinanciamientoServicioProvider>.value(value: provider),
            Provider<AuthProvider>.value(value: _Auth()),
          ],
          child: const MaterialApp(home: CalculoFinanciamientoPage()),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('un servicio en soles muestra «Yape – Próximamente» debajo del método de pago, sin poder elegirlo', (tester) async {
      await abrir(tester, _servicio());

      expect(find.text('Pago por: Caja Arequipa'), findsOneWidget);
      expect(find.byKey(const Key('pago_metodo_yape_proximamente')), findsOneWidget);
      expect(find.byKey(const Key('pago_yape_etiqueta_proximamente')), findsOneWidget);
      expect(find.text('Próximamente'), findsOneWidget);

      // Apagada: no hay nada que tocar dentro de la tarjeta.
      final tarjeta = find.byKey(const Key('pago_metodo_yape_proximamente'));
      expect(find.descendant(of: tarjeta, matching: find.byType(InkWell)), findsNothing);
      expect(find.descendant(of: tarjeta, matching: find.byType(GestureDetector)), findsNothing);
      expect(find.descendant(of: tarjeta, matching: find.byType(RadioListTile)), findsNothing);

      // El método sigue siendo Caja Arequipa y su nota sigue ahí.
      expect(find.textContaining('Realiza el pago en cualquier agente Caja Arequipa'), findsOneWidget);
    });

    testWidgets('un servicio en dólares no lo muestra', (tester) async {
      await abrir(tester, _servicio(moneda: r'$'));

      expect(find.byKey(const Key('pago_metodo_yape_proximamente')), findsNothing);
      expect(find.text('Próximamente'), findsNothing);
    });

    testWidgets('un servicio que ya ofrece su Yape manual no muestra un segundo Yape', (tester) async {
      await abrir(tester, _servicio(metodos: const ['CAJA_AREQUIPA', 'YAPE']));

      expect(find.byKey(const Key('pago_metodo_yape_proximamente')), findsNothing);
      expect(find.text('Próximamente'), findsNothing);
    });
  });
}
