class BeneficioEntity {
  final String titulo;
  final String descripcion;
  final String icono;
  final bool activo;

  const BeneficioEntity({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.activo,
  });

  // Factory para crear beneficios basados en puntaje
  static List<BeneficioEntity> fromPuntaje(int puntaje) {
    return [
      BeneficioEntity(
        titulo: 'Tasas preferenciales',
        descripcion: 'Acceso a tasas de interés reducidas',
        icono: 'percentage',
        activo: puntaje >= 60,
      ),
      BeneficioEntity(
        titulo: 'Financiamiento express',
        descripcion: 'Aprobación rápida de créditos',
        icono: 'flash',
        activo: puntaje >= 40,
      ),
      BeneficioEntity(
        titulo: 'Montos mayores',
        descripcion: 'Acceso a financiamientos de mayor valor',
        icono: 'money',
        activo: puntaje >= 80,
      ),
      BeneficioEntity(
        titulo: 'Cupones premium',
        descripcion: 'Descuentos exclusivos en servicios',
        icono: 'gift',
        activo: puntaje >= 60,
      ),
    ];
  }
}

class BeneficioComercialEntity {
  final int id;
  final String nombre;
  final int planFinanciamientoId;
  final int? categoria;
  final String descripcion;
  final double cuotaInicial;
  final int cantidadCuotas;
  final double cuotaMensual;
  final double? pagoInscripcion;
  final String? imagen;
  final bool disponible;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String moneda;

  BeneficioComercialEntity({
    required this.id,
    required this.nombre,
    required this.planFinanciamientoId,
    this.categoria,
    required this.descripcion,
    required this.cuotaInicial,
    required this.cantidadCuotas,
    required this.cuotaMensual,
    this.pagoInscripcion,
    this.imagen,
    required this.disponible,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.moneda,
  });
}
