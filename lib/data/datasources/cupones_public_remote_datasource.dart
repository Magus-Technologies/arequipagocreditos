import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/errors/exceptions.dart';
import '../../core/constants/api_constants.dart';
import '../models/cupon_public_model.dart';

abstract class CuponesPublicRemoteDataSource {
  Future<List<CuponPublicModel>> getPublicCupones();
}

class CuponesPublicRemoteDataSourceImpl implements CuponesPublicRemoteDataSource {
  final http.Client client;
  CuponesPublicRemoteDataSourceImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<List<CuponPublicModel>> getPublicCupones() async {
    try {
        final response = await client
          .get(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cuponesEndpoint}'))
          .timeout(ApiConstants.connectionTimeout);
      if (response.statusCode == 200) {
        dynamic decoded = jsonDecode(response.body);

        if (decoded is String) {
          try {
            decoded = jsonDecode(decoded);
          } catch (_) {}
        }

        List<dynamic> dataList;
        if (decoded is List) {
          dataList = decoded;
        } else if (decoded is Map) {
          if (decoded['cupones'] is List) {
            dataList = decoded['cupones'] as List<dynamic>;
          } else if (decoded['data'] is Map && decoded['data']['cupones'] is List) {
             dataList = decoded['data']['cupones'] as List<dynamic>;
          } else if (decoded['data'] is List) {
            dataList = decoded['data'] as List<dynamic>;
          } else {
            // Check if there's any field that is a list
            final firstList = decoded.values.firstWhere((v) => v is List, orElse: () => null);
            if (firstList is List) {
              dataList = firstList;
            } else {
              throw ServerException('No se encontró el listado de cupones en la respuesta');
            }
          }
        } else {
          // If map has numeric keys like '0','1', collect their values
          final numericValues = decoded.values.where((v) => v is Map).toList();
          if (numericValues.isNotEmpty) {
            dataList = numericValues.cast<dynamic>();
          } else {
            throw ServerException('Formato de respuesta inesperado');
          }
        }

        return dataList.map((e) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(e as Map);
          map['imagen_banner'] = map['imagen_banner'] ?? map['imagenBanner'] ?? map['imagen'];
          map['tipo_descuento'] = map['tipo_descuento'] ?? map['tipoDescuento'];
          map['valor'] = map['valor']?.toString();
          return CuponPublicModel.fromJson(map);
        }).toList();
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error de conexión: $e');
    }
  }
}
