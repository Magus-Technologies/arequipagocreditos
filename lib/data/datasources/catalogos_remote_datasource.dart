import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/catalogo_models.dart';
import '../models/conductor_estado_model.dart';

abstract class CatalogosRemoteDataSource {
  Future<List<UbigeoItemModel>> getDepartamentos();
  Future<List<UbigeoItemModel>> getProvincias(String codigoDepartamento);
  Future<List<UbigeoItemModel>> getDistritos(String codigoProvincia);
  Future<List<PlataformaItemModel>> getPlataformas();
  Future<ConductorEstadoModel> getConductorEstado(int conductorId);
}

class CatalogosRemoteDataSourceImpl implements CatalogosRemoteDataSource {
  final http.Client client;

  CatalogosRemoteDataSourceImpl({required this.client});

  Future<List<T>> _getList<T>(String endpoint, T Function(Map<String, dynamic>) fromJson, String errorLabel) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      final response = await client
          .get(Uri.parse(url), headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error desconocido');
        }
      } else {
        throw Exception('Error HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener $errorLabel: $e');
    }
  }

  @override
  Future<List<UbigeoItemModel>> getDepartamentos() {
    return _getList(ApiConstants.ubigeoDepartamentosEndpoint, UbigeoItemModel.fromJson, 'departamentos');
  }

  @override
  Future<List<UbigeoItemModel>> getProvincias(String codigoDepartamento) {
    final endpoint = ApiConstants.ubigeoProvinciasEndpoint.replaceAll('{codigo}', codigoDepartamento);
    return _getList(endpoint, UbigeoItemModel.fromJson, 'provincias');
  }

  @override
  Future<List<UbigeoItemModel>> getDistritos(String codigoProvincia) {
    final endpoint = ApiConstants.ubigeoDistritosEndpoint.replaceAll('{codigo}', codigoProvincia);
    return _getList(endpoint, UbigeoItemModel.fromJson, 'distritos');
  }

  @override
  Future<List<PlataformaItemModel>> getPlataformas() {
    return _getList(ApiConstants.plataformasEndpoint, PlataformaItemModel.fromJson, 'plataformas');
  }

  @override
  Future<ConductorEstadoModel> getConductorEstado(int conductorId) async {
    try {
      final endpoint = ApiConstants.conductorEstadoEndpoint.replaceAll('{id}', conductorId.toString());
      final url = '${ApiConstants.baseUrl}$endpoint';
      final response = await client
          .get(Uri.parse(url), headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return ConductorEstadoModel.fromJson(jsonResponse['data'] as Map<String, dynamic>);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error desconocido');
        }
      } else if (response.statusCode == 404) {
        throw Exception('No encontramos tu solicitud de registro');
      } else {
        throw Exception('Error HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al consultar el estado: $e');
    }
  }
}
