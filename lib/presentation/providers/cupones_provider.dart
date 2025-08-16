import 'package:flutter/material.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/cupon_entity.dart';
import '../../domain/usecases/cupones_usecases.dart';

enum CuponesStatus { initial, loading, loaded, error, using }

class CuponesProvider extends ChangeNotifier {
  final GetCuponesUseCase _getCuponesUseCase;
  final UsarCuponUseCase _usarCuponUseCase;
  final FilterCuponesByCategoria _filterCuponesByCategoria;
  
  CuponesProvider({
    required GetCuponesUseCase getCuponesUseCase,
    required UsarCuponUseCase usarCuponUseCase,
    required FilterCuponesByCategoria filterCuponesByCategoria,
  })  : _getCuponesUseCase = getCuponesUseCase,
        _usarCuponUseCase = usarCuponUseCase,
        _filterCuponesByCategoria = filterCuponesByCategoria;

  CuponesStatus _status = CuponesStatus.initial;
  List<CuponEntity> _allCupones = [];
  List<CuponEntity> _displayedCupones = [];
  String _selectedCategory = 'Todos';
  String? _errorMessage;
  bool _isUsingCupon = false;

  // Getters
  CuponesStatus get status => _status;
  List<CuponEntity> get cupones => _displayedCupones;
  List<CuponEntity> get allCupones => _allCupones;
  String get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CuponesStatus.loading;
  bool get isUsingCupon => _isUsingCupon;

  List<String> get availableCategories => [
    'Todos',
    'Restaurantes',
    'Tiendas',
    'Servicios',
    'Entretenimiento',
    'Promociones',
  ];

  // Métodos públicos
  Future<void> loadCupones() async {
    _setStatus(CuponesStatus.loading);
    
    final result = await _getCuponesUseCase();
    
    result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _setStatus(CuponesStatus.error);
      },
      (cupones) {
        _allCupones = cupones;
        _errorMessage = null;
        _filterByCategory(_selectedCategory);
        _setStatus(CuponesStatus.loaded);
      },
    );
  }

  Future<bool> usarCupon(int cuponId) async {
    _isUsingCupon = true;
    notifyListeners();
    
    final result = await _usarCuponUseCase(cuponId);
    
    _isUsingCupon = false;
    
    return result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
        return false;
      },
      (response) {
        // Recargar cupones después de usar uno
        loadCupones();
        return true;
      },
    );
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _filterByCategory(category);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Métodos privados
  void _setStatus(CuponesStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  Future<void> _filterByCategory(String category) async {
    final result = await _filterCuponesByCategoria(_allCupones, category);
    
    result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        _displayedCupones = _allCupones;
      },
      (filteredCupones) {
        _displayedCupones = filteredCupones;
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ValidationFailure _:
        return failure.message;
      case ServerFailure _:
        return 'Error del servidor. Intenta nuevamente.';
      case NetworkFailure _:
        return 'Sin conexión a internet. Verifica tu conexión.';
      case CacheFailure _:
        return 'Error de almacenamiento. Reinicia la aplicación.';
      default:
        return 'Ha ocurrido un error inesperado.';
    }
  }

  int get cuponesCount => _displayedCupones.length;
  
  int get cuponesDisponiblesCount => _displayedCupones.where((c) => c.puedeUsarse).length;
  
  List<CuponEntity> get cuponesDisponibles => _displayedCupones.where((c) => c.puedeUsarse).toList();
  
  List<CuponEntity> get cuponesVencidos => _displayedCupones.where((c) => c.estaVencido).toList();
}
