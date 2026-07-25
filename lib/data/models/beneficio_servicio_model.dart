import '../../domain/entities/beneficio_servicio_entity.dart';

class ClienteAlertasModel extends ClienteAlertasEntity {
  const ClienteAlertasModel({
    required super.puedeSolicitar,
    super.motivoPrincipal,
    super.motivos,
    super.puntajeActual,
    super.tienePuntajeBajo,
    super.estaEnIncobrables,
    super.estaDesvinculado,
    super.tienePendientes,
    super.cantidadPendientes,
    super.documentosCompletos,
    super.documentosFaltantes,
    super.yaAdquirioServicio,
  });

  factory ClienteAlertasModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value is List) return value.map((e) => e.toString()).toList();
      return const [];
    }

    return ClienteAlertasModel(
      puedeSolicitar: json['puede_solicitar'] == true,
      motivoPrincipal: json['motivo_principal']?.toString(),
      motivos: parseStringList(json['motivos']),
      puntajeActual: json['puntaje_actual'] is int ? json['puntaje_actual'] : null,
      tienePuntajeBajo: json['tiene_puntaje_bajo'] == true,
      estaEnIncobrables: json['esta_en_incobrables'] == true,
      estaDesvinculado: json['esta_desvinculado'] == true,
      tienePendientes: json['tiene_pendientes'] == true,
      cantidadPendientes: json['cantidad_pendientes'] is int ? json['cantidad_pendientes'] : 0,
      documentosCompletos: json['documentos_completos'] == true,
      documentosFaltantes: parseStringList(json['documentos_faltantes']),
      yaAdquirioServicio: json['ya_adquirio_servicio'] == true,
    );
  }
}

class VarianteModel extends VarianteEntity {
  const VarianteModel({
    required super.varianteId,
    required super.nombre,
    super.familia,
    super.certificado,
    super.montoTotal,
    super.montoCuota,
    super.cantidadCuotas,
    super.cuotaInicial,
    super.porcentajeInicial,
    super.montoInscripcion,
    super.tasaInteres,
    super.frecuenciaPagoId,
    super.monedaId,
    super.monedaSimbolo,
    super.monedaInicialId,
    super.monedaInicialSimbolo,
  });

  factory VarianteModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int toInt(dynamic value, [int fallback = 0]) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? fallback;
    }

    return VarianteModel(
      varianteId: toInt(json['variante_id']),
      nombre: json['nombre']?.toString() ?? '',
      familia: json['familia']?.toString(),
      certificado: toDouble(json['certificado']),
      montoTotal: toDouble(json['monto_total']),
      montoCuota: toDouble(json['monto_cuota']),
      cantidadCuotas: toInt(json['cantidad_cuotas']),
      cuotaInicial: toDouble(json['cuota_inicial']),
      porcentajeInicial: json['porcentaje_inicial'] != null
          ? toDouble(json['porcentaje_inicial'])
          : null,
      montoInscripcion: toDouble(json['monto_inscripcion']),
      tasaInteres: toDouble(json['tasa_interes']),
      frecuenciaPagoId: json['frecuencia_pago_id'] != null
          ? toInt(json['frecuencia_pago_id'])
          : null,
      monedaId: toInt(json['moneda_id'], 1),
      monedaSimbolo: json['moneda_simbolo']?.toString() ?? 'S/.',
      monedaInicialId: toInt(json['moneda_inicial_id'], 1),
      monedaInicialSimbolo: json['moneda_inicial_simbolo']?.toString() ?? 'S/.',
    );
  }
}

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
    super.metodosPago,
    super.visiblePara,
    super.clienteAlertas,
    super.notaImportante,
    super.variantesDisponibles,
  });

  factory BeneficioServicioModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final detalleRaw = json['detalle_financiamiento'] as Map<String, dynamic>?;
    final fijoRaw = detalleRaw?['fijo'] as Map<String, dynamic>?;
    final porcentualRaw = detalleRaw?['porcentual'] as Map<String, dynamic>?;

    // New endpoint: read flat fields from detalle sub-blocks; fallback to root for legacy
    final cuotaInicial = parseDouble(fijoRaw?['cuota_inicial'] ?? json['cuota_inicial']);
    final cuotaMensual = parseDouble(fijoRaw?['cuota_mensual'] ?? json['cuota_mensual']);
    final cantidadCuotas = (fijoRaw?['cantidad_cuotas'] ?? json['cantidad_cuotas'] ?? 0) as int;
    final precioServicio = parseDouble(porcentualRaw?['precio_servicio'] ?? json['precio_servicio']);
    final moneda = (detalleRaw?['moneda'] ?? json['moneda'] ?? 'S/.') as String;
    final frecuenciaPago = (detalleRaw?['frecuencia_pago_default'] ?? detalleRaw?['frecuencia_pago'] ?? json['frecuencia_pago']) as String?;
    final metodosPagoRaw = detalleRaw?['metodos_pago'] ?? json['metodos_pago'];
    final visibleParaRaw = detalleRaw?['visible_para'] ?? json['visible_para'];
    final modoCalculo = (json['modo_calculo'] ?? detalleRaw?['modo_calculo'] ?? 'fijo') as String;

    return BeneficioServicioModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      tallerId: json['taller_id'] ?? 0,
      precioServicio: precioServicio,
      cuotaInicialTipo: json['cuota_inicial_tipo'] ?? detalleRaw?['cuota_inicial_tipo'] ?? 0,
      cuotaInicialPorcentaje: parseDouble(json['cuota_inicial_porcentaje'] ?? detalleRaw?['cuota_inicial_porcentaje']),
      tipoPago: json['tipo_pago'] ?? detalleRaw?['tipo_pago'] ?? 0,
      grupoFinanciamientoId: json['grupo_financiamiento_id'] ?? json['plan_financiamiento_id'],
      detalleFinanciamiento: detalleRaw != null
          ? DetalleFinanciamientoModel.fromJson(detalleRaw)
          : null,
      modoCalculo: modoCalculo,
      permiteMontoLibre: json['permite_monto_libre'] ?? detalleRaw?['permite_monto_libre'] ?? false,
      porcentajeInicialDefault: parseDouble(
        json['porcentaje_inicial_default'] ?? json['porcentaje_inicial'] ??
        detalleRaw?['porcentaje_inicial_default'] ?? detalleRaw?['porcentaje_inicial'],
      ),
      minCuotas: json['min_cuotas'] ?? detalleRaw?['min_cuotas'] ?? 0,
      maxCuotas: json['max_cuotas'] ?? detalleRaw?['max_cuotas'] ?? 0,
      imagen: json['imagen'],
      cuotaInicial: cuotaInicial,
      cantidadCuotas: cantidadCuotas,
      cuotaMensual: cuotaMensual,
      moneda: moneda,
      frecuenciaPago: frecuenciaPago,
      disponible: json['disponible'] == true,
      metodosPago: _parseMetodosPago(metodosPagoRaw),
      visiblePara: _parseVisiblePara(visibleParaRaw),
      clienteAlertas: json['cliente_alertas'] != null
          ? ClienteAlertasModel.fromJson(json['cliente_alertas'] as Map<String, dynamic>)
          : null,
      notaImportante: json['nota_importante']?.toString(),
      variantesDisponibles: _parseVariantes(json['variantes_disponibles']),
    );
  }

  static List<VarianteEntity> _parseVariantes(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => VarianteModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<String>? _parseVisiblePara(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    return null;
  }

  static List<String> _parseMetodosPago(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value.map((e) => e.toString()).toList();
    }
    return const ['CAJA_AREQUIPA'];
  }
}

class ContratoDetalleModel extends ContratoDetalleEntity {
  const ContratoDetalleModel({
    required super.disponible,
    super.templateId,
    super.nombre,
    super.url,
  });

  factory ContratoDetalleModel.fromJson(Map<String, dynamic> json) {
    return ContratoDetalleModel(
      disponible: json['disponible'] == true,
      templateId: json['template_id'] is int ? json['template_id'] as int : null,
      nombre: json['nombre']?.toString(),
      url: json['url']?.toString(),
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
    super.metodosPago,
    super.porcentajeInicialMin,
    super.porcentajeInicialMax,
    super.montoProducto,
    super.aprobacionAutomatica,
    super.requiereDobleValidacion,
    super.permitirUnaSolaAprobacion,
    super.contratoDisponible,
    super.contrato,
  });

  factory DetalleFinanciamientoModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    List<String> parseMetodos(dynamic value) {
      if (value is List && value.isNotEmpty) {
        return value.map((e) => e.toString()).toList();
      }
      return const ['CAJA_AREQUIPA'];
    }

    final porcentajeDefault = parseDouble(json['porcentaje_inicial_default'] ?? json['porcentaje_inicial']);

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
      frecuenciaPago: json['frecuencia_pago_default'] ?? json['frecuencia_pago'] ?? '',
      frecuenciasDisponibles: (json['frecuencias_disponibles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      moneda: json['moneda'] ?? 'S/.',
      modoCalculo: json['modo_calculo'] ?? 'fijo',
      porcentajeInicialDefault: porcentajeDefault,
      metodosPago: parseMetodos(json['metodos_pago']),
      porcentajeInicialMin: parseDouble(json['porcentaje_inicial_min'] ?? json['porcentaje_inicial_default'] ?? json['porcentaje_inicial']),
      porcentajeInicialMax: parseDouble(json['porcentaje_inicial_max'] ?? json['porcentaje_inicial_default'] ?? json['porcentaje_inicial']),
      montoProducto: parseNullableDouble(json['tope_maximo'] ?? json['monto_producto']),
      aprobacionAutomatica: json['aprobacion_automatica'] != false,
      requiereDobleValidacion: json['requiere_doble_validacion'] == true,
      permitirUnaSolaAprobacion: json['permitir_una_sola_aprobacion'] == true,
      contratoDisponible: json['contrato_disponible'] == true,
      contrato: json['contrato'] is Map<String, dynamic>
          ? ContratoDetalleModel.fromJson(json['contrato'] as Map<String, dynamic>)
          : null,
    );
  }
}
