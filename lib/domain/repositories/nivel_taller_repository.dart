import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/nivel_taller_entity.dart';

abstract class NivelTallerRepository {
  Future<Either<Failure, NivelTallerEntity>> getMiNivel({required int clienteConductorId});
}
