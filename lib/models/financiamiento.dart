class Financiamiento {
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

  Financiamiento({
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
  });

  factory Financiamiento.fromJson(Map<String, dynamic> json) {
    return Financiamiento(
      idFinanciamiento: json['idfinanciamiento'],
      idConductor: json['id_conductor'],
      idProducto: json['idproductosv2'],
      idCoti: json['id_coti'],
      codigoAsociado: json['codigo_asociado'],
      grupoFinanciamiento: json['grupo_financiamiento'],
      cantidadProducto: json['cantidad_producto'],
      montoTotal: json['monto_total'],
      cuotaInicial: json['cuota_inicial'],
      cuotas: json['cuotas'],
      estado: json['estado'],
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
      fechaCreacion: json['fecha_creacion'],
      frecuencia: json['frecuencia'],
      secondProduct: json['second_product'],
    );
  }
}