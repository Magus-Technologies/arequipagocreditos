import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/financiamiento_entity.dart';
import '../repositories/financiamiento_repository.dart';

class CreateFinanciamientoUseCase {
  final FinanciamientoRepository repository;

  CreateFinanciamientoUseCase(this.repository);

  Future<Either<Failure, FinanciamientoEntity>> call(Map<String, dynamic> data) async {
    return await repository.createFinanciamiento(data);
  }
}
