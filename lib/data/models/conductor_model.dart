import '../../domain/entities/conductor_entity.dart';

class ConductorModel extends ConductorEntity {
  const ConductorModel({
    required super.idConductor,
    required super.nombres,
    required super.nroDocumento,
    required super.telefono,
    required super.direccion,
    required super.correo,
    required super.flag,
    required super.tipo,
    super.fotoPerfil,
    super.fotoPerfilCambiada,
  });

  factory ConductorModel.fromJson(Map<String, dynamic> json) {
    return ConductorModel(
      idConductor: json['conductor']['id_conductor'] ?? 0,
      nroDocumento: json['conductor']['nro_documento'] ?? '',
      nombres: json['conductor']['nombres'] ?? '',
      telefono: json['conductor']['telefono'] ?? '',
      direccion: json['conductor']['direccion'] ?? '',
      correo: json['conductor']['correo'] ?? '',
      flag: json['flag'] ?? 0,
      tipo: json['conductor']['tipo'],
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

  ConductorEntity toEntity() => ConductorEntity(
    idConductor: idConductor,
    nombres: nombres,
    nroDocumento: nroDocumento,
    telefono: telefono,
    direccion: direccion,
    correo: correo,
    flag: flag,
    tipo: tipo,
    fotoPerfil: fotoPerfil,
    fotoPerfilCambiada: fotoPerfilCambiada,
  );

  ConductorModel copyWith({
    int? idConductor,
    String? nombres,
    String? nroDocumento,
    String? telefono,
    String? direccion,
    String? correo,
    int? flag,
    int? tipo,
    String? fotoPerfil,
    bool? fotoPerfilCambiada,
  }) {
    return ConductorModel(
      idConductor: idConductor ?? this.idConductor,
      nombres: nombres ?? this.nombres,
      nroDocumento: nroDocumento ?? this.nroDocumento,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      correo: correo ?? this.correo,
      flag: flag ?? this.flag,
      tipo: tipo ?? this.tipo,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      fotoPerfilCambiada: fotoPerfilCambiada ?? this.fotoPerfilCambiada,
    );
  }
}
