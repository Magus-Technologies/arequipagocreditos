class Conductor {
  final int idConductor;
  final String nroDocumento;
  final String nombres;
  final String? correo;
  final int flag;

  Conductor({
    required this.idConductor,
    required this.nroDocumento,
    required this.nombres,
    this.correo,
    required this.flag,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      idConductor: json['conductor']['id_conductor'],
      nroDocumento: json['conductor']['nro_documento'],
      nombres: json['conductor']['nombres'],
      correo: json['conductor']['correo'],
      flag: json['flag'],
    );
  }
}
