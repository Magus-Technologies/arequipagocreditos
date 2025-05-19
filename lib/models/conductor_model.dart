class Conductor {
  final int idConductor;
  final String nombres;
  final String nroDocumento;
  final String telefono;
  final String direccion;
  final String correo;
  final int flag;
  final int tipo;

  Conductor({
    required this.idConductor,
    required this.nombres,
    required this.nroDocumento,
    required this.telefono,
    required this.direccion,
    required this.correo,
    required this.flag,
    required this.tipo,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      idConductor: json['conductor']['id_conductor'] ?? 0,
      nroDocumento: json['conductor']['nro_documento'] ?? '',
      nombres: json['conductor']['nombres'] ?? '',
      telefono: json['conductor']['telefono'] ?? '',
      direccion: json['conductor']['direccion'] ?? '',
      correo: json['conductor']['correo'] ?? '',
      flag: json['flag'] ?? 0,
      tipo: json['conductor']['tipo'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idConductor': idConductor,
      'nombres': nombres,
      'nro_documento': nroDocumento,
      'telefono': telefono,
      'direccion': direccion,
      'correo': correo,
      'tipo': tipo,
    };
  }
}
