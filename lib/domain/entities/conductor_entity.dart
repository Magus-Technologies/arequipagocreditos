class ConductorEntity {
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

  const ConductorEntity({
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

  String get nombreCompleto => nombres;
}
