class ResumenDocumentosEntity {
  final int conductorId;
  final String nombreConductor;
  final String nroDocumento;
  final int totalDocumentos;
  final int afiliaciones;
  final int contratos;
  final DateTime? ultimoFirmado;

  ResumenDocumentosEntity({
    required this.conductorId,
    required this.nombreConductor,
    required this.nroDocumento,
    required this.totalDocumentos,
    required this.afiliaciones,
    required this.contratos,
    this.ultimoFirmado,
  });
}

class DocumentoFirmadoEntity {
  final int id;
  final String tipo;
  final String tipoDocumento;
  final String nombreDocumento;
  final int? financiamientoId;
  final String? grupoFinanciamiento;
  final double? montoTotal;
  final int? cantidadCuotas;
  final String? frecuenciaPago;
  final String nombreFirmante;
  final String documentoFirmante;
  final String cargo;
  final String firmaUrl;
  final String? contratoUrl;
  final DateTime firmadoAt;
  final String origen;

  DocumentoFirmadoEntity({
    required this.id,
    required this.tipo,
    required this.tipoDocumento,
    required this.nombreDocumento,
    this.financiamientoId,
    this.grupoFinanciamiento,
    this.montoTotal,
    this.cantidadCuotas,
    this.frecuenciaPago,
    required this.nombreFirmante,
    required this.documentoFirmante,
    required this.cargo,
    required this.firmaUrl,
    this.contratoUrl,
    required this.firmadoAt,
    required this.origen,
  });
}

class ListadoDocumentosEntity {
  final ResumenDocumentosEntity resumen;
  final List<DocumentoFirmadoEntity> documentos;

  ListadoDocumentosEntity({
    required this.resumen,
    required this.documentos,
  });
}
