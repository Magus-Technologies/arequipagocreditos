import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/data/models/beneficio_servicio_model.dart';

/// Diseño Credi Ahorro (pág. 25): al elegir el plan, cada certificado muestra "Descuento S/. 50, meta 80 viajes".
/// La API manda `descuento_semanal` y `viajes_requeridos` por variante (null cuando no tiene, p. ej. Yango).
void main() {
  Map<String, dynamic> variante({Object? descuento, Object? viajes}) => {
        'variante_id': 78,
        'nombre': '13,000',
        'monto_cuota': 308,
        'cantidad_cuotas': 215,
        'monto_total': 61920,
        'descuento_semanal': descuento,
        'viajes_requeridos': viajes,
      };

  test('lee el descuento y la meta de viajes del certificado', () {
    final v = VarianteModel.fromJson(variante(descuento: 50, viajes: 80));

    expect(v.descuentoSemanal, 50.0);
    expect(v.viajesRequeridos, 80);
  });

  test('también los acepta como texto (decimales de Laravel llegan como "55.00")', () {
    final v = VarianteModel.fromJson(variante(descuento: '55.00', viajes: '90'));

    expect(v.descuentoSemanal, 55.0);
    expect(v.viajesRequeridos, 90);
  });

  test('sin descuento en la variante no hay nada que mostrar', () {
    final v = VarianteModel.fromJson(variante());

    expect(v.descuentoSemanal, isNull);
    expect(v.viajesRequeridos, isNull);
  });
}
