import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../../core/constants/api_constants.dart';
import '../models/conductor_model.dart';

abstract class AuthRemoteDataSource {
  Future<ConductorModel> login(String nroDocumento, String password);
  Future<void> logout();
  Future<ConductorModel?> getCurrentUser();
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

  Future<void> _saveUserToPrefs(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('conductor', jsonEncode(userData));
    } catch (e) {
      throw CacheException('Error al guardar usuario: $e');
    }
  }
}
