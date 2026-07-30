import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/orden_pago_entity.dart';
import '../repositories/ordenes_pago_repository.dart';

class GetOrdenesPagoUseCase {
  final OrdenesPagoRepository repository;

  GetOrdenesPagoUseCase(this.repository);

  Future<Either<Failure, ListadoOrdenesPagoEntity>> call({
    required int clienteId,
    bool incluirHistorial = false,
  }) async {
    return await repository.getOrdenesPago(
      clienteId: clienteId,
      incluirHistorial: incluirHistorial,
    );
  }
}
