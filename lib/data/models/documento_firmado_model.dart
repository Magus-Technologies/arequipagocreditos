import '../../domain/entities/documento_firmado_entity.dart';

class ListadoDocumentosModel extends ListadoDocumentosEntity {
  ListadoDocumentosModel({
    required super.resumen,
    required super.documentos,
  });

  factory ListadoDocumentosModel.fromJson(Map<String, dynamic> json) {
    return ListadoDocumentosModel(
      resumen: ResumenDocumentosModel.fromJson(json['resumen']),
      documentos: (json['documentos'] as List)
          .map((d) => DocumentoFirmadoModel.fromJson(d))
          .toList(),
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
    super.ultimoFirmado,
  });

  factory ResumenDocumentosModel.fromJson(Map<String, dynamic> json) {
    final conductor = json['conductor'] ?? {};
    return ResumenDocumentosModel(
      conductorId: conductor['id'] ?? 0,
      nombreConductor: conductor['nombre'] ?? '',
      nroDocumento: conductor['nro_documento'] ?? '',
      totalDocumentos: json['total_documentos'] ?? 0,
      afiliaciones: json['afiliaciones'] ?? 0,
      contratos: json['contratos'] ?? 0,
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
    required super.firmadoAt,
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
      firmadoAt: DateTime.tryParse(json['firmado_at'] ?? '') ?? DateTime.now(),
      origen: json['origen'] ?? '',
    );
  }
}
