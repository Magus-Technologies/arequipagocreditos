import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/orden_pago_entity.dart';

abstract class OrdenesPagoRepository {
  Future<Either<Failure, ListadoOrdenesPagoEntity>> getOrdenesPago({
    required int clienteId,
    bool incluirHistorial = false,
  });
}
