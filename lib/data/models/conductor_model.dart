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
    super.ingresoNetoMensual,
    super.estadoAprobacion,
    super.fechaRegistro,
    super.contactoEmergencia,
    super.documentos,
    required super.afiliacionFirmada,
    super.contratoAfiliacionUrl,
    super.firmaAfiliacionUrl,
    super.firmaAfiliacionAt,
  });

  factory ConductorModel.fromJson(Map<String, dynamic> json) {
    // SOPORTE PARA MÚLTIPLES FORMATOS DE RESPUESTA:
    // 1. { "conductor": { ... } } -> Formato Driver
    // 2. { "data": { ... } }      -> Formato Pasajero
    // 3. { ... }                  -> Formato plano
    final Map<String, dynamic> c = (json['conductor'] is Map)
        ? Map<String, dynamic>.from(json['conductor'])
        : (json['data'] is Map)
            ? Map<String, dynamic>.from(json['data'])
            : Map<String, dynamic>.from(json);

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    final dynamic rawId = c['id_conductor'] ?? c['id'];
    final int conductorId = (rawId is int) ? rawId : int.tryParse((rawId ?? '0').toString()) ?? 0;

    final dynamic rawTipo = c['tipo'];
    final int tipo = (rawTipo is int) ? rawTipo : int.tryParse((rawTipo ?? '4').toString()) ?? 4;

    return ConductorModel(
      idConductor: conductorId,
      nroDocumento: (c['nro_documento'] ?? '').toString(),
      nombres: (c['nombres'] ?? c['nombre_completo'] ?? '').toString(),
      telefono: (c['telefono'] ?? '').toString(),
      direccion: (c['direccion'] ?? '').toString(),
      correo: (c['correo'] ?? '').toString(),
      flag: (json['flag'] ?? c['flag']) is int ? (json['flag'] ?? c['flag']) : int.tryParse((json['flag'] ?? c['flag'] ?? '0').toString()) ?? 0,
      tipo: tipo,
      fotoPerfil: c['foto_perfil']?.toString(),
      fotoPerfilCambiada: (c['foto_perfil_cambiada'] == 1) || (c['foto_perfil_cambiada'] == true),
      fechaNacimiento: (c['fecha_nac'] ?? c['fecha_nacimiento'])?.toString(),
      placa: c['placa']?.toString(),
      soat: c['soat']?.toString(),
      revisionTecnica: c['revision_tecnica']?.toString(),
      seguroVehicular: c['seguro_vehicular']?.toString(),
      color: c['color']?.toString(),
      anio: parseNullableInt(c['anio']),
      marca: c['marca']?.toString(),
      modelo: c['modelo']?.toString(),
      ingresoNetoMensual: (c['ingreso_neto_mensual'] ?? c['ingreso_mensual'])?.toString(),
      estadoAprobacion: c['estado_aprobacion']?.toString(),
      fechaRegistro: c['fecha_registro']?.toString(),
      contactoEmergencia: c['contacto_emergencia'] is Map ? Map<String, dynamic>.from(c['contacto_emergencia']) : null,
      documentos: c['documentos'] is List 
          ? (c['documentos'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : null,
      afiliacionFirmada: c['afiliacion_firmada'] == true || c['afiliacion_firmada'] == 1,
      contratoAfiliacionUrl: c['contrato_afiliacion_url']?.toString(),
      firmaAfiliacionUrl: c['firma_afiliacion_url']?.toString(),
      firmaAfiliacionAt: c['firma_afiliacion_at']?.toString(),
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
      'ingreso_neto_mensual': ingresoNetoMensual,
      'estado_aprobacion': estadoAprobacion,
      'fecha_registro': fechaRegistro,
      'contacto_emergencia': contactoEmergencia,
      'documentos': documentos,
      'afiliacion_firmada': afiliacionFirmada,
      'contrato_afiliacion_url': contratoAfiliacionUrl,
      'firma_afiliacion_url': firmaAfiliacionUrl,
      'firma_afiliacion_at': firmaAfiliacionAt,
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
    ingresoNetoMensual: ingresoNetoMensual,
    estadoAprobacion: estadoAprobacion,
    fechaRegistro: fechaRegistro,
    contactoEmergencia: contactoEmergencia,
    documentos: documentos,
    afiliacionFirmada: afiliacionFirmada,
    contratoAfiliacionUrl: contratoAfiliacionUrl,
    firmaAfiliacionUrl: firmaAfiliacionUrl,
    firmaAfiliacionAt: firmaAfiliacionAt,
  );
}
