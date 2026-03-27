import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
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
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
      
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
      
      final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.cuponesEndpoint}?cliente_conductor_id=$idConductor');
      final response = await client
          .get(
            url,
            headers: ApiConstants.defaultHeaders,
          )
          .timeout(ApiConstants.connectionTimeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> fullResponse = jsonDecode(response.body);
        
        // Extract the map that contains the coupons
        final dynamic nestedData = fullResponse['data'];
        List<dynamic> cuponesData = [];
        
        if (nestedData is Map && nestedData.containsKey('cupones')) {
          cuponesData = nestedData['cupones'];
        } else if (nestedData is List) {
          cuponesData = nestedData;
        } else if (fullResponse.containsKey('cupones')) {
           cuponesData = fullResponse['cupones'];
        }

        if (cuponesData.isNotEmpty) {
          // Agregar campos adicionales que necesita el modelo si faltan
          List<Map<String, dynamic>> cuponesFormateados =
              cuponesData.map((cupon) {
                Map<String, dynamic> cuponFormateado =
                    Map<String, dynamic>.from(cupon);

                // Agregar campos por defecto si no existen
                cuponFormateado['categoria'] =
                    cuponFormateado['tipo_cupon'] ?? cuponFormateado['categoria'] ?? 'General';
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
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
      
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

      final endpoint = ApiConstants.usarCuponEndpoint.replaceFirst('{id}', cuponId.toString());
      final url = Uri.parse('${ApiConstants.apiBaseUrl}$endpoint');
      print(url);
      final response = await client
          .post(
            url,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode({
              'cliente_conductor_id': idConductor,
              'monto_descuento': 0.0, // Default for now, as use case doesn't provide it yet
            }),
          )
          .timeout(ApiConstants.connectionTimeout);

      final responseData = _parseResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? 'Cupón aplicado correctamente',
          'data': responseData['data'] ?? responseData,
        };
      } else {
        throw ServerException(responseData['message'] ?? 'Error al usar cupón (Status: ${response.statusCode})');
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
