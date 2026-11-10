import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';

/// Documentos del cliente desde el app: sube uno (DNI/CE, recibo de servicios, licencia, documentos del vehículo… según su tipo de
/// cliente) y consulta la lista de «Mis documentos» con el estado de cada uno.
///
/// El documento NO entra directo: queda «en revisión» hasta que el personal lo apruebe en el dashboard (cualquiera puede subir
/// cualquier cosa). Las rutas del app son públicas: además del id se manda el número de documento de la cuenta.
///
/// Los errores de negocio (documento que ya está al día, formato, peso, cuenta eliminada) salen como [ValidationException] con el
/// mensaje del servidor, listo para mostrarse; lo demás (red, 5xx) sale como [ServerException].
class DocumentosPendientesRemoteDataSource {
  final http.Client client;

  DocumentosPendientesRemoteDataSource({required this.client});

  static const String _sinConexion = 'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.';

  /// Mismo tope que el servidor (6 MB): se avisa antes de gastar datos subiendo un archivo que va a rechazar.
  static const int maxBytes = 6 * 1024 * 1024;

  /// Envía el documento y devuelve los `datos_pendientes` ya actualizados.
  Future<List<Map<String, dynamic>>> subir({
    required int clienteId,
    required String nroDocumento,
    required String tipoDocumento,
    required File archivo,
  }) async {
    try {
      if (await archivo.length() > maxBytes) {
        throw const ValidationException('El archivo pesa más de 6 MB. Toma la foto de nuevo o elige uno más liviano.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.documentosPendientesEndpoint}'),
      )
        ..headers['Accept'] = 'application/json'
        ..fields['idConductor'] = clienteId.toString()
        ..fields['nro_documento'] = nroDocumento
        ..fields['tipo_documento'] = tipoDocumento;
      request.files.add(await http.MultipartFile.fromPath('archivo', archivo.path));

      final streamed = await client.send(request).timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);

      return _lista(_exigirExito(response)['datos_pendientes']);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(_sinConexion);
    }
  }

  /// La lista de «Mis documentos»: cada documento que su tipo de cliente puede subir, con `guardado` (y el nombre y la fecha del
  /// último), `envio` (`pendiente` o `rechazado` con su `motivo`) y `en_alerta` (lo pide su alerta de datos por actualizar).
  Future<List<Map<String, dynamic>>> listarMisDocumentos({required int clienteId, required String nroDocumento}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.misDocumentosEndpoint}').replace(
        queryParameters: {'idConductor': clienteId.toString(), 'nro_documento': nroDocumento},
      );
      final response = await client.get(uri, headers: ApiConstants.defaultHeaders).timeout(ApiConstants.receiveTimeout);

      return _lista(_exigirExito(response)['data']);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(_sinConexion);
    }
  }

  List<Map<String, dynamic>> _lista(Object? valor) =>
      valor is List ? valor.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

  /// El cuerpo de la respuesta si fue exitosa; si no, lanza con el mensaje del servidor.
  Map<String, dynamic> _exigirExito(http.Response response) {
    Map<String, dynamic>? body;
    try {
      final decoded = json.decode(response.body);
      body = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      body = null;
    }

    final mensaje = body?['message']?.toString().trim();
    final codigo = response.statusCode;

    if (codigo == 429) {
      throw const ValidationException('Demasiados intentos. Espera un momento e inténtalo de nuevo.');
    }
    if (codigo == 413) {
      throw const ValidationException('El archivo pesa demasiado. Toma la foto de nuevo o elige uno más liviano.');
    }
    if (codigo == 422 || codigo == 403 || codigo == 404 || codigo == 503) {
      throw ValidationException(mensaje != null && mensaje.isNotEmpty ? mensaje : 'No se pudo enviar el documento.');
    }
    if (codigo >= 200 && codigo < 300 && body != null && body['success'] != false) {
      return body;
    }
    throw ServerException(mensaje != null && mensaje.isNotEmpty ? mensaje : 'Error del servidor (HTTP $codigo). Intenta nuevamente.');
  }
}
