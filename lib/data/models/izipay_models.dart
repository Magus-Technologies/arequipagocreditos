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

/// Lo que el conductor paga al registrarse y cómo: el monto según su plataforma y departamento, y si IziPay está disponible
/// (con su QR). Caja Arequipa siempre está. Viene de `GET /app/inscripcion/monto`, antes de que exista el registro.
class InscripcionPagoInfoModel {
  final double monto;
  final bool cajaDisponible;
  final bool izipayDisponible;
  final String? qrUrl;

  const InscripcionPagoInfoModel({
    required this.monto,
    this.cajaDisponible = true,
    this.izipayDisponible = false,
    this.qrUrl,
  });

  factory InscripcionPagoInfoModel.fromJson(Map<String, dynamic> json) {
    final caja = json['caja_arequipa'];
    final izipay = json['izipay'];
    return InscripcionPagoInfoModel(
      monto: double.tryParse((json['monto'] ?? '0').toString()) ?? 0,
      cajaDisponible: caja is Map ? caja['disponible'] != false : true,
      izipayDisponible: izipay is Map && izipay['disponible'] == true,
      qrUrl: izipay is Map ? izipay['qr_url']?.toString() : null,
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
