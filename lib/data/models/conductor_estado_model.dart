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

class CuotaInscripcionModel {
  final int numero;
  final double monto;
  final String? fechaVencimiento;
  final String estado;

  const CuotaInscripcionModel({
    required this.numero,
    required this.monto,
    this.fechaVencimiento,
    required this.estado,
  });

  factory CuotaInscripcionModel.fromJson(Map<String, dynamic> json) {
    return CuotaInscripcionModel(
      numero: int.tryParse((json['numero'] ?? '0').toString()) ?? 0,
      monto: double.tryParse((json['monto'] ?? '0').toString()) ?? 0,
      fechaVencimiento: json['fecha_vencimiento']?.toString(),
      estado: (json['estado'] ?? '').toString(),
    );
  }
}

class PagoInscripcionModel {
  final String tipoPago;
  final double montoTotal;
  final String estado;
  final List<CuotaInscripcionModel> cuotas;

  const PagoInscripcionModel({
    required this.tipoPago,
    required this.montoTotal,
    required this.estado,
    required this.cuotas,
  });

  factory PagoInscripcionModel.fromJson(Map<String, dynamic> json) {
    return PagoInscripcionModel(
      tipoPago: (json['tipo_pago'] ?? '').toString(),
      montoTotal: double.tryParse((json['monto_total'] ?? '0').toString()) ?? 0,
      estado: (json['estado'] ?? '').toString(),
      cuotas: (json['cuotas'] as List<dynamic>? ?? [])
          .map((c) => CuotaInscripcionModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ConductorEstadoModel {
  final int id;
  final String estadoAprobacion;
  final String? motivoRechazo;
  final String? modalidadPagoInscripcion;
  final OrdenPagoModel? ordenPago;
  final PagoInscripcionModel? pagoInscripcion;

  const ConductorEstadoModel({
    required this.id,
    required this.estadoAprobacion,
    this.motivoRechazo,
    this.modalidadPagoInscripcion,
    this.ordenPago,
    this.pagoInscripcion,
  });

  factory ConductorEstadoModel.fromJson(Map<String, dynamic> json) {
    return ConductorEstadoModel(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
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
