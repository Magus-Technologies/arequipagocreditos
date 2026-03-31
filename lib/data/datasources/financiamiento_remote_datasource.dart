import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/errors/exceptions.dart';
import '../../core/constants/api_constants.dart';
import '../models/financiamiento_model.dart';
import '../models/cuota_financiamiento_model.dart';

abstract class FinanciamientoRemoteDataSource {
  Future<List<FinanciamientoModel>> getFinanciamientos(int idConductor, int tipo);
  Future<FinanciamientoModel> getFinanciamientoById(int id);
  Future<List<CuotaFinanciamientoModel>> getCuotasFinanciamiento(int idFinanciamiento);
  Future<CuotaFinanciamientoModel> pagarCuota(int idCuota, double monto);
  Future<String> generarReporteCuota(int idCuota);
}

class FinanciamientoRemoteDataSourceImpl implements FinanciamientoRemoteDataSource {
  final http.Client client;
  
  FinanciamientoRemoteDataSourceImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<List<FinanciamientoModel>> getFinanciamientos(int idConductor, int tipo) async {
    try {
      final endpoint = ApiConstants.financiamientosEndpoint
          .replaceFirst('{id}', idConductor.toString())
          .replaceFirst('{tipo}', tipo.toString());
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await client
          .get(url)
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList.map((json) => FinanciamientoModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response.statusCode >= 500) {
        throw const ServerException('Error del servidor');
      } else {
        throw ServerException('Error al obtener financiamientos: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error de conexión: $e');
    }
  }

  @override
  Future<FinanciamientoModel> getFinanciamientoById(int id) async {
    try {
      final endpoint = ApiConstants.cuotasEndpoint.replaceFirst('{id}', id.toString());
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await client
          .get(url)
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Handle wrapped response
        if (data.containsKey('data')) {
          return FinanciamientoModel.fromJson(data['data'] as Map<String, dynamic>);
        }
        return FinanciamientoModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw const ValidationException('Financiamiento no encontrado');
      } else if (response.statusCode >= 500) {
        throw const ServerException('Error del servidor');
      } else {
        throw ServerException('Error al obtener financiamiento: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error de conexión: $e');
    }
  }

  @override
  Future<List<CuotaFinanciamientoModel>> getCuotasFinanciamiento(int idFinanciamiento) async {
    try {
      final endpoint = ApiConstants.cuotasEndpoint.replaceFirst('{id}', idFinanciamiento.toString());
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await client
          .get(url)
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        List<dynamic> jsonList = [];
        if (data.containsKey('data') && data['data'].containsKey('cuotas')) {
          jsonList = data['data']['cuotas'] as List<dynamic>;
        } else if (data.containsKey('cuotas')) {
          jsonList = data['cuotas'] as List<dynamic>;
        } else if (data is List) {
           jsonList = data as List<dynamic>;
        }
        
        return jsonList.map((json) => CuotaFinanciamientoModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response.statusCode >= 500) {
        throw const ServerException('Error del servidor');
      } else {
        throw ServerException('Error al obtener cuotas: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error de conexión: $e');
    }
  }

  @override
  Future<CuotaFinanciamientoModel> pagarCuota(int idCuota, double monto) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.pagarCuotaEndpoint}');
      
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id_cuota': idCuota,
              'monto': monto,
            }),
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CuotaFinanciamientoModel.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw ValidationException(error['message'] ?? 'Datos de pago inválidos');
      } else if (response.statusCode >= 500) {
        throw const ServerException('Error del servidor');
      } else {
        throw ServerException('Error al procesar pago: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error de conexión: $e');
    }
  }

  @override
  Future<String> generarReporteCuota(int idCuota) async {
    try {
      final endpoint = ApiConstants.reporteCuotaEndpoint.replaceFirst('{id}', idCuota.toString());
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      
      final response = await client
          .post(url)
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reporte_url'] ?? '';
      } else if (response.statusCode >= 500) {
        throw const ServerException('Error del servidor');
      } else {
        throw ServerException('Error al generar reporte: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error de conexión: $e');
    }
  }
}
