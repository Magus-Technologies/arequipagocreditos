import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/errors/exceptions.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/posicion_firma.dart';

abstract class SignatureRemoteDataSource {
  Future<Map<String, dynamic>> firmar({
    required String tipo,
    required int id,
    required String firmaBase64,
    required String nroDocumento,
    PosicionFirma? posicion,
    int? version,
  });
}

class SignatureRemoteDataSourceImpl implements SignatureRemoteDataSource {
  final http.Client client;

  SignatureRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> firmar({
    required String tipo,
    required int id,
    required String firmaBase64,
    required String nroDocumento,
    PosicionFirma? posicion,
    int? version,
  }) async {
    try {
      final endpoint = ApiConstants.firmarEndpoint
          .replaceFirst('{tipo}', tipo)
          .replaceFirst('{id}', id.toString());
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await client.post(
        url,
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode({
          'firma': firmaBase64,
          'nro_documento': nroDocumento,
          // TK-0353: dónde colocó el conductor su firma sobre el PDF (solo documentos adicionales).
          if (posicion != null) 'posicion': posicion.toJson(),
          // TK-0401: qué versión del contrato de afiliación leyó; si se publicó otra mientras tanto, el servidor no la registra.
          if (version != null) 'version': version,
        }),
      ).timeout(ApiConstants.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw ServerException(data['message'] ?? 'Error al registrar la firma');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión: $e');
    }
  }
}
