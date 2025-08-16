import '../../domain/entities/cuota_financiamiento_entity.dart';

class CuotaFinanciamientoModel extends CuotaFinanciamientoEntity {
  const CuotaFinanciamientoModel({
    required super.id,
    required super.idFinanciamiento,
    required super.numeroCuota,
    required super.monto,
    required super.fechaVencimiento,
    required super.estado,
    super.fechaPago,
    required super.idPago,
  });

  factory CuotaFinanciamientoModel.fromJson(Map<String, dynamic> json) {
    return CuotaFinanciamientoModel(
      id: json["idcuotas_financiamiento"] ?? 0,
      idFinanciamiento: json["id_financiamiento"] ?? 0,
      numeroCuota: json["numero_cuota"] ?? 0,
      monto: double.tryParse(json["monto"]?.toString() ?? "0") ?? 0.0,
      fechaVencimiento: json["fecha_vencimiento"] ?? '',
      estado: json["estado"] ?? '',
      fechaPago: json["fecha_pago"],
      idPago: json["idPago"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "idcuotas_financiamiento": id,
      "id_financiamiento": idFinanciamiento,
      "numero_cuota": numeroCuota,
      "monto": monto.toString(),
      "fecha_vencimiento": fechaVencimiento,
      "estado": estado,
      "fecha_pago": fechaPago,
      "idPago": idPago,
    };
  }

  CuotaFinanciamientoEntity toEntity() => CuotaFinanciamientoEntity(
        id: id,
        idFinanciamiento: idFinanciamiento,
        numeroCuota: numeroCuota,
        monto: monto,
        fechaVencimiento: fechaVencimiento,
        estado: estado,
        fechaPago: fechaPago,
        idPago: idPago,
      );

  @override
  CuotaFinanciamientoModel copyWith({
    int? id,
    int? idFinanciamiento,
    int? numeroCuota,
    double? monto,
    String? fechaVencimiento,
    String? estado,
    String? fechaPago,
    int? idPago,
  }) {
    return CuotaFinanciamientoModel(
      id: id ?? this.id,
      idFinanciamiento: idFinanciamiento ?? this.idFinanciamiento,
      numeroCuota: numeroCuota ?? this.numeroCuota,
      monto: monto ?? this.monto,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
      fechaPago: fechaPago ?? this.fechaPago,
      idPago: idPago ?? this.idPago,
    );
  }
}
