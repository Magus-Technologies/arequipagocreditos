import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/evento_invitado.dart';
import '../models/evento_models.dart';

/// Endpoints públicos `/app/eventos/...` (sin token). Los de una persona REGISTRADA piden `cliente_conductor_id` + `nro_documento`
/// (deben coincidir); en la lista y en `activo` son opcionales (con ellos se ven también los eventos privados). Los de un INVITADO
/// (TK-0450: compra de un evento público sin cuenta) piden `nro_documento` + `telefono` del comprador.
///
/// Los errores de negocio (422 tope excedido, evento vencido, 403, 404) salen como [ValidationException] con el mensaje del
/// servidor, listo para mostrarse; lo demás (red, 5xx) sale como [ServerException].
abstract class EventoRemoteDataSource {
  /// Los eventos que se pueden ver: los próximos y los ya realizados. Sin persona, solo los PÚBLICOS; con persona válida, también los
  /// privados.
  Future<EventosListaModel> getEventos({int? clienteConductorId, String? nroDocumento});

  /// Evento activo más próximo, o null si no hay.
  Future<EventoModel?> getEventoActivo({int? clienteConductorId, String? nroDocumento});

  Future<List<EventoCompraModel>> getMisCompras({required int clienteConductorId, required String nroDocumento});

  /// La captura del pago es OBLIGATORIA: la compra solo se registra con ella (viaja en la misma solicitud).
  Future<EventoCompraModel> registrarCompra({
    required int eventoId,
    required int clienteConductorId,
    required String nroDocumento,
    required int cantidad,
    required File captura,
  });

  Future<EventoCompraModel> subirCaptura({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
    required File captura,
  });

  Future<EventoCompraModel> cancelarCompra({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
  });

  /// El ticket de una compra CONFIRMADA como PDF. Lo arma el SERVIDOR (su diseño se cambia allá, sin publicar otro app).
  Future<Uint8List> descargarTicketPdf({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
  });

  // ---------------------------------------------------------------------------------------------------------------------
  // Invitado (sin cuenta): eventos PÚBLICOS

  /// El evento público completo (términos, política y QR de pago incluidos), o null si ya no está disponible o no es público.
  Future<EventoModel?> getEventoPublico(int eventoId);

  Future<EventoCompraModel> registrarCompraInvitado({
    required int eventoId,
    required EventoInvitado invitado,
    required int cantidad,
    required File captura,
  });

  Future<List<EventoCompraModel>> getMisComprasInvitado({required String nroDocumento, required String telefono});

  Future<EventoCompraModel> subirCapturaInvitado({
    required int compraId,
    required String nroDocumento,
    required String telefono,
    required File captura,
  });

  Future<Uint8List> descargarTicketPdfInvitado({
    required int compraId,
    required String nroDocumento,
    required String telefono,
  });
}

class EventoRemoteDataSourceImpl implements EventoRemoteDataSource {
  final http.Client client;

  EventoRemoteDataSourceImpl({required this.client});

  static const String _sinConexion = 'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.';

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Map<String, String> _persona(int clienteConductorId, String nroDocumento) => {
        'cliente_conductor_id': clienteConductorId.toString(),
        'nro_documento': nroDocumento,
      };

  /// Qué eventos se piden en la lista y en «activo»: con la persona de la sesión (id + documento) el servidor devuelve los públicos Y
  /// los privados; SIN sesión se manda `solo_publicos=1` (así solo salen los públicos). Un app antiguo que no manda ninguno de los dos
  /// recibe todo, como hasta ahora: por eso el app nuevo sin sesión lo dice explícitamente.
  Map<String, String> _filtroVisibilidad(int? clienteConductorId, String? nroDocumento) {
    if (clienteConductorId == null || nroDocumento == null || nroDocumento.isEmpty) return const {'solo_publicos': '1'};
    return _persona(clienteConductorId, nroDocumento);
  }

  Map<String, String> _comprador(String nroDocumento, String telefono) => {
        'nro_documento': nroDocumento,
        'telefono': telefono,
      };

  Map<String, dynamic>? _decode(http.Response response) {
    try {
      final body = json.decode(response.body);
      return body is Map ? Map<String, dynamic>.from(body) : null;
    } catch (_) {
      return null;
    }
  }

  /// Lo que el servidor dice que pasó: su `message`; si no vino, el primer texto de `errors` (formato de validación de Laravel:
  /// `{"message": "...", "errors": {"campo": ["texto"]}}`).
  String? _mensajeDe(Map<String, dynamic>? body) {
    final mensaje = body?['message']?.toString().trim();
    if (mensaje != null && mensaje.isNotEmpty) return mensaje;

    final errores = body?['errors'];
    if (errores is Map) {
      for (final valor in errores.values) {
        final texto = (valor is List ? (valor.isEmpty ? null : valor.first) : valor)?.toString().trim();
        if (texto != null && texto.isNotEmpty) return texto;
      }
    }
    return null;
  }

