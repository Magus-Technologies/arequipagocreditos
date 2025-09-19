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
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  
  AuthRemoteDataSourceImpl({http.Client? client}) : client = client ?? http.Client();

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

        // Guardar en SharedPreferences para persistencia
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
      if (e is AppException) {
        rethrow;
      }
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
      final String dni = conductorData['conductor']['nro_documento'];

      final url = Uri.parse('${ApiConstants.baseUrl}/conductor/$dni/refresh');
      final response = await client.get(url).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final freshConductor = ConductorModel.fromJson(data);

        // Actualizar los datos en cache
        await _saveUserToPrefs(data);

        return freshConductor;
      } else {
        // Si falla, devolver los datos del cache
        return getCurrentUser();
      }
    } catch (e) {
      // Si hay error, devolver los datos del cache
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
      final url = Uri.parse('${ApiConstants.baseUrl}/update-password-conductor');

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nro_documento': dni, 'password': newPassword}),
      ).timeout(ApiConstants.connectionTimeout);

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
  Future<Map<String, dynamic>> validateDniForPasswordRecovery(String dni) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/validate-dni');

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nro_documento': dni}),
      ).timeout(ApiConstants.connectionTimeout);

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
  Future<Map<String, dynamic>> resetPassword(String dni, String newPassword) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/reset-password');

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nro_documento': dni, 'password': newPassword}),
      ).timeout(ApiConstants.connectionTimeout);

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
      final String dni = conductorData['conductor']['nro_documento'];

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/upload-profile-picture'),
      );

      request.fields['nro_documento'] = dni;
      request.files.add(
        await http.MultipartFile.fromPath('foto_perfil', imageFile.path),
      );

      var streamedResponse = await request.send().timeout(ApiConstants.connectionTimeout);
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

  Future<void> _saveUserToPrefs(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('conductor', jsonEncode(userData));
    } catch (e) {
      throw CacheException('Error al guardar usuario: $e');
    }
  }
}
