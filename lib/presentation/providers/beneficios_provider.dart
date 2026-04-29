import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/beneficio_entity.dart';
import '../../domain/usecases/get_beneficios_comercial_usecase.dart';

class BeneficiosProvider extends ChangeNotifier {
  final GetBeneficiosComercialUseCase getBeneficiosComercialUseCase;

  BeneficiosProvider({
    required this.getBeneficiosComercialUseCase,
  });

  // Estado del provider
  List<BeneficioComercialEntity> _beneficios = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Failure? _failure;
  int _currentTipo = 1; // 1: Beneficio, 2: Servicio

  // Getters
  List<BeneficioComercialEntity> get beneficios => _beneficios;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Failure? get failure => _failure;
  int get currentTipo => _currentTipo;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get isEmpty => _beneficios.isEmpty && !_isLoading && !hasError;

  /// Obtiene la lista de beneficios comerciales
  Future<void> getBeneficios({int? tipo}) async {
    if (tipo != null) {
      _currentTipo = tipo;
    }
    
    _setLoading(true);
    _clearError();

    try {
      final result = await getBeneficiosComercialUseCase(tipo: _currentTipo);
      
      result.fold(
        (failure) => _handleFailure(failure),
        (beneficios) => _handleSuccess(beneficios),
      );
    } catch (e) {
      _handleError('Error inesperado: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Reintenta obtener los beneficios
  Future<void> retry() async {
    await getBeneficios(tipo: _currentTipo);
  }

  /// Actualiza/refresca la lista de beneficios
  Future<void> refresh() async {
    await getBeneficios(tipo: _currentTipo);
  }

  /// Busca beneficios por término de búsqueda
  List<BeneficioComercialEntity> searchBeneficios(String query) {
    if (query.isEmpty) return _beneficios;
    
    return _beneficios.where((beneficio) {
      return beneficio.nombre.toLowerCase().contains(query.toLowerCase()) ||
             beneficio.descripcion.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Filtra beneficios por categoría si es necesario
  List<BeneficioComercialEntity> filterByCategory(int? categoria) {
    if (categoria == null) return _beneficios;
    return _beneficios.where((beneficio) => beneficio.categoria == categoria).toList();
  }

  /// Obtiene un beneficio por ID
  BeneficioComercialEntity? getBeneficioById(int id) {
    try {
      return _beneficios.firstWhere((beneficio) => beneficio.id == id);
    } catch (e) {
      return null;
    }
  }

  // Métodos privados para manejo de estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    _failure = null;
    notifyListeners();
  }

  void _handleSuccess(List<BeneficioComercialEntity> beneficios) {
    _beneficios = beneficios;
    _clearError();
    notifyListeners();
  }

  void _handleFailure(Failure failure) {
    _failure = failure;
    
    if (failure is ServerFailure) {
      _errorMessage = 'Error del servidor. Intenta nuevamente.';
    } else if (failure is ValidationFailure) {
      _errorMessage = 'Datos inválidos. Verifica la información.';
    } else {
      _errorMessage = 'Error desconocido. Intenta nuevamente.';
    }
    
    notifyListeners();
  }

  void _handleError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Limpia todos los datos del provider
  void clear() {
    _beneficios.clear();
    _isLoading = false;
    _errorMessage = '';
    _failure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}