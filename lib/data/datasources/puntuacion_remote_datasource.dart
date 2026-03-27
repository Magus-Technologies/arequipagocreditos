import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/errors/exceptions.dart';
import '../../core/constants/api_constants.dart';
import '../models/puntuacion_model.dart';

abstract class PuntuacionRemoteDataSource {
  Future<PuntuacionModel> getPuntuacion(int idConductor, int tipo);
  Future<List<HistorialPuntosModel>> getHistorialPuntos(int idConductor, int tipo);
  Future<void> actualizarPuntuacion(int idConductor, int nuevoPuntaje, int tipo);
}

class PuntuacionRemoteDataSourceImpl implements PuntuacionRemoteDataSource {
  final http.Client client;
  
  PuntuacionRemoteDataSourceImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<PuntuacionModel> getPuntuacion(int idConductor, int tipo) async {
    try {
      String tipoUsuario = tipo == 1 ? 'conductor' : 'cliente';
      final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.puntajeEndpoint}?tipo=$tipoUsuario&id=$idConductor');
      final response = await client
          .get(
            url,
            headers: ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Verificar si la respuesta viene en el formato envuelto
        if (data.containsKey('data') && data['data'].containsKey('puntaje')) {
          return PuntuacionModel.fromJson(data['data']['puntaje'] as Map<String, dynamic>);
        } else {
          return PuntuacionModel.fromJson(data);
        }
      } else if (response.statusCode == 404) {
        throw const ValidationException('Puntuación no encontrada');
      } else if (response.statusCode >= 500) {
        throw const ServerException('Error del servidor');
      } else {
        throw ServerException('Error al obtener puntuación: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error de conexión: $e');
    }
  }

  @override
  Future<List<HistorialPuntosModel>> getHistorialPuntos(int idConductor, int tipo) async {
    try {
      String tipoUsuario = tipo == 1 ? 'conductor' : 'cliente';

      final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.puntajeEndpoint}?tipo=$tipoUsuario&id=$idConductor');
      final response = await client
          .get(
            url,
            headers: ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Verificar si la respuesta viene en el formato envuelto
        List<dynamic> historialJson = [];
        if (data.containsKey('data')) {
          final dataMap = data['data'] as Map<String, dynamic>;
          if (dataMap.containsKey('historial_reciente')) {
            historialJson = dataMap['historial_reciente'] as List<dynamic>;
          } else if (dataMap.containsKey('historial')) {
            historialJson = dataMap['historial'] as List<dynamic>;
          }
        } else if (data.containsKey('historial_reciente')) {
          historialJson = data['historial_reciente'] as List<dynamic>;
        } else if (data.containsKey('historial')) {
          historialJson = data['historial'] as List<dynamic>;
        }
        
        return historialJson
            .map((json) => HistorialPuntosModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode >= 500) {
        throw const ServerException('Error del servidor');
      } else {
        throw ServerException('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error de conexión: $e');
    }
  }

  @override
  Future<void> actualizarPuntuacion(int idConductor, int nuevoPuntaje, int tipo) async {
    try {
      String tipoUsuario = tipo == 1 ? 'conductor' : 'cliente';

      final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.puntajeEndpoint}?tipo=$tipoUsuario&id=$idConductor');
      final response = await client
          .put(
            url,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode({
              'puntaje_actual': nuevoPuntaje,
            }),
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw ValidationException(error['message'] ?? 'Datos de puntuación inválidos');
      } else if (response.statusCode >= 500) {
        throw const ServerException('Error del servidor');
      } else {
        throw ServerException('Error al actualizar puntuación: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error de conexión: $e');
    }
  }
}
