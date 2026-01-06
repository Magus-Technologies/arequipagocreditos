import '../../core/utils/either.dart';
import '../entities/cupon_entity.dart';
import '../repositories/cupones_public_repository.dart';

class GetPublicCuponesUseCase {
  final CuponesPublicRepository repository;
  GetPublicCuponesUseCase(this.repository);

  Future<Either<dynamic, List<CuponEntity>>> call() async {
    return await repository.getPublicCupones();
  }
}
