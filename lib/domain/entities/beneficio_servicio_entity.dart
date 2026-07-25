class ClienteAlertasEntity {
  final bool puedeSolicitar;
  final String? motivoPrincipal;
  final List<String> motivos;
  final int? puntajeActual;
  final bool tienePuntajeBajo;
  final bool estaEnIncobrables;
  final bool estaDesvinculado;
  final bool tienePendientes;
  final int cantidadPendientes;
  final bool documentosCompletos;
  final List<String> documentosFaltantes;
  final bool yaAdquirioServicio;

  const ClienteAlertasEntity({
    required this.puedeSolicitar,
    this.motivoPrincipal,
    this.motivos = const [],
    this.puntajeActual,
    this.tienePuntajeBajo = false,
    this.estaEnIncobrables = false,
    this.estaDesvinculado = false,
    this.tienePendientes = false,
    this.cantidadPendientes = 0,
    this.documentosCompletos = true,
    this.documentosFaltantes = const [],
    this.yaAdquirioServicio = false,
  });
}

/// Variante seleccionable de un beneficio (ej. certificado 13k / 15k / 17k).
/// Trae su propio set financiero completo, calculado en el backend.
class VarianteEntity {
  final int varianteId;
  final String nombre;
  final String? familia;
  final double certificado;
  final double montoTotal;
  final double montoCuota;
  final int cantidadCuotas;
  final double cuotaInicial;
  final double? porcentajeInicial;
  final double montoInscripcion;
  final double tasaInteres;
  final int? frecuenciaPagoId;
  final int monedaId;
  final String monedaSimbolo;
  final int monedaInicialId;
  final String monedaInicialSimbolo;

  const VarianteEntity({
    required this.varianteId,
    required this.nombre,
    this.familia,
    this.certificado = 0.0,
    this.montoTotal = 0.0,
    this.montoCuota = 0.0,
    this.cantidadCuotas = 0,
    this.cuotaInicial = 0.0,
    this.porcentajeInicial,
    this.montoInscripcion = 0.0,
    this.tasaInteres = 0.0,
    this.frecuenciaPagoId,
    this.monedaId = 1,
    this.monedaSimbolo = 'S/.',
    this.monedaInicialId = 1,
    this.monedaInicialSimbolo = 'S/.',
  });
}

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
  final List<String>? visiblePara;
  final ClienteAlertasEntity? clienteAlertas;
  final String? notaImportante;
  final List<VarianteEntity> variantesDisponibles;

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
    this.visiblePara,
    this.clienteAlertas,
    this.notaImportante,
    this.variantesDisponibles = const [],
  });

  /// Retorna true si este servicio es visible para la audiencia dada.
  bool esVisiblePara(String audiencia) {
    if (visiblePara == null) return true;
    return visiblePara!.contains(audiencia);
  }
}

class ContratoDetalleEntity {
  final bool disponible;
  final int? templateId;
  final String? nombre;
  final String? url;

  const ContratoDetalleEntity({
    required this.disponible,
    this.templateId,
    this.nombre,
    this.url,
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
  // Nuevos campos v2
  final double porcentajeInicialMin;
  final double porcentajeInicialMax;
  final double? montoProducto;
  final bool aprobacionAutomatica;
  final bool requiereDobleValidacion;
  final bool permitirUnaSolaAprobacion;
  final bool contratoDisponible;
  final ContratoDetalleEntity? contrato;

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
    this.porcentajeInicialMin = 0,
    this.porcentajeInicialMax = 100,
    this.montoProducto,
    this.aprobacionAutomatica = true,
    this.requiereDobleValidacion = false,
    this.permitirUnaSolaAprobacion = false,
    this.contratoDisponible = false,
    this.contrato,
  });
}
