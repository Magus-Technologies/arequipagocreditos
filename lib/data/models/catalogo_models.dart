class UbigeoItemModel {
  final String codigo;
  final String nombre;

  const UbigeoItemModel({required this.codigo, required this.nombre});

  factory UbigeoItemModel.fromJson(Map<String, dynamic> json) {
    return UbigeoItemModel(
      codigo: (json['codigo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
    );
  }
}

class PlataformaItemModel {
  final int id;
  final String plataforma;
  final String nombrePlataforma;
  final String? logo;

  const PlataformaItemModel({
    required this.id,
    required this.plataforma,
    required this.nombrePlataforma,
    this.logo,
  });

  factory PlataformaItemModel.fromJson(Map<String, dynamic> json) {
    return PlataformaItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      plataforma: (json['plataforma'] ?? '').toString(),
      nombrePlataforma: (json['nombre_plataforma'] ?? '').toString(),
      logo: json['logo']?.toString(),
    );
  }
}
