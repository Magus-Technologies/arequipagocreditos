import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../../core/constants/app_constants.dart';
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
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');

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
      await prefs.remove(AppConstants.userStorageKey);
    } catch (e) {
      throw CacheException('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<ConductorModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString(AppConstants.userStorageKey);

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
      final conductorJson = prefs.getString(AppConstants.userStorageKey);

      if (conductorJson == null) {
        return null;
      }

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      // support both shapes: { AppConstants.userStorageKey: {...}, ... } or flat conductor object
      final Map<String, dynamic> conductorMap =
          (conductorData['conductor'] is Map)
              ? Map<String, dynamic>.from(conductorData['conductor'])
              : Map<String, dynamic>.from(conductorData);

      final dynamic rawId = conductorMap['id_conductor'] ?? conductorMap['id'];
      final int idConductor = (rawId is int) ? rawId : int.tryParse((rawId ?? '0').toString()) ?? 0;
      final dynamic rawTipo = conductorMap['tipo'];
      final int tipo = (rawTipo is int) ? rawTipo : int.tryParse((rawTipo ?? '0').toString()) ?? 0;

      final endpoint = ApiConstants.perfilUsuarioEndpoint
          .replaceFirst('{id}', idConductor.toString())
          .replaceFirst('{tipo}', tipo.toString());
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
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
            updatedCache['near_expiry_documents'] =
                data['near_expiry_documents'];
          }
        } else {
          updatedCache['conductor'] = data;
          if (data.containsKey('expired_documents')) {
            updatedCache['expired_documents'] = data['expired_documents'];
          }
          if (data.containsKey('near_expiry_documents')) {
            updatedCache['near_expiry_documents'] =
                data['near_expiry_documents'];
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
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
      if (conductorJson == null) {
        throw const AuthException('No se encontró el usuario');
      }

      final conductorData = jsonDecode(conductorJson) as Map<String, dynamic>;
      final String dni = conductorData['conductor']['nro_documento'];
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.updatePasswordConductorEndpoint}',
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
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.validateDniEndpoint}');

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
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resetPasswordEndpoint}');

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

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  @override
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
      if (conductorJson == null) {
        throw const AuthException('No se encontró el usuario');
      }

      final decoded = jsonDecode(conductorJson);
      if (decoded is! Map<String, dynamic>) {
        throw const AuthException('Formato inválido de datos del conductor');
      }
      final conductorData = Map<String, dynamic>.from(decoded);

      // Asegurarse de que exista la clave AppConstants.userStorageKey
      if (conductorData['conductor'] == null ||
          conductorData['conductor'] is! Map) {
        throw const AuthException('Datos de conductor incompletos');
      }
      final Map<String, dynamic> conductorMap = Map<String, dynamic>.from(
        conductorData['conductor'],
      );

      // Convertir de forma segura a int, funciona si el valor viene como int o como String
      final int idConductor = _toInt(conductorMap['id_conductor']);
      final int tipo = _toInt(conductorMap['tipo']);

      if (idConductor <= 0 || tipo <= 0) {
        throw const AuthException('Datos de usuario inválidos');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadProfilePictureEndpoint}'),
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

      // Intentar decodificar la respuesta de forma segura
      final dynamic decodedResponse = jsonDecode(response.body);
      final Map<String, dynamic> responseData =
          (decodedResponse is Map<String, dynamic>) ? decodedResponse : {};

      if (response.statusCode == 200) {
        // Asegurarse que foto_url sea string (si existe)
        final String? fotoUrl =
            responseData['foto_url']?.toString();

        // Actualizar los datos del conductor en SharedPreferences
        conductorMap['foto_perfil'] = fotoUrl;
        conductorMap['foto_perfil_cambiada'] = 1;
        conductorData['conductor'] = conductorMap;

        await prefs.setString(AppConstants.userStorageKey, jsonEncode(conductorData));

        return {
          'success': true,
          'message': responseData['message']?.toString() ?? 'OK',
          'foto_url': fotoUrl,
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message']?.toString() ??
              'Error inesperado: ${response.statusCode}',
        };
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
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
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

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateDatosUsuarioEndpoint}');

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
          await prefs.setString(AppConstants.userStorageKey, jsonEncode(updatedCache));
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
      await prefs.setString(AppConstants.userStorageKey, jsonEncode(userData));
    } catch (e) {
      throw CacheException('Error al guardar usuario: $e');
    }
  }
}
