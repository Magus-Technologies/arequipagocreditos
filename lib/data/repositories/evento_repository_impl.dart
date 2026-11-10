import 'dart:io';
import 'dart:typed_data';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/repositories/evento_repository.dart';
import '../datasources/evento_remote_datasource.dart';
import '../models/evento_invitado.dart';
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
  Future<Either<Failure, EventosListaModel>> getEventos({int? clienteConductorId, String? nroDocumento}) {
    return _ejecutar(
      () => remoteDataSource.getEventos(clienteConductorId: clienteConductorId, nroDocumento: nroDocumento),
    );
  }

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

  // ---------------------------------------------------------------------------------------------------------------------
  // Invitado (sin cuenta): eventos PÚBLICOS

  @override
  Future<Either<Failure, EventoModel?>> getEventoPublico(int eventoId) {
    return _ejecutar(() => remoteDataSource.getEventoPublico(eventoId));
  }

  @override
  Future<Either<Failure, EventoCompraModel>> registrarCompraInvitado({
    required int eventoId,
    required EventoInvitado invitado,
    required int cantidad,
    required File captura,
  }) {
    return _ejecutar(
      () => remoteDataSource.registrarCompraInvitado(
        eventoId: eventoId,
        invitado: invitado,
        cantidad: cantidad,
        captura: captura,
      ),
    );
  }

  @override
  Future<Either<Failure, List<EventoCompraModel>>> getMisComprasInvitado({
    required String nroDocumento,
    required String telefono,
  }) {
    return _ejecutar(() => remoteDataSource.getMisComprasInvitado(nroDocumento: nroDocumento, telefono: telefono));
  }

  @override
  Future<Either<Failure, EventoCompraModel>> subirCapturaInvitado({
    required int compraId,
    required String nroDocumento,
    required String telefono,
    required File captura,
  }) {
    return _ejecutar(
      () => remoteDataSource.subirCapturaInvitado(
        compraId: compraId,
        nroDocumento: nroDocumento,
        telefono: telefono,
        captura: captura,
      ),
    );
  }

  @override
  Future<Either<Failure, Uint8List>> descargarTicketPdfInvitado({
    required int compraId,
    required String nroDocumento,
    required String telefono,
  }) {
    return _ejecutar(
      () => remoteDataSource.descargarTicketPdfInvitado(
        compraId: compraId,
        nroDocumento: nroDocumento,
        telefono: telefono,
      ),
    );
  }
}
