import '../entities/cupon_entity.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

abstract class CuponesRepository {
  Future<Either<Failure, List<CuponEntity>>> getCupones({String? audiencia});
  Future<Either<Failure, Map<String, dynamic>>> usarCupon(int cuponId);
  Future<Either<Failure, List<CuponEntity>>> getCuponesPorCategoria(String categoria);
}
