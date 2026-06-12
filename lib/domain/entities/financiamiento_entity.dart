class FinanciamientoEntity {
  final int idFinanciamiento;
  final int idConductor;
  final int idProducto;
  final int? idCoti;
  final int codigoAsociado;
  final String grupoFinanciamiento;
  final String cantidadProducto;
  final String montoTotal;
  final String cuotaInicial;
  final int cuotas;
  final String estado;
  final String fechaInicio;
  final String fechaFin;
  final String fechaCreacion;
  final String frecuencia;
  final String secondProduct;
  final String moneda;
  final String? nombreProducto;
  // Caja Arequipa: cuota de pago inicial
  final bool tieneCuotaInicial;
  final String? cuotaInicialEstado;
  final double? cuotaInicialMonto;
  final bool firmado;
  final String? contratoUrl;
  final String? boletaInicialUrl;
  final String? firmaUrl;
  final String? firmadoAt;
  final int? aprobado;
  final String? estadoEntrega;
  final String? estadoApp;

  const FinanciamientoEntity({
    required this.idFinanciamiento,
    required this.idConductor,
    required this.idProducto,
    this.idCoti,
    required this.codigoAsociado,
    required this.grupoFinanciamiento,
    required this.cantidadProducto,
    required this.montoTotal,
    required this.cuotaInicial,
    required this.cuotas,
    required this.estado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.fechaCreacion,
    required this.frecuencia,
    required this.secondProduct,
    required this.moneda,
    this.nombreProducto,
    this.tieneCuotaInicial = false,
    this.cuotaInicialEstado,
    this.cuotaInicialMonto,
    this.firmado = false,
    this.contratoUrl,
    this.boletaInicialUrl,
    this.firmaUrl,
    this.firmadoAt,
    this.aprobado,
    this.estadoEntrega,
    this.estadoApp,
  });

  // Getters útiles
  bool get isActive => estado.toLowerCase() == 'activo';
  bool get isPaid => estado.toLowerCase() == 'pagado';
  bool get isPending => estado.toLowerCase() == 'pendiente';
  
  String get montoFormateado {
    try {
      final double monto = double.parse(montoTotal.replaceAll(',', ''));
      return '${moneda == 'USD' ? '\$' : 'S/ '}${monto.toStringAsFixed(2)}';
    } catch (e) {
      return '$moneda $montoTotal';
    }
  }
  
  String get cuotaFormateada {
    try {
      final double cuota = double.parse(cuotaInicial.replaceAll(',', ''));
      return '${moneda == 'USD' ? '\$' : 'S/ '}${cuota.toStringAsFixed(2)}';
    } catch (e) {
      return '$moneda $cuotaInicial';
    }
  }
  
  int get diasRestantes {
    try {
      final fechaFinDate = DateTime.parse(fechaFin);
      final now = DateTime.now();
      final difference = fechaFinDate.difference(now);
      return difference.inDays;
    } catch (e) {
      return 0;
    }
  }

  FinanciamientoEntity copyWith({
    int? idFinanciamiento,
    int? idConductor,
    int? idProducto,
    int? idCoti,
    int? codigoAsociado,
    String? grupoFinanciamiento,
    String? cantidadProducto,
    String? montoTotal,
    String? cuotaInicial,
    int? cuotas,
    String? estado,
    String? fechaInicio,
    String? fechaFin,
    String? fechaCreacion,
    String? frecuencia,
    String? secondProduct,
    String? moneda,
    String? nombreProducto,
    bool? tieneCuotaInicial,
    String? cuotaInicialEstado,
    double? cuotaInicialMonto,
    bool? firmado,
    String? contratoUrl,
    String? boletaInicialUrl,
    String? firmaUrl,
    String? firmadoAt,
    int? aprobado,
    String? estadoEntrega,
    String? estadoApp,
  }) {
    return FinanciamientoEntity(
      idFinanciamiento: idFinanciamiento ?? this.idFinanciamiento,
      idConductor: idConductor ?? this.idConductor,
      idProducto: idProducto ?? this.idProducto,
      idCoti: idCoti ?? this.idCoti,
      codigoAsociado: codigoAsociado ?? this.codigoAsociado,
      grupoFinanciamiento: grupoFinanciamiento ?? this.grupoFinanciamiento,
      cantidadProducto: cantidadProducto ?? this.cantidadProducto,
      montoTotal: montoTotal ?? this.montoTotal,
      cuotaInicial: cuotaInicial ?? this.cuotaInicial,
      cuotas: cuotas ?? this.cuotas,
      estado: estado ?? this.estado,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      frecuencia: frecuencia ?? this.frecuencia,
      secondProduct: secondProduct ?? this.secondProduct,
      moneda: moneda ?? this.moneda,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      tieneCuotaInicial: tieneCuotaInicial ?? this.tieneCuotaInicial,
      cuotaInicialEstado: cuotaInicialEstado ?? this.cuotaInicialEstado,
      cuotaInicialMonto: cuotaInicialMonto ?? this.cuotaInicialMonto,
      firmado: firmado ?? this.firmado,
      contratoUrl: contratoUrl ?? this.contratoUrl,
      boletaInicialUrl: boletaInicialUrl ?? this.boletaInicialUrl,
      firmaUrl: firmaUrl ?? this.firmaUrl,
      firmadoAt: firmadoAt ?? this.firmadoAt,
      aprobado: aprobado ?? this.aprobado,
      estadoEntrega: estadoEntrega ?? this.estadoEntrega,
      estadoApp: estadoApp ?? this.estadoApp,
    );
  }
}
