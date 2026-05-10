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
  final String moneda;

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
    required this.moneda,
  });
}
