class IzipayAPagarModel {
  final String tipoPago;
  final double monto;
  final int? cuotaNumero;
  final int? totalCuotas;

  const IzipayAPagarModel({
    required this.tipoPago,
    required this.monto,
    this.cuotaNumero,
    this.totalCuotas,
  });

  factory IzipayAPagarModel.fromJson(Map<String, dynamic> json) {
    return IzipayAPagarModel(
      tipoPago: (json['tipo_pago'] ?? '').toString(),
      monto: double.tryParse((json['monto'] ?? '0').toString()) ?? 0,
      cuotaNumero: int.tryParse((json['cuota_numero'] ?? '').toString()),
      totalCuotas: int.tryParse((json['total_cuotas'] ?? '').toString()),
    );
  }
}

class IzipayCapturaItemModel {
  final int id;
  final int? cuotaInscripcionId;
  final String estado;
  final String? motivoRechazo;
  final String? fechaSubida;

  const IzipayCapturaItemModel({
    required this.id,
    this.cuotaInscripcionId,
    required this.estado,
    this.motivoRechazo,
    this.fechaSubida,
  });

  factory IzipayCapturaItemModel.fromJson(Map<String, dynamic> json) {
    return IzipayCapturaItemModel(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      cuotaInscripcionId: int.tryParse((json['cuota_inscripcion_id'] ?? '').toString()),
      estado: (json['estado'] ?? 'pendiente').toString(),
      motivoRechazo: json['motivo_rechazo']?.toString(),
      fechaSubida: json['fecha_subida']?.toString(),
    );
  }
}

class IzipayInfoModel {
  final String qrUrl;
  final IzipayAPagarModel? aPagar;
  final String? mensaje;
  final List<IzipayCapturaItemModel> capturas;

  const IzipayInfoModel({
    required this.qrUrl,
    this.aPagar,
    this.mensaje,
    required this.capturas,
  });

  factory IzipayInfoModel.fromJson(Map<String, dynamic> json) {
    return IzipayInfoModel(
      qrUrl: (json['qr_url'] ?? '').toString(),
      aPagar: json['a_pagar'] != null
          ? IzipayAPagarModel.fromJson(json['a_pagar'] as Map<String, dynamic>)
          : null,
      mensaje: json['mensaje']?.toString(),
      capturas: (json['capturas'] as List<dynamic>? ?? [])
          .map((c) => IzipayCapturaItemModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
