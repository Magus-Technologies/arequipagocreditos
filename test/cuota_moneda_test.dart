import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/data/models/cuota_financiamiento_model.dart';
import 'package:arequipagocreditos/presentation/components/cuota_card.dart';

/// Una cuota especial por adenda va en soles dentro de un contrato en dólares: la tarjeta tiene que mostrar el símbolo de la
/// moneda de ESA cuota (S/.), no el del contrato ($), o el cliente ve "$ 380.00" cuando en realidad debe S/ 380.
Map<String, dynamic> _cuotaJson({Object? monedaId, num monto = 380}) => {
      'id': 15,
      'financiamiento_id': 908,
      'numero_cuota': 15,
      'monto_cuota': monto,
      'fecha_vencimiento': '2026-10-19T00:00:00.000000Z',
      'estado': 'pendiente',
      if (monedaId != null) 'moneda_id': monedaId,
    };

void main() {
  group('símbolo de moneda por cuota', () {
    test('una cuota en soles dentro de un contrato en dólares usa S/.', () {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(monedaId: 1));

      expect(cuota.monedaId, 1);
      expect(cuota.simboloMoneda('\$'), 'S/.');
    });

    test('una cuota sin moneda propia usa la del contrato', () {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson());

      expect(cuota.monedaId, isNull);
      expect(cuota.simboloMoneda('\$'), '\$');
      expect(cuota.simboloMoneda('S/.'), 'S/.');
    });

    test('al terminar la cuota especial vuelve a dólares aunque el contrato diga otra cosa', () {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(monedaId: '2'));

      expect(cuota.simboloMoneda('S/.'), '\$');
    });

    test('la moneda sobrevive a copyWith y a la conversión a entidad', () {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(monedaId: 1));

      expect(cuota.copyWith(estado: 'pagado').monedaId, 1);
      expect(cuota.toEntity().monedaId, 1);
    });
  });

  testWidgets('la tarjeta de una cuota especial muestra S/. 380.00 y no \$ 380.00', (tester) async {
    final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(monedaId: 1));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: CuotaCard(cuota: cuota, moneda: '\$'))),
    ));

    expect(find.text('S/. 380.00'), findsOneWidget);
    expect(find.text('\$ 380.00'), findsNothing);
  });

  testWidgets('la tarjeta de una cuota normal conserva el símbolo del contrato', (tester) async {
    final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(monto: 105));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: CuotaCard(cuota: cuota, moneda: '\$'))),
    ));

    expect(find.text('\$ 105.00'), findsOneWidget);
  });
}
