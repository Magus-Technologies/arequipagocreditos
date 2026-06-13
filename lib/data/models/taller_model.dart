class TallerUbicacion {
  final int id;
  final int tallerId;
  final String? ubigeo;
  final String? departamentoNombre;
  final String? provinciaNombre;
  final String? distritoNombre;
  final String? direccion;
  final String? googleMapsUrl;
  final bool esPrincipal;

  TallerUbicacion({
    required this.id,
    required this.tallerId,
    this.ubigeo,
    this.departamentoNombre,
    this.provinciaNombre,
    this.distritoNombre,
    this.direccion,
    this.googleMapsUrl,
    this.esPrincipal = false,
  });

  factory TallerUbicacion.fromJson(Map<String, dynamic> json) {
    return TallerUbicacion(
      id: json['id'] ?? 0,
      tallerId: json['taller_id'] ?? 0,
      ubigeo: json['ubigeo'] as String?,
      departamentoNombre: json['departamento_nombre'] as String?,
      provinciaNombre: json['provincia_nombre'] as String?,
      distritoNombre: json['distrito_nombre'] as String?,
      direccion: json['direccion'] as String?,
      googleMapsUrl: json['google_maps_url'] as String?,
      esPrincipal: json['es_principal'] == true,
    );
  }
}

class TallerGrupo {
  final String nombre;
  final int total;
  final List<TallerModel> talleres;

  TallerGrupo({required this.nombre, required this.total, required this.talleres});

  factory TallerGrupo.fromJson(Map<String, dynamic> json) {
    return TallerGrupo(
      nombre: json['nombre'] as String? ?? 'Sin ubicación',
      total: json['total'] as int? ?? 0,
      talleres: (json['talleres'] as List? ?? [])
          .map((t) => TallerModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TalleresAgrupadosResponse {
  final int total;
  final List<TallerGrupo> grupos;

  TalleresAgrupadosResponse({required this.total, required this.grupos});

  factory TalleresAgrupadosResponse.fromJson(Map<String, dynamic> json) {
    return TalleresAgrupadosResponse(
      total: json['total'] as int? ?? 0,
      grupos: (json['grupos'] as List? ?? [])
          .map((g) => TallerGrupo.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }
}

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
  final List<TallerUbicacion> ubicaciones;

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
    this.ubicaciones = const [],
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
      ubicaciones: (json['ubicaciones'] as List? ?? [])
          .map((u) => TallerUbicacion.fromJson(u as Map<String, dynamic>))
          .toList(),
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
