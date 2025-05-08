class Conductor {
  final int idConductor;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String nroDocumento;
  final String telefono;
  final String direccion;
  final String correo;
  final int flag;

  Conductor({
    required this.idConductor,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.nroDocumento,
    required this.telefono,
    required this.direccion,
    required this.correo,
    required this.flag,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      idConductor: json['conductor']['id_conductor'] ?? 0,
      nroDocumento: json['conductor']['nro_documento'] ?? '',
      nombres: json['conductor']['nombres'] ?? '',
      apellidoPaterno: json['conductor']['apellido_paterno'] ?? '',
      apellidoMaterno: json['conductor']['apellido_materno'] ?? '',
      telefono: json['conductor']['telefono'] ?? '',
      direccion: json['conductor']['direccion'] ?? '',
      correo: json['conductor']['correo'] ?? '',
      flag: json['flag'] ?? 0, // Si es null, asignar 0
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idConductor': idConductor,
      'nombres': nombres,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'nro_documento': nroDocumento,
      'telefono': telefono,
      'direccion': direccion,
      'correo': correo,
    };
  }
}
