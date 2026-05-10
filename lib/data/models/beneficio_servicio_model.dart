import '../../domain/entities/beneficio_servicio_entity.dart';

class BeneficioServicioModel extends BeneficioServicioEntity {
  BeneficioServicioModel({
    required super.id,
    required super.nombre,
    required super.descripcion,
    required super.tallerId,
    required super.precioServicio,
    required super.cuotaInicialTipo,
    required super.cuotaInicialPorcentaje,
    required super.tipoPago,
    super.grupoFinanciamientoId,
    super.detalleFinanciamiento,
  });

  factory BeneficioServicioModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return BeneficioServicioModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      tallerId: json['taller_id'] ?? 0,
      precioServicio: parseDouble(json['precio_servicio']),
      cuotaInicialTipo: json['cuota_inicial_tipo'] ?? 0,
      cuotaInicialPorcentaje: parseDouble(json['cuota_inicial_porcentaje']),
      tipoPago: json['tipo_pago'] ?? 0,
      grupoFinanciamientoId: json['grupo_financiamiento_id'] ?? json['plan_financiamiento_id'],
      detalleFinanciamiento: json['detalle_financiamiento'] != null
          ? DetalleFinanciamientoModel.fromJson(json['detalle_financiamiento'])
          : null,
    );
  }
}

class DetalleFinanciamientoModel extends DetalleFinanciamientoEntity {
  DetalleFinanciamientoModel({
    required super.tipoPago,
    required super.precioServicio,
    required super.cuotaInicialTipo,
    required super.cuotaInicialPorcentaje,
    required super.cantidadCuotas,
    required super.montoMaximo,
    required super.porcentajeInicial,
    required super.interes,
    required super.minCuotas,
    required super.maxCuotas,
    required super.frecuenciaPago,
    required super.moneda,
  });

  factory DetalleFinanciamientoModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return DetalleFinanciamientoModel(
      tipoPago: json['tipo_pago'] ?? 0,
      precioServicio: parseDouble(json['precio_servicio']),
      cuotaInicialTipo: json['cuota_inicial_tipo'] ?? 0,
      cuotaInicialPorcentaje: parseDouble(json['cuota_inicial_porcentaje']),
      cantidadCuotas: json['cantidad_cuotas'] ?? 0,
      montoMaximo: parseDouble(json['monto_maximo']),
      porcentajeInicial: parseDouble(json['porcentaje_inicial']),
      interes: parseDouble(json['interes'] ?? json['tasa_interes']),
      minCuotas: json['min_cuotas'] ?? 0,
      maxCuotas: json['max_cuotas'] ?? 0,
      frecuenciaPago: json['frecuencia_pago'] ?? '',
      moneda: json['moneda'] ?? 'S/.',
    );
  }
}
