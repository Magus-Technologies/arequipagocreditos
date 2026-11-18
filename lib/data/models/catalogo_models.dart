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

/// Departamento habilitado para una plataforma, con las provincias habilitadas dentro de él.
class DepartamentoUbicacionModel {
  final String codigo;
  final String nombre;
  final List<UbigeoItemModel> provincias;

  const DepartamentoUbicacionModel({required this.codigo, required this.nombre, this.provincias = const []});

  factory DepartamentoUbicacionModel.fromJson(Map<String, dynamic> json) {
    final provincias = json['provincias'];
    return DepartamentoUbicacionModel(
      codigo: (json['codigo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      provincias: provincias is List
          ? provincias.whereType<Map>().map((p) => UbigeoItemModel.fromJson(Map<String, dynamic>.from(p))).toList()
          : const [],
    );
  }
}

/// Dónde está habilitada una plataforma (`GET /app/plataformas/{plataforma}/ubicaciones`).
///
/// Con [restringido] en false la plataforma trabaja en cualquier lugar y el registro usa los catálogos completos de ubicación.
/// Con [restringido] en true solo valen los [departamentos] (y las provincias de cada uno) que manda el servidor.
class UbicacionPlataformaModel {
  final bool restringido;
  final List<DepartamentoUbicacionModel> departamentos;

  const UbicacionPlataformaModel({required this.restringido, this.departamentos = const []});

  factory UbicacionPlataformaModel.fromJson(Map<String, dynamic> json) {
    final departamentos = json['departamentos'];
    final restringido = json['restringido'];
    return UbicacionPlataformaModel(
      restringido: restringido == true || restringido == 1 || restringido == '1' || restringido == 'true',
      departamentos: departamentos is List
          ? departamentos.whereType<Map>().map((d) => DepartamentoUbicacionModel.fromJson(Map<String, dynamic>.from(d))).toList()
          : const [],
    );
  }

  /// Los departamentos habilitados, listos para el selector.
  List<UbigeoItemModel> get departamentosItems =>
      departamentos.map((d) => UbigeoItemModel(codigo: d.codigo, nombre: d.nombre)).toList();

  /// Las provincias habilitadas dentro de [codigoDepartamento] (vacía si el departamento no está habilitado).
  List<UbigeoItemModel> provinciasDe(String? codigoDepartamento) {
    for (final d in departamentos) {
      if (d.codigo == codigoDepartamento) return d.provincias;
    }
    return const [];
  }

  bool permiteDepartamento(String? codigoDepartamento) =>
      codigoDepartamento != null && departamentos.any((d) => d.codigo == codigoDepartamento);

  bool permiteProvincia(String? codigoDepartamento, String? codigoProvincia) =>
      codigoProvincia != null && provinciasDe(codigoDepartamento).any((p) => p.codigo == codigoProvincia);
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
