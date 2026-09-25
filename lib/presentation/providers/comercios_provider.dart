import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/comercio_entity.dart';
import '../../domain/usecases/get_comercios_usecase.dart';

class ComerciosProvider extends ChangeNotifier {
  final GetComerciosUseCase getComerciosUseCase;
  final GetComercioCategoriasUseCase getComercioCategoriasUseCase;

  ComerciosProvider({
    required this.getComerciosUseCase,
    required this.getComercioCategoriasUseCase,
  });

  List<ComercioEntity> _comercios = [];
  List<ComercioCategoriaEntity> _categorias = [];
  bool _loading = false;
  bool _loadingCategorias = false;
  String? _error;
  String _searchQuery = '';
  int? _categoriaFiltro;

  List<ComercioEntity> get comercios => _comercios;
  List<ComercioCategoriaEntity> get categorias => _categorias;
  bool get loading => _loading;
  bool get loadingCategorias => _loadingCategorias;
  String? get error => _error;
  int? get categoriaFiltro => _categoriaFiltro;

  List<ComercioEntity> get filteredComercios {
    if (_searchQuery.trim().isEmpty) return _comercios;
    final q = _searchQuery.trim().toLowerCase();
    return _comercios.where((c) {
      return c.nombreParaMostrar.toLowerCase().contains(q) ||
          (c.direccion?.toLowerCase().contains(q) ?? false) ||
          (c.categoriaNombre?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> cargarComercios({String? departamento}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await getComerciosUseCase(categoriaId: _categoriaFiltro, departamento: departamento);
    result.fold(
      (failure) {
        _error = failure is ServerFailure ? 'Error del servidor. Intenta nuevamente.' : 'No se pudieron cargar los comercios.';
      },
      (comercios) {
        _comercios = comercios;
      },
    );

    _loading = false;
    notifyListeners();
  }

  Future<void> cargarCategorias() async {
    _loadingCategorias = true;
    notifyListeners();

    final result = await getComercioCategoriasUseCase();
    result.fold(
      (_) {},
      (categorias) => _categorias = categorias,
    );

    _loadingCategorias = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoriaFiltro(int? categoriaId, {String? departamento}) {
    _categoriaFiltro = categoriaId;
    cargarComercios(departamento: departamento);
  }
}
