import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/beneficio_comercial_model.dart';
import '../models/beneficio_servicio_model.dart';
import '../models/taller_model.dart';

abstract class BeneficiosComercialRemoteDataSource {
  Future<List<BeneficioComercialModel>> getBeneficiosComerciales({int? tipo});
  Future<List<BeneficioServicioModel>> getBeneficiosServicios({int? tallerId});
  Future<List<TallerModel>> getTalleres();
}

class BeneficiosComercialRemoteDataSourceImpl
    implements BeneficiosComercialRemoteDataSource {
  final http.Client client;

  BeneficiosComercialRemoteDataSourceImpl({required this.client});

  @override
  Future<List<BeneficioComercialModel>> getBeneficiosComerciales({int? tipo}) async {
    try {
      String url = '${ApiConstants.baseUrl}${ApiConstants.beneficiosEndpoint}';
      if (tipo != null) {
        url += '?tipo=$tipo';
      }

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
  Future<List<BeneficioServicioModel>> getBeneficiosServicios({int? tallerId}) async {
    try {
      String url = '${ApiConstants.baseUrl}${ApiConstants.beneficiosEndpoint}?tipo=2';
      if (tallerId != null) {
        url += '&taller_id=$tallerId';
      }

      final response = await client.get(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
      );

      if (response.statusCode == 200) {
        print('BENEFICIOS SERVICIOS RESPONSE: ${response.body}');
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> beneficiosData = jsonResponse['data'];
          return beneficiosData
              .map((beneficio) => BeneficioServicioModel.fromJson(beneficio))
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
      throw Exception('Error al obtener beneficios de servicios: $e');
    }
  }

  @override
  Future<List<TallerModel>> getTalleres() async {
    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.beneficiosEndpoint}?tipo=2';
      final response = await client.get(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
      );

      if (response.statusCode == 200) {
        print('TALLERES RESPONSE: ${response.body}');
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
}
