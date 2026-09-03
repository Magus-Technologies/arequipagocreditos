import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/nivel_taller_entity.dart';
import '../repositories/nivel_taller_repository.dart';

class GetNivelTallerUseCase {
  final NivelTallerRepository repository;

  GetNivelTallerUseCase(this.repository);

  Future<Either<Failure, NivelTallerEntity>> call({required int clienteConductorId}) async {
    return await repository.getMiNivel(clienteConductorId: clienteConductorId);
  }
}
