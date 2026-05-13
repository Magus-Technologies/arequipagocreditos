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
    super.modoCalculo,
    super.permiteMontoLibre,
    super.porcentajeInicialDefault,
    super.minCuotas,
    super.maxCuotas,
    super.imagen,
    super.cuotaInicial,
    super.cantidadCuotas,
    super.cuotaMensual,
    super.moneda,
    super.frecuenciaPago,
    super.disponible,
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
          ? (() {
              final detalleJson = Map<String, dynamic>.from(
                json['detalle_financiamiento'] as Map,
              );
              // Merge root-level fields if missing inside detalle_financiamiento
              if (detalleJson['frecuencias_disponibles'] == null) {
                detalleJson['frecuencias_disponibles'] =
                    json['frecuencias_disponibles'];
              }
              if (detalleJson['frecuencia_pago'] == null ||
                  (detalleJson['frecuencia_pago'] as String?)?.isEmpty == true) {
                detalleJson['frecuencia_pago'] = json['frecuencia_pago'];
              }
              return DetalleFinanciamientoModel.fromJson(detalleJson);
            })()
          : null,
      modoCalculo: json['modo_calculo'] ?? 'fijo',
      permiteMontoLibre: json['permite_monto_libre'] ?? false,
      porcentajeInicialDefault: parseDouble(json['porcentaje_inicial_default'] ?? json['porcentaje_inicial']),
      minCuotas: json['min_cuotas'] ?? 0,
      maxCuotas: json['max_cuotas'] ?? 0,
      imagen: json['imagen'],
      cuotaInicial: parseDouble(json['cuota_inicial']),
      cantidadCuotas: json['cantidad_cuotas'] ?? 0,
      cuotaMensual: parseDouble(json['cuota_mensual']),
      moneda: json['moneda'] ?? 'S/.',
      frecuenciaPago: json['frecuencia_pago'],
      disponible: json['disponible'] == true,
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
    required super.frecuenciasDisponibles,
    required super.moneda,
    required super.modoCalculo,
    required super.porcentajeInicialDefault,
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
      minCuotas: json['min_cuotas'] ?? json['cantidad_cuotas'] ?? 0,
      maxCuotas: json['max_cuotas'] ?? json['cantidad_cuotas'] ?? 0,
      frecuenciaPago: json['frecuencia_pago'] ?? '',
      frecuenciasDisponibles: (json['frecuencias_disponibles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      moneda: json['moneda'] ?? 'S/.',
      modoCalculo: json['modo_calculo'] ?? 'fijo',
      porcentajeInicialDefault: parseDouble(json['porcentaje_inicial_default'] ?? json['porcentaje_inicial']),
    );
  }
}
