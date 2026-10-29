class ConductorEntity {
  final int idConductor;
  final String nombres;
  final String nroDocumento;
  final String telefono;
  final String direccion;
  final String? departamento;
  final String correo;
  final int flag;
  final int tipo;
  final String? fotoPerfil;
  final bool fotoPerfilCambiada;
  final String? fechaNacimiento;
  
  // Vehículo
  final String? placa;
  final String? soat;
  final String? revisionTecnica;
  final String? seguroVehicular;
  final String? color;
  final int? anio;
  final String? marca;
  final String? modelo;

  // Pasajeros
  final String? ingresoNetoMensual;
  final String? estadoAprobacion;
  final String? fechaRegistro;
  final Map<String, dynamic>? contactoEmergencia;
  final List<Map<String, dynamic>>? documentos;

  // Firmas
  final bool afiliacionFirmada;

  /// TK-0401: ya había firmado, pero se publicó una versión nueva del contrato de afiliación y debe firmarla otra vez.
  /// El servidor manda `afiliacion_firmada = false` y el app bloquea todo hasta que firme (ver `main.dart`).
  final bool afiliacionActualizada;

  /// TK-0401: número de la versión vigente del contrato de afiliación (null si nunca se publicó una). Viaja con la firma para
  /// que el servidor no registre la firma de una versión que ya no es la vigente.
  final int? contratoAfiliacionVersion;
  final String? contratoAfiliacionUrl;
  final String? firmaAfiliacionUrl;
  final String? firmaAfiliacionAt;

  /// TK-0357: datos por actualizar (foto de perfil, DNI, SOAT). Cada item trae `codigo`, `mensaje` y `descripcion`.
  /// Con algo pendiente no puede generar financiamientos. Lista vacía = al día.
  final List<Map<String, dynamic>> datosPendientes;

  const ConductorEntity({
    required this.idConductor,
    required this.nombres,
    required this.nroDocumento,
    required this.telefono,
    required this.direccion,
    this.departamento,
    required this.correo,
    required this.flag,
    required this.tipo,
    this.fotoPerfil,
    required this.fotoPerfilCambiada,
    this.fechaNacimiento,
    this.placa,
    this.soat,
    this.revisionTecnica,
    this.seguroVehicular,
    this.color,
    this.anio,
    this.marca,
    this.modelo,
    this.ingresoNetoMensual,
    this.estadoAprobacion,
    this.fechaRegistro,
    this.contactoEmergencia,
    this.documentos,
    this.afiliacionFirmada = false,
    this.afiliacionActualizada = false,
    this.contratoAfiliacionVersion,
    this.contratoAfiliacionUrl,
    this.firmaAfiliacionUrl,
    this.firmaAfiliacionAt,
    this.datosPendientes = const [],
  });

  String get nombreCompleto => nombres;

  DateTime? get fechaNacimientoAsDate {
    if (fechaNacimiento == null) return null;
    try {
      return DateTime.tryParse(fechaNacimiento!);
    } catch (_) {
      return null;
    }
  }

  String get fechaNacimientoFormatted {
    final dt = fechaNacimientoAsDate;
    if (dt == null) return '-';
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}