import 'package:flutter/material.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/cupon_entity.dart';
import '../../domain/usecases/get_public_cupones_usecase.dart';

enum PublicCuponesStatus { initial, loading, loaded, error }

class CuponesPublicProvider extends ChangeNotifier {
  final GetPublicCuponesUseCase _getPublicCuponesUseCase;
  CuponesPublicProvider({required GetPublicCuponesUseCase getPublicCuponesUseCase}) : _getPublicCuponesUseCase = getPublicCuponesUseCase;

  PublicCuponesStatus _status = PublicCuponesStatus.initial;
  List<CuponEntity> _cupones = [];
  String? _errorMessage;

  PublicCuponesStatus get status => _status;
  List<CuponEntity> get cupones => _cupones;
  bool get isLoading => _status == PublicCuponesStatus.loading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPublicCupones() async {
    _status = PublicCuponesStatus.loading;
    notifyListeners();

    final result = await _getPublicCuponesUseCase();

    result.fold((failure) {
      _errorMessage = _mapFailureToMessage(failure);
      _status = PublicCuponesStatus.error;
      notifyListeners();
    }, (cupones) {
      _cupones = cupones;
      _errorMessage = null;
      _status = PublicCuponesStatus.loaded;
      notifyListeners();
    });
  }

  String _mapFailureToMessage(dynamic failure) {
    if (failure is Failure) {
      switch (failure.runtimeType) {
        case const (ServerFailure):
          return 'Error del servidor. Intenta nuevamente.';
        case const (NetworkFailure):
          return 'Sin conexión a internet. Verifica tu conexión.';
        default:
          return failure.message;
      }
    }
    return 'Ha ocurrido un error.';
  }
}
