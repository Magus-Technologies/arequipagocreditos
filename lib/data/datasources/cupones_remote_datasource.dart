import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../../core/constants/api_constants.dart';
import '../models/cupon_model.dart';

abstract class CuponesRemoteDataSource {
  Future<List<CuponModel>> getCupones();
  Future<Map<String, dynamic>> usarCupon(int cuponId);
}

class CuponesRemoteDataSourceImpl implements CuponesRemoteDataSource {
  final http.Client client;
  
  CuponesRemoteDataSourceImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<List<CuponModel>> getCupones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      
      if (conductorJson == null) {
        throw const CacheException('Usuario no encontrado');
      }

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      
      if (!conductorData.containsKey('conductor')) {
        throw const CacheException('Datos de conductor inválidos');
      }

      final conductorInfo = conductorData['conductor'] as Map<String, dynamic>;
      
      if (!conductorInfo.containsKey('id_conductor')) {
        throw const CacheException('ID de conductor no encontrado');
      }

      final int idConductor = conductorInfo['id_conductor'];
      final String tipo = conductorInfo['tipo'].toString() == "1" ? 'conductor' : 'cliente';
      final response = await client
          .get(
            Uri.parse('${ApiConstants.cuponesBaseUrl}/cupones/verificar/$tipo/$idConductor'),
            headers: ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.connectionTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['tiene_cupones'] == true && data['cupones'] != null) {
          List<dynamic> cuponesData = data['cupones'];

          // Agregar campos adicionales que necesita el modelo
          List<Map<String, dynamic>> cuponesFormateados =
              cuponesData.map((cupon) {
                Map<String, dynamic> cuponFormateado =
                    Map<String, dynamic>.from(cupon);

                // Agregar campos por defecto si no existen
                cuponFormateado['categoria'] =
                    cuponFormateado['categoria'] ?? 'Promociones';
                cuponFormateado['descripcion'] =
                    cuponFormateado['descripcion'] ??
                    'Descuento especial disponible para ti';
                cuponFormateado['codigo'] =
                    cuponFormateado['codigo'] ?? 'CUPON${cupon['id']}';
                cuponFormateado['empresa'] =
                    cuponFormateado['empresa'] ?? 'Arequipa GO';
                cuponFormateado['condiciones'] =
                    cuponFormateado['condiciones'] ??
                    'Válido según términos y condiciones.';

                return cuponFormateado;
              }).toList();

          return cuponesFormateados
              .map((data) => CuponModel.fromJson(data))
              .toList();
        } else {
          return [];
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error de conexión: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> usarCupon(int cuponId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      
      if (conductorJson == null) {
        throw const CacheException('Usuario no encontrado');
      }

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      
      if (!conductorData.containsKey('conductor')) {
        throw const CacheException('Datos de conductor inválidos');
      }

      final conductorInfo = conductorData['conductor'] as Map<String, dynamic>;
      
      if (!conductorInfo.containsKey('id_conductor')) {
        throw const CacheException('ID de conductor no encontrado');
      }

      final int idConductor = conductorInfo['id_conductor'];

      final response = await client
          .post(
            Uri.parse('${ApiConstants.cuponesBaseUrl}/cupones/usar-codigo/$idConductor/$cuponId'),
            headers: ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.connectionTimeout);

      final responseData = _parseResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? 'Cupón aplicado correctamente',
          'data': responseData,
        };
      } else {
        throw ServerException(responseData['message'] ?? 'Error al usar cupón');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error de conexión: $e');
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ServerException('Error al parsear respuesta: $e');
    }
  }
}
