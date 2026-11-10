import 'dart:io';
import 'dart:typed_data';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../data/models/evento_invitado.dart';
import '../../data/models/evento_models.dart';

abstract class EventoRepository {
  /// Los eventos próximos y los ya realizados. Sin persona solo salen los PÚBLICOS; con una persona válida (id + documento) también los
  /// privados (solo clientes GO).
  Future<Either<Failure, EventosListaModel>> getEventos({int? clienteConductorId, String? nroDocumento});

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

  // ---------------------------------------------------------------------------------------------------------------------
  // Invitado (sin cuenta): eventos PÚBLICOS (TK-0450)

  /// El evento público completo (con términos, política y QR de pago); `right(null)` si ya no está disponible o no es público.
  Future<Either<Failure, EventoModel?>> getEventoPublico(int eventoId);

  Future<Either<Failure, EventoCompraModel>> registrarCompraInvitado({
    required int eventoId,
    required EventoInvitado invitado,
    required int cantidad,
    required File captura,
  });

  Future<Either<Failure, List<EventoCompraModel>>> getMisComprasInvitado({
    required String nroDocumento,
    required String telefono,
  });

  Future<Either<Failure, EventoCompraModel>> subirCapturaInvitado({
    required int compraId,
    required String nroDocumento,
    required String telefono,
    required File captura,
  });

  Future<Either<Failure, Uint8List>> descargarTicketPdfInvitado({
    required int compraId,
    required String nroDocumento,
    required String telefono,
  });
}
