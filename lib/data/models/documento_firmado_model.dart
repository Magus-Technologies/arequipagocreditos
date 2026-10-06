import '../../domain/entities/documento_firmado_entity.dart';

class ListadoDocumentosModel extends ListadoDocumentosEntity {
  ListadoDocumentosModel({
    required super.resumen,
    required super.documentos,
  });

  factory ListadoDocumentosModel.fromJson(Map<String, dynamic> json) {
    final documentos = (json['documentos'] as List)
        .map((d) => DocumentoFirmadoModel.fromJson(d))
        .toList();
    // TK-0355: las adendas vienen en su propia lista (`adendas`, ya con las pendientes primero) para que una versión
    // vieja del app no las confunda con contratos. Aquí se muestran junto a los demás documentos, pendientes primero.
    final adendas = ((json['adendas'] ?? const []) as List)
        .map((d) => DocumentoFirmadoModel.fromJson(d))
        .toList();
    final todos = [...documentos, ...adendas];
    return ListadoDocumentosModel(
      resumen: ResumenDocumentosModel.fromJson(json['resumen']),
      documentos: [
        ...todos.where((d) => !d.firmado),
        ...todos.where((d) => d.firmado),
      ],
    );
  }
}

class ResumenDocumentosModel extends ResumenDocumentosEntity {
  ResumenDocumentosModel({
    required super.conductorId,
    required super.nombreConductor,
    required super.nroDocumento,
    required super.totalDocumentos,
    required super.afiliaciones,
    required super.contratos,
    super.adendas,
    super.adendasPendientes,
    super.ultimoFirmado,
  });

  factory ResumenDocumentosModel.fromJson(Map<String, dynamic> json) {
    final conductor = json['conductor'] ?? {};
    return ResumenDocumentosModel(
      conductorId: conductor['id'] ?? 0,
      nombreConductor: conductor['nombre'] ?? '',
      nroDocumento: conductor['nro_documento'] ?? '',
      // El total del servidor no cuenta las adendas (van en su lista aparte): se suman aquí.
      totalDocumentos: (json['total_documentos'] ?? 0) + (json['adendas'] ?? 0) + (json['adendas_pendientes'] ?? 0),
      afiliaciones: json['afiliaciones'] ?? 0,
      contratos: json['contratos'] ?? 0,
      adendas: json['adendas'] ?? 0,
      adendasPendientes: json['adendas_pendientes'] ?? 0,
      ultimoFirmado: DateTime.tryParse(json['ultimo_firmado'] ?? ''),
    );
  }
}

class DocumentoFirmadoModel extends DocumentoFirmadoEntity {
  DocumentoFirmadoModel({
    required super.id,
    required super.tipo,
    required super.tipoDocumento,
    required super.nombreDocumento,
    super.financiamientoId,
    super.grupoFinanciamiento,
    super.montoTotal,
    super.cantidadCuotas,
    super.frecuenciaPago,
    required super.nombreFirmante,
    required super.documentoFirmante,
    required super.cargo,
    required super.firmaUrl,
    super.contratoUrl,
    super.tipoFirma,
    super.adendaId,
    super.firmado,
    super.firmadoAt,
    required super.origen,
  });

  factory DocumentoFirmadoModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return DocumentoFirmadoModel(
      id: json['id'] ?? 0,
      tipo: json['tipo'] ?? '',
      tipoDocumento: json['tipo_documento'] ?? '',
      nombreDocumento: json['nombre_documento'] ?? '',
      financiamientoId: json['financiamiento_id'],
      grupoFinanciamiento: json['grupo_financiamiento'],
      montoTotal: json['monto_total'] != null ? parseDouble(json['monto_total']) : null,
      cantidadCuotas: json['cantidad_cuotas'],
      frecuenciaPago: json['frecuencia_pago'],
      nombreFirmante: json['nombre_firmante'] ?? '',
      documentoFirmante: json['documento_firmante'] ?? '',
      cargo: json['cargo'] ?? '',
      firmaUrl: json['firma_url'] ?? '',
      contratoUrl: json['contrato_url'],
      tipoFirma: json['tipo_firma'],
      adendaId: json['adenda_id'],
      // Documentos de afiliación no mandan el flag: siempre están firmados.
      firmado: json['firmado'] ?? true,
      firmadoAt: DateTime.tryParse(json['firmado_at'] ?? ''),
      origen: json['origen'] ?? '',
    );
  }
}
