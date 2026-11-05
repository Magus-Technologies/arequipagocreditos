import 'dart:io';
import 'dart:typed_data';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/models/evento_models.dart';
import 'package:arequipagocreditos/domain/repositories/evento_repository.dart';

/// JSON de ejemplo igual al que manda el backend real de `/app/eventos/...` y un repositorio falso, compartidos por las pruebas de
/// «Eventos». El backend manda los precios como float (`50.0`), los códigos como `EV-` + 6 caracteres y las fechas con el offset
/// de Lima. Los textos decimales («50.00») se prueban aparte, como caso de tolerancia.

/// Código de compra como lo arma el backend.
const String codigoCompra = 'EV-K7M2QX';

/// «Ahora» fijo de las pruebas: sábado 14-nov-2026, 2:01 p. m. en Lima (el evento recién empezó). Así nada depende de la fecha real.
final DateTime ahoraDePrueba = DateTime.utc(2026, 11, 14, 19, 1);

Map<String, dynamic> eventoJson({Object? precio = 50.0, Object? mis = const {'comprados': 1, 'disponibles': 3}}) => {
      'id': 7,
      'nombre': '3er Aniversario Arequipa Go',
      'descripcion': 'Música, sorteos y bingo',
      'lugar': 'Local de la empresa',
      'fecha_hora': '2026-11-14T14:00:00-05:00',
      'banner_url': 'https://credigo.test/storage/eventos/banners/aniversario.webp',
      'precio_ticket': precio,
      'max_tickets_por_persona': 4,
      'terminos': 'Primera línea.\nSegunda línea.',
      'politica_privacidad': 'Tus datos se usan solo para el evento.',
      'mis_tickets': mis,
    };

Map<String, dynamic> compraJson({
  String estado = 'pendiente',
  Object? capturaUrl,
  Object? puedeSubir = true,
  Object? puedeCancelar = true,
  Object? precioUnitario = 50.0,
  Object? montoTotal = 100.0,
  String? motivo,
}) =>
    {
      'id': 31,
      'codigo': codigoCompra,
      'evento_id': 7,
      'evento_nombre': '3er Aniversario Arequipa Go',
      'fecha_hora_evento': '2026-11-14T14:00:00-05:00',
      'cantidad': 2,
      'precio_unitario': precioUnitario,
      'monto_total': montoTotal,
      'estado': estado,
      'motivo_rechazo': motivo,
      'captura_url': capturaUrl,
      'qr_url': 'https://credigo.test/storage/eventos/qr/qr.png',
      'puede_subir_captura': puedeSubir,
      'puede_cancelar': puedeCancelar,
      'creado_en': '2026-11-04T12:30:00-05:00',
    };

/// Evento con un máximo por persona y los tickets que ya lleva (`null` = el servidor no mandó `mis_tickets`).
EventoModel evento({
  int max = 4,
  int? comprados,
  int id = 7,
  Object? precio = 50.0,
  bool conBanner = true,
  bool conQr = true,
  String? descripcion = 'Música, sorteos y bingo',
}) =>
    EventoModel.fromJson({
      ...eventoJson(
        precio: precio,
        mis: comprados == null ? null : {'comprados': comprados, 'disponibles': max - comprados},
      ),
      'id': id,
      'max_tickets_por_persona': max,
      'descripcion': descripcion,
      if (!conBanner) 'banner_url': null,
      // El QR de pago llega con el evento solo cuando la persona está identificada (la compra exige la captura del pago).
      if (conQr) 'qr_url': 'https://credigo.test/storage/eventos/qr/qr.png',
    });

