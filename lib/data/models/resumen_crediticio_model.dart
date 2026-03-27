class ResumenCrediticio {
  final int creditosActivos;
  final int puntaje;
  final int cuponesDisponibles;

  ResumenCrediticio({
    required this.creditosActivos,
    required this.puntaje,
    required this.cuponesDisponibles,
  });

  factory ResumenCrediticio.fromJson(Map<String, dynamic> json) {
    // If the response is wrapped in 'data'
    final Map<String, dynamic> data = json.containsKey('data') && json['data'] is Map 
        ? json['data'] as Map<String, dynamic> 
        : json;

    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return double.tryParse(value)?.toInt() ?? 0;
      return 0;
    }

    return ResumenCrediticio(
      creditosActivos: toInt(data['creditos_activos'] ?? data['creditosActivos']),
      puntaje: toInt(data['puntaje']),
      cuponesDisponibles: toInt(data['cupones_disponibles'] ?? data['cuponesDisponibles']),
    );
  }
}
