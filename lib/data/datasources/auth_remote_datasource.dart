import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../../core/constants/api_constants.dart';
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
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({http.Client? client})
    : client = client ?? http.Client();

  @override
  Future<ConductorModel> login(String nroDocumento, String password) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/conductor');

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nro_documento': nroDocumento,
              'password': password,
            }),
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final conductor = ConductorModel.fromJson(data);
        // Limpiar datos anteriores y guardar nuevo
        await _saveUserToPrefs(data);

        return conductor;
      } else if (response.statusCode == 401) {
        throw const AuthException('Credenciales incorrectas');
      } else if (response.statusCode >= 500) {
        throw const ServerException('Error del servidor');
      } else {
        throw ServerException('Error de autenticación: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error de conexión: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('conductor');
    } catch (e) {
      throw CacheException('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<ConductorModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');

      if (conductorJson != null) {
        final data = jsonDecode(conductorJson) as Map<String, dynamic>;
        return ConductorModel.fromJson(data);
      }

      return null;
    } catch (e) {
      throw CacheException('Error al obtener usuario: $e');
    }
  }

  @override
  Future<ConductorModel?> refreshUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');

      if (conductorJson == null) {
        return null;
      }

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      // support both shapes: { 'conductor': {...}, ... } or flat conductor object
      final Map<String, dynamic> conductorMap =
          (conductorData['conductor'] is Map)
              ? Map<String, dynamic>.from(conductorData['conductor'])
              : Map<String, dynamic>.from(conductorData);

      final int idConductor =
          conductorMap['id_conductor'] is int
              ? conductorMap['id_conductor']
              : int.tryParse((conductorMap['id_conductor'] ?? '').toString()) ??
                  0;
      final int tipo =
          conductorMap['tipo'] is int
              ? conductorMap['tipo']
              : int.tryParse((conductorMap['tipo'] ?? '').toString()) ?? 0;

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/get-perfil-usuario/$idConductor/$tipo',
      );
      final response = await client
          .get(url)
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final updatedCache = Map<String, dynamic>.from(conductorData);
        if (data.containsKey('conductor')) {
          // response already wrapped
          updatedCache.addAll(data);
          // If backend provides document alerts, persist them at top-level so UI can read them
          if (data.containsKey('expired_documents')) {
            updatedCache['expired_documents'] = data['expired_documents'];
          }
          if (data.containsKey('near_expiry_documents')) {
            updatedCache['near_expiry_documents'] = data['near_expiry_documents'];
          }
        } else {
          updatedCache['conductor'] = data;
          if (data.containsKey('expired_documents')) {
            updatedCache['expired_documents'] = data['expired_documents'];
          }
          if (data.containsKey('near_expiry_documents')) {
            updatedCache['near_expiry_documents'] = data['near_expiry_documents'];
          }
        }
        await _saveUserToPrefs(updatedCache);
        return ConductorModel.fromJson(updatedCache);
      } else {
        return getCurrentUser();
      }
    } catch (e) {
      return getCurrentUser();
    }
  }

  @override
  Future<Map<String, dynamic>> changePassword(String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      if (conductorJson == null) {
        throw const AuthException('No se encontró el usuario');
      }

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      final String dni = conductorData['conductor']['nro_documento'];
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/update-password-conductor',
      );

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nro_documento': dni, 'password': newPassword}),
          )
          .timeout(ApiConstants.connectionTimeout);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error al cambiar contraseña: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> validateDniForPasswordRecovery(
    String dni,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/validate-dni');

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nro_documento': dni}),
          )
          .timeout(ApiConstants.connectionTimeout);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'conductor': responseData['conductor'],
        };
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error al validar DNI: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> resetPassword(
    String dni,
    String newPassword,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/reset-password');

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nro_documento': dni, 'password': newPassword}),
          )
          .timeout(ApiConstants.connectionTimeout);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error al restablecer contraseña: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      if (conductorJson == null) {
        throw const AuthException('No se encontró el usuario');
      }

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      final int idConductor = conductorData['conductor']['id_conductor'];
      final int tipo = conductorData['conductor']['tipo'];

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/upload-profile-picture'),
      );

      request.fields['idConductor'] = idConductor.toString();
      request.fields['tipo'] = tipo.toString();
      request.files.add(
        await http.MultipartFile.fromPath('foto_perfil', imageFile.path),
      );

      var streamedResponse = await request.send().timeout(
        ApiConstants.connectionTimeout,
      );
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Actualizar los datos del conductor en SharedPreferences
        conductorData['conductor']['foto_perfil'] = responseData['foto_url'];
        conductorData['conductor']['foto_perfil_cambiada'] = 1;
        await prefs.setString('conductor', jsonEncode(conductorData));

        return {
          'success': true,
          'message': responseData['message'],
          'foto_url': responseData['foto_url'],
        };
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException('Error al subir foto de perfil: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> updateVehicleData(
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      if (conductorJson == null) {
        throw const AuthException('No se encontró el usuario');
      }

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      final Map<String, dynamic> conductorMap =
          (conductorData['conductor'] is Map)
              ? Map<String, dynamic>.from(conductorData['conductor'])
              : Map<String, dynamic>.from(conductorData);

      final int idConductor =
          conductorMap['id_conductor'] is int
              ? conductorMap['id_conductor']
              : int.tryParse((conductorMap['id_conductor'] ?? '').toString()) ??
                  0;
      final int tipo =
          conductorMap['tipo'] is int
              ? conductorMap['tipo']
              : int.tryParse((conductorMap['tipo'] ?? '').toString()) ?? 0;

      final body = <String, dynamic>{
        'id_usuario': idConductor,
        'tipo_usuario': tipo,
        ...data,
      };

      final url = Uri.parse('${ApiConstants.baseUrl}/update-datos-usuario');

      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.connectionTimeout);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        if (responseData.containsKey('conductor')) {
          await _saveUserToPrefs(responseData);
        } else {
          final updatedCache = Map<String, dynamic>.from(conductorData);
          final existingConductor = Map<String, dynamic>.from(conductorMap);

          // prefer server response fields, otherwise apply submitted data
          if (responseData.isNotEmpty) {
            for (final entry in responseData.entries) {
              existingConductor[entry.key] = entry.value;
            }
          } else {
            for (final entry in data.entries) {
              existingConductor[entry.key] = entry.value;
            }
          }

          updatedCache['conductor'] = existingConductor;
          await prefs.setString('conductor', jsonEncode(updatedCache));
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Datos actualizados',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Error al actualizar',
          'data': responseData,
        };
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error al actualizar datos del vehículo: $e');
    }
  }

  Future<void> _saveUserToPrefs(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('conductor', jsonEncode(userData));
    } catch (e) {
      throw CacheException('Error al guardar usuario: $e');
    }
  }
}
