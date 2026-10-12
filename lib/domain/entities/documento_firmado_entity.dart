class ResumenDocumentosEntity {
  final int conductorId;
  final String nombreConductor;
  final String nroDocumento;
  final int totalDocumentos;
  final int afiliaciones;
  final int contratos;
  /// Adendas ya firmadas / pendientes de firma (cada una se firma aparte del contrato).
  final int adendas;
  final int adendasPendientes;
  /// TK-0353: documentos adicionales que la empresa anexó al financiamiento (PDF a firmar), firmados / pendientes.
  final int documentosAdicionales;
  final int documentosAdicionalesPendientes;
  final DateTime? ultimoFirmado;

  ResumenDocumentosEntity({
    required this.conductorId,
    required this.nombreConductor,
    required this.nroDocumento,
    required this.totalDocumentos,
    required this.afiliaciones,
    required this.contratos,
    this.adendas = 0,
    this.adendasPendientes = 0,
    this.documentosAdicionales = 0,
    this.documentosAdicionalesPendientes = 0,
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
  /// Solo adendas y documentos adicionales: el `tipo` que se manda a `POST /app/firmar/{tipoFirma}/{adendaId}`
  /// (`adenda-yango` | `adenda-indriver` | `documento-adicional`) y el id del documento a firmar (en los documentos
  /// adicionales el servidor lo manda como `documento_id`). El resto de documentos no los trae.
  final String? tipoFirma;
  final int? adendaId;
  /// TK-0353: lo que la empresa escribió al anexar el documento adicional (opcional).
  final String? descripcion;
  /// true = ya firmado; false = pendiente de firma (se puede firmar desde el app).
  final bool firmado;
  final DateTime? firmadoAt;
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
    this.tipoFirma,
    this.adendaId,
    this.descripcion,
    this.firmado = true,
    this.firmadoAt,
    required this.origen,
  });

  /// Adendas (TK-0355) y documentos adicionales (TK-0353) se firman POR SEPARADO del contrato: cada uno con su propio
  /// `tipoFirma` e id, no con el del financiamiento.
  bool get esFirmaSeparada => tipo == 'adenda' || tipo == 'documento_adicional';

  bool get esDocumentoAdicional => tipo == 'documento_adicional';
}

class ListadoDocumentosEntity {
  final ResumenDocumentosEntity resumen;
  final List<DocumentoFirmadoEntity> documentos;

  ListadoDocumentosEntity({
    required this.resumen,
    required this.documentos,
  });
}
