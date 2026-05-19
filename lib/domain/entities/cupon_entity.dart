class CuponEntity {
  final int id;
  final String titulo;
  final String? descripcion;
  final String categoria;
  final double valor;
  final String tipoDescuento; // 'monto_fijo' o 'porcentaje'
  final String? codigo;
  final DateTime fechaFin;
  final bool esActivo;
  final String? imagenBanner;
  final String? empresa;
  final String? condiciones;
  final int? limiteUsosConductor;
  final int usosRealizados;
  final bool puedeUsar;
  final String estado;
  final DateTime? fechaAsignacion;
  final List<String>? visiblePara;

  const CuponEntity({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.categoria,
    required this.valor,
    required this.tipoDescuento,
    this.codigo,
    required this.fechaFin,
    required this.esActivo,
    this.imagenBanner,
    this.empresa,
    this.condiciones,
    this.limiteUsosConductor,
    required this.usosRealizados,
    required this.puedeUsar,
    required this.estado,
    this.fechaAsignacion,
    this.visiblePara,
  });

  /// Retorna true si este cupón es visible para la audiencia dada.
  bool esVisiblePara(String audiencia) {
    if (visiblePara == null) return true;
    return visiblePara!.contains(audiencia);
  }

  bool get puedeUsarse => estado == "activo" && !estaVencido && tieneUsosDisponibles;
  
  bool get estaVencido => DateTime.now().isAfter(fechaFin);
  
  bool get tieneUsosDisponibles {
    if (limiteUsosConductor == null) return true;
    return (usosRealizados) < limiteUsosConductor!;
  }
  
  int get usosRestantes {
    if (limiteUsosConductor == null) return -1; // Ilimitado
    return limiteUsosConductor! - usosRealizados;
  }
  
  String get valorFormateado {
    if (tipoDescuento == 'porcentaje') {
      return '${valor.toInt()}% OFF';
    } else {
      return 'S/. ${valor.toStringAsFixed(2)}';
    }
  }
}
