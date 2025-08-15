class PuntuacionEntity {
  final int id;
  final String tipoCliente;
  final int? idConductor;
  final int puntajeActual;
  final int totalFinanciamientos;
  final int totalRetrasos;
  final DateTime fechaActualizacion;
  final DateTime fechaCreacion;

  const PuntuacionEntity({
    required this.id,
    required this.tipoCliente,
    this.idConductor,
    required this.puntajeActual,
    required this.totalFinanciamientos,
    required this.totalRetrasos,
    required this.fechaActualizacion,
    required this.fechaCreacion,
  });

  // Getters útiles para el nivel de puntuación
  String get nivel {
    if (puntajeActual >= 80) return 'Excelente';
    if (puntajeActual >= 60) return 'Bueno';
    if (puntajeActual >= 40) return 'Regular';
    if (puntajeActual >= 20) return 'Malo';
    return 'Crítico';
  }

  String get colorHex {
    if (puntajeActual >= 80) return '#4CAF50'; // Verde
    if (puntajeActual >= 60) return '#8BC34A'; // Verde claro
    if (puntajeActual >= 40) return '#FFC107'; // Amarillo
    if (puntajeActual >= 20) return '#FF9800'; // Naranja
    return '#F44336'; // Rojo
  }

  String get descripcion {
    if (puntajeActual >= 80) return 'Excelente historial crediticio. Acceso a todos los beneficios.';
    if (puntajeActual >= 60) return 'Buen historial de pagos. Acceso a la mayoría de beneficios.';
    if (puntajeActual >= 40) return 'Historial regular. Algunos beneficios disponibles.';
    if (puntajeActual >= 20) return 'Historial con retrasos. Beneficios limitados.';
    return 'Historial crítico. Es necesario mejorar el record de pagos.';
  }

  int get siguienteNivel {
    if (puntajeActual >= 80) return 100;
    if (puntajeActual >= 60) return 80;
    if (puntajeActual >= 40) return 60;
    if (puntajeActual >= 20) return 40;
    return 20;
  }

  int get puntosRestantes => siguienteNivel - puntajeActual;

  double get porcentajeNivel {
    if (puntajeActual >= 80) return 1.0;
    if (puntajeActual >= 60) return (puntajeActual - 60) / 20.0;
    if (puntajeActual >= 40) return (puntajeActual - 40) / 20.0;
    if (puntajeActual >= 20) return (puntajeActual - 20) / 20.0;
    return puntajeActual / 20.0;
  }

  bool get tieneAccesoTasasPreferenciales => puntajeActual >= 60;
  bool get tieneAccesoFinanciamientoExpress => puntajeActual >= 40;
  bool get tieneAccesoMontosMayores => puntajeActual >= 80;
  bool get tieneAccesoCuponesPremium => puntajeActual >= 60;
}
