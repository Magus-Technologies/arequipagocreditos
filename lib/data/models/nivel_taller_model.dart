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

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final texto = value?.toString().toLowerCase();
  return texto == 'true' || texto == '1';
}

/// Texto opcional del servidor: null si no vino o llegó vacío.
String? _toNullableString(dynamic value) {
  final texto = value?.toString().trim();
  return texto == null || texto.isEmpty ? null : texto;
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
    super.nombre,
    super.imagenUrl,
    super.esBase,
    required super.financiamientosRequeridos,
    required super.porcentajesPorCategoria,
  });

  factory NivelInfoModel.fromJson(Map<String, dynamic> json) {
    return NivelInfoModel(
      nivel: json['nivel']?.toString() ?? '',
      nombre: _toNullableString(json['nombre']) ?? '',
      imagenUrl: _toNullableString(json['imagen_url']),
      esBase: _toBool(json['es_base']),
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
    super.nivelActualNombre,
    super.porcentajeInicialActualPorCategoria,
    super.siguienteNivel,
    super.siguienteNivelNombre,
    super.financiamientosFaltantes,
    super.niveles,
  });

  factory NivelTallerModel.fromJson(Map<String, dynamic> json) {
    final nivelesRaw = json['niveles'] as List<dynamic>? ?? const [];

    return NivelTallerModel(
      clienteConductorId: _toInt(json['cliente_conductor_id']),
      financiamientosFinalizados: _toInt(json['financiamientos_finalizados']),
      nivelActual: json['nivel_actual']?.toString(),
      nivelActualNombre: _toNullableString(json['nivel_actual_nombre']),
      porcentajeInicialActualPorCategoria: () {
        final raw = json['porcentaje_inicial_actual'];
        if (raw is! Map) return const <String, double?>{};
        return raw.map((key, value) => MapEntry(key.toString(), _toNullableDouble(value)));
      }(),
      siguienteNivel: json['siguiente_nivel']?.toString(),
      siguienteNivelNombre: _toNullableString(json['siguiente_nivel_nombre']),
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
