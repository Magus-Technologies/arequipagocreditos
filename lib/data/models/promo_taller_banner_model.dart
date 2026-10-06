class PromoTallerBannerModel {
  final int id;
  final String nombreBanner;
  final String rutaImagen;

  const PromoTallerBannerModel({
    required this.id,
    required this.nombreBanner,
    required this.rutaImagen,
  });

  factory PromoTallerBannerModel.fromJson(Map<String, dynamic> json) {
    return PromoTallerBannerModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      nombreBanner: json['nombre_banner']?.toString() ?? '',
      rutaImagen: json['ruta_imagen']?.toString() ?? '',
    );
  }
}