EventoCompraModel compra({
  int id = 31,
  String estado = 'pendiente',
  int cantidad = 2,
  String? captura,
  bool puedeCancelar = true,
  bool puedeSubir = true,
  String? motivo,
  double precioUnitario = 50.0,
  double? montoTotal,
  String? fechaHoraEvento,
}) =>
    EventoCompraModel.fromJson({
      ...compraJson(
        estado: estado,
        capturaUrl: captura,
        puedeCancelar: puedeCancelar,
        puedeSubir: puedeSubir,
        motivo: motivo,
        precioUnitario: precioUnitario,
        montoTotal: montoTotal ?? cantidad * precioUnitario,
      ),
      'id': id,
      'cantidad': cantidad,
      if (fechaHoraEvento != null) 'fecha_hora_evento': fechaHoraEvento,
    });

Either<Failure, EventoModel?> activo(EventoModel? e) => Either.right(e);

class FakeEventoRepository implements EventoRepository {
  /// Respuesta de `getEventos` (la pantalla «Eventos»).
  Either<Failure, EventosListaModel> lista = Either.right(const EventosListaModel());
  int llamadasLista = 0;

  @override
  Future<Either<Failure, EventosListaModel>> getEventos() async {
    llamadasLista++;
    final respuesta = lista;
    await Future<void>.delayed(Duration.zero);
    return respuesta;
  }

  /// Cada llamada a getEventoActivo devuelve la siguiente respuesta; la última se repite.
  List<Either<Failure, EventoModel?>> activo = [];
  Either<Failure, List<EventoCompraModel>> misCompras = Either.right(const []);
  Either<Failure, EventoCompraModel>? compra;
  Either<Failure, EventoCompraModel>? captura;
  Either<Failure, EventoCompraModel>? cancelar;

  int llamadasActivo = 0;
  int llamadasMisCompras = 0;
  int llamadasRegistrar = 0;
  int llamadasCancelar = 0;
  int? ultimaCantidad;

  /// La captura con la que se pidió la última compra (la compra exige captura).
  File? ultimaCapturaDeCompra;

  /// Lo que responde el servidor al pedir el PDF del ticket (por defecto, un «PDF» de mentira que empieza con %PDF-).
  Either<Failure, Uint8List> ticketPdf = Either.right(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 1, 2, 3]));
  int llamadasTicketPdf = 0;
  int? ultimaCompraDelTicket;
  int? ultimaPersonaId;
  String? ultimoDocumento;

  @override
  Future<Either<Failure, Uint8List>> descargarTicketPdf({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
  }) async {
    llamadasTicketPdf++;
    ultimaCompraDelTicket = compraId;
    await Future<void>.delayed(Duration.zero);
    return ticketPdf;
  }

  @override
  Future<Either<Failure, EventoModel?>> getEventoActivo({int? clienteConductorId, String? nroDocumento}) async {
    ultimaPersonaId = clienteConductorId;
    ultimoDocumento = nroDocumento;
    final i = llamadasActivo < activo.length ? llamadasActivo : activo.length - 1;
    llamadasActivo++;
    await Future<void>.delayed(Duration.zero);
    return activo[i];
  }

  @override
  Future<Either<Failure, List<EventoCompraModel>>> getMisCompras({
    required int clienteConductorId,
    required String nroDocumento,
  }) async {
    llamadasMisCompras++;
    final respuesta = misCompras; // la que había al llamar, no la que haya cuando «llegue»
    await Future<void>.delayed(Duration.zero);
    return respuesta;
  }

  @override
  Future<Either<Failure, EventoCompraModel>> registrarCompra({
    required int eventoId,
    required int clienteConductorId,
    required String nroDocumento,
    required int cantidad,
    required File captura,
  }) async {
    llamadasRegistrar++;
    ultimaCantidad = cantidad;
    ultimaCapturaDeCompra = captura;
    await Future<void>.delayed(Duration.zero);
    return compra!;
  }

  @override
  Future<Either<Failure, EventoCompraModel>> subirCaptura({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
    required File captura,
  }) async =>
      this.captura!;

  @override
  Future<Either<Failure, EventoCompraModel>> cancelarCompra({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
  }) async {
    llamadasCancelar++;
    return cancelar!;
  }
}
