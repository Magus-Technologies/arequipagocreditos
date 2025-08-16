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
    return ResumenCrediticio(
      creditosActivos: json['creditosActivos'] ?? 0,
      puntaje: json['puntaje'] ?? 0,
      cuponesDisponibles: json['cuponesDisponibles'] ?? 0,
    );
  }
}
