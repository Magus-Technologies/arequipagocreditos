import '../entities/cupon_entity.dart';
import '../repositories/cupones_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

class GetCuponesUseCase {
  final CuponesRepository repository;
  
  GetCuponesUseCase(this.repository);
  
  Future<Either<Failure, List<CuponEntity>>> call({String? audiencia}) async {
    return await repository.getCupones(audiencia: audiencia);
  }
}

class UsarCuponUseCase {
  final CuponesRepository repository;
  
  UsarCuponUseCase(this.repository);
  
  Future<Either<Failure, Map<String, dynamic>>> call(int cuponId) async {
    if (cuponId <= 0) {
      return Either.left(const ValidationFailure('ID de cupón inválido'));
    }
    
    return await repository.usarCupon(cuponId);
  }
}

class FilterCuponesByCategoria {
  Future<Either<Failure, List<CuponEntity>>> call(
    List<CuponEntity> cupones, 
    String categoria
  ) async {
    try {
      if (categoria == 'Todos') {
        return Either.right(cupones);
      }
      
      final filteredCupones = cupones.where((cupon) => 
        _getCategoryDisplayName(cupon.categoria) == categoria
      ).toList();
      
      return Either.right(filteredCupones);
    } catch (e) {
      return Either.left(UnknownFailure('Error al filtrar cupones: $e'));
    }
  }
  
  String _getCategoryDisplayName(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'restaurantes':
      case 'comida':
      case 'food':
        return 'Restaurantes';
      case 'tiendas':
      case 'shopping':
        return 'Tiendas';
      case 'servicios':
      case 'services':
        return 'Servicios';
      case 'entretenimiento':
      case 'entertainment':
        return 'Entretenimiento';
      default:
        return 'Promociones';
    }
  }
}
