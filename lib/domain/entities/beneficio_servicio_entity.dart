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
  /// Stock del modelo de esta variante (matcheado por nombre contra el
  /// producto). Null = no hay producto que matchee (no se muestra stock).
  final int? stockDisponible;
  /// Foto del modelo (ruta relativa del almacén; null si no tiene).
  final String? imagen;
  /// Características del modelo para mostrar (pantalla, RAM, ROM, cámara, red).
  final Map<String, String> caracteristicas;
  /// Colores disponibles del modelo (de sus unidades).
  final List<String> coloresDisponibles;
  /// Descuento semanal en soles y meta de viajes de este certificado (Credi Ahorro InDriver: 13,000 → S/. 50 y 80 viajes).
  /// Null cuando la variante no tiene (p. ej. Yango): no se muestra nada.
  final double? descuentoSemanal;
  final int? viajesRequeridos;

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
    this.stockDisponible,
    this.imagen,
    this.caracteristicas = const {},
    this.coloresDisponibles = const [],
    this.descuentoSemanal,
    this.viajesRequeridos,
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

  /// Producto real vinculado (ficha técnica, colores y stock del modelo en la
  /// ciudad del cliente). Null si el beneficio no tiene producto vinculado.
  final ProductoBeneficioEntity? producto;

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
    this.producto,
  });

  /// Retorna true si este servicio es visible para la audiencia dada.
  bool esVisiblePara(String audiencia) {
    if (visiblePara == null) return true;
    return visiblePara!.contains(audiencia);
  }
}

/// Producto real vinculado al servicio/beneficio (TK-0306 / TK-0337).
/// `stockDisponible` = unidades del modelo disponibles en los almacenes de la
/// ciudad del cliente; `disponible` = false cuando no hay stock ("Sin stock").
class ProductoBeneficioEntity {
  final int id;
  final String nombre;
  final String? fichaTecnicaUrl;
  final List<String> coloresDisponibles;
  final int stockDisponible;
  final bool disponible;

  const ProductoBeneficioEntity({
    required this.id,
    required this.nombre,
    this.fichaTecnicaUrl,
    this.coloresDisponibles = const [],
    this.stockDisponible = 0,
    this.disponible = false,
  });
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
