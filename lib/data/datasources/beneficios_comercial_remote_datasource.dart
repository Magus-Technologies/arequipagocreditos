import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/beneficio_comercial_model.dart';
import '../models/beneficio_servicio_model.dart';
import '../models/taller_model.dart';

abstract class BeneficiosComercialRemoteDataSource {
  Future<List<BeneficioComercialModel>> getBeneficiosComerciales({int? tipo, String? audiencia});
  Future<List<BeneficioServicioModel>> getBeneficiosServicios({int? tallerId, String? audiencia, int? clienteConductorId});
  Future<BeneficioServicioModel> getBeneficioDetalle({required int beneficioId, int? clienteConductorId});
  Future<List<TallerModel>> getTalleres();
  Future<TalleresAgrupadosResponse> getTalleresAgrupados({
    String? audiencia,
    String? departamento,
    String? tipoVehicular,
  });
  Future<Map<String, dynamic>> calificarTaller({required int tallerId, required int clienteConductorId, required int puntuacion, String? comentario, int? financiamientoId});
}

class BeneficiosComercialRemoteDataSourceImpl
    implements BeneficiosComercialRemoteDataSource {
  final http.Client client;

  BeneficiosComercialRemoteDataSourceImpl({required this.client});

  @override
  Future<List<BeneficioComercialModel>> getBeneficiosComerciales({int? tipo, String? audiencia}) async {
    try {
      String url = '${ApiConstants.baseUrl}${ApiConstants.beneficiosEndpoint}';
      final queryParams = <String>[];
      if (tipo != null) queryParams.add('tipo=$tipo');
      if (audiencia != null) queryParams.add('audiencia=$audiencia');
      if (queryParams.isNotEmpty) url += '?${queryParams.join('&')}';

      final response = await client.get(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> beneficiosData = jsonResponse['data'];
          return beneficiosData
              .map((beneficio) => BeneficioComercialModel.fromJson(beneficio))
              .toList();
        } else {
          throw Exception(
            'API response indicates failure: ${jsonResponse['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al obtener beneficios comerciales: $e');
    }
  }

  @override
  Future<List<BeneficioServicioModel>> getBeneficiosServicios({int? tallerId, String? audiencia, int? clienteConductorId}) async {
    try {
      if (tallerId == null) return [];
      String url = '${ApiConstants.baseUrl}${ApiConstants.talleresListServiciosEndpoint}/$tallerId';
      final queryParams = <String>[];
      if (audiencia != null) queryParams.add('audiencia=$audiencia');
      if (clienteConductorId != null) queryParams.add('cliente_conductor_id=$clienteConductorId');
      if (queryParams.isNotEmpty) url += '?${queryParams.join('&')}';

      final response = await client.get(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          // Nuevo endpoint: data es { ...taller, servicios: [...] }
          final data = jsonResponse['data'] as Map<String, dynamic>;
          final List<dynamic> serviciosData = data['servicios'] ?? [];
          return serviciosData
              .map((s) => BeneficioServicioModel.fromJson(s))
              .toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error desconocido');
        }
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al obtener servicios del taller: $e');
    }
  }

  /// Detalle de un beneficio con el mismo shape que un servicio de taller:
  /// incluye detalle_financiamiento, variantes_disponibles y, si se envia
  /// clienteConductorId, las alertas de elegibilidad de ese cliente.
  @override
  Future<BeneficioServicioModel> getBeneficioDetalle({
    required int beneficioId,
    int? clienteConductorId,
  }) async {
    try {
      String url = '${ApiConstants.baseUrl}${ApiConstants.beneficiosEndpoint}/$beneficioId';
      if (clienteConductorId != null) {
        url += '?cliente_conductor_id=$clienteConductorId';
      }

      final response = await client
          .get(Uri.parse(url), headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.receiveTimeout);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true && jsonResponse['data'] != null) {
        return BeneficioServicioModel.fromJson(
          Map<String, dynamic>.from(jsonResponse['data'] as Map),
        );
      }

      throw Exception(jsonResponse['message'] ?? 'No se pudo obtener el beneficio');
    } catch (e) {
      throw Exception('Error al obtener el detalle del beneficio: $e');
    }
  }

  @override
  Future<List<TallerModel>> getTalleres() async {
    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.talleresListEndpoint}';
      final response = await client.get(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((t) => TallerModel.fromJson(t)).toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error desconocido');
        }
      } else {
        throw Exception('Error HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener talleres: $e');
    }
  }

  @override
  Future<TalleresAgrupadosResponse> getTalleresAgrupados({
    String? audiencia,
    String? departamento,
    String? tipoVehicular,
  }) async {
    try {
      final queryParams = <String, String>{'agrupar': 'true'};
      if (audiencia != null) queryParams['audiencia'] = audiencia;
      if (departamento != null && departamento.isNotEmpty) queryParams['departamento'] = departamento;
      if (tipoVehicular != null && tipoVehicular.isNotEmpty) queryParams['tipo_vehicular'] = tipoVehicular;

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.talleresListEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await client.get(uri, headers: ApiConstants.defaultHeaders);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return TalleresAgrupadosResponse.fromJson(
            jsonResponse['data'] as Map<String, dynamic>,
          );
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error desconocido');
        }
      } else {
        throw Exception('Error HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener talleres agrupados: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> calificarTaller({
    required int tallerId,
    required int clienteConductorId,
    required int puntuacion,
    String? comentario,
    int? financiamientoId,
  }) async {
    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.talleresCalificarEndpoint.replaceAll('{id}', '$tallerId')}';
      final body = <String, dynamic>{
        'cliente_conductor_id': clienteConductorId,
        'puntuacion': puntuacion,
      };
      if (comentario != null && comentario.isNotEmpty) body['comentario'] = comentario;
      if (financiamientoId != null) body['financiamiento_id'] = financiamientoId;

      final response = await client.post(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
        body: json.encode(body),
      );

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data'] as Map<String, dynamic>;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Error al calificar');
      }
    } catch (e) {
      throw Exception('Error al calificar taller: $e');
    }
  }
}
