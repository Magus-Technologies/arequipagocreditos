import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/comercio_model.dart';
import '../models/promo_taller_banner_model.dart';

abstract class ComercioRemoteDataSource {
  Future<List<ComercioModel>> getComercios({int? categoriaId, String? departamento});

  /// TK-0382: lo mismo que en talleres. Con la `audiencia` del conductor y su `tipoVehicular` el servidor solo manda los comercios
  /// con servicios para él (y cuenta solo esos); agrupa por ciudad (Lima por distrito, el resto por provincia).
  Future<List<ComercioGrupoModel>> getComerciosAgrupados({
    int? categoriaId,
    String? departamento,
    String? audiencia,
    String? tipoVehicular,
  });

  /// TK-0382: el conductor califica un comercio (1 a 5 estrellas). Devuelve el promedio y el total actualizados.
  Future<Map<String, dynamic>> calificarComercio({
    required int comercioId,
    required int clienteConductorId,
    required int puntuacion,
    String? comentario,
  });
  Future<List<ComercioCategoriaModel>> getCategorias();
  /// Con la ciudad del conductor (`departamento`, de su perfil) el servidor solo manda los flyers de todas las ciudades y los de la
  /// suya (TK-0393); sin ella, solo los de todas las ciudades.
  Future<List<PromoTallerBannerModel>> getPromocionesBanners({String? departamento});
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
  Future<List<ComercioGrupoModel>> getComerciosAgrupados({
    int? categoriaId,
    String? departamento,
    String? audiencia,
    String? tipoVehicular,
  }) async {
    try {
      final queryParams = <String, String>{'agrupar': 'true'};
      if (categoriaId != null) queryParams['categoria_id'] = '$categoriaId';
      final ciudad = departamento?.trim() ?? '';
      if (ciudad.isNotEmpty) queryParams['departamento'] = ciudad;
      if (audiencia != null && audiencia.isNotEmpty) queryParams['audiencia'] = audiencia;
      if (tipoVehicular != null && tipoVehicular.isNotEmpty) queryParams['tipo_vehicular'] = tipoVehicular;

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.comerciosListEndpoint}').replace(queryParameters: queryParams);
      final response = await client.get(uri, headers: ApiConstants.defaultHeaders).timeout(ApiConstants.receiveTimeout);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      final data = jsonResponse['data'];
      if (response.statusCode == 200 && jsonResponse['success'] == true && data is Map) {
        return (data['grupos'] as List? ?? const [])
            .map((g) => ComercioGrupoModel.fromJson(Map<String, dynamic>.from(g as Map)))
            .toList();
      }

      throw Exception(jsonResponse['message'] ?? 'No se pudieron obtener los comercios');
    } catch (e) {
      throw Exception('Error al obtener comercios: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> calificarComercio({
    required int comercioId,
    required int clienteConductorId,
    required int puntuacion,
    String? comentario,
  }) async {
    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.comerciosCalificarEndpoint.replaceAll('{id}', '$comercioId')}';
      final body = <String, dynamic>{'cliente_conductor_id': clienteConductorId, 'puntuacion': puntuacion};
      if (comentario != null && comentario.isNotEmpty) body['comentario'] = comentario;

      final response = await client
          .post(Uri.parse(url), headers: ApiConstants.defaultHeaders, body: json.encode(body))
          .timeout(ApiConstants.receiveTimeout);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true && jsonResponse['data'] is Map) {
        return Map<String, dynamic>.from(jsonResponse['data'] as Map);
      }

      throw Exception(jsonResponse['message'] ?? 'Error al calificar');
    } catch (e) {
      throw Exception('Error al calificar comercio: $e');
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
  Future<List<PromoTallerBannerModel>> getPromocionesBanners({String? departamento}) async {
    try {
      final ciudad = departamento?.trim() ?? '';
      var uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.comerciosBannersEndpoint}');
      if (ciudad.isNotEmpty) uri = uri.replace(queryParameters: {'departamento': ciudad});
      final response = await client
          .get(uri, headers: ApiConstants.defaultHeaders)
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
