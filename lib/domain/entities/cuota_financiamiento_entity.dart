/// Descuento semanal de InDrive o Yango que ya se restó de una cuota (TK-0425): el conductor lo ve en el detalle de la cuota.
class DescuentoCuotaEntity {
  /// 'indriver' o 'yango'.
  final String plataforma;

  /// Lo que se restó, en la moneda de la cuota (si la cuota es en dólares, ya convertido).
  final double monto;

  /// El descuento original, en soles.
  final double montoSoles;
  final double? tipoCambio;

  /// Lunes de la semana del descuento y su domingo, como 'yyyy-MM-dd'.
  final String semanaInicio;
  final String semanaFin;

  const DescuentoCuotaEntity({
    required this.plataforma,
    required this.monto,
    required this.montoSoles,
    this.tipoCambio,
    required this.semanaInicio,
    required this.semanaFin,
  });

  factory DescuentoCuotaEntity.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) => double.tryParse((value ?? '0').toString()) ?? 0.0;
    final monto = toDouble(json['monto']);

    return DescuentoCuotaEntity(
      plataforma: (json['plataforma'] ?? '').toString().toLowerCase(),
      monto: monto,
      montoSoles: json['monto_soles'] == null ? monto : toDouble(json['monto_soles']),
      tipoCambio: double.tryParse((json['tipo_cambio'] ?? '').toString()),
      semanaInicio: (json['semana_inicio'] ?? '').toString().split('T')[0],
      semanaFin: (json['semana_fin'] ?? '').toString().split('T')[0],
    );
  }

  Map<String, dynamic> toJson() => {
        'plataforma': plataforma,
        'monto': monto,
        'monto_soles': montoSoles,
        'tipo_cambio': tipoCambio,
        'semana_inicio': semanaInicio,
        'semana_fin': semanaFin,
      };

  String get plataformaTexto {
    switch (plataforma) {
      case 'yango':
        return 'Yango';
      case 'indriver':
        return 'InDrive';
      default:
        return plataforma;
    }
  }

  /// true cuando la cuota es en dólares y el descuento en soles se convirtió: ahí conviene mostrar también los soles.
  bool get fueConvertido => (monto - montoSoles).abs() > 0.005;

  /// «26/10 al 01/11» (día/mes). Si la fecha no se puede leer, se muestra tal cual vino.
  String get semanaTexto {
    String corta(String fecha) {
      final partes = fecha.split('-');
      return partes.length == 3 ? '${partes[2]}/${partes[1]}' : fecha;
    }

    if (semanaInicio.isEmpty) return '';
    return '${corta(semanaInicio)} al ${corta(semanaFin)}';
  }
}

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

  /// Lo que falta pagar de esta cuota sin contar la mora (ya con los descuentos de InDrive/Yango restados). null si el servidor no lo manda.
  final double? montoPendiente;

  /// Descuentos semanales de InDrive/Yango ya aplicados a esta cuota (TK-0425). Vacío si no tiene.
  final List<DescuentoCuotaEntity> descuentos;

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
    this.montoPendiente,
    this.descuentos = const [],
  });

  bool get tieneDescuento => descuentos.isNotEmpty;

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
    double? montoPendiente,
    List<DescuentoCuotaEntity>? descuentos,
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
      montoPendiente: montoPendiente ?? this.montoPendiente,
      descuentos: descuentos ?? this.descuentos,
    );
  }
}
