class CuotaFinanciamientoEntity {
  final int id;
  final int idFinanciamiento;
  final int numeroCuota;
  final double monto;
  final String fechaVencimiento;
  final String estado;
  final String? fechaPago;
  final int idPago;
  /// true para la cuota 0 de Caja Arequipa (pago inicial)
  final bool esInicial;
  /// Moneda propia de la cuota (1 = soles, 2 = dólares). Solo viene cuando difiere del contrato: una cuota especial por adenda
  /// va en soles dentro de un contrato en dólares. null = la moneda del financiamiento.
  final int? monedaId;

  const CuotaFinanciamientoEntity({
    required this.id,
    required this.idFinanciamiento,
    required this.numeroCuota,
    required this.monto,
    required this.fechaVencimiento,
    required this.estado,
    this.fechaPago,
    required this.idPago,
    this.esInicial = false,
    this.monedaId,
  });

  /// Símbolo con el que se muestra el monto de ESTA cuota: el suyo si tiene moneda propia, si no el del contrato.
  String simboloMoneda(String monedaContrato) {
    switch (monedaId) {
      case 1:
        return 'S/.';
      case 2:
        return '\$';
      default:
        return monedaContrato;
    }
  }

  // Getters útiles
  bool get isPaid => estado.toLowerCase() == 'pagado' || estado.toLowerCase() == 'puntual';
  bool get isPending => estado.toLowerCase() == 'pendiente';
  bool get isOverdue => estado.toLowerCase() == 'vencido' || estado.toLowerCase() == 'retraso';
  
  bool get isLate {
    if (isPaid && fechaPago != null) {
      try {
        final fechaPagoDate = DateTime.parse(fechaPago!);
        final fechaVencimientoDate = DateTime.parse(fechaVencimiento);
        return fechaPagoDate.isAfter(fechaVencimientoDate);
      } catch (e) {
        return false;
      }
    }
    if (isPending) {
      try {
        final fechaVencimientoDate = DateTime.parse(fechaVencimiento);
        return DateTime.now().isAfter(fechaVencimientoDate);
      } catch (e) {
        return false;
      }
    }
    return false;
  }
  
  int get diasVencimiento {
    if (isPaid) return 0;
    
    try {
      final fechaVencimientoDate = DateTime.parse(fechaVencimiento);
      final now = DateTime.now();
      final difference = fechaVencimientoDate.difference(now);
      return difference.inDays;
    } catch (e) {
      return 0;
    }
  }
  
  String get montoFormateado => 'S/ ${monto.toStringAsFixed(2)}';
  
  String get estadoTexto {
    switch (estado.toLowerCase()) {
      case 'pagado':
      case 'puntual':
        return 'Pagado';
      case 'pendiente':
        return 'Pendiente';
      case 'vencido':
      case 'retraso':
        return 'Vencido';
      default:
        return estado;
    }
  }

  CuotaFinanciamientoEntity copyWith({
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
  }) {
    return CuotaFinanciamientoEntity(
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
    );
  }
}
