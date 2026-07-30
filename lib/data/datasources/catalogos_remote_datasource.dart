import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/catalogo_models.dart';
import '../models/conductor_estado_model.dart';
import '../models/izipay_models.dart';

abstract class CatalogosRemoteDataSource {
  Future<List<UbigeoItemModel>> getDepartamentos();
  Future<List<UbigeoItemModel>> getProvincias(String codigoDepartamento);
  Future<List<UbigeoItemModel>> getDistritos(String codigoProvincia);
  Future<List<PlataformaItemModel>> getPlataformas();
  Future<ConductorEstadoModel> getConductorEstado(int conductorId);
  Future<IzipayInfoModel> getIzipayInfo(int clienteId);
  Future<ConductorEstadoModel> generarOrdenCajaArequipa(int clienteId);
  Future<Map<String, dynamic>> subirCapturaIzipay({
    required int clienteConductorId,
    required String nroDocumento,
    required File captura,
    String? numeroOperacion,
  });
}

class CatalogosRemoteDataSourceImpl implements CatalogosRemoteDataSource {
  final http.Client client;

  CatalogosRemoteDataSourceImpl({required this.client});

  Future<List<T>> _getList<T>(String endpoint, T Function(Map<String, dynamic>) fromJson, String errorLabel) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      final response = await client
          .get(Uri.parse(url), headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error desconocido');
        }
      } else {
        throw Exception('Error HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener $errorLabel: $e');
    }
  }

  @override
  Future<List<UbigeoItemModel>> getDepartamentos() {
    return _getList(ApiConstants.ubigeoDepartamentosEndpoint, UbigeoItemModel.fromJson, 'departamentos');
  }

  @override
  Future<List<UbigeoItemModel>> getProvincias(String codigoDepartamento) {
    final endpoint = ApiConstants.ubigeoProvinciasEndpoint.replaceAll('{codigo}', codigoDepartamento);
    return _getList(endpoint, UbigeoItemModel.fromJson, 'provincias');
  }

  @override
  Future<List<UbigeoItemModel>> getDistritos(String codigoProvincia) {
    final endpoint = ApiConstants.ubigeoDistritosEndpoint.replaceAll('{codigo}', codigoProvincia);
    return _getList(endpoint, UbigeoItemModel.fromJson, 'distritos');
  }

  @override
  Future<List<PlataformaItemModel>> getPlataformas() {
    return _getList(ApiConstants.plataformasEndpoint, PlataformaItemModel.fromJson, 'plataformas');
  }

  @override
  Future<ConductorEstadoModel> getConductorEstado(int conductorId) async {
    try {
      final endpoint = ApiConstants.conductorEstadoEndpoint.replaceAll('{id}', conductorId.toString());
      final url = '${ApiConstants.baseUrl}$endpoint';
      final response = await client
          .get(Uri.parse(url), headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return ConductorEstadoModel.fromJson(jsonResponse['data'] as Map<String, dynamic>);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error desconocido');
        }
      } else if (response.statusCode == 404) {
        throw Exception('No encontramos tu solicitud de registro');
      } else {
        throw Exception('Error HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al consultar el estado: $e');
    }
  }

  @override
  Future<ConductorEstadoModel> generarOrdenCajaArequipa(int clienteId) async {
    final endpoint = ApiConstants.ordenCajaInscripcionEndpoint
        .replaceAll('{id}', clienteId.toString());

    final response = await client
        .post(
          Uri.parse('${ApiConstants.baseUrl}$endpoint'),
          headers: ApiConstants.defaultHeaders,
        )
        .timeout(ApiConstants.connectionTimeout);

    Map<String, dynamic>? body;
    try {
      body = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = null;
    }

    if (response.statusCode == 200 &&
        body?['success'] == true &&
        body?['data'] != null) {
      return ConductorEstadoModel.fromJson(body!['data'] as Map<String, dynamic>);
    }

    // El backend explica el motivo (codigo vencido, plan inexistente): se
    // propaga tal cual para mostrarselo a la persona.
    throw Exception(
      body?['message'] ?? 'No pudimos generar tu codigo de pago.',
    );
  }

  @override
  Future<IzipayInfoModel> getIzipayInfo(int clienteId) async {
    try {
      final endpoint = ApiConstants.izipayInfoEndpoint.replaceAll('{id}', clienteId.toString());
      final response = await client
          .get(Uri.parse('${ApiConstants.baseUrl}$endpoint'), headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.connectionTimeout);

      Map<String, dynamic>? body;
      try {
        body = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = null;
      }

      if (response.statusCode == 200 && body?['success'] == true && body?['data'] != null) {
        return IzipayInfoModel.fromJson(body!['data'] as Map<String, dynamic>);
      }
      if (response.statusCode == 422 || response.statusCode == 404) {
        throw ValidationException(body?['message']?.toString() ?? 'El pago por IziPay no está disponible por el momento.');
      }
      throw ServerException('Error del servidor (HTTP ${response.statusCode}). Intenta nuevamente.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error al consultar IziPay: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> subirCapturaIzipay({
    required int clienteConductorId,
    required String nroDocumento,
    required File captura,
    String? numeroOperacion,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.izipayCapturaEndpoint}');
      final request = http.MultipartRequest('POST', url);
      request.fields['cliente_conductor_id'] = clienteConductorId.toString();
      request.fields['nro_documento'] = nroDocumento;
      if (numeroOperacion != null && numeroOperacion.isNotEmpty) {
        request.fields['numero_operacion'] = numeroOperacion;
      }
      request.files.add(await http.MultipartFile.fromPath('captura', captura.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic>? body;
      try {
        body = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = null;
      }

      if (response.statusCode == 429) {
        throw const ValidationException('Demasiados intentos. Espera unos minutos e inténtalo de nuevo.');
      }
      if (response.statusCode == 422) {
        throw ValidationException(body?['message']?.toString() ?? 'Datos inválidos');
      }
      if (body == null) {
        throw ServerException('Error del servidor (HTTP ${response.statusCode}). Intenta nuevamente.');
      }
      return body;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error al subir la captura: $e');
    }
  }
}
