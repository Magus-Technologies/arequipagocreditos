import '../../domain/entities/nivel_taller_entity.dart';

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

/// Convierte el mapa `{ "taller": 30.0, "celular": 40.0 }` del backend,
/// descartando categorías sin valor numérico.
Map<String, double> _porcentajesPorCategoriaFromJson(dynamic raw) {
  if (raw is! Map) return const {};
  final resultado = <String, double>{};
  raw.forEach((key, value) {
    final porcentaje = _toNullableDouble(value);
    if (porcentaje != null) {
      resultado[key.toString()] = porcentaje;
    }
  });
  return resultado;
}

class NivelInfoModel extends NivelInfoEntity {
  const NivelInfoModel({
    required super.nivel,
    required super.financiamientosRequeridos,
    required super.porcentajesPorCategoria,
  });

  factory NivelInfoModel.fromJson(Map<String, dynamic> json) {
    return NivelInfoModel(
      nivel: json['nivel']?.toString() ?? '',
      financiamientosRequeridos: _toInt(json['financiamientos_requeridos']),
      porcentajesPorCategoria: _porcentajesPorCategoriaFromJson(json['porcentajes']),
    );
  }
}

class NivelTallerModel extends NivelTallerEntity {
  const NivelTallerModel({
    required super.clienteConductorId,
    required super.financiamientosFinalizados,
    super.nivelActual,
    super.porcentajeInicialActualPorCategoria,
    super.siguienteNivel,
    super.financiamientosFaltantes,
    super.niveles,
  });

  factory NivelTallerModel.fromJson(Map<String, dynamic> json) {
    final nivelesRaw = json['niveles'] as List<dynamic>? ?? const [];

    return NivelTallerModel(
      clienteConductorId: _toInt(json['cliente_conductor_id']),
      financiamientosFinalizados: _toInt(json['financiamientos_finalizados']),
      nivelActual: json['nivel_actual']?.toString(),
      porcentajeInicialActualPorCategoria: () {
        final raw = json['porcentaje_inicial_actual'];
        if (raw is! Map) return const <String, double?>{};
        return raw.map((key, value) => MapEntry(key.toString(), _toNullableDouble(value)));
      }(),
      siguienteNivel: json['siguiente_nivel']?.toString(),
      financiamientosFaltantes: json['financiamientos_faltantes'] != null
          ? _toInt(json['financiamientos_faltantes'])
          : null,
      niveles: nivelesRaw
          .whereType<Map>()
          .map((e) => NivelInfoModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
