import '../../domain/entities/financiamiento_entity.dart';

class FinanciamientoModel extends FinanciamientoEntity {
  const FinanciamientoModel({
    required super.idFinanciamiento,
    required super.idConductor,
    required super.idProducto,
    super.idCoti,
    required super.codigoAsociado,
    required super.grupoFinanciamiento,
    required super.cantidadProducto,
    required super.montoTotal,
    required super.cuotaInicial,
    required super.cuotas,
    required super.estado,
    required super.fechaInicio,
    required super.fechaFin,
    required super.fechaCreacion,
    required super.frecuencia,
    required super.secondProduct,
    required super.moneda,
    super.nombreProducto,
  });

   factory FinanciamientoModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String toStringValue(dynamic value) {
      if (value == null) return '-';
      return value.toString();
    }

    // El API ahora devuelve codigo_asociado como String "000121"
    // Pero la entidad espera un int. Intentamos parsear o devolvemos el id como fallback.
    int parseCodigoAsociado(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        // Quitamos ceros a la izquierda para poder parsear a int
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return FinanciamientoModel(
      idFinanciamiento: toInt(json['idfinanciamiento'] ?? json['id']),
      idConductor: toInt(json['id_conductor'] ?? json['cliente_conductor_id']),
      idProducto: toInt(json['idproductosv2'] ?? json['producto_id']),
      idCoti: json['id_coti'] != null ? toInt(json['id_coti']) : 0,
      codigoAsociado: parseCodigoAsociado(json['codigo_asociado']),
      grupoFinanciamiento: toStringValue(json['grupo_financiamiento'] ?? (json['grupo'] != null ? json['grupo']['nombre'] : null)),
      cantidadProducto: toStringValue(json['cantidad_producto'] ?? json['cantidad_cuotas']), 
      montoTotal: toStringValue(json['monto_total']),
      cuotaInicial: toStringValue(json['cuota_inicial']),
      cuotas: toInt(json['cuotas'] ?? json['cantidad_cuotas']),
      estado: toStringValue(json['estado']),
      fechaInicio: toStringValue(json['fecha_inicio']).split('T')[0],
      fechaFin: toStringValue(json['fecha_fin']).split('T')[0],
      fechaCreacion: toStringValue(json['fecha_creacion'] ?? json['created_at']).split('T')[0],
      frecuencia: json['frecuencia'] != null ? json['frecuencia'].toString() : (json['frecuencia_pago'] != null ? json['frecuencia_pago']['nombre'] : (json['frecuencia_pago_id'] == 1 ? 'Semanal' : 'Mensual')),
      secondProduct: toStringValue(json['second_product']),
      moneda: json['moneda'] != null ? json['moneda'].toString() : (json['producto'] != null ? json['producto']['moneda'] : (json['moneda_id'] == 1 ? 'PEN' : 'S/.')),
      nombreProducto: json['producto'] != null ? toStringValue(json['producto']['nombre']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idfinanciamiento': idFinanciamiento,
      'id_conductor': idConductor,
      'idproductosv2': idProducto,
      'id_coti': idCoti,
      'codigo_asociado': codigoAsociado,
      'grupo_financiamiento': grupoFinanciamiento,
      'cantidad_producto': cantidadProducto,
      'monto_total': montoTotal,
      'cuota_inicial': cuotaInicial,
      'cuotas': cuotas,
      'estado': estado,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'fecha_creacion': fechaCreacion,
      'frecuencia': frecuencia,
      'second_product': secondProduct,
      'moneda': moneda,
      'nombre_producto': nombreProducto,
    };
  }

  FinanciamientoEntity toEntity() => FinanciamientoEntity(
        idFinanciamiento: idFinanciamiento,
        idConductor: idConductor,
        idProducto: idProducto,
        idCoti: idCoti,
        codigoAsociado: codigoAsociado,
        grupoFinanciamiento: grupoFinanciamiento,
        cantidadProducto: cantidadProducto,
        montoTotal: montoTotal,
        cuotaInicial: cuotaInicial,
        cuotas: cuotas,
        estado: estado,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        fechaCreacion: fechaCreacion,
        frecuencia: frecuencia,
        secondProduct: secondProduct,
        moneda: moneda,
        nombreProducto: nombreProducto,
      );
      
  @override
  FinanciamientoModel copyWith({
    int? idFinanciamiento,
    int? idConductor,
    int? idProducto,
    int? idCoti,
    int? codigoAsociado,
    String? grupoFinanciamiento,
    String? cantidadProducto,
    String? montoTotal,
    String? cuotaInicial,
    int? cuotas,
    String? estado,
    String? fechaInicio,
    String? fechaFin,
    String? fechaCreacion,
    String? frecuencia,
    String? secondProduct,
    String? moneda,
    String? nombreProducto,
  }) {
    return FinanciamientoModel(
      idFinanciamiento: idFinanciamiento ?? this.idFinanciamiento,
      idConductor: idConductor ?? this.idConductor,
      idProducto: idProducto ?? this.idProducto,
      idCoti: idCoti ?? this.idCoti,
      codigoAsociado: codigoAsociado ?? this.codigoAsociado,
      grupoFinanciamiento: grupoFinanciamiento ?? this.grupoFinanciamiento,
      cantidadProducto: cantidadProducto ?? this.cantidadProducto,
      montoTotal: montoTotal ?? this.montoTotal,
      cuotaInicial: cuotaInicial ?? this.cuotaInicial,
      cuotas: cuotas ?? this.cuotas,
      estado: estado ?? this.estado,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      frecuencia: frecuencia ?? this.frecuencia,
      secondProduct: secondProduct ?? this.secondProduct,
      moneda: moneda ?? this.moneda,
      nombreProducto: nombreProducto ?? this.nombreProducto,
    );
  }
}
