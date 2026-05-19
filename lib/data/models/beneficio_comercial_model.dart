import '../../domain/entities/beneficio_entity.dart';
import '../../core/constants/api_constants.dart';

class BeneficioComercialModel extends BeneficioComercialEntity {
  BeneficioComercialModel({
    required super.id,
    required super.nombre,
    required super.planFinanciamientoId,
    super.categoria,
    required super.descripcion,
    required super.cuotaInicial,
    required super.cantidadCuotas,
    required super.cuotaMensual,
    super.pagoInscripcion,
    super.imagen,
    required super.disponible,
    required super.fechaCreacion,
    required super.fechaActualizacion,
    required super.moneda,
    required super.frecuenciaPago,
    super.visiblePara,
  });

  factory BeneficioComercialModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      return false;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    List<String>? parseVisiblePara(dynamic value) {
      if (value == null) return null;
      if (value is List) return value.map((e) => e.toString()).toList();
      return null;
    }

    return BeneficioComercialModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      planFinanciamientoId: json['grupo_financiamiento_id'] ?? json['plan_financiamiento_id'] ?? 0,
      categoria: json['categoria'],
      descripcion: json['descripcion'] ?? '',
      cuotaInicial: parseDouble(json['cuota_inicial']),
      cantidadCuotas: json['cantidad_cuotas'] ?? 0,
      cuotaMensual: parseDouble(json['cuota_mensual']),
      pagoInscripcion: json['pago_inscripcion'] != null ? parseDouble(json['pago_inscripcion']) : null,
      imagen: json['imagen'],
      disponible: parseBool(json['disponible']),
      fechaCreacion: DateTime.tryParse(json['created_at'] ?? json['fecha_creacion'] ?? '') ?? DateTime.now(),
      fechaActualizacion: DateTime.tryParse(json['updated_at'] ?? json['fecha_actualizacion'] ?? '') ?? DateTime.now(),
      moneda: json['moneda'] ?? 'S/.',
      frecuenciaPago: (json['frecuencia_pago'] ?? '').toString(),
      visiblePara: parseVisiblePara(json['visible_para']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'grupo_financiamiento_id': planFinanciamientoId,
      'categoria': categoria,
      'descripcion': descripcion,
      'cuota_inicial': cuotaInicial.toString(),
      'cantidad_cuotas': cantidadCuotas,
      'cuota_mensual': cuotaMensual.toString(),
      'pago_inscripcion': pagoInscripcion?.toString(),
      'imagen': imagen,
      'disponible': disponible,
      'created_at': fechaCreacion.toIso8601String(),
      'updated_at': fechaActualizacion.toIso8601String(),
      'moneda': moneda,
      'frecuencia_pago': frecuenciaPago,
    };
  }

  // URL completa de la imagen
  String? get imageUrl {
    if (imagen == null || imagen!.isEmpty) return null;
    return '${ApiConstants.imagenesBaseUrl}/$imagen';
  }

  // Formato de moneda para mostrar
  String get cuotaInicialFormatted => 'S/ ${cuotaInicial.toStringAsFixed(2)}';
  String get cuotaMensualFormatted => 'S/ ${cuotaMensual.toStringAsFixed(2)}';
  String? get pagoInscripcionFormatted => pagoInscripcion != null ? 'S/ ${pagoInscripcion!.toStringAsFixed(2)}' : null;
}