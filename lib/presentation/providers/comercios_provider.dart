import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/promociones_flyers_cache.dart';
import '../../data/models/promo_taller_banner_model.dart';
import '../../domain/entities/comercio_entity.dart';
import '../../domain/usecases/get_comercios_usecase.dart';

class ComerciosProvider extends ChangeNotifier {
  final GetComerciosUseCase getComerciosUseCase;
  final GetComercioCategoriasUseCase getComercioCategoriasUseCase;
  final GetComercioPromocionesBannersUseCase getPromocionesBannersUseCase;

  ComerciosProvider({
    required this.getComerciosUseCase,
    required this.getComercioCategoriasUseCase,
    required this.getPromocionesBannersUseCase,
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

  Future<List<PromoTallerBannerModel>> _pedirPromociones() async {
    final result = await getPromocionesBannersUseCase();
    // Un error se lanza (en vez de devolver vacío) para que la caché conserve los flyers guardados en lugar de borrarlos.
    return result.fold((falla) => throw Exception(falla.message), (banners) => banners);
  }

  /// Flyers de la pestaña Promociones de la web, listos para mostrar al entrar: usa la lista guardada (memoria o celular) y la refresca
  /// por detrás; solo la primera vez espera al servidor. Si algo falla (o el interruptor está apagado) devuelve vacío:
  /// un flyer que no carga nunca debe estorbar el listado de comercios.
  Future<List<PromoTallerBannerModel>> cargarPromocionesBanners() =>
      PromocionesFlyersCache.paraMostrar(PromocionesFlyersCache.comercios, _pedirPromociones);

  /// Se llama al abrir el app: trae la lista y baja las imágenes por adelantado, así el cuadro sale al instante al entrar a Comercios GO.
  Future<void> precargarPromociones() async {
    await PromocionesFlyersCache.actualizar(PromocionesFlyersCache.comercios, _pedirPromociones);
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
