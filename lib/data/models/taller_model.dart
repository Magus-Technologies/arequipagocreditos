class TallerModel {
  final int id;
  final String razonSocial;
  final String nombreComercial;
  final String? logo;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? descripcion;
  final int serviciosCount;
  final bool activo;

  final String? whatsapp;
  final String? googleMapsUrl;
  final String? whatsappUrl;
  final String? notaImportante;
  final Map<String, dynamic>? horarioAtencion;
  final double promedioCalificacion;
  final int totalCalificaciones;

  TallerModel({
    required this.id,
    required this.razonSocial,
    required this.nombreComercial,
    this.logo,
    this.telefono,
    this.email,
    this.direccion,
    this.descripcion,
    required this.serviciosCount,
    required this.activo,
    this.whatsapp,
    this.googleMapsUrl,
    this.whatsappUrl,
    this.notaImportante,
    this.horarioAtencion,
    this.promedioCalificacion = 0.0,
    this.totalCalificaciones = 0,
  });

  factory TallerModel.fromJson(Map<String, dynamic> json) {
    return TallerModel(
      id: json['id'] ?? 0,
      razonSocial: json['razon_social'] ?? '',
      nombreComercial: json['nombre_comercial'] ?? json['razon_social'] ?? '',
      logo: json['logo'],
      telefono: json['telefono'],
      email: json['email'],
      direccion: json['direccion'],
      descripcion: json['descripcion'],
      serviciosCount: json['servicios_count'] ?? 0,
      activo: json['activo'] == true,
      whatsapp: json['whatsapp'],
      googleMapsUrl: json['google_maps_url'],
      whatsappUrl: json['whatsapp_url'],
      notaImportante: json['nota_importante']?.toString(),
      horarioAtencion: json['horario_atencion'] is Map
          ? Map<String, dynamic>.from(json['horario_atencion'] as Map)
          : null,
      promedioCalificacion: _parseDouble(json['promedio_calificacion']),
      totalCalificaciones: json['total_calificaciones'] is int ? json['total_calificaciones'] : 0,
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
