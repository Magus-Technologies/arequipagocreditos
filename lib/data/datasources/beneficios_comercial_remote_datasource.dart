import 'dart:convert';
import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../models/beneficio_comercial_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BeneficiosComercialRemoteDataSource {
  Future<List<BeneficioComercialModel>> getBeneficiosComerciales();
}

class BeneficiosComercialRemoteDataSourceImpl
    implements BeneficiosComercialRemoteDataSource {
  final http.Client client;

  BeneficiosComercialRemoteDataSourceImpl({required this.client});

  @override
  Future<List<BeneficioComercialModel>> getBeneficiosComerciales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      String url ='${ApiConstants.cuponesBaseUrl}${ApiConstants.beneficiosEndpoint}';
      if (conductorJson != null) {
        final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
        final int idConductor = conductorData['conductor']['id_conductor'];
        final String tipo = conductorData['conductor']['tipo'].toString() == "1" ? 'conductor' : 'cliente';
        url ='${ApiConstants.cuponesBaseUrl}${ApiConstants.beneficiosEndpoint}/$idConductor/$tipo';
      }

      final response = await client.get(
        Uri.parse(
          url,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
}
