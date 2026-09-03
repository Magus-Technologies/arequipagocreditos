/// Categorías con tabla de % propia dentro del mismo sistema de niveles.
const String categoriaNivelTaller = 'taller';
const String categoriaNivelCelular = 'celular';

/// Un nivel de la tabla de niveles (bronce/plata/oro). El % de inicial que
/// otorga depende de la categoría que se esté financiando (talleres vs
/// equipos celulares tienen su propia tabla de %), por eso viene como mapa.
class NivelInfoEntity {
  final String nivel;
  final int financiamientosRequeridos;
  final Map<String, double> porcentajesPorCategoria;

  const NivelInfoEntity({
    required this.nivel,
    required this.financiamientosRequeridos,
    required this.porcentajesPorCategoria,
  });

  double? porcentajePara(String categoria) => porcentajesPorCategoria[categoria];
}

/// Nivel de fidelización del cliente/conductor (o pasajero, se maneja igual).
///
/// El NIVEL en sí es uno solo: se calcula acumulando financiamientos
/// finalizados (pagados), sin importar si son de vehículo, taller o celular.
/// Lo que cambia por categoría es el % de inicial que ese nivel otorga.
class NivelTallerEntity {
  final int clienteConductorId;
  final int financiamientosFinalizados;
  final String? nivelActual;
  final Map<String, double?> porcentajeInicialActualPorCategoria;
  final String? siguienteNivel;
  final int? financiamientosFaltantes;
  final List<NivelInfoEntity> niveles;

  const NivelTallerEntity({
    required this.clienteConductorId,
    required this.financiamientosFinalizados,
    this.nivelActual,
    this.porcentajeInicialActualPorCategoria = const {},
    this.siguienteNivel,
    this.financiamientosFaltantes,
    this.niveles = const [],
  });

  bool get tieneNivel => nivelActual != null;

  bool get esNivelMaximo => siguienteNivel == null;

  double? porcentajeInicialActualPara(String categoria) =>
      porcentajeInicialActualPorCategoria[categoria];

  /// Progreso (0.0 a 1.0) hacia el siguiente nivel, según los financiamientos
  /// finalizados del nivel anterior al siguiente objetivo.
  double get progresoSiguienteNivel {
    if (esNivelMaximo) return 1.0;

    NivelInfoEntity? siguiente;
    for (final n in niveles) {
      if (n.nivel == siguienteNivel) {
        siguiente = n;
        break;
      }
    }
    siguiente ??= niveles.isNotEmpty
        ? niveles.first
        : const NivelInfoEntity(
            nivel: '',
            financiamientosRequeridos: 1,
            porcentajesPorCategoria: {},
          );

    final requeridosSiguiente = siguiente.financiamientosRequeridos;

    final requeridosAnterior = niveles
        .where((n) => n.financiamientosRequeridos < requeridosSiguiente)
        .fold<int>(0, (max, n) => n.financiamientosRequeridos > max ? n.financiamientosRequeridos : max);

    final rango = requeridosSiguiente - requeridosAnterior;
    if (rango <= 0) return 0.0;

    final avance = financiamientosFinalizados - requeridosAnterior;
    return (avance / rango).clamp(0.0, 1.0);
  }
}
