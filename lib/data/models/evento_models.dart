import '../../core/constants/api_constants.dart';

/// Modelos del módulo «Eventos» (venta de tickets). Forma JSON: contrato `/app/eventos/...`.
///
/// El servidor puede mandar los decimales como número o como texto ("50.00") y cualquier campo opcional como null:
/// todo se lee con tolerancia, nada lanza por un dato ausente.

double _toDouble(dynamic value) {
  if (value == null) return 0;
  return num.tryParse(value.toString())?.toDouble() ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  return num.tryParse(value.toString())?.toInt() ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final texto = value?.toString().trim().toLowerCase();
  return texto == 'true' || texto == '1';
}

/// Texto opcional: null si no vino o llegó vacío.
String? _toText(dynamic value) {
  final texto = value?.toString().trim();
  return texto == null || texto.isEmpty ? null : texto;
}

/// Fecha ISO 8601 del servidor como instante en UTC (NO en la zona del teléfono: la hora del evento se muestra siempre en hora de
/// Lima, ver `EventoFormato`). Con offset o «Z» el instante es exacto; una fecha sin offset se entiende como hora de Lima
/// (Perú es UTC-5 todo el año). Null si no vino o no se puede leer.
DateTime? _toDate(dynamic value) {
  final texto = _toText(value);
  if (texto == null) return null;
  final fecha = DateTime.tryParse(texto);
  if (fecha == null) return null;
  if (fecha.isUtc) return fecha; // venía con offset o «Z»: Dart ya lo pasó a UTC
  return DateTime.utc(fecha.year, fecha.month, fecha.day, fecha.hour, fecha.minute, fecha.second)
      .add(const Duration(hours: 5));
}

/// URL de imagen: absoluta tal cual, relativa con el host del backend. Null si no vino.
String? _toUrl(dynamic value) {
  final texto = _toText(value);
  if (texto == null) return null;
  return ApiConstants.normalizeUrl(texto);
}

/// Enlace del mapa (Google Maps u otro): solo se acepta un enlace http o https. Cualquier otra cosa (vacío, «javascript:», texto suelto) es «sin mapa»:
/// el botón «Cómo llegar» no aparece en vez de abrir algo raro.
String? _toEnlace(dynamic value) {
  final texto = _toText(value);
  if (texto == null) return null;
  final uri = Uri.tryParse(texto);
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) return null;
  return texto;
}

/// Cuántos tickets lleva esta persona en el evento y cuántos más puede comprar (tope por persona).
class MisTicketsModel {
  final int comprados;
  final int disponibles;

  const MisTicketsModel({required this.comprados, required this.disponibles});

  factory MisTicketsModel.fromJson(Map<String, dynamic> json) {
    return MisTicketsModel(
      comprados: _toInt(json['comprados']),
      disponibles: _toInt(json['disponibles']),
    );
  }
}

class EventoModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? lugar;

  /// Enlace de Google Maps del lugar (opcional). Con él las pantallas del evento ofrecen «Cómo llegar».
  final String? mapaUrl;

  /// Instante del evento en UTC. Para mostrarlo usar `EventoFormato.fechaHora` (hora de Lima).
  final DateTime? fechaHora;
  final String? bannerUrl;
  final double precioTicket;
  final int maxTicketsPorPersona;
  final String? terminos;
  final String? politicaPrivacidad;

  /// QR para pagar. Solo viene si el id y el DNI que mandó el app coinciden con una persona (hace falta para pagar ANTES de registrar la
  /// compra, que exige la captura del pago).
  final String? qrUrl;

  /// Solo viene si el id y el DNI que mandó el app coinciden con una persona.
  final MisTicketsModel? misTickets;

  const EventoModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.lugar,
    this.mapaUrl,
    this.fechaHora,
    this.bannerUrl,
    this.precioTicket = 0,
    this.maxTicketsPorPersona = 0,
    this.terminos,
    this.politicaPrivacidad,
    this.qrUrl,
    this.misTickets,
  });

  factory EventoModel.fromJson(Map<String, dynamic> json) {
    final mis = json['mis_tickets'];
    return EventoModel(
      id: _toInt(json['id']),
      nombre: _toText(json['nombre']) ?? 'Evento',
      descripcion: _toText(json['descripcion']),
      lugar: _toText(json['lugar']),
      mapaUrl: _toEnlace(json['mapa_url']),
      fechaHora: _toDate(json['fecha_hora']),
      bannerUrl: _toUrl(json['banner_url']),
      precioTicket: _toDouble(json['precio_ticket']),
      maxTicketsPorPersona: _toInt(json['max_tickets_por_persona']),
      terminos: _toText(json['terminos']),
      politicaPrivacidad: _toText(json['politica_privacidad']),
      qrUrl: _toUrl(json['qr_url']),
      misTickets: mis is Map ? MisTicketsModel.fromJson(Map<String, dynamic>.from(mis)) : null,
    );
  }

  EventoModel copyWith({MisTicketsModel? misTickets}) {
    return EventoModel(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      lugar: lugar,
      mapaUrl: mapaUrl,
      fechaHora: fechaHora,
      bannerUrl: bannerUrl,
      precioTicket: precioTicket,
      maxTicketsPorPersona: maxTicketsPorPersona,
      terminos: terminos,
      politicaPrivacidad: politicaPrivacidad,
      qrUrl: qrUrl,
      misTickets: misTickets ?? this.misTickets,
    );
  }

  /// ¿El evento trae un enlace de mapa que se puede abrir?
  bool get tieneMapa => mapaUrl != null;
}