  /// Devuelve el cuerpo si la respuesta fue exitosa; si no, lanza con el mensaje del servidor.
  Map<String, dynamic> _exigirExito(http.Response response) {
    final body = _decode(response);
    final mensaje = _mensajeDe(body);
    final codigo = response.statusCode;

    if (codigo == 429) {
      throw const ValidationException('Demasiados intentos. Espera un momento e inténtalo de nuevo.');
    }
    if (codigo == 404 && body?['success'] != false) {
      // Un 404 que no armó credigo (ruta o modelo inexistente) trae texto técnico en inglés: no se le muestra a la persona.
      throw const ValidationException('El evento o la compra ya no está disponible.');
    }
    if (codigo == 422 || codigo == 403 || codigo == 404 || codigo == 409) {
      throw ValidationException(mensaje ?? 'No se pudo completar la operación.');
    }
    if (codigo >= 200 && codigo < 300 && body != null && body['success'] != false) {
      return body;
    }
    throw ServerException(mensaje ?? 'Error del servidor (HTTP $codigo). Intenta nuevamente.');
  }

  EventoCompraModel _compra(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! Map) {
      throw const ServerException('El servidor no devolvió la compra. Intenta nuevamente.');
    }
    return EventoCompraModel.fromJson(Map<String, dynamic>.from(data));
  }

  List<EventoCompraModel> _compras(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! List) return const [];
    return data.whereType<Map>().map((c) => EventoCompraModel.fromJson(Map<String, dynamic>.from(c))).toList();
  }

  Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(_sinConexion);
    }
  }

  @override
  Future<EventosListaModel> getEventos({int? clienteConductorId, String? nroDocumento}) {
    return _proteger(() async {
      final response = await client
          .get(
            _uri(ApiConstants.eventosListaEndpoint, _filtroVisibilidad(clienteConductorId, nroDocumento)),
            headers: ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.receiveTimeout);

      final data = _exigirExito(response)['data'];
      if (data is! Map) return const EventosListaModel();
      return EventosListaModel.fromJson(Map<String, dynamic>.from(data));
    });
  }

  @override
  Future<EventoModel?> getEventoActivo({int? clienteConductorId, String? nroDocumento}) {
    return _proteger(() async {
      final response = await client
          .get(
            _uri(ApiConstants.eventoActivoEndpoint, _filtroVisibilidad(clienteConductorId, nroDocumento)),
            headers: ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.receiveTimeout);

      final body = _exigirExito(response);
      final data = body['data'];
      if (data is! Map) return null;
      return EventoModel.fromJson(Map<String, dynamic>.from(data));
    });
  }

  @override
  Future<List<EventoCompraModel>> getMisCompras({required int clienteConductorId, required String nroDocumento}) {
    return _proteger(() async {
      final response = await client
          .get(
            _uri(ApiConstants.eventoMisComprasEndpoint, _persona(clienteConductorId, nroDocumento)),
            headers: ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.receiveTimeout);

      return _compras(_exigirExito(response));
    });
  }

  @override
  Future<EventoCompraModel> registrarCompra({
    required int eventoId,
    required int clienteConductorId,
    required String nroDocumento,
    required int cantidad,
    required File captura,
  }) {
    return _proteger(() async {
      final path = ApiConstants.eventoComprasEndpoint.replaceAll('{id}', eventoId.toString());
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers['Accept'] = 'application/json'
        ..fields.addAll(_persona(clienteConductorId, nroDocumento))
        ..fields['cantidad'] = cantidad.toString()
        ..fields['acepta_terminos'] = '1'
        ..files.add(await http.MultipartFile.fromPath('captura', captura.path));

      // Una foto de celular tarda más que un JSON: mismo margen que al subir la captura de una compra.
      final streamed = await client.send(request).timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);
      return _compra(_exigirExito(response));
    });
  }

  @override
  Future<EventoCompraModel> subirCaptura({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
    required File captura,
  }) {
    return _proteger(() async {
      final path = ApiConstants.eventoCompraCapturaEndpoint.replaceAll('{id}', compraId.toString());
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers['Accept'] = 'application/json'
        ..fields.addAll(_persona(clienteConductorId, nroDocumento))
        ..files.add(await http.MultipartFile.fromPath('captura', captura.path));

      // Una foto de celular tarda más que un JSON: mismo margen que la captura de IziPay.
      final streamed = await client.send(request).timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);
      return _compra(_exigirExito(response));
    });
  }

  /// Baja el PDF del ticket (con o sin persona: `consulta` trae los datos que piden las dos variantes). Un error del servidor sale
  /// con su mensaje.
  Future<Uint8List> _bajarPdf(String path, Map<String, String> consulta) async {
    final response = await client
        .get(
          _uri(path, consulta),
          // Con «json» en el Accept, Laravel contesta los errores en JSON (con su mensaje) y no con una página HTML.
          headers: const {'Accept': 'application/pdf, application/json'},
        )
        .timeout(const Duration(seconds: 60));

    final tipo = (response.headers['content-type'] ?? '').toLowerCase();
    if (response.statusCode == 200 && tipo.contains('application/pdf') && response.bodyBytes.isNotEmpty) {
      return response.bodyBytes;
    }
    // Un error del servidor (422 «se habilita cuando confirmemos tu pago», 403, 404…) sale con su mensaje.
    _exigirExito(response);
    throw const ServerException('El servidor no devolvió el ticket. Intenta nuevamente.');
  }

  @override
  Future<Uint8List> descargarTicketPdf({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
  }) {
    return _proteger(() {
      final path = ApiConstants.eventoCompraTicketPdfEndpoint.replaceAll('{id}', compraId.toString());
      return _bajarPdf(path, _persona(clienteConductorId, nroDocumento));
    });
  }

  @override
  Future<EventoCompraModel> cancelarCompra({
    required int compraId,
    required int clienteConductorId,
    required String nroDocumento,
  }) {
    return _proteger(() async {
      final path = ApiConstants.eventoCompraCancelarEndpoint.replaceAll('{id}', compraId.toString());
      final response = await client
          .post(
            _uri(path),
            headers: ApiConstants.defaultHeaders,
            body: json.encode({
              'cliente_conductor_id': clienteConductorId,
              'nro_documento': nroDocumento,
            }),
          )
          .timeout(ApiConstants.receiveTimeout);

      return _compra(_exigirExito(response));
    });
  }

  // ---------------------------------------------------------------------------------------------------------------------
  // Invitado (sin cuenta)

  @override
  Future<EventoModel?> getEventoPublico(int eventoId) {
    return _proteger(() async {
      final path = ApiConstants.eventoPublicoEndpoint.replaceAll('{id}', eventoId.toString());
      final response = await client.get(_uri(path), headers: ApiConstants.defaultHeaders).timeout(ApiConstants.receiveTimeout);

      // 404: el evento ya no está disponible, es privado o no existe. No es un error de red: simplemente no hay evento que comprar.
      if (response.statusCode == 404) return null;

      final data = _exigirExito(response)['data'];
      if (data is! Map) return null;
      return EventoModel.fromJson(Map<String, dynamic>.from(data));
    });
  }

  @override
  Future<EventoCompraModel> registrarCompraInvitado({
    required int eventoId,
    required EventoInvitado invitado,
    required int cantidad,
    required File captura,
  }) {
    return _proteger(() async {
      final path = ApiConstants.eventoComprasInvitadoEndpoint.replaceAll('{id}', eventoId.toString());
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers['Accept'] = 'application/json'
        ..fields['nombre'] = invitado.nombre
        ..fields['nro_documento'] = invitado.documento
        ..fields['telefono'] = invitado.telefono
        ..fields['cantidad'] = cantidad.toString()
        ..fields['acepta_terminos'] = '1'
        ..files.add(await http.MultipartFile.fromPath('captura', captura.path));
      final correo = invitado.correo;
      if (correo != null && correo.isNotEmpty) request.fields['correo'] = correo;

      final streamed = await client.send(request).timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);
      return _compra(_exigirExito(response));
    });
  }

  @override
  Future<List<EventoCompraModel>> getMisComprasInvitado({required String nroDocumento, required String telefono}) {
    return _proteger(() async {
      final response = await client
          .get(
            _uri(ApiConstants.eventoMisComprasInvitadoEndpoint, _comprador(nroDocumento, telefono)),
            headers: ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.receiveTimeout);

      return _compras(_exigirExito(response));
    });
  }

  @override
  Future<EventoCompraModel> subirCapturaInvitado({
    required int compraId,
    required String nroDocumento,
    required String telefono,
    required File captura,
  }) {
    return _proteger(() async {
      final path = ApiConstants.eventoCompraInvitadoCapturaEndpoint.replaceAll('{id}', compraId.toString());
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers['Accept'] = 'application/json'
        ..fields.addAll(_comprador(nroDocumento, telefono))
        ..files.add(await http.MultipartFile.fromPath('captura', captura.path));

      final streamed = await client.send(request).timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);
      return _compra(_exigirExito(response));
    });
  }

  @override
  Future<Uint8List> descargarTicketPdfInvitado({
    required int compraId,
    required String nroDocumento,
    required String telefono,
  }) {
    return _proteger(() {
      final path = ApiConstants.eventoCompraInvitadoTicketPdfEndpoint.replaceAll('{id}', compraId.toString());
      return _bajarPdf(path, _comprador(nroDocumento, telefono));
    });
  }
}
