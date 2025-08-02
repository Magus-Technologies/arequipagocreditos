class PuntuacionCredito {
  final int puntaje;
  final String nivel;
  final String color;
  final String descripcion;
  final int siguienteNivel;
  final int puntosRestantes;
  final List<Beneficio> beneficios;

  PuntuacionCredito({
    required this.puntaje,
    required this.nivel,
    required this.color,
    required this.descripcion,
    required this.siguienteNivel,
    required this.puntosRestantes,
    required this.beneficios,
  });

  factory PuntuacionCredito.fromJson(Map<String, dynamic> json) {
    return PuntuacionCredito(
      puntaje: json['puntaje'] ?? 0,
      nivel: json['nivel'] ?? '',
      color: json['color'] ?? '',
      descripcion: json['descripcion'] ?? '',
      siguienteNivel: json['siguiente_nivel'] ?? 0,
      puntosRestantes: json['puntos_restantes'] ?? 0,
      beneficios: (json['beneficios'] as List<dynamic>?)
          ?.map((item) => Beneficio.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'puntaje': puntaje,
      'nivel': nivel,
      'color': color,
      'descripcion': descripcion,
      'siguiente_nivel': siguienteNivel,
      'puntos_restantes': puntosRestantes,
      'beneficios': beneficios.map((e) => e.toJson()).toList(),
    };
  }
}

class Beneficio {
  final String titulo;
  final String descripcion;
  final String icono;
  final bool activo;

  Beneficio({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.activo,
  });

  factory Beneficio.fromJson(Map<String, dynamic> json) {
    return Beneficio(
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      icono: json['icono'] ?? '',
      activo: json['activo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'icono': icono,
      'activo': activo,
    };
  }
}

class HistorialPuntos {
  final int id;
  final String descripcion;
  final int puntos;
  final String tipo; // "suma" o "resta"
  final DateTime fecha;

  HistorialPuntos({
    required this.id,
    required this.descripcion,
    required this.puntos,
    required this.tipo,
    required this.fecha,
  });

  factory HistorialPuntos.fromJson(Map<String, dynamic> json) {
    return HistorialPuntos(
      id: json['id'] ?? 0,
      descripcion: json['descripcion'] ?? '',
      puntos: json['puntos'] ?? 0,
      tipo: json['tipo'] ?? '',
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descripcion': descripcion,
      'puntos': puntos,
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
    };
  }
}
