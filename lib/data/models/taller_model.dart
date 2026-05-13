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
    );
  }
}
