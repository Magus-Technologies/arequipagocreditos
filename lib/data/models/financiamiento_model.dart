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
  });

   factory FinanciamientoModel.fromJson(Map<String, dynamic> json) {
    return FinanciamientoModel(
      idFinanciamiento: json['idfinanciamiento'],
      idConductor: json['id_conductor'],
      idProducto: json['idproductosv2'],
      idCoti: json['id_coti'] ?? 0,
      codigoAsociado: json['codigo_asociado'] ?? 0,
      grupoFinanciamiento: json['grupo_financiamiento'] ?? '-',
      cantidadProducto: json['cantidad_producto'] ?? '-',
      montoTotal: json['monto_total'] ?? '-',
      cuotaInicial: json['cuota_inicial'] ?? '-',
      cuotas: json['cuotas'] ?? 0,
      estado: json['estado'] ?? '-',
      fechaInicio: json['fecha_inicio'] ?? '-',
      fechaFin: json['fecha_fin'] ?? '-',
      fechaCreacion: json['fecha_creacion'] ?? '-',
      frecuencia: json['frecuencia'] ?? '-',
      secondProduct: json['second_product'] ?? '-',
      moneda: json["moneda"],
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
      );

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
    );
  }
}
