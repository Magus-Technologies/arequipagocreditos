import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/comercio_model.dart';

abstract class ComercioRemoteDataSource {
  Future<List<ComercioModel>> getComercios({int? categoriaId, String? departamento});
  Future<List<ComercioCategoriaModel>> getCategorias();
}

class ComercioRemoteDataSourceImpl implements ComercioRemoteDataSource {
  final http.Client client;

  ComercioRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ComercioModel>> getComercios({int? categoriaId, String? departamento}) async {
    try {
      String url = '${ApiConstants.baseUrl}${ApiConstants.comerciosListEndpoint}';
      final queryParams = <String>[];
      if (categoriaId != null) queryParams.add('categoria_id=$categoriaId');
      if (departamento != null && departamento.isNotEmpty) {
        queryParams.add('departamento=${Uri.encodeQueryComponent(departamento)}');
      }
      if (queryParams.isNotEmpty) url += '?${queryParams.join('&')}';

      final response = await client
          .get(Uri.parse(url), headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.receiveTimeout);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true && jsonResponse['data'] != null) {
        final List<dynamic> data = jsonResponse['data'];
        return data.map((c) => ComercioModel.fromJson(Map<String, dynamic>.from(c as Map))).toList();
      }

      throw Exception(jsonResponse['message'] ?? 'No se pudieron obtener los comercios');
    } catch (e) {
      throw Exception('Error al obtener comercios: $e');
    }
  }

  @override
  Future<List<ComercioCategoriaModel>> getCategorias() async {
    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.comerciosCategoriasEndpoint}';
      final response = await client
          .get(Uri.parse(url), headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.receiveTimeout);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true && jsonResponse['data'] != null) {
        final List<dynamic> data = jsonResponse['data'];
        return data.map((c) => ComercioCategoriaModel.fromJson(Map<String, dynamic>.from(c as Map))).toList();
      }

      throw Exception(jsonResponse['message'] ?? 'No se pudieron obtener los rubros');
    } catch (e) {
      throw Exception('Error al obtener rubros de comercios: $e');
    }
  }
}
