import 'package:flutter/foundation.dart';
import '../../domain/entities/financiamiento_entity.dart';
import '../../domain/entities/cuota_financiamiento_entity.dart';
import '../../domain/usecases/financiamiento_usecases.dart';
import '../../core/errors/failures.dart';

class FinanciamientoProvider extends ChangeNotifier {
  final GetFinanciamientosUseCase getFinanciamientosUseCase;
  final GetFinanciamientoByIdUseCase getFinanciamientoByIdUseCase;
  final GetCuotasFinanciamientoUseCase getCuotasFinanciamientoUseCase;
  final PagarCuotaUseCase pagarCuotaUseCase;
  final GenerarReporteCuotaUseCase generarReporteCuotaUseCase;

  FinanciamientoProvider({
    required this.getFinanciamientosUseCase,
    required this.getFinanciamientoByIdUseCase,
    required this.getCuotasFinanciamientoUseCase,
    required this.pagarCuotaUseCase,
    required this.generarReporteCuotaUseCase,
  });

  // Estado
  bool _isLoading = false;
  String? _errorMessage;
  List<FinanciamientoEntity> _financiamientos = [];
  FinanciamientoEntity? _currentFinanciamiento;
  List<CuotaFinanciamientoEntity> _cuotas = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FinanciamientoEntity> get financiamientos => _financiamientos;
  FinanciamientoEntity? get currentFinanciamiento => _currentFinanciamiento;
  List<CuotaFinanciamientoEntity> get cuotas => _cuotas;

  // Computed properties
  List<FinanciamientoEntity> get financiamientosActivos => 
      _financiamientos.where((f) => f.isActive).toList();

  List<FinanciamientoEntity> get financiamientosVencidos =>
      _financiamientos.where((f) => f.diasRestantes < 0).toList();

  double get totalDeuda => 
      _financiamientos.fold(0.0, (sum, f) {
        final monto = double.tryParse(f.montoTotal.replaceAll(',', '')) ?? 0.0;
        return sum + monto;
      });

  List<CuotaFinanciamientoEntity> get cuotasPendientes =>
      _cuotas.where((c) => c.isPending).toList();

  List<CuotaFinanciamientoEntity> get cuotasVencidas =>
      _cuotas.where((c) => c.isOverdue).toList();

  double get totalCuotasPendientes =>
      cuotasPendientes.fold(0.0, (sum, c) => sum + c.monto);

  // Métodos
  Future<void> loadFinanciamientos({int? idConductor, int tipo = 1}) async {
    _setLoading(true);
    
    if (idConductor == null) {
      _setError('ID de conductor requerido');
      _setLoading(false);
      return;
    }
    
    final result = await getFinanciamientosUseCase(idConductor, tipo);
    
    result.fold(
      (failure) => _setError(_getFailureMessage(failure)),
      (financiamientos) {
        _financiamientos = financiamientos;
        _clearError();
      },
    );
    
    _setLoading(false);
  }

  Future<void> loadFinanciamientoById(int id) async {
    _setLoading(true);
    
    final result = await getFinanciamientoByIdUseCase(id);
    
    result.fold(
      (failure) => _setError(_getFailureMessage(failure)),
      (financiamiento) {
        _currentFinanciamiento = financiamiento;
        _clearError();
      },
    );
    
    _setLoading(false);
  }

  Future<void> loadCuotasFinanciamiento(int financiamientoId) async {
    _setLoading(true);
    
    final result = await getCuotasFinanciamientoUseCase(financiamientoId);
    
    result.fold(
      (failure) => _setError(_getFailureMessage(failure)),
      (cuotas) {
        _cuotas = cuotas;
        _clearError();
      },
    );
    
    _setLoading(false);
  }

  Future<bool> pagarCuota({
    required int cuotaId,
    required double montoPago,
    String? metodoPago,
    String? referenciaPago,
  }) async {
    _setLoading(true);
    
    final result = await pagarCuotaUseCase(cuotaId, montoPago);
    
    bool success = false;
    result.fold(
      (failure) => _setError(_getFailureMessage(failure)),
      (cuotaActualizada) {
        success = true;
        _clearError();
        // Actualizar la cuota en la lista local
        _updateCuotaAfterPayment(cuotaId, cuotaActualizada);
      },
    );
    
    _setLoading(false);
    return success;
  }

  Future<String?> generarReporteCuota({
    required int cuotaId,
    String? tipoReporte = 'pdf',
  }) async {
    _setLoading(true);
    
    final result = await generarReporteCuotaUseCase(cuotaId);
    
    String? reporteUrl;
    result.fold(
      (failure) => _setError(_getFailureMessage(failure)),
      (url) {
        reporteUrl = url;
        _clearError();
      },
    );
    
    _setLoading(false);
    return reporteUrl;
  }

  // Métodos de filtrado y búsqueda
  List<FinanciamientoEntity> filterByEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return financiamientosActivos;
      case 'vencido':
        return financiamientosVencidos;
      case 'cancelado':
        return _financiamientos.where((f) => f.estado == 'cancelado').toList();
      default:
        return _financiamientos;
    }
  }

  List<FinanciamientoEntity> searchByNumero(String query) {
    if (query.isEmpty) return _financiamientos;
    
    return _financiamientos.where((f) => 
      f.grupoFinanciamiento.toLowerCase().contains(query.toLowerCase()) ||
      f.idFinanciamiento.toString().contains(query)
    ).toList();
  }

  List<CuotaFinanciamientoEntity> filterCuotasByEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return cuotasPendientes;
      case 'vencida':
        return cuotasVencidas;
      case 'pagada':
        return _cuotas.where((c) => c.estado == 'pagada').toList();
      default:
        return _cuotas;
    }
  }

  // Métodos de utilidad
  void clearData() {
    _financiamientos = [];
    _currentFinanciamiento = null;
    _cuotas = [];
    _clearError();
    notifyListeners();
  }

  void selectFinanciamiento(FinanciamientoEntity financiamiento) {
    _currentFinanciamiento = financiamiento;
    notifyListeners();
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _updateCuotaAfterPayment(int cuotaId, CuotaFinanciamientoEntity cuotaActualizada) {
    final index = _cuotas.indexWhere((c) => c.id == cuotaId);
    if (index != -1) {
      // Reemplazar la cuota con la actualizada que viene del servidor
      _cuotas[index] = cuotaActualizada;
      
      // Opcional: Reload financiamientos para obtener datos actualizados
      // En una implementación real, podrías hacer un refresh automático
    }
  }

  String _getFailureMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return 'Error del servidor. Intente nuevamente.';
      case NetworkFailure _:
        return 'Error de conexión. Verifique su internet.';
      case AuthenticationFailure _:
        return 'Sesión expirada. Inicie sesión nuevamente.';
      case ValidationFailure _:
        return 'Datos inválidos. Verifique la información.';
      default:
        return 'Error inesperado. Intente nuevamente.';
    }
  }
}
