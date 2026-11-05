import 'dart:io';
import 'dart:typed_data';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../data/models/evento_models.dart';

abstract class EventoRepository {
  /// Los eventos próximos y los ya realizados (sin identificar a nadie).
  Future<Either<Failure, EventosListaModel>> getEventos();

  /// Evento activo más próximo; `right(null)` si no hay ninguno.
  Future<Either<Failure, EventoModel?>> getEventoActivo({int? clienteConductorId, String? nroDocumento});

  Future<Either<Failure, List<EventoCompraModel>>> getMisCompras({
    required int clienteConductorId,
    required String nroDocumento,
  });

  Future<Either<Failure, EventoCompraModel>> registrarCompra({
    required int eventoId,
    required int clienteConductorId,
    required String nroDocumento,
    required int cantidad,
    required File captura,
  });

  Future<Either<Failure, EventoCompraModel>> subirCaptura({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
    required File captura,
  });

  Future<Either<Failure, EventoCompraModel>> cancelarCompra({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
  });

  /// El PDF del ticket de una compra CONFIRMADA, armado por el servidor.
  Future<Either<Failure, Uint8List>> descargarTicketPdf({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
  });
}
