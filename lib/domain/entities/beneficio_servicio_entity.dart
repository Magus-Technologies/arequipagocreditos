class BeneficioServicioEntity {
  final int id;
  final String nombre;
  final String descripcion;
  final int tallerId;
  final double precioServicio;
  final int cuotaInicialTipo;
  final double cuotaInicialPorcentaje;
  final int tipoPago;
  final int? grupoFinanciamientoId;
  final DetalleFinanciamientoEntity? detalleFinanciamiento;
  final String modoCalculo;
  final bool permiteMontoLibre;
  final double porcentajeInicialDefault;
  final int minCuotas;
  final int maxCuotas;
  // Extra fields from API
  final String? imagen;
  final double cuotaInicial;
  final int cantidadCuotas;
  final double cuotaMensual;
  final String moneda;
  final String? frecuenciaPago;
  final bool disponible;
  final List<String> metodosPago;

  BeneficioServicioEntity({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tallerId,
    required this.precioServicio,
    required this.cuotaInicialTipo,
    required this.cuotaInicialPorcentaje,
    required this.tipoPago,
    this.grupoFinanciamientoId,
    this.detalleFinanciamiento,
    this.modoCalculo = 'fijo',
    this.permiteMontoLibre = false,
    this.porcentajeInicialDefault = 30.0,
    this.minCuotas = 0,
    this.maxCuotas = 0,
    this.imagen,
    this.cuotaInicial = 0.0,
    this.cantidadCuotas = 0,
    this.cuotaMensual = 0.0,
    this.moneda = 'S/.',
    this.frecuenciaPago,
    this.disponible = true,
    this.metodosPago = const ['CAJA_AREQUIPA'],
  });
}

class DetalleFinanciamientoEntity {
  final int tipoPago;
  final double precioServicio;
  final int cuotaInicialTipo;
  final double cuotaInicialPorcentaje;
  final int cantidadCuotas;
  final double montoMaximo;
  final double porcentajeInicial;
  final double interes;
  final int minCuotas;
  final int maxCuotas;
  final String frecuenciaPago;
  final List<String> frecuenciasDisponibles;
  final String moneda;
  final String modoCalculo;
  final double porcentajeInicialDefault;
  final List<String> metodosPago;

  DetalleFinanciamientoEntity({
    required this.tipoPago,
    required this.precioServicio,
    required this.cuotaInicialTipo,
    required this.cuotaInicialPorcentaje,
    required this.cantidadCuotas,
    required this.montoMaximo,
    required this.porcentajeInicial,
    required this.interes,
    required this.minCuotas,
    required this.maxCuotas,
    required this.frecuenciaPago,
    required this.frecuenciasDisponibles,
    required this.moneda,
    required this.modoCalculo,
    required this.porcentajeInicialDefault,
    this.metodosPago = const ['CAJA_AREQUIPA'],
  });
}
