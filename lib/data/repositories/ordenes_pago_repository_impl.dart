import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/orden_pago_entity.dart';
import '../../domain/repositories/ordenes_pago_repository.dart';
import '../datasources/ordenes_pago_remote_datasource.dart';

class OrdenesPagoRepositoryImpl implements OrdenesPagoRepository {
  final OrdenesPagoRemoteDataSource remoteDataSource;

  OrdenesPagoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ListadoOrdenesPagoEntity>> getOrdenesPago({
    required int clienteId,
    bool incluirHistorial = false,
  }) async {
    try {
      final listado = await remoteDataSource.getOrdenesPago(
        clienteId: clienteId,
        incluirHistorial: incluirHistorial,
      );
      return Either.right(listado);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
