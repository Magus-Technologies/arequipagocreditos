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
  final bool fotoPerfilCambiada;
  final String? fechaNacimiento; // ahora nullable
  final String? placa;
  final String? soat;
  final String? revisionTecnica;
  final String? seguroVehicular;
  final String? color;
  final int? anio;
  final String? marca;
  final String? modelo;

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
  });

  String get nombreCompleto => nombres;

  // Helper: intenta parsear y devolver DateTime, o null si no es válido
  DateTime? get fechaNacimientoAsDate {
    if (fechaNacimiento == null) return null;
    try {
      return DateTime.tryParse(fechaNacimiento!);
    } catch (_) {
      return null;
    }
  }

  // Helper: devuelve fecha formateada o un placeholder
  String get fechaNacimientoFormatted {
    final dt = fechaNacimientoAsDate;
    if (dt == null) return '-';
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    // Puedes usar intl para formateos más avanzados
  }
}