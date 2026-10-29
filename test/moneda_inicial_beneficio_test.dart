import 'package:arequipagocreditos/core/utils/simbolo_moneda.dart';
import 'package:arequipagocreditos/data/models/beneficio_servicio_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// TK-0414 (Gian, p.11): en «Editar beneficio» la cuota inicial y la cuota pueden estar en monedas distintas (inicial en dólares y
/// cuota en soles). El servidor manda `moneda_inicial` (la de la cuota si no se eligió otra) y el app muestra cada monto con la suya.
void main() {
  Map<String, dynamic> json(Map<String, dynamic> extra) => {'id': 1, 'nombre': 'CREDI YANGO', 'descripcion': '', ...extra};

  group('moneda de la inicial en el beneficio', () {
    test('se lee del beneficio cuando viene', () {
      final b = BeneficioServicioModel.fromJson(json({'moneda': 'S/.', 'moneda_inicial': '\$'}));
      expect(b.moneda, 'S/.');
      expect(b.monedaInicial, '\$');
    });

    test('también cuando viene dentro del detalle de financiamiento', () {
      final b = BeneficioServicioModel.fromJson(json({
        'moneda': 'S/.',
        'detalle_financiamiento': {'moneda': 'S/.', 'moneda_inicial': '\$'},
      }));
      expect(b.monedaInicial, '\$');
    });

    test('sin ese dato (servidor anterior) queda vacía y se usa la moneda de la cuota', () {
      final b = BeneficioServicioModel.fromJson(json({'moneda': '\$'}));
      expect(b.monedaInicial, '');
      final simbolo = simboloMonedaBeneficio(b.monedaInicial.trim().isNotEmpty ? b.monedaInicial : b.moneda);
      expect(simbolo, '\$');
    });
  });

  group('símbolo de la inicial', () {
    String simboloInicial(String moneda, String monedaInicial, {String? variante}) => simboloMonedaBeneficio(
          monedaInicial.trim().isNotEmpty ? monedaInicial : moneda,
          monedaDeLaVariante: variante,
        );

    test('con moneda propia, la inicial sale en esa y la cuota en la suya', () {
      expect(simboloInicial('S/.', '\$'), '\$');
      expect(simboloMonedaBeneficio('S/.'), 'S/');
      expect(simboloInicial('\$', 'S/.'), 'S/');
    });

    test('sin moneda propia, la inicial sigue a la cuota', () {
      expect(simboloInicial('\$', ''), '\$');
      expect(simboloInicial('S/.', '   '), 'S/');
    });

    test('la variante elegida manda sobre el beneficio', () {
      expect(simboloInicial('S/.', '', variante: '\$'), '\$');
      expect(simboloInicial('\$', '\$', variante: 'S/.'), 'S/');
    });
  });
}
