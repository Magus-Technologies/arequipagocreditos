/// Categorías con tabla de % propia dentro del mismo sistema de niveles.
const String categoriaNivelTaller = 'taller';
const String categoriaNivelCelular = 'celular';

String _capitalizarNivel(String texto) =>
    texto.isEmpty ? texto : '${texto[0].toUpperCase()}${texto.substring(1)}';

/// Un nivel de la tabla de niveles (pollito/bronce/plata/oro y los que cree el
/// Director). El % de inicial que otorga depende de la categoría que se esté
/// financiando (talleres vs equipos celulares tienen su propia tabla de %), por
/// eso viene como mapa.
///
/// Los niveles los administra el Director desde el panel (TK-0390): el nombre y
/// la imagen llegan del servidor, y `nivel` es solo el código estable que sirve
/// para reconocerlo.
class NivelInfoEntity {
  final String nivel;
  final String nombre;
  final String? imagenUrl;

  /// Nivel base (Pollito): el que tiene todo conductor nuevo, con 0
  /// financiamientos finalizados.
  final bool esBase;
  final int financiamientosRequeridos;
  final Map<String, double> porcentajesPorCategoria;

  const NivelInfoEntity({
    required this.nivel,
    this.nombre = '',
    this.imagenUrl,
    this.esBase = false,
    required this.financiamientosRequeridos,
    required this.porcentajesPorCategoria,
  });

  /// El nombre que ve el conductor; si el servidor no lo mandó (versión
  /// anterior), el código con la primera letra en mayúscula.
  String get nombreVisible => nombre.isNotEmpty ? nombre : _capitalizarNivel(nivel);

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
  final String? nivelActualNombre;
  final Map<String, double?> porcentajeInicialActualPorCategoria;
  final String? siguienteNivel;
  final String? siguienteNivelNombre;
  final int? financiamientosFaltantes;
  final List<NivelInfoEntity> niveles;

  const NivelTallerEntity({
    required this.clienteConductorId,
    required this.financiamientosFinalizados,
    this.nivelActual,
    this.nivelActualNombre,
    this.porcentajeInicialActualPorCategoria = const {},
    this.siguienteNivel,
    this.siguienteNivelNombre,
    this.financiamientosFaltantes,
    this.niveles = const [],
  });

  bool get tieneNivel => nivelActual != null;

  bool get esNivelMaximo => siguienteNivel == null;

  NivelInfoEntity? _infoDe(String? codigo) {
    if (codigo == null) return null;
    for (final n in niveles) {
      if (n.nivel == codigo) return n;
    }
    return null;
  }

  /// Datos del nivel en el que está hoy (null si todavía no tiene ninguno).
  NivelInfoEntity? get infoNivelActual => _infoDe(nivelActual);

  /// Nombre del nivel actual tal como lo definió el Director.
  String? get nombreNivelActual {
    if (nivelActual == null) return null;
    final nombre = nivelActualNombre ?? infoNivelActual?.nombre;
    return nombre != null && nombre.isNotEmpty ? nombre : _capitalizarNivel(nivelActual!);
  }

  /// Nombre del siguiente nivel (null si ya está en el más alto).
  String? get nombreSiguienteNivel {
    if (siguienteNivel == null) return null;
    final nombre = siguienteNivelNombre ?? _infoDe(siguienteNivel)?.nombre;
    return nombre != null && nombre.isNotEmpty ? nombre : _capitalizarNivel(siguienteNivel!);
  }

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
