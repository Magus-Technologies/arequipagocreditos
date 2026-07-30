import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/orden_pago_model.dart';

abstract class OrdenesPagoRemoteDataSource {
  Future<ListadoOrdenesPagoModel> getOrdenesPago({
    required int clienteId,
    bool incluirHistorial = false,
  });
}

class OrdenesPagoRemoteDataSourceImpl implements OrdenesPagoRemoteDataSource {
  final http.Client client;

  OrdenesPagoRemoteDataSourceImpl({required this.client});

  @override
  Future<ListadoOrdenesPagoModel> getOrdenesPago({
    required int clienteId,
    bool incluirHistorial = false,
  }) async {
    try {
      final endpoint = ApiConstants.ordenesPagoEndpoint
          .replaceFirst('{clienteId}', clienteId.toString());

      var url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      if (incluirHistorial) {
        url = url.replace(queryParameters: {'incluir_historial': '1'});
      }

      final response =
          await client.get(url).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return ListadoOrdenesPagoModel.fromJson(
            jsonResponse['data'] as Map<String, dynamic>,
          );
        }
        throw ServerException(
          jsonResponse['message'] ?? 'Error al obtener las órdenes de pago',
        );
      }

      throw ServerException(
        'Error al obtener las órdenes de pago: ${response.statusCode}',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error de conexión: $e');
    }
  }
}
