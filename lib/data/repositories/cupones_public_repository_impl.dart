import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/cupon_entity.dart';
import '../../domain/repositories/cupones_public_repository.dart';
import '../datasources/cupones_public_remote_datasource.dart';

class CuponesPublicRepositoryImpl implements CuponesPublicRepository {
  final CuponesPublicRemoteDataSource remoteDataSource;
  CuponesPublicRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CuponEntity>>> getPublicCupones() async {
    try {
      final models = await remoteDataSource.getPublicCupones();
      final entities = models.map((m) => m.toEntity()).toList();
      return Either.right(entities);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al obtener cupones públicos: $e'));
    }
  }
}
