class Conductor {
  final int idConductor;
  final String nombres;
  final String nroDocumento;
  final String telefono;
  final String direccion;
  final String correo;
  final int flag;
  final int tipo;
  final String? fotoPerfil;
  final bool? fotoPerfilCambiada;

  Conductor({
    required this.idConductor,
    required this.nombres,
    required this.nroDocumento,
    required this.telefono,
    required this.direccion,
    required this.correo,
    required this.flag,
    required this.tipo,
    this.fotoPerfil,
    this.fotoPerfilCambiada,
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
      fotoPerfil: json['conductor']['foto_perfil'],
      fotoPerfilCambiada: json['conductor']['foto_perfil_cambiada'] == 1,
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
      'foto_perfil': fotoPerfil,
      'foto_perfil_cambiada': fotoPerfilCambiada,
    };
  }
}
