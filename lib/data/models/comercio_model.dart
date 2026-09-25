import '../../domain/entities/comercio_entity.dart';

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class ComercioCategoriaModel extends ComercioCategoriaEntity {
  const ComercioCategoriaModel({
    required super.id,
    required super.nombre,
    super.slug,
    super.icono,
    super.comerciosCount,
  });

  factory ComercioCategoriaModel.fromJson(Map<String, dynamic> json) {
    return ComercioCategoriaModel(
      id: _toInt(json['id']),
      nombre: json['nombre']?.toString() ?? '',
      slug: json['slug']?.toString(),
      icono: json['icono']?.toString(),
      comerciosCount: _toInt(json['comercios_count']),
    );
  }
}

class ComercioModel extends ComercioEntity {
  const ComercioModel({
    required super.id,
    super.categoriaId,
    super.categoriaNombre,
    required super.razonSocial,
    super.nombreComercial,
    super.telefono,
    super.whatsapp,
    super.whatsappUrl,
    super.logo,
    super.direccion,
    super.googleMapsUrl,
    super.descripcion,
    super.notaImportante,
    super.serviciosCount,
  });

  factory ComercioModel.fromJson(Map<String, dynamic> json) {
    final categoria = json['categoria'] as Map?;
    return ComercioModel(
      id: _toInt(json['id']),
      categoriaId: json['categoria_id'] != null ? _toInt(json['categoria_id']) : null,
      categoriaNombre: categoria?['nombre']?.toString(),
      razonSocial: json['razon_social']?.toString() ?? '',
      nombreComercial: json['nombre_comercial']?.toString(),
      telefono: json['telefono']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      whatsappUrl: json['whatsapp_url']?.toString(),
      logo: json['logo']?.toString(),
      direccion: json['direccion']?.toString(),
      googleMapsUrl: json['google_maps_url']?.toString(),
      descripcion: json['descripcion']?.toString(),
      notaImportante: json['nota_importante']?.toString(),
      serviciosCount: _toInt(json['servicios_count']),
    );
  }
}
