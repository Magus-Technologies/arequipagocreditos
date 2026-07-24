class OrdenPagoModel {
  final String codigo;
  final String estado;
  final double montoTotal;

  const OrdenPagoModel({
    required this.codigo,
    required this.estado,
    required this.montoTotal,
  });

  factory OrdenPagoModel.fromJson(Map<String, dynamic> json) {
    return OrdenPagoModel(
      codigo: (json['codigo'] ?? '').toString(),
      estado: (json['estado'] ?? '').toString(),
      montoTotal: double.tryParse((json['monto_total'] ?? '0').toString()) ?? 0,
    );
  }
}

class CapturaIzipayModel {
  final String estado;
  final String? motivoRechazo;
  final String? fechaSubida;

  const CapturaIzipayModel({
    required this.estado,
    this.motivoRechazo,
    this.fechaSubida,
  });

  factory CapturaIzipayModel.fromJson(Map<String, dynamic> json) {
    return CapturaIzipayModel(
      estado: (json['estado'] ?? 'pendiente').toString(),
      motivoRechazo: json['motivo_rechazo']?.toString(),
      fechaSubida: json['fecha_subida']?.toString(),
    );
  }
}

class CuotaInscripcionModel {
  final int numero;
  final double monto;
  final String? fechaVencimiento;
  final String estado;
  final CapturaIzipayModel? capturaIzipay;

  const CuotaInscripcionModel({
    required this.numero,
    required this.monto,
    this.fechaVencimiento,
    required this.estado,
    this.capturaIzipay,
  });

  factory CuotaInscripcionModel.fromJson(Map<String, dynamic> json) {
    return CuotaInscripcionModel(
      numero: int.tryParse((json['numero'] ?? '0').toString()) ?? 0,
      monto: double.tryParse((json['monto'] ?? '0').toString()) ?? 0,
      fechaVencimiento: json['fecha_vencimiento']?.toString(),
      estado: (json['estado'] ?? '').toString(),
      capturaIzipay: json['captura_izipay'] != null
          ? CapturaIzipayModel.fromJson(json['captura_izipay'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PagoInscripcionModel {
  final String tipoPago;
  final double montoTotal;
  final String estado;
  final List<CuotaInscripcionModel> cuotas;
  final CapturaIzipayModel? capturaIzipay;

  const PagoInscripcionModel({
    required this.tipoPago,
    required this.montoTotal,
    required this.estado,
    required this.cuotas,
    this.capturaIzipay,
  });

  factory PagoInscripcionModel.fromJson(Map<String, dynamic> json) {
    return PagoInscripcionModel(
      tipoPago: (json['tipo_pago'] ?? '').toString(),
      montoTotal: double.tryParse((json['monto_total'] ?? '0').toString()) ?? 0,
      estado: (json['estado'] ?? '').toString(),
      cuotas: (json['cuotas'] as List<dynamic>? ?? [])
          .map((c) => CuotaInscripcionModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      capturaIzipay: json['captura_izipay'] != null
          ? CapturaIzipayModel.fromJson(json['captura_izipay'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ConductorEstadoModel {
  final int id;
  final String nroDocumento;
  final String estadoAprobacion;
  final String? motivoRechazo;
  final String? modalidadPagoInscripcion;
  final OrdenPagoModel? ordenPago;
  final PagoInscripcionModel? pagoInscripcion;

  const ConductorEstadoModel({
    required this.id,
    required this.nroDocumento,
    required this.estadoAprobacion,
    this.motivoRechazo,
    this.modalidadPagoInscripcion,
    this.ordenPago,
    this.pagoInscripcion,
  });

  factory ConductorEstadoModel.fromJson(Map<String, dynamic> json) {
    return ConductorEstadoModel(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      nroDocumento: (json['nro_documento'] ?? '').toString(),
      estadoAprobacion: (json['estado_aprobacion'] ?? 'pendiente').toString(),
      motivoRechazo: json['motivo_rechazo']?.toString(),
      modalidadPagoInscripcion: json['modalidad_pago_inscripcion']?.toString(),
      ordenPago: json['orden_pago'] != null
          ? OrdenPagoModel.fromJson(json['orden_pago'] as Map<String, dynamic>)
          : null,
      pagoInscripcion: json['pago_inscripcion'] != null
          ? PagoInscripcionModel.fromJson(json['pago_inscripcion'] as Map<String, dynamic>)
          : null,
    );
  }
}
