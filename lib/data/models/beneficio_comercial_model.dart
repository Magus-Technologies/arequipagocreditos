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
    super.imagen,
    required super.disponible,
    required super.fechaCreacion,
    required super.fechaActualizacion,
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
      imagen: json['imagen'],
      disponible: (json['disponible'] ?? 0) == 1,
      fechaCreacion: DateTime.tryParse(json['fecha_creacion'] ?? '') ?? DateTime.now(),
      fechaActualizacion: DateTime.tryParse(json['fecha_actualizacion'] ?? '') ?? DateTime.now(),
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
      'imagen': imagen,
      'disponible': disponible ? 1 : 0,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
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
}