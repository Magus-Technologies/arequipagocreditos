import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/comercio_model.dart';
import '../models/promo_taller_banner_model.dart';

abstract class ComercioRemoteDataSource {
  Future<List<ComercioModel>> getComercios({int? categoriaId, String? departamento});
  Future<List<ComercioCategoriaModel>> getCategorias();
  Future<List<PromoTallerBannerModel>> getPromocionesBanners();
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

  /// Flyers que se muestran al entrar a Comercios GO (los administra la web en Promociones > Comercios).
  /// El servidor devuelve la lista vacía cuando el interruptor está apagado.
  @override
  Future<List<PromoTallerBannerModel>> getPromocionesBanners() async {
    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.comerciosBannersEndpoint}';
      final response = await client
          .get(Uri.parse(url), headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.receiveTimeout);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final data = jsonResponse['data'];

      if (response.statusCode == 200 && jsonResponse['success'] == true && data is List) {
        return data
            .map((banner) => PromoTallerBannerModel.fromJson(Map<String, dynamic>.from(banner as Map)))
            .toList();
      }

      throw Exception(jsonResponse['message'] ?? 'No se pudieron obtener las promociones');
    } catch (e) {
      throw Exception('Error al obtener promociones de comercios: $e');
    }
  }
}
