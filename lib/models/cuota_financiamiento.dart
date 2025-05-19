class CuotaFinanciamiento {
  final int id;
  final int idFinanciamiento;
  final int numeroCuota;
  final double monto;
  final String fechaVencimiento;
  final String estado;
  final String? fechaPago;
  final int idPago;
  CuotaFinanciamiento({
    required this.id,
    required this.idFinanciamiento,
    required this.numeroCuota,
    required this.monto,
    required this.fechaVencimiento,
    required this.estado,
    this.fechaPago,
    required this.idPago,
  });

  factory CuotaFinanciamiento.fromJson(Map<String, dynamic> json) {
    return CuotaFinanciamiento(
      id: json["idcuotas_financiamiento"],
      idFinanciamiento: json["id_financiamiento"],
      numeroCuota: json["numero_cuota"],
      monto: double.parse(json["monto"]),
      fechaVencimiento: json["fecha_vencimiento"],
      estado: json["estado"],
      fechaPago: json["fecha_pago"],
      idPago: json["idPago"],
    );
  }
}
