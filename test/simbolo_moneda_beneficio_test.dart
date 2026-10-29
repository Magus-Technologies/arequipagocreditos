import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/core/utils/simbolo_moneda.dart';

/// TK-0414: «Cálculo de Pago» decía «S/» fijo aunque el beneficio estuviera en dólares (el GPS de $ 267.80 salía «S/ 267.80»
/// arriba y «Cuota Inicial a pagar: $ 267.80» abajo). El símbolo sale de la moneda configurada del beneficio.
void main() {
  group('símbolo de moneda de un beneficio', () {
    test('un beneficio en dólares muestra \$', () {
      expect(simboloMonedaBeneficio('\$'), '\$');
    });

    test('soles (en cualquiera de sus formas), vacío o sin dato muestran S/ como siempre', () {
      expect(simboloMonedaBeneficio('S/.'), 'S/');
      expect(simboloMonedaBeneficio('S/'), 'S/');
      expect(simboloMonedaBeneficio('s/.'), 'S/');
      expect(simboloMonedaBeneficio(''), 'S/');
      expect(simboloMonedaBeneficio('   '), 'S/');
      expect(simboloMonedaBeneficio(null), 'S/');
    });

    test('la moneda de la variante elegida manda sobre la del beneficio', () {
      expect(simboloMonedaBeneficio('S/.', monedaDeLaVariante: '\$'), '\$');
      expect(simboloMonedaBeneficio('\$', monedaDeLaVariante: 'S/.'), 'S/');
      expect(simboloMonedaBeneficio('\$', monedaDeLaVariante: ''), '\$');
    });
  });
}
