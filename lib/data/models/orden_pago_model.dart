import '../../domain/entities/orden_pago_entity.dart';

class OrdenPagoModel extends OrdenPagoEntity {
  const OrdenPagoModel({
    required super.id,
    required super.codigo,
    required super.tipoPagoId,
    required super.concepto,
    required super.monto,
    required super.moneda,
    required super.estado,
    required super.pagable,
    required super.esTemporal,
    required super.fechaExpiracion,
    required super.fechaCreacion,
    required super.voucherUrl,
  });

  factory OrdenPagoModel.fromJson(Map<String, dynamic> json) {
    return OrdenPagoModel(
      id: _toInt(json['id']),
      codigo: json['codigo']?.toString() ?? '',
      tipoPagoId: _toInt(json['tipo_pago_id']),
      concepto: json['concepto']?.toString() ?? 'Pago',
      monto: _toDouble(json['monto']),
      moneda: json['moneda']?.toString() ?? 'S/.',
      estado: json['estado']?.toString() ?? 'pendiente',
      pagable: json['pagable'] == true,
      esTemporal: json['es_temporal'] == true,
      // Las fechas llegan en ISO 8601 con offset de Lima (-05:00). Se pasan a
      // local para que el contador use el mismo reloj que ve la persona.
      fechaExpiracion: _toDate(json['fecha_expiracion']),
      fechaCreacion: _toDate(json['fecha_creacion']),
      voucherUrl: json['voucher_url']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    final parsed = DateTime.tryParse(v.toString());
    return parsed?.toLocal();
  }
}

class ListadoOrdenesPagoModel extends ListadoOrdenesPagoEntity {
  const ListadoOrdenesPagoModel({
    required super.ordenes,
    required super.resumen,
  });

  factory ListadoOrdenesPagoModel.fromJson(Map<String, dynamic> json) {
    final lista = (json['ordenes'] as List<dynamic>? ?? [])
        .map((e) => OrdenPagoModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final resumen = json['resumen'] as Map<String, dynamic>? ?? const {};

    return ListadoOrdenesPagoModel(
      ordenes: lista,
      resumen: ResumenOrdenesEntity(
        pagables: OrdenPagoModel._toInt(resumen['pagables']),
        vencidas: OrdenPagoModel._toInt(resumen['vencidas']),
      ),
    );
  }
}
