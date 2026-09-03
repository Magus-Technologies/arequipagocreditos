import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/nivel_taller_entity.dart';
import '../../domain/repositories/nivel_taller_repository.dart';
import '../datasources/nivel_taller_remote_datasource.dart';

class NivelTallerRepositoryImpl implements NivelTallerRepository {
  final NivelTallerRemoteDataSource remoteDataSource;

  NivelTallerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, NivelTallerEntity>> getMiNivel({required int clienteConductorId}) async {
    try {
      final nivel = await remoteDataSource.getMiNivel(clienteConductorId: clienteConductorId);
      return Either.right(nivel);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
