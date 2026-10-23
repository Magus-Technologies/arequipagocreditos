import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/domain/entities/beneficio_servicio_entity.dart';

/// Un celular con 0 de stock en la ciudad del cliente (HONOR X8C) se podía pedir desde el app: el aviso «Sin stock» era solo
/// informativo. Ahora el botón queda desactivado, pero solo con un 0 CONFIRMADO: sin información de stock (modelo sin unidades
/// cargadas) se deja pedir, como antes.
VarianteEntity _variante(String nombre, {int? stock}) =>
    VarianteEntity(varianteId: 1, nombre: nombre, stockDisponible: stock);

BeneficioServicioEntity _beneficio({List<VarianteEntity> variantes = const [], ProductoBeneficioEntity? producto}) =>
    BeneficioServicioEntity(
      id: 59,
      nombre: 'CREDI GO CELULARES',
      descripcion: '',
      tallerId: 0,
      precioServicio: 0,
      cuotaInicialTipo: 2,
      cuotaInicialPorcentaje: 0,
      tipoPago: 2,
      variantesDisponibles: variantes,
      producto: producto,
    );

void main() {
  group('beneficio sin stock', () {
    test('la opción elegida con 0 de stock no se puede pedir y el motivo dice cuál es', () {
      final honor = _variante('HONOR X8C', stock: 0);
      final beneficio = _beneficio(variantes: [honor]);

      expect(beneficio.motivoSinStock(honor), contains('«HONOR X8C» no tiene stock disponible en tu ciudad'));
    });

    test('con stock, o sin información de stock, se puede pedir', () {
      final conStock = _variante('HONOR X8C', stock: 3);
      final sinInfo = _variante('17,000');
      final beneficio = _beneficio(variantes: [conStock, sinInfo]);

      expect(beneficio.motivoSinStock(conStock), isNull);
      expect(beneficio.motivoSinStock(sinInfo), isNull);
    });

    test('con opciones, mientras no elija una no hay motivo de stock (ya se le pide elegir)', () {
      final beneficio = _beneficio(variantes: [_variante('HONOR X8C', stock: 0)]);

      expect(beneficio.motivoSinStock(null), isNull);
    });

    test('solo cuenta la opción elegida: una opción agotada no bloquea a otra con stock', () {
      final agotada = _variante('HONOR X8C', stock: 0);
      final disponible = _variante('REDMI NOTE 15', stock: 5);
      final beneficio = _beneficio(variantes: [agotada, disponible]);

      expect(beneficio.motivoSinStock(agotada), isNotNull);
      expect(beneficio.motivoSinStock(disponible), isNull);
    });

    test('un beneficio ligado a un producto sin opciones se mira por el stock del producto', () {
      const sinStock = ProductoBeneficioEntity(id: 7, nombre: 'MOTO XYZ', stockDisponible: 0);
      const conStock = ProductoBeneficioEntity(id: 7, nombre: 'MOTO XYZ', stockDisponible: 2, disponible: true);

      expect(_beneficio(producto: sinStock).motivoSinStock(null), contains('«MOTO XYZ»'));
      expect(_beneficio(producto: conStock).motivoSinStock(null), isNull);
      expect(_beneficio().motivoSinStock(null), isNull);
    });
  });
}