/// Lo que muestra la pantalla «Eventos»: los próximos (del más cercano al más lejano) y los ya realizados (el más reciente primero).
/// Son eventos «de vitrina»: sin términos ni cupos de nadie, solo lo que se ve.
class EventosListaModel {
  final List<EventoModel> proximos;
  final List<EventoModel> anteriores;

  const EventosListaModel({this.proximos = const [], this.anteriores = const []});

  factory EventosListaModel.fromJson(Map<String, dynamic> json) {
    List<EventoModel> leer(dynamic lista) {
      if (lista is! List) return const [];
      return lista.whereType<Map>().map((e) => EventoModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    return EventosListaModel(proximos: leer(json['proximos']), anteriores: leer(json['anteriores']));
  }

  bool get vacia => proximos.isEmpty && anteriores.isEmpty;
}

/// Estados de una compra. `pendiente` → `confirmado` | `rechazado` | `anulado`; `confirmado` → `anulado`.
/// `rechazado` y `anulado` son finales y liberan cupo.
enum EstadoCompra { pendiente, confirmado, rechazado, anulado, desconocido }

class EventoCompraModel {
  final int id;
  final String codigo;
  final int eventoId;
  final String eventoNombre;
  final DateTime? fechaHoraEvento;
  final int cantidad;
  final double precioUnitario;
  final double montoTotal;

  /// Texto tal cual lo manda el servidor. Para decidir algo usar [estadoCompra].
  final String estado;
  final String? motivoRechazo;
  final String? capturaUrl;
  final String? qrUrl;

  /// Enlace de Google Maps del lugar del evento (opcional): el ticket ofrece «Cómo llegar» con él.
  final String? mapaUrl;
  final bool puedeSubirCaptura;
  final bool puedeCancelar;
  final DateTime? creadoEn;

  const EventoCompraModel({
    required this.id,
    required this.codigo,
    required this.eventoId,
    required this.eventoNombre,
    this.fechaHoraEvento,
    required this.cantidad,
    required this.precioUnitario,
    required this.montoTotal,
    required this.estado,
    this.motivoRechazo,
    this.capturaUrl,
    this.qrUrl,
    this.mapaUrl,
    this.puedeSubirCaptura = false,
    this.puedeCancelar = false,
    this.creadoEn,
  });

  factory EventoCompraModel.fromJson(Map<String, dynamic> json) {
    return EventoCompraModel(
      id: _toInt(json['id']),
      codigo: _toText(json['codigo']) ?? '',
      eventoId: _toInt(json['evento_id']),
      eventoNombre: _toText(json['evento_nombre']) ?? 'Evento',
      fechaHoraEvento: _toDate(json['fecha_hora_evento']),
      cantidad: _toInt(json['cantidad']),
      precioUnitario: _toDouble(json['precio_unitario']),
      montoTotal: _toDouble(json['monto_total']),
      estado: _toText(json['estado']) ?? '',
      motivoRechazo: _toText(json['motivo_rechazo']),
      capturaUrl: _toUrl(json['captura_url']),
      qrUrl: _toUrl(json['qr_url']),
      mapaUrl: _toEnlace(json['mapa_url']),
      puedeSubirCaptura: _toBool(json['puede_subir_captura']),
      puedeCancelar: _toBool(json['puede_cancelar']),
      creadoEn: _toDate(json['creado_en']),
    );
  }

  EstadoCompra get estadoCompra {
    switch (estado.trim().toLowerCase()) {
      case 'pendiente':
        return EstadoCompra.pendiente;
      case 'confirmado':
        return EstadoCompra.confirmado;
      case 'rechazado':
        return EstadoCompra.rechazado;
      case 'anulado':
        return EstadoCompra.anulado;
      default:
        return EstadoCompra.desconocido;
    }
  }

  bool get tieneCaptura => capturaUrl != null && capturaUrl!.isNotEmpty;

  /// Pendiente y confirmada cuentan para el tope por persona; rechazada y anulada lo liberan.
  bool get ocupaCupo => estadoCompra == EstadoCompra.pendiente || estadoCompra == EstadoCompra.confirmado;

  /// Texto del chip de estado. Una compra pendiente se ve distinto según haya subido ya la captura o no.
  String get etiquetaEstado {
    switch (estadoCompra) {
      case EstadoCompra.pendiente:
        return tieneCaptura ? 'En revisión' : 'Falta subir captura';
      case EstadoCompra.confirmado:
        return 'Confirmado';
      case EstadoCompra.rechazado:
        return 'Rechazado';
      case EstadoCompra.anulado:
        return 'Anulado';
      case EstadoCompra.desconocido:
        return estado.isEmpty ? 'Sin estado' : '${estado[0].toUpperCase()}${estado.substring(1)}';
    }
  }
}
