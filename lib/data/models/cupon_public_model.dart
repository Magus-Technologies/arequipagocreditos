import '../../domain/entities/cupon_entity.dart';

class CuponPublicModel {
  final int id;
  final String titulo;
  final String? descripcion;
  final String? tipoDescuento;
  final String? valor;
  final String? imagenBanner;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? departamentoNombre;

  CuponPublicModel({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.tipoDescuento,
    this.valor,
    this.imagenBanner,
    this.fechaInicio,
    this.fechaFin,
    this.departamentoNombre,
  });

  factory CuponPublicModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? s) {
      if (s == null) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    return CuponPublicModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      tipoDescuento: json['tipo_descuento']?.toString(),
      valor: json['valor']?.toString(),
      imagenBanner: json['imagen_banner']?.toString(),
      fechaInicio: parseDate(json['fecha_inicio']?.toString()),
      fechaFin: parseDate(json['fecha_fin']?.toString()),
      departamentoNombre: json['departamento_nombre']?.toString(),
    );
  }

  CuponEntity toEntity() {
    double parseValor(String? s) {
      if (s == null) return 0.0;
      try {
        return double.parse(s.replaceAll(',', '.'));
      } catch (_) {
        return 0.0;
      }
    }


    final valorDouble = parseValor(valor);
    final fechaFinDt = fechaFin ?? DateTime.now();

    return CuponEntity(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      categoria: 'Promociones',
      valor: valorDouble,
      tipoDescuento: tipoDescuento ?? 'monto_fijo',
      codigo: 'CUPON$id',
      fechaFin: fechaFinDt,
      esActivo: true,
      imagenBanner: imagenBanner,
      empresa: departamentoNombre,
      condiciones: null,
      limiteUsosConductor: null,
      usosRealizados: 0,
      puedeUsar: !(fechaFinDt.isBefore(DateTime.now())),
      estado: 'activo',
      fechaAsignacion: null,
    );
  }
}
