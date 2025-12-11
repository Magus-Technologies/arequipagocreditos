import '../../domain/entities/beneficio_entity.dart';

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
  });

  factory BeneficioComercialModel.fromJson(Map<String, dynamic> json) {
    return BeneficioComercialModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      planFinanciamientoId: json['plan_financiamiento_id'] ?? 0,
      categoria: json['categoria'],
      descripcion: json['descripcion'] ?? '',
      cuotaInicial: double.tryParse(json['cuota_inicial']?.toString() ?? '0') ?? 0.0,
      cantidadCuotas: json['cantidad_cuotas'] ?? 0,
      cuotaMensual: double.tryParse(json['cuota_mensual']?.toString() ?? '0') ?? 0.0,
      pagoInscripcion: json['pago_inscripcion'] != null ? double.tryParse(json['pago_inscripcion']?.toString() ?? '0') : null,
      imagen: json['imagen'],
      disponible: (json['disponible'] ?? 0) == 1,
      fechaCreacion: DateTime.tryParse(json['fecha_creacion'] ?? '') ?? DateTime.now(),
      fechaActualizacion: DateTime.tryParse(json['fecha_actualizacion'] ?? '') ?? DateTime.now(),
      moneda: json['moneda'] ?? 'S/.',
      frecuenciaPago: json['frecuencia_pago'] ?? 'mensual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'plan_financiamiento_id': planFinanciamientoId,
      'categoria': categoria,
      'descripcion': descripcion,
      'cuota_inicial': cuotaInicial.toString(),
      'cantidad_cuotas': cantidadCuotas,
      'cuota_mensual': cuotaMensual.toString(),
      'pago_inscripcion': pagoInscripcion?.toString(),
      'imagen': imagen,
      'disponible': disponible ? 1 : 0,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
      'moneda': moneda,
      'frecuencia_pago': frecuenciaPago,
    };
  }

  // URL completa de la imagen
  String? get imageUrl {
    if (imagen == null || imagen!.isEmpty) return null;
    return 'https://arequipago-ventas.pe/$imagen';
  }

  // Formato de moneda para mostrar
  String get cuotaInicialFormatted => 'S/ ${cuotaInicial.toStringAsFixed(2)}';
  String get cuotaMensualFormatted => 'S/ ${cuotaMensual.toStringAsFixed(2)}';
  String? get pagoInscripcionFormatted => pagoInscripcion != null ? 'S/ ${pagoInscripcion!.toStringAsFixed(2)}' : null;
}