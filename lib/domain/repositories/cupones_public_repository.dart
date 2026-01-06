import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/cupon_entity.dart';

abstract class CuponesPublicRepository {
  Future<Either<Failure, List<CuponEntity>>> getPublicCupones();
}
