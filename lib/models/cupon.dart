class Cupon {
  final int id;
  final String titulo;
  final String descripcion;
  final String categoria;
  final double descuento;
  final String tipoDescuento; // 'porcentaje' o 'monto'
  final String codigo;
  final DateTime fechaVencimiento;
  final bool esActivo;
  final String imagen;
  final String empresa;
  final String? condiciones;
  final int? limiteUsos;
  final int? usosRestantes;

  Cupon({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.descuento,
    required this.tipoDescuento,
    required this.codigo,
    required this.fechaVencimiento,
    required this.esActivo,
    required this.imagen,
    required this.empresa,
    this.condiciones,
    this.limiteUsos,
    this.usosRestantes,
  });

  factory Cupon.fromJson(Map<String, dynamic> json) {
    return Cupon(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      categoria: json['categoria'] ?? '',
      descuento: (json['descuento'] ?? 0).toDouble(),
      tipoDescuento: json['tipo_descuento'] ?? 'porcentaje',
      codigo: json['codigo'] ?? '',
      fechaVencimiento: DateTime.parse(json['fecha_vencimiento'] ?? DateTime.now().toString()),
      esActivo: json['es_activo'] ?? true,
      imagen: json['imagen'] ?? '',
      empresa: json['empresa'] ?? '',
      condiciones: json['condiciones'],
      limiteUsos: json['limite_usos'],
      usosRestantes: json['usos_restantes'],
    );
  }

  String get descuentoFormateado {
    if (tipoDescuento == 'porcentaje') {
      return '${descuento.toInt()}% OFF';
    } else {
      return 'S/ ${descuento.toStringAsFixed(0)} OFF';
    }
  }

  bool get estaVencido => DateTime.now().isAfter(fechaVencimiento);
  
  bool get tieneUsosDisponibles => usosRestantes == null || usosRestantes! > 0;
  
  bool get puedeUsarse => esActivo && !estaVencido && tieneUsosDisponibles;
}
