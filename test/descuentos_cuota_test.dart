import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/data/models/cuota_financiamiento_model.dart';
import 'package:arequipagocreditos/presentation/components/cuota_card.dart';

/// TK-0425: el conductor no veía en el app cuándo se le aplicaba el descuento semanal de InDrive o Yango. El servidor ahora manda, en cada
/// cuota, los descuentos ya restados y lo que queda por pagar; la tarjeta de la cuota los muestra.
Map<String, dynamic> _cuotaJson({
  num monto = 380,
  Object? montoPendiente = 330,
  String estado = 'mora',
  Object? monedaId = 1,
  String? fechaPago,
  Object? descuentos,
}) =>
    {
      'id': 96200,
      'financiamiento_id': 911,
      'numero_cuota': 18,
      'monto_cuota': monto,
      'monto_pendiente': montoPendiente,
      'fecha_vencimiento': '2026-10-28T00:00:00.000000Z',
      'estado': estado,
      if (monedaId != null) 'moneda_id': monedaId,
      if (fechaPago != null) 'fecha_pago': fechaPago,
      if (descuentos != null) 'descuentos': descuentos,
    };

Map<String, dynamic> _indrive({num monto = 50, num montoSoles = 50}) => {
      'plataforma': 'indriver',
      'monto': monto,
      'monto_soles': montoSoles,
      'tipo_cambio': 3.6,
      'semana_inicio': '2026-10-26',
      'semana_fin': '2026-11-01',
      'aplicado_at': '2026-10-28 16:26:22',
    };

Future<void> _mostrar(WidgetTester tester, CuotaFinanciamientoModel cuota, {String moneda = '\$'}) =>
    tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: CuotaCard(cuota: cuota, moneda: moneda))),
    ));

void main() {
  group('lectura de los descuentos de la cuota', () {
    test('trae los descuentos, el saldo y la plataforma con su nombre', () {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(descuentos: [_indrive()]));

      expect(cuota.tieneDescuento, isTrue);
      expect(cuota.montoPendiente, 330.0);
      expect(cuota.descuentos, hasLength(1));
      expect(cuota.descuentos.first.plataformaTexto, 'InDrive');
      expect(cuota.descuentos.first.monto, 50.0);
      expect(cuota.descuentos.first.semanaTexto, '26/10 al 01/11');
    });

    test('el servidor guarda Yango como «django» en la base, pero al app le llega «yango»', () {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(descuentos: [
        {..._indrive(monto: 22.22, montoSoles: 80), 'plataforma': 'yango'},
      ]));

      expect(cuota.descuentos.first.plataformaTexto, 'Yango');
      expect(cuota.descuentos.first.fueConvertido, isTrue);
    });

    test('un servidor antiguo no manda descuentos ni saldo: la cuota queda sin descuentos', () {
      final json = _cuotaJson(montoPendiente: null)..remove('monto_pendiente');
      final cuota = CuotaFinanciamientoModel.fromJson(json);

      expect(cuota.tieneDescuento, isFalse);
      expect(cuota.descuentos, isEmpty);
      expect(cuota.montoPendiente, isNull);
    });

    test('una lista de descuentos vacía o mal formada no rompe la lectura', () {
      expect(CuotaFinanciamientoModel.fromJson(_cuotaJson(descuentos: [])).descuentos, isEmpty);
      expect(CuotaFinanciamientoModel.fromJson(_cuotaJson(descuentos: 'nada')).descuentos, isEmpty);
    });

    test('los descuentos y el saldo sobreviven a copyWith, a toEntity y a toJson', () {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(descuentos: [_indrive()]));

      expect(cuota.copyWith(estado: 'pagado').descuentos, hasLength(1));
      expect(cuota.copyWith(estado: 'pagado').montoPendiente, 330.0);
      expect(cuota.toEntity().descuentos, hasLength(1));
      expect(CuotaFinanciamientoModel.fromJson(cuota.toJson()).descuentos.first.monto, 50.0);
    });
  });

  group('la tarjeta de la cuota', () {
    testWidgets('muestra el descuento de InDrive, su semana y lo que queda por pagar (caso del financiamiento #911)', (tester) async {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(descuentos: [_indrive()]));

      await _mostrar(tester, cuota);

      expect(find.text('S/. 380.00'), findsOneWidget);
      expect(find.text('Descuento InDrive'), findsOneWidget);
      expect(find.text('− S/. 50.00'), findsOneWidget);
      expect(find.text('Semana del 26/10 al 01/11'), findsOneWidget);
      expect(find.text('Saldo por pagar'), findsOneWidget);
      expect(find.text('S/. 330.00'), findsOneWidget);
    });

    testWidgets('un descuento de Yango en una cuota en dólares muestra los dólares y, aparte, los soles con el tipo de cambio', (tester) async {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(
        monto: 100,
        montoPendiente: 77.78,
        monedaId: null,
        estado: 'pendiente',
        descuentos: [
          {..._indrive(monto: 22.22, montoSoles: 80), 'plataforma': 'yango'},
        ],
      ));

      await _mostrar(tester, cuota);

      expect(find.text('Descuento Yango'), findsOneWidget);
      expect(find.text('− \$ 22.22'), findsOneWidget);
      expect(find.text('Semana del 26/10 al 01/11 · S/ 80.00 al tipo de cambio 3.60'), findsOneWidget);
      expect(find.text('\$ 77.78'), findsOneWidget);
    });

    testWidgets('si InDrive y Yango descontaron la misma cuota salen los dos', (tester) async {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(descuentos: [
        _indrive(),
        {..._indrive(monto: 30, montoSoles: 30), 'plataforma': 'yango'},
      ], montoPendiente: 300));

      await _mostrar(tester, cuota);

      expect(find.text('Descuento InDrive'), findsOneWidget);
      expect(find.text('Descuento Yango'), findsOneWidget);
      expect(find.text('Saldo por pagar'), findsOneWidget);
    });

    testWidgets('una cuota ya pagada muestra el descuento que tuvo pero no un saldo por pagar', (tester) async {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(
        estado: 'pagada',
        montoPendiente: 0,
        fechaPago: '2026-10-29 00:00:00',
        descuentos: [_indrive()],
      ));

      await _mostrar(tester, cuota);

      expect(find.text('Pagado'), findsOneWidget);
      expect(find.text('Descuento InDrive'), findsOneWidget);
      expect(find.text('Saldo por pagar'), findsNothing);
    });

    testWidgets('una cuota sin descuentos queda como antes: sin bloque de descuento ni saldo', (tester) async {
      final cuota = CuotaFinanciamientoModel.fromJson(_cuotaJson(monto: 105, montoPendiente: 105, monedaId: null, estado: 'pendiente'));

      await _mostrar(tester, cuota);

      expect(find.text('\$ 105.00'), findsOneWidget);
      expect(find.textContaining('Descuento'), findsNothing);
      expect(find.text('Saldo por pagar'), findsNothing);
    });
  });
}
