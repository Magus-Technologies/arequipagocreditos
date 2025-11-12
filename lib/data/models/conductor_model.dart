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
    required super.fotoPerfilCambiada,
    super.fechaNacimiento,
    super.placa,
    super.soat,
    super.revisionTecnica,
    super.seguroVehicular,
    super.color,
    super.anio,
    super.marca,
    super.modelo,
  });

  factory ConductorModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> c =
        (json['conductor'] is Map) ? Map<String, dynamic>.from(json['conductor']) : Map<String, dynamic>.from(json);

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return ConductorModel(
      idConductor: c['id_conductor'] is int ? c['id_conductor'] : int.tryParse((c['id_conductor'] ?? '0').toString()) ?? 0,
      nroDocumento: (c['nro_documento'] ?? '').toString(),
      nombres: (c['nombres'] ?? '').toString(),
      telefono: (c['telefono'] ?? '').toString(),
      direccion: (c['direccion'] ?? '').toString(),
      correo: (c['correo'] ?? '').toString(),
      flag: json['flag'] is int ? json['flag'] : int.tryParse((json['flag'] ?? '0').toString()) ?? 0,
      tipo: c['tipo'] is int ? c['tipo'] : int.tryParse((c['tipo'] ?? '0').toString()) ?? 0,
      fotoPerfil: c['foto_perfil']?.toString(),
      fotoPerfilCambiada: (c['foto_perfil_cambiada'] == 1) || (c['foto_perfil_cambiada'] == true),
      fechaNacimiento: c['fecha_nac']?.toString(), // nullable string
      placa: c['placa']?.toString(),
      soat: c['soat']?.toString(),
      revisionTecnica: c['revision_tecnica']?.toString(),
      seguroVehicular: c['seguro_vehicular']?.toString(),
      color: c['color']?.toString(),
      anio: parseNullableInt(c['anio']),
      marca: c['marca']?.toString(),
      modelo: c['modelo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_conductor': idConductor,
      'nro_documento': nroDocumento,
      'nombres': nombres,
      'telefono': telefono,
      'direccion': direccion,
      'correo': correo,
      'flag': flag,
      'tipo': tipo,
      'foto_perfil': fotoPerfil,
      'foto_perfil_cambiada': fotoPerfilCambiada ? 1 : 0,
      'fecha_nac': fechaNacimiento,
      'placa': placa,
      'soat': soat,
      'revision_tecnica': revisionTecnica,
      'seguro_vehicular': seguroVehicular,
      'color': color,
      'anio': anio,
      'marca': marca,
      'modelo': modelo,
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
    fechaNacimiento: fechaNacimiento,
    placa: placa,
    soat: soat,
    revisionTecnica: revisionTecnica,
    seguroVehicular: seguroVehicular,
    color: color,
    anio: anio,
    marca: marca,
    modelo: modelo,
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
    String? fechaNacimiento,
    String? placa,
    String? soat,
    String? revisionTecnica,
    String? seguroVehicular,
    String? color,
    int? anio,
    String? marca,
    String? modelo,
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
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      placa: placa ?? this.placa,
      soat: soat ?? this.soat,
      revisionTecnica: revisionTecnica ?? this.revisionTecnica,
      seguroVehicular: seguroVehicular ?? this.seguroVehicular,
      color: color ?? this.color,
      anio: anio ?? this.anio,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
    );
  }
}
