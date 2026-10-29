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
    super.esInicial,
    super.monedaId,
    super.montoPendiente,
    super.descuentos,
  });

  factory CuotaFinanciamientoModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // TK-0425: descuentos de InDrive/Yango ya restados de esta cuota. Un servidor antiguo no los manda: sin descuentos.
    final descuentosJson = json["descuentos"];
    final descuentos = descuentosJson is List
        ? descuentosJson
            .whereType<Map>()
            .map((d) => DescuentoCuotaEntity.fromJson(Map<String, dynamic>.from(d)))
            .toList()
        : <DescuentoCuotaEntity>[];

    return CuotaFinanciamientoModel(
      id: toInt(json["id"] ?? json["idcuotas_financiamiento"]),
      idFinanciamiento: toInt(json["id_financiamiento"] ?? json["financiamiento_id"]),
      numeroCuota: toInt(json["numero_cuota"]),
      monto: double.tryParse((json["monto_cuota"] ?? json["monto"] ?? "0").toString()) ?? 0.0,
      fechaVencimiento: (json["fecha_vencimiento"] ?? '').toString().split('T')[0],
      estado: json["estado"] ?? '',
      fechaPago: json["fecha_pago"]?.toString(),
      idPago: toInt(json["idPago"] ?? json["id_pago"] ?? json["pago_id"]),
      esInicial: json["es_inicial"] == true || json["es_inicial"] == 1,
      monedaId: int.tryParse((json["moneda_id"] ?? '').toString()),
      montoPendiente: double.tryParse((json["monto_pendiente"] ?? '').toString()),
      descuentos: descuentos,
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
      "es_inicial": esInicial,
      "moneda_id": monedaId,
      "monto_pendiente": montoPendiente,
      "descuentos": descuentos.map((d) => d.toJson()).toList(),
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
        esInicial: esInicial,
        monedaId: monedaId,
        montoPendiente: montoPendiente,
        descuentos: descuentos,
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
    bool? esInicial,
    int? monedaId,
    double? montoPendiente,
    List<DescuentoCuotaEntity>? descuentos,
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
      esInicial: esInicial ?? this.esInicial,
      monedaId: monedaId ?? this.monedaId,
      montoPendiente: montoPendiente ?? this.montoPendiente,
      descuentos: descuentos ?? this.descuentos,
    );
  }
}
