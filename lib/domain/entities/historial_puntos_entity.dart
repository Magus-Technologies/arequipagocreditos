class HistorialPuntosEntity {
  final int? id;
  final int? puntajeAnterior;
  final int? puntajeNuevo;
  final int puntosPerdidos;
  final String motivo;
  final DateTime fechaReferencia;
  final int? numeroCuota;
  final String? montoCuota;
  final DateTime? fechaVencimiento;
  final DateTime? fechaPago;
  final int? idFinanciamiento;
  final String? nombreProducto;
  final String estadoCuota;
  final String origen;

  const HistorialPuntosEntity({
    this.id,
    this.puntajeAnterior,
    this.puntajeNuevo,
    required this.puntosPerdidos,
    required this.motivo,
    required this.fechaReferencia,
    this.numeroCuota,
    this.montoCuota,
    this.fechaVencimiento,
    this.fechaPago,
    this.idFinanciamiento,
    this.nombreProducto,
    required this.estadoCuota,
    required this.origen,
  });

  // Getters útiles
  String get tipo {
    switch (estadoCuota.toLowerCase()) {
      case 'puntual':
        return 'suma';
      case 'retraso':
        return 'resta';
      case 'pendiente':
        return 'neutro';
      default:
        if (puntosPerdidos > 0) return 'resta';
        if (estadoCuota.contains('puntual') || estadoCuota.contains('tiempo')) return 'suma';
        return 'neutro';
    }
  }

  String get descripcion {
    if (numeroCuota != null && nombreProducto != null) {
      String estado = '';
      switch (estadoCuota) {
        case 'puntual':
          estado = 'pagada a tiempo';
          break;
        case 'retraso':
          estado = 'pagada con retraso';
          break;
        case 'pendiente':
          estado = 'pendiente';
          break;
        default:
          estado = estadoCuota;
      }
      return 'Cuota #$numeroCuota $estado - $nombreProducto';
    }
    return motivo.isNotEmpty ? motivo : 'Movimiento de puntaje';
  }

  int get puntos {
    switch (estadoCuota.toLowerCase()) {
      case 'puntual':
        return 5; // Suma puntos por pago puntual
      case 'retraso':
        return puntosPerdidos > 0 ? -puntosPerdidos : -5; // Resta puntos por retraso
      case 'pendiente':
        return 0; // Neutro para cuotas pendientes
      default:
        if (puntosPerdidos > 0) return -puntosPerdidos;
        if (estadoCuota.contains('puntual') || estadoCuota.contains('tiempo')) return 5;
        return 0;
    }
  }

  DateTime get fecha => fechaReferencia;

  bool get isSuma => tipo == 'suma';
  bool get isResta => tipo == 'resta';
  bool get isNeutro => tipo == 'neutro';

  String get montoFormateado {
    if (montoCuota == null) return '';
    try {
      final double monto = double.parse(montoCuota!.replaceAll(',', ''));
      return 'S/ ${monto.toStringAsFixed(2)}';
    } catch (e) {
      return 'S/ $montoCuota';
    }
  }
}
