import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../models/conductor_model.dart';

abstract class AuthRemoteDataSource {
  Future<ConductorModel> login(String nroDocumento, String password);
  Future<void> logout();
  Future<ConductorModel?> getCurrentUser();
  Future<ConductorModel?> refreshUserData();
  Future<Map<String, dynamic>> changePassword(String newPassword);
  Future<Map<String, dynamic>> validateDniForPasswordRecovery(String dni);
  Future<Map<String, dynamic>> resetPassword(String dni, String newPassword);
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile);
  Future<Map<String, dynamic>> updateVehicleData(Map<String, dynamic> data);
  Future<Map<String, dynamic>> preRegister(Map<String, dynamic> data, Map<String, File> files);
  Future<Map<String, dynamic>> conductorPreRegister(Map<String, dynamic> data, Map<String, File> files);
  Future<Map<String, dynamic>> deleteAccount();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<ConductorModel> login(String nroDocumento, String password) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
      final response = await client
          .post(
            url,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode({
              'nro_documento': nroDocumento,
              'password': password,
            }),
          )
          .timeout(ApiConstants.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          _saveUserToPrefs(data);
          return ConductorModel.fromJson(data);
        } else {
          throw AuthException(data['message'] ?? 'Credenciales incorrectas');
        }
      } else {
        throw AuthException(data['message'] ?? 'Error en el servidor (${response.statusCode})');
      }
    } on SocketException {
      throw const NetworkException('No hay conexión a internet');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException('Error al iniciar sesión: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userStorageKey);
      await prefs.remove(AppConstants.contratoAfiliacionUrlKey);
      await prefs.remove(AppConstants.afiliacionFirmadaKey);
    } catch (e) {
      throw CacheException('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<ConductorModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
      if (conductorJson == null) return null;
      return ConductorModel.fromJson(jsonDecode(conductorJson));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ConductorModel?> refreshUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
      if (conductorJson == null) return null;

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      final Map<String, dynamic> conductorMap =
          (conductorData['conductor'] is Map)
              ? Map<String, dynamic>.from(conductorData['conductor'])
              : Map<String, dynamic>.from(conductorData);

      final dynamic rawId = conductorMap['id_conductor'] ?? conductorMap['id'];
      final int idConductor = (rawId is int) ? rawId : int.tryParse((rawId ?? '0').toString()) ?? 0;
      final dynamic rawTipo = conductorMap['tipo'];
      final int tipo = (rawTipo is int) ? rawTipo : int.tryParse((rawTipo ?? '0').toString()) ?? 0;

      final endpoint = (tipo == 4)
          ? ApiConstants.perfilPasajeroEndpoint.replaceFirst('{id}', idConductor.toString())
          : ApiConstants.perfilUsuarioEndpoint
              .replaceFirst('{id}', idConductor.toString())
              .replaceFirst('{tipo}', tipo.toString());
      
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final response = await client.get(url).timeout(ApiConstants.connectionTimeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body) as Map<String, dynamic>;
        Map<String, dynamic> profileData = {};
        
        if (responseData.containsKey('conductor')) {
          profileData = Map<String, dynamic>.from(responseData['conductor']);
        } else if (responseData.containsKey('data')) {
          profileData = Map<String, dynamic>.from(responseData['data']);
        } else {
          profileData = Map<String, dynamic>.from(responseData);
        }

        // Aplanar dirección si es objeto
        if (profileData['direccion'] is Map) {
          final dir = profileData['direccion'];
          profileData['direccion'] = "${dir['direccion_detallada'] ?? ''}, ${dir['distrito'] ?? ''}, ${dir['provincia'] ?? ''}";
        }

        // Preservar Tipo e ID
        profileData['id_conductor'] = profileData['id'] ?? idConductor;
        profileData['tipo'] = profileData['tipo'] ?? tipo;

        // Preservar campos de afiliación: prioridad → perfil API → sesión existente → claves dedicadas
        final savedContratoUrl = prefs.getString(AppConstants.contratoAfiliacionUrlKey);
        final savedFirmada = prefs.getBool(AppConstants.afiliacionFirmadaKey);
        // savedFirmada == true tiene prioridad absoluta: una vez firmado, siempre firmado,
        // aunque el servidor devuelva false (no null) por retraso de sincronización.
        final bool localFirmada = savedFirmada == true;
        final bool serverFirmada = profileData['afiliacion_firmada'] == true || profileData['afiliacion_firmada'] == 1;
        final bool existingFirmada = conductorMap['afiliacion_firmada'] == true || conductorMap['afiliacion_firmada'] == 1;
        profileData['afiliacion_firmada'] = localFirmada || serverFirmada || existingFirmada;
        profileData['contrato_afiliacion_url'] = profileData['contrato_afiliacion_url'] ?? conductorMap['contrato_afiliacion_url'] ?? savedContratoUrl;
        profileData['firma_afiliacion_url'] = profileData['firma_afiliacion_url'] ?? conductorMap['firma_afiliacion_url'];
        profileData['firma_afiliacion_at'] = profileData['firma_afiliacion_at'] ?? conductorMap['firma_afiliacion_at'];

        // Guardar de forma limpia
        final Map<String, dynamic> newSessionData = {
          'success': true,
          'conductor': profileData,
          'flag': responseData['flag'] ?? conductorData['flag'] ?? 1,
        };

        await prefs.setString(AppConstants.userStorageKey, jsonEncode(newSessionData));
        
        try {
          return ConductorModel.fromJson(newSessionData);
        } catch (e) {
          debugPrint('CRITICAL ERROR MAPPING MODEL: $e');
          rethrow;
        }
      }
      return getCurrentUser();
    } catch (e) {
      debugPrint('Error en refreshUserData: $e');
      return getCurrentUser();
    }
  }

  @override
  Future<Map<String, dynamic>> changePassword(String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
      if (conductorJson == null) throw const AuthException('No se encontró el usuario');

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      final conductorMap = (conductorData['conductor'] is Map) ? conductorData['conductor'] : conductorData;
      final String dni = conductorMap['nro_documento'];

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updatePasswordConductorEndpoint}');
      final response = await client.post(url, headers: ApiConstants.defaultHeaders, body: jsonEncode({'dni': dni, 'password': newPassword})).timeout(ApiConstants.connectionTimeout);
      return jsonDecode(response.body);
    } catch (e) {
      throw ServerException('Error al actualizar contraseña: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> validateDniForPasswordRecovery(String dni) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.validateDniEndpoint}');
      final response = await client.post(url, headers: ApiConstants.defaultHeaders, body: jsonEncode({'nro_documento': dni})).timeout(ApiConstants.connectionTimeout);
      return jsonDecode(response.body);
    } catch (e) {
      throw ServerException('Error al validar DNI: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> resetPassword(String dni, String newPassword) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resetPasswordEndpoint}');
      final response = await client.post(url, headers: ApiConstants.defaultHeaders, body: jsonEncode({'nro_documento': dni, 'new_password': newPassword})).timeout(ApiConstants.connectionTimeout);
      return jsonDecode(response.body);
    } catch (e) {
      throw ServerException('Error al resetear contraseña: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
      if (conductorJson == null) throw const AuthException('No se encontró el usuario');

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      final conductorMap = (conductorData['conductor'] is Map) ? conductorData['conductor'] : conductorData;
      final int idConductor = _toInt(conductorMap['id_conductor']);
      final int tipo = _toInt(conductorMap['tipo']);

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadProfilePictureEndpoint}');
      final request = http.MultipartRequest('POST', url);
      request.fields['id_usuario'] = idConductor.toString();
      request.fields['tipo'] = tipo.toString();
      request.files.add(await http.MultipartFile.fromPath('foto_perfil', imageFile.path));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      throw ServerException('Error al subir foto de perfil: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> updateVehicleData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
      if (conductorJson == null) throw const AuthException('No se encontró el usuario');

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      final conductorMap = (conductorData['conductor'] is Map) ? conductorData['conductor'] : conductorData;
      final int idConductor = _toInt(conductorMap['id_conductor']);
      final int tipo = _toInt(conductorMap['tipo']);

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateDatosUsuarioEndpoint}');
      final body = <String, dynamic>{'id_usuario': idConductor, 'tipo_usuario': tipo, ...data};
      final response = await client.post(url, headers: ApiConstants.defaultHeaders, body: jsonEncode(body)).timeout(ApiConstants.connectionTimeout);
      return jsonDecode(response.body);
    } catch (e) {
      throw ServerException('Error al actualizar datos del vehículo: $e');
    }
  }

  Future<Map<String, dynamic>> _sendPreRegistroMultipart(
    String endpoint,
    Map<String, dynamic> data,
    Map<String, File> files,
    String errorLabel,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', url);
      data.forEach((key, value) => request.fields[key] = value.toString());
      for (var entry in files.entries) {
        request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value.path));
      }
      final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
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
      throw ServerException('Error al realizar $errorLabel: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> preRegister(Map<String, dynamic> data, Map<String, File> files) {
    return _sendPreRegistroMultipart(
      ApiConstants.preRegistroEndpoint,
      data,
      files,
      'pre-registro',
    );
  }

  @override
  Future<Map<String, dynamic>> conductorPreRegister(Map<String, dynamic> data, Map<String, File> files) {
    return _sendPreRegistroMultipart(
      ApiConstants.conductorPreRegistroEndpoint,
      data,
      files,
      'pre-registro de conductor',
    );
  }

  @override
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.delayed(const Duration(seconds: 1));
      await prefs.remove(AppConstants.userStorageKey);
      return {'success': true, 'message': 'Simulación de eliminación exitosa.'};
    } catch (e) {
      throw CacheException('Error en simulación de eliminación: $e');
    }
  }

  void _saveUserToPrefs(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userStorageKey, jsonEncode(userData));

      // Guardar campos de afiliación en claves dedicadas para que
      // no se pierdan cuando refreshUserData sobreescribe la sesión
      final c = userData['conductor'] is Map
          ? userData['conductor'] as Map<String, dynamic>
          : userData;
      final contratoUrl = c['contrato_afiliacion_url']?.toString();
      final firmada = c['afiliacion_firmada'];
      if (contratoUrl != null) {
        await prefs.setString(AppConstants.contratoAfiliacionUrlKey, contratoUrl);
      }
      await prefs.setBool(AppConstants.afiliacionFirmadaKey, firmada == true || firmada == 1);
    } catch (e) {
      debugPrint('Error al guardar datos de sesión: $e');
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
