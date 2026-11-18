import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/models/beneficio_servicio_model.dart';
import 'package:arequipagocreditos/domain/entities/beneficio_entity.dart';
import 'package:arequipagocreditos/domain/entities/beneficio_servicio_entity.dart';
import 'package:arequipagocreditos/domain/repositories/beneficios_comercial_repository.dart';
import 'package:arequipagocreditos/domain/usecases/create_financiamiento_usecase.dart';
import 'package:arequipagocreditos/domain/usecases/get_beneficios_servicios_usecase.dart';
import 'package:arequipagocreditos/domain/usecases/get_documentos_firmados_usecase.dart';
import 'package:arequipagocreditos/presentation/components/beneficio_details_modal.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/financiamiento_servicio_provider.dart';

/// TK-0454 (Gian, 16-nov): al solicitar un celular el app indica AL CONTADO (el precio de venta del producto) y FINANCIADO (el monto
/// financiado, con su inicial y sus cuotas). El contado solo se MUESTRA: los beneficios comerciales se adquieren financiados. El servidor
/// manda `precio_contado` solo en los celulares; en las demás variantes (certificados de InDriver, etc.) todo queda como siempre.
Map<String, dynamic> _variante({Object? precioContado, int id = 51, String nombre = 'REDMI NOTE 15 5G'}) => {
      'variante_id': id,
      'nombre': nombre,
      'certificado': 1218.39,
      'precio_contado': precioContado,
      'monto_total': 1320,
      'monto_cuota': 160.29,
      'cantidad_cuotas': 7,
      'cuota_inicial': 198,
    };

class _Repo extends Fake implements BeneficiosComercialRepository {
  _Repo(this.detalle);
  final BeneficioServicioEntity detalle;

  @override
  Future<Either<Failure, BeneficioServicioEntity>> getBeneficioDetalle({required int beneficioId, int? clienteConductorId}) async =>
      Either.right(detalle);
}

class _SinUsar extends Fake implements GetBeneficiosServiciosUseCase {}

class _SinUsar2 extends Fake implements CreateFinanciamientoUseCase {}

class _SinUsar3 extends Fake implements GetDocumentosFirmadosUseCase {}

class _Auth extends Fake implements AuthProvider {
  @override
  get currentUser => null;
}

BeneficioServicioEntity _detalle(List<VarianteEntity> variantes) => BeneficioServicioEntity(
      id: 59,
      nombre: 'CREDI GO CELULARES',
      descripcion: 'Celulares',
      tallerId: 0,
      precioServicio: 0,
      cuotaInicialTipo: 1,
      cuotaInicialPorcentaje: 0,
      tipoPago: 2,
      variantesDisponibles: variantes,
    );

void main() {
  // AuthProvider es un ChangeNotifier y aquí se da con `Provider.value` (el modal solo lo lee): provider lo advierte.
  setUpAll(() => Provider.debugCheckInvalidValueType = null);

  group('lectura del precio al contado', () {
    test('se lee de la variante, también como texto (los decimales de Laravel llegan como "1218.39")', () {
      expect(VarianteModel.fromJson(_variante(precioContado: 1218.39)).precioContado, 1218.39);
      expect(VarianteModel.fromJson(_variante(precioContado: '1218.39')).precioContado, 1218.39);
    });

    test('sin precio (otras variantes, o un servidor anterior) no hay nada que mostrar', () {
      expect(VarianteModel.fromJson(_variante()).precioContado, isNull);
      expect(VarianteModel.fromJson(_variante(precioContado: 0)).precioContado, isNull);
    });
  });

  group('tarjeta «Elige tu opción» del beneficio', () {
    Future<void> abrir(WidgetTester tester, List<VarianteEntity> variantes) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final provider = FinanciamientoServicioProvider(
        getBeneficiosServiciosUseCase: _SinUsar(),
        createFinanciamientoUseCase: _SinUsar2(),
        getDocumentosFirmadosUseCase: _SinUsar3(),
        beneficiosRepository: _Repo(_detalle(variantes)),
      );
      final beneficio = BeneficioComercialEntity(
        id: 59,
        nombre: 'CREDI GO CELULARES',
        planFinanciamientoId: 1,
        descripcion: 'Celulares',
        cuotaInicial: 0,
        cantidadCuotas: 7,
        cuotaMensual: 0,
        disponible: true,
        fechaCreacion: DateTime(2026, 11, 1),
        fechaActualizacion: DateTime(2026, 11, 1),
        moneda: 'S/.',
        frecuenciaPago: 'mensual',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FinanciamientoServicioProvider>.value(value: provider),
            Provider<AuthProvider>.value(value: _Auth()),
          ],
          child: MaterialApp(home: Scaffold(body: BeneficioDetailsModal(beneficio: beneficio))),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('un celular muestra «Al contado» con el precio de venta y «Financiado» con el total, la inicial y las cuotas', (tester) async {
      await abrir(tester, [VarianteModel.fromJson(_variante(precioContado: 1218.39)), VarianteModel.fromJson(_variante(precioContado: 1040, id: 52, nombre: 'REDMI NOTE 15 PRO 4G'))]);

      // Cada opción trae sus propias líneas (se identifican por el id de la variante).
      String texto(String clave) => tester.widget<Text>(find.byKey(Key(clave))).data!;
      expect(texto('variante_contado_51'), 'Al contado: S/. 1218.39');
      expect(texto('variante_financiado_51'), 'Financiado: S/. 1320.00');
      expect(texto('variante_plan_51'), 'Inicial S/. 198.00 + 7 cuotas de S/. 160.29');
      expect(texto('variante_contado_52'), 'Al contado: S/. 1040.00');
      // El contado es el precio de venta, no el total financiado con la ganancia.
      expect(find.text('Al contado: S/. 1320.00'), findsNothing);
      // «Total:» se reemplaza por «Financiado:»: no se repite el mismo monto con dos nombres.
      expect(find.textContaining('Total:'), findsNothing);
    });

    testWidgets('una variante que no es de celular (certificado de InDriver) se ve como siempre', (tester) async {
      await abrir(tester, [VarianteModel.fromJson(_variante(nombre: '13,000')), VarianteModel.fromJson(_variante(id: 52, nombre: '15,000'))]);

      expect(find.byKey(const Key('variante_contado_51')), findsNothing);
      expect(find.textContaining('Al contado'), findsNothing);
      expect(find.text('7 cuotas de S/. 160.29'), findsNWidgets(2));
      expect(find.text('Total: S/. 1320.00'), findsNWidgets(2));
    });
  });
}
