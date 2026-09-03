import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/nivel_taller_model.dart';

abstract class NivelTallerRemoteDataSource {
  Future<NivelTallerModel> getMiNivel({required int clienteConductorId});
}

class NivelTallerRemoteDataSourceImpl implements NivelTallerRemoteDataSource {
  final http.Client client;

  NivelTallerRemoteDataSourceImpl({required this.client});

  @override
  Future<NivelTallerModel> getMiNivel({required int clienteConductorId}) async {
    try {
      final path = ApiConstants.miNivelTallerEndpoint
          .replaceAll('{clienteConductorId}', '$clienteConductorId');
      final url = '${ApiConstants.baseUrl}$path';

      final response = await client
          .get(Uri.parse(url), headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.receiveTimeout);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true && jsonResponse['data'] != null) {
        return NivelTallerModel.fromJson(
          Map<String, dynamic>.from(jsonResponse['data'] as Map),
        );
      }

      throw Exception(jsonResponse['message'] ?? 'No se pudo obtener el nivel');
    } catch (e) {
      throw Exception('Error al obtener el nivel de talleres: $e');
    }
  }
}
