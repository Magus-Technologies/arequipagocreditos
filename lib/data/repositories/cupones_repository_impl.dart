import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/cupon_entity.dart';
import '../../domain/repositories/cupones_repository.dart';
import '../datasources/cupones_remote_datasource.dart';

class CuponesRepositoryImpl implements CuponesRepository {
  final CuponesRemoteDataSource remoteDataSource;
  
  CuponesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CuponEntity>>> getCupones({String? audiencia}) async {
    try {
      final cuponesModels = await remoteDataSource.getCupones(audiencia: audiencia);
      final cuponesEntities = cuponesModels
          .map((model) => model.toEntity())
          .toList();
      return Either.right(cuponesEntities);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al obtener cupones: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> usarCupon(int cuponId) async {
    try {
      final result = await remoteDataSource.usarCupon(cuponId);
      return Either.right(result);
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al usar cupón: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CuponEntity>>> getCuponesPorCategoria(String categoria) async {
    try {
      final allCupones = await getCupones();
      
      return allCupones.fold(
        (failure) => Either.left(failure),
        (cupones) {
          if (categoria == 'Todos') {
            return Either.right(cupones);
          }
          
          final filteredCupones = cupones.where((cupon) => 
            _getCategoryDisplayName(cupon.categoria) == categoria
          ).toList();
          
          return Either.right(filteredCupones);
        },
      );
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
