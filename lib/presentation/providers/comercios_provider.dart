import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/audiencia_helper.dart';
import '../../core/utils/promociones_flyers_cache.dart';
import '../../data/models/promo_taller_banner_model.dart';
import '../../domain/entities/comercio_entity.dart';
import '../../domain/usecases/get_comercios_usecase.dart';

class ComerciosProvider extends ChangeNotifier {
  final GetComerciosUseCase getComerciosUseCase;
  final GetComerciosAgrupadosUseCase getComerciosAgrupadosUseCase;
  final CalificarComercioUseCase calificarComercioUseCase;
  final GetComercioCategoriasUseCase getComercioCategoriasUseCase;
  final GetComercioPromocionesBannersUseCase getPromocionesBannersUseCase;

  ComerciosProvider({
    required this.getComerciosUseCase,
    required this.getComerciosAgrupadosUseCase,
    required this.calificarComercioUseCase,
    required this.getComercioCategoriasUseCase,
    required this.getPromocionesBannersUseCase,
  });

  List<ComercioGrupoEntity> _grupos = [];
  String? _audiencia;
  String? _tipoVehicularFiltro;
  String? _departamentoActual;

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
  List<ComercioGrupoEntity> get grupos => _grupos;

  /// Filtro por tipo de vehículo ('moto', 'vehiculo', 'tuktuk'); null = todos.
  String? get tipoVehicularFiltro => _tipoVehicularFiltro;

  /// TK-0382: la audiencia del conductor (por su tipo de usuario): el servidor solo manda los comercios con servicios para él.
  void setAudiencia(int tipoUsuario) {
    _audiencia = AudienciaHelper.fromTipo(tipoUsuario);
  }

  /// TK-0382: comercios agrupados por ciudad y filtrados por la búsqueda (solo quedan los grupos con coincidencias).
  List<ComercioGrupoEntity> get filteredGrupos {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _grupos;
    return _grupos
        .map((g) {
          final coincidencias = g.comercios.where((c) => _coincide(c, q)).toList();
          if (coincidencias.isEmpty) return null;
          return ComercioGrupoEntity(nombre: g.nombre, total: coincidencias.length, comercios: coincidencias);
        })
        .whereType<ComercioGrupoEntity>()
        .toList();
  }

  bool _coincide(ComercioEntity c, String q) =>
      c.nombreParaMostrar.toLowerCase().contains(q) ||
      (c.direccion?.toLowerCase().contains(q) ?? false) ||
      (c.categoriaNombre?.toLowerCase().contains(q) ?? false);

  List<ComercioEntity> get filteredComercios {
    if (_searchQuery.trim().isEmpty) return _comercios;
    final q = _searchQuery.trim().toLowerCase();
    return _comercios.where((c) => _coincide(c, q)).toList();
  }

  /// Carga los comercios agrupados por ciudad (TK-0382), con la audiencia del conductor y el tipo de vehículo elegido. `_comercios` queda
  /// como la lista plana de lo mismo (buscador y conteo).
  Future<void> cargarComercios({String? departamento}) async {
    _departamentoActual = departamento;
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await getComerciosAgrupadosUseCase(
      categoriaId: _categoriaFiltro,
      departamento: departamento,
      audiencia: _audiencia,
      tipoVehicular: _tipoVehicularFiltro,
    );
    result.fold(
      (failure) {
        _error = failure is ServerFailure ? 'Error del servidor. Intenta nuevamente.' : 'No se pudieron cargar los comercios.';
      },
      (grupos) {
        _grupos = grupos;
        _comercios = grupos.expand((g) => g.comercios).toList();
      },
    );

    _loading = false;
    notifyListeners();
  }

  /// Filtro por tipo de vehículo ('' o null = todos). Vuelve a pedir el listado con la misma ciudad.
  Future<void> setTipoVehicularFiltro(String? tipoVehicular) async {
    _tipoVehicularFiltro = (tipoVehicular == null || tipoVehicular.isEmpty) ? null : tipoVehicular;
    await cargarComercios(departamento: _departamentoActual);
  }

  /// El conductor califica un comercio. Devuelve el promedio y el total nuevos, o null si no se pudo enviar.
  Future<Map<String, dynamic>?> calificarComercio({
    required int comercioId,
    required int clienteConductorId,
    required int puntuacion,
    String? comentario,
  }) async {
    final result = await calificarComercioUseCase(
      comercioId: comercioId,
      clienteConductorId: clienteConductorId,
      puntuacion: puntuacion,
      comentario: comentario,
    );
    return result.fold((_) => null, (datos) => datos);
  }

  /// Los flyers guardados son de una ciudad (TK-0393): cada ciudad tiene su propia lista en la caché, así quien cambia de ciudad o de
  /// cuenta en el mismo celular no ve primero los flyers de la otra. Sin ciudad conocida es la lista general de siempre.
  String _seccionFlyers(String? departamento) {
    final ciudad = departamento?.trim().toLowerCase() ?? '';
    return ciudad.isEmpty ? PromocionesFlyersCache.comercios : '${PromocionesFlyersCache.comercios}_$ciudad';
  }

  Future<List<PromoTallerBannerModel>> _pedirPromociones(String? departamento) async {
    final result = await getPromocionesBannersUseCase(departamento: departamento);
    // Un error se lanza (en vez de devolver vacío) para que la caché conserve los flyers guardados en lugar de borrarlos.
    return result.fold((falla) => throw Exception(falla.message), (banners) => banners);
  }

  /// Flyers de la pestaña Promociones de la web, listos para mostrar al entrar: usa la lista guardada (memoria o celular) y la refresca
  /// por detrás; solo la primera vez espera al servidor. Si algo falla (o el interruptor está apagado) devuelve vacío:
  /// un flyer que no carga nunca debe estorbar el listado de comercios.
  Future<List<PromoTallerBannerModel>> cargarPromocionesBanners({String? departamento}) =>
      PromocionesFlyersCache.paraMostrar(_seccionFlyers(departamento), () => _pedirPromociones(departamento));

  /// Se llama al abrir el app: trae la lista y baja las imágenes por adelantado, así el cuadro sale al instante al entrar a Comercios GO.
  Future<void> precargarPromociones({String? departamento}) async {
    await PromocionesFlyersCache.actualizar(_seccionFlyers(departamento), () => _pedirPromociones(departamento));
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

  /// Hay un filtro de categoría o de tipo de vehículo puesto (la búsqueda por texto no cuenta: se borra con su propia X).
  bool get hayFiltros => _categoriaFiltro != null || _tipoVehicularFiltro != null;

  /// Quita la categoría y el tipo de vehículo de una vez, con un solo pedido al servidor.
  Future<void> limpiarFiltros({String? departamento}) async {
    _categoriaFiltro = null;
    _tipoVehicularFiltro = null;
    await cargarComercios(departamento: departamento ?? _departamentoActual);
  }
}
