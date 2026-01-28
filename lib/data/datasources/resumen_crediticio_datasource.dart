import 'dart:convert';
import 'package:arequipagocreditos/data/models/resumen_crediticio_model.dart';
import 'package:http/http.dart' as http;
import '../../core/errors/exceptions.dart';
import '../../core/constants/api_constants.dart';

abstract class ResumenCrediticioRemoteDataSource {
  Future<ResumenCrediticio> getResumenCrediticio(int idConductor, int tipo);
}

class ResumenRemoteDataSourceImpl implements ResumenCrediticioRemoteDataSource {
  final http.Client client;

  ResumenRemoteDataSourceImpl({http.Client? client})
    : client = client ?? http.Client();

  @override
  Future<ResumenCrediticio> getResumenCrediticio(
    int idConductor,
    int tipo,
  ) async {
    try {
      String tipoUsuario = tipo == 1 ? 'conductor' : 'cliente';
      final url = Uri.parse(
        '${ApiConstants.cuponesBaseUrl}/resumen-crediticio/conductor/$idConductor/$tipoUsuario',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ResumenCrediticio.fromJson(data);
      } else if (response.statusCode == 404) {
        throw const ValidationException('Puntuación no encontrada');
      } else if (response.statusCode >= 500) {
        throw const ServerException('Error del servidor');
      } else {
        throw ServerException(
          'Error al obtener puntuación: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error de conexión: $e');
    }
  }
}
