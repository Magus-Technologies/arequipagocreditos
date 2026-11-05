import 'dart:io';
import 'dart:typed_data';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/repositories/evento_repository.dart';
import '../datasources/evento_remote_datasource.dart';
import '../models/evento_models.dart';

class EventoRepositoryImpl implements EventoRepository {
  final EventoRemoteDataSource remoteDataSource;

  EventoRepositoryImpl({required this.remoteDataSource});

  /// Un error de negocio (tope, evento vencido) se distingue de uno técnico: el primero se muestra tal cual a la persona.
  Future<Either<Failure, T>> _ejecutar<T>(Future<T> Function() accion) async {
    try {
      return Either.right(await accion());
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EventosListaModel>> getEventos() => _ejecutar(remoteDataSource.getEventos);

  @override
  Future<Either<Failure, EventoModel?>> getEventoActivo({int? clienteConductorId, String? nroDocumento}) {
    return _ejecutar(
      () => remoteDataSource.getEventoActivo(clienteConductorId: clienteConductorId, nroDocumento: nroDocumento),
    );
  }

  @override
  Future<Either<Failure, List<EventoCompraModel>>> getMisCompras({
    required int clienteConductorId,
    required String nroDocumento,
  }) {
    return _ejecutar(
      () => remoteDataSource.getMisCompras(clienteConductorId: clienteConductorId, nroDocumento: nroDocumento),
    );
  }

  @override
  Future<Either<Failure, EventoCompraModel>> registrarCompra({
    required int eventoId,
    required int clienteConductorId,
    required String nroDocumento,
    required int cantidad,
    required File captura,
  }) {
    return _ejecutar(
      () => remoteDataSource.registrarCompra(
        eventoId: eventoId,
        clienteConductorId: clienteConductorId,
        nroDocumento: nroDocumento,
        cantidad: cantidad,
        captura: captura,
      ),
    );
  }

  @override
  Future<Either<Failure, EventoCompraModel>> subirCaptura({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
    required File captura,
  }) {
    return _ejecutar(
      () => remoteDataSource.subirCaptura(
        compraId: compraId,
        clienteConductorId: clienteConductorId,
        nroDocumento: nroDocumento,
        captura: captura,
      ),
    );
  }

  @override
  Future<Either<Failure, EventoCompraModel>> cancelarCompra({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
  }) {
    return _ejecutar(
      () => remoteDataSource.cancelarCompra(
        compraId: compraId,
        clienteConductorId: clienteConductorId,
        nroDocumento: nroDocumento,
      ),
    );
  }

  @override
  Future<Either<Failure, Uint8List>> descargarTicketPdf({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
  }) {
    return _ejecutar(
      () => remoteDataSource.descargarTicketPdf(
        compraId: compraId,
        clienteConductorId: clienteConductorId,
        nroDocumento: nroDocumento,
      ),
    );
  }
}
