import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/nivel_taller_entity.dart';
import '../../domain/usecases/get_nivel_taller_usecase.dart';

class NivelTallerProvider extends ChangeNotifier {
  final GetNivelTallerUseCase getNivelTallerUseCase;

  NivelTallerProvider({required this.getNivelTallerUseCase});

  NivelTallerEntity? _nivel;
  bool _isLoading = false;
  String _errorMessage = '';

  NivelTallerEntity? get nivel => _nivel;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  Future<void> cargarNivel(int clienteConductorId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await getNivelTallerUseCase(clienteConductorId: clienteConductorId);
      result.fold(
        (failure) => _handleFailure(failure),
        (nivel) {
          _nivel = nivel;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void _handleFailure(Failure failure) {
    _errorMessage = failure is ServerFailure
        ? 'Error del servidor. Intenta nuevamente.'
        : 'No se pudo cargar tu nivel. Intenta nuevamente.';
    notifyListeners();
  }
}
