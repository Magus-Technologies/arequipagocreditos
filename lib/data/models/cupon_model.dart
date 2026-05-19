import '../../domain/entities/cupon_entity.dart';

class CuponModel extends CuponEntity {
  const CuponModel({
    required super.id,
    required super.titulo,
    super.descripcion,
    required super.categoria,
    required super.valor,
    required super.tipoDescuento, // 'monto_fijo' o 'porcentaje'
    super.codigo,
    required super.fechaFin,
    required super.esActivo,
    super.imagenBanner,
    super.empresa,
    super.condiciones,
    super.limiteUsosConductor,
    required super.usosRealizados,
    required super.puedeUsar,
    required super.estado,
    super.fechaAsignacion,
    super.visiblePara,
  });

  factory CuponModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1' || value.toLowerCase() == 'activo';
      }
      return false;
    }

    return CuponModel(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? 'Sin título',
      descripcion: json['descripcion'],
      categoria: json['categoria'] ?? 'General',
      valor: double.tryParse(json['valor'].toString()) ?? 0.0,
      tipoDescuento: json['tipo_descuento'] ?? 'porcentaje',
      codigo: json['codigo'],
      fechaFin:
          json['fecha_fin'] != null
              ? DateTime.tryParse(json['fecha_fin'].toString()) ?? DateTime.now()
              : DateTime.now(),
      esActivo: parseBool(json['activo'] ?? json['es_activo'] ?? (json['estado'] == 'activo')),
      imagenBanner: json['imagen_banner'],
      empresa: json['empresa'] ?? 'Arequipa GO',
      condiciones: json['condiciones'],
      limiteUsosConductor: json['limite_usos_conductor'],
      usosRealizados: json['usos_realizados'] ?? (json['ya_usado'] == true ? 1 : 0),
      puedeUsar: json['puede_usar'] ?? (json['ya_usado'] == false),
      estado: json['estado'] ?? (json['activo'] == true ? 'activo' : 'inactivo'),
      fechaAsignacion:
          json['created_at'] != null || json['fecha_asignacion'] != null
              ? DateTime.tryParse((json['created_at'] ?? json['fecha_asignacion']).toString()) ?? DateTime.now()
              : null,
      visiblePara: json['visible_para'] is List
          ? (json['visible_para'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'valor': valor.toString(),
      'tipo_descuento': tipoDescuento,
      'codigo': codigo,
      'fecha_fin': fechaFin.toIso8601String(),
      'es_activo': esActivo,
      'imagen_banner': imagenBanner,
      'empresa': empresa,
      'condiciones': condiciones,
      'limite_usos_conductor': limiteUsosConductor,
      'usos_realizados': usosRealizados,
      'puede_usar': puedeUsar,
      'estado': estado,
      'fecha_asignacion': fechaAsignacion?.toIso8601String(),
    };
  }

  CuponEntity toEntity() => CuponEntity(
    id: id,
    titulo: titulo,
    descripcion: descripcion,
    categoria: categoria,
    valor: valor,
    tipoDescuento: tipoDescuento,
    codigo: codigo,
    fechaFin: fechaFin,
    esActivo: esActivo,
    imagenBanner: imagenBanner,
    empresa: empresa,
    condiciones: condiciones,
    limiteUsosConductor: limiteUsosConductor,
    usosRealizados: usosRealizados,
    puedeUsar: puedeUsar,
    estado: estado,
    fechaAsignacion: fechaAsignacion,
    visiblePara: visiblePara,
  );

  CuponModel copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    String? categoria,
    double? valor,
    String? tipoDescuento,
    String? codigo,
    DateTime? fechaFin,
    bool? esActivo,
    String? imagenBanner,
    String? empresa,
    String? condiciones,
    int? limiteUsosConductor,
    int? usosRealizados,
    bool? puedeUsar,
    String? estado,
    DateTime? fechaAsignacion,
    List<String>? visiblePara,
  }) {
    return CuponModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      valor: valor ?? this.valor,
      tipoDescuento: tipoDescuento ?? this.tipoDescuento,
      codigo: codigo ?? this.codigo,
      fechaFin: fechaFin ?? this.fechaFin,
      esActivo: esActivo ?? this.esActivo,
      imagenBanner: imagenBanner ?? this.imagenBanner,
      empresa: empresa ?? this.empresa,
      condiciones: condiciones ?? this.condiciones,
      limiteUsosConductor: limiteUsosConductor ?? this.limiteUsosConductor,
      usosRealizados: usosRealizados ?? this.usosRealizados,
      puedeUsar: puedeUsar ?? this.puedeUsar,
      estado: estado ?? this.estado,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      visiblePara: visiblePara ?? this.visiblePara,
    );
  }
}
