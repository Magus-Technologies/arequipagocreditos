import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/beneficio_comercial_model.dart';
import '../models/beneficio_servicio_model.dart';
import '../models/taller_model.dart';

abstract class BeneficiosComercialRemoteDataSource {
  Future<List<BeneficioComercialModel>> getBeneficiosComerciales({int? tipo, String? audiencia});
  Future<List<BeneficioServicioModel>> getBeneficiosServicios({int? tallerId, String? audiencia, int? clienteConductorId});
  Future<List<TallerModel>> getTalleres();
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
