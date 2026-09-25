/// Categoría/rubro de un comercio afiliado a COMERCIOS GO (restaurantes,
/// farmacias, minimarkets, etc.).
class ComercioCategoriaEntity {
  final int id;
  final String nombre;
  final String? slug;
  final String? icono;
  final int comerciosCount;

  const ComercioCategoriaEntity({
    required this.id,
    required this.nombre,
    this.slug,
    this.icono,
    this.comerciosCount = 0,
  });
}

/// Establecimiento comercial afiliado (COMERCIOS GO, K-0314): tiendas,
/// restaurantes, etc. con descuentos para el cliente/conductor.
class ComercioEntity {
  final int id;
  final int? categoriaId;
  final String? categoriaNombre;
  final String razonSocial;
  final String? nombreComercial;
  final String? telefono;
  final String? whatsapp;
  final String? whatsappUrl;
  final String? logo;
  final String? direccion;
  final String? googleMapsUrl;
  final String? descripcion;
  final String? notaImportante;

  /// TK-0314: cuántos servicios ofrece este comercio en el app.
  final int serviciosCount;

  const ComercioEntity({
    required this.id,
    this.categoriaId,
    this.categoriaNombre,
    required this.razonSocial,
    this.nombreComercial,
    this.telefono,
    this.whatsapp,
    this.whatsappUrl,
    this.logo,
    this.direccion,
    this.googleMapsUrl,
    this.descripcion,
    this.notaImportante,
    this.serviciosCount = 0,
  });

  String get nombreParaMostrar =>
      (nombreComercial != null && nombreComercial!.trim().isNotEmpty) ? nombreComercial! : razonSocial;
}
