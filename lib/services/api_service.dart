import 'dart:convert';
import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/data/models/cuota_financiamiento_model.dart';
import 'package:arequipagocreditos/data/models/cupon_model.dart';
import 'package:arequipagocreditos/data/models/financiamiento_model.dart';
import 'package:arequipagocreditos/data/models/puntuacion_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ApiService {
  // Configuración de URLs
  static const String _localUrl =
      "http://192.168.100.2/arequipago-api/public/api";
  static const String _productionUrl =
      "https://magusemail.com/arequipago-api/public/api";
  static const String _cuponesUrl = "https://arequipago-ventas.pe/ajs";

  // Cambiar este valor para alternar entre desarrollo y producción
  static const bool _useProduction = true;

  static String get baseUrl => _useProduction ? _productionUrl : _localUrl;
  static String get cuponesBaseUrl => _cuponesUrl;


  static Future<ConductorModel?> login(String nroDocumento, String password) async {
    final url = Uri.parse('$baseUrl/auth/conductor');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nro_documento': nroDocumento,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 30), // Timeout de 30 segundos
            onTimeout: () {
              throw Exception('Timeout de conexión');
            },
          );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ConductorModel conductor = ConductorModel.fromJson(data);

        // Guardar los datos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('conductor', jsonEncode(data)); // Guardar como JSON

        return conductor;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Método para cerrar sesión
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('conductor'); // Eliminar los datos guardados
  }

  // Método para verificar si hay un usuario logueado
  static Future<ConductorModel?> getLoggedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final conductorJson = prefs.getString('conductor');

    if (conductorJson != null) {
      final Map<String, dynamic> decodedData = jsonDecode(conductorJson);
      return ConductorModel.fromJson(decodedData);
    }

    return null;
  }

  // Método para obtener datos frescos del usuario desde el servidor
  static Future<ConductorModel?> refreshUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');

      if (conductorJson == null) {
        return null;
      }

      final conductorData = jsonDecode(conductorJson);
      final String dni = conductorData['conductor']['nro_documento'];

      final url = Uri.parse('$baseUrl/conductor/$dni/refresh');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ConductorModel freshConductor = ConductorModel.fromJson(data);

        // Actualizar los datos en cache
        await saveLoggedUser(freshConductor);

        return freshConductor;
      } else {
        // Si falla, devolver los datos del cache
        return getLoggedUser();
      }
    } catch (e) {
      // Si hay error, devolver los datos del cache
      return getLoggedUser();
    }
  }

  static Future<void> saveLoggedUser(ConductorModel conductor) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('conductor', jsonEncode(conductor.toJson()));
  }

  static Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      if (conductorJson == null) {
        return {'success': false, 'message': 'No se encontró el usuario'};
      }

      final conductorData = jsonDecode(conductorJson);
      final String dni = conductorData['conductor']['nro_documento'];
      final url = Uri.parse('$baseUrl/update-password');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nro_documento': dni, 'password': newPassword}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  static Future<Map<String, dynamic>> validateDniForPasswordRecovery(
    String dni,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/validate-dni');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nro_documento': dni}),
      );

      final responseData = jsonDecode(response.body);
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
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
    String dni,
    String newPassword,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/reset-password');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nro_documento': dni, 'password': newPassword}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  static Future<Map<String, dynamic>> uploadProfilePicture(
    File imageFile,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      if (conductorJson == null) {
        return {'success': false, 'message': 'No se encontró el usuario'};
      }

      final conductorData = jsonDecode(conductorJson);
      final String dni = conductorData['conductor']['nro_documento'];

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-profile-picture'),
      );

      request.fields['nro_documento'] = dni;
      request.files.add(
        await http.MultipartFile.fromPath('foto_perfil', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Actualizar los datos del conductor en SharedPreferences
        conductorData['conductor']['foto_perfil'] = responseData['foto_url'];
        conductorData['conductor']['foto_perfil_cambiada'] = 1;
        prefs.setString('conductor', jsonEncode(conductorData));

        return {
          'success': true,
          'message': responseData['message'],
          'foto_url': responseData['foto_url'],
        };
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  static Future<List<FinanciamientoModel>> fetchFinanciamientos(
    int idConductor,
    int tipo,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/list-financiamiento/$idConductor/$tipo'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((json) => FinanciamientoModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los financiamientos');
    }
  }

  static Future<List<CuotaFinanciamientoModel>> fetchCuotas(
    int idFinanciamiento,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/financiamiento-detalle/$idFinanciamiento"),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((json) => CuotaFinanciamientoModel.fromJson(json)).toList();
    } else {
      throw Exception("Error al cargar las cuotas (${response.statusCode})");
    }
  }

  // Función para guardar el archivo PDF en el almacenamiento local
  Future<String> savePdfToFile(List<int> pdfBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/prestamo_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(pdfBytes); // Guarda el archivo PDF
    return file.path; // Retorna la ruta del archivo guardado
  }

  // Métodos para manejo de puntuaciones
  static Future<PuntuacionModel?> getPuntuacionYDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      if (conductorJson == null) {
        return null;
      }

      final conductorData = jsonDecode(conductorJson);
      final int idConductor = conductorData['conductor']['id_conductor'];
      final String tipo =
          conductorData['tipo'].toString() == "1" ? 'conductor' : 'cliente';
      // Usar tu endpoint real
      final response = await http.get(
        Uri.parse(
          'https://arequipago-ventas.pe/obtenerPuntajeYDatos?tipo=$tipo&id=$idConductor',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PuntuacionModel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<PuntuacionModel?> getPuntuacionCredito() async {
    try {
      final response = await getPuntuacionYDatos();
      if (response != null && response.success) {
        return PuntuacionModel.fromJson(response.data.puntaje);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<HistorialPuntos>> getHistorialPuntos() async {
    try {
      final response = await getPuntuacionYDatos();
      if (response != null && response.success) {
        // Ordenar por fecha más reciente primero - mostrar todo el historial
        final historial = response.data.historial;
        historial.sort(
          (a, b) => b.fechaReferencia.compareTo(a.fechaReferencia),
        );
        return historial; // Devolver todo el historial sin limitación
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Método para obtener cupones disponibles
  static Future<List<CuponModel>> getCupones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      if (conductorJson == null) {
        return [];
      }

      final conductorData = jsonDecode(conductorJson);
      // Verificar que existe la clave 'conductor'
      if (!conductorData.containsKey('conductor')) {
        return [];
      }

      final conductorInfo = conductorData['conductor'];
      // Verificar que existen las claves necesarias
      if (!conductorInfo.containsKey('id_conductor')) {
        return [];
      }

      final int idConductor = conductorInfo['id_conductor'];
      final String tipo =
          conductorInfo['tipo'].toString() == "1" ? 'conductor' : 'cliente';

      // Llamar a tu API real
      final response = await http.get(
        Uri.parse('$cuponesBaseUrl/cupones/verificar/$tipo/$idConductor'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['tiene_cupones'] == true && data['cupones'] != null) {
          List<dynamic> cuponesData = data['cupones'];

          // Agregar campos adicionales que necesita el modelo
          List<Map<String, dynamic>> cuponesFormateados =
              cuponesData.map((cupon) {
                Map<String, dynamic> cuponFormateado =
                    Map<String, dynamic>.from(cupon);

                // Agregar campos por defecto si no existen
                cuponFormateado['categoria'] =
                    cuponFormateado['categoria'] ?? 'Promociones';
                cuponFormateado['descripcion'] =
                    cuponFormateado['descripcion'] ??
                    'Descuento especial disponible para ti';
                cuponFormateado['codigo'] =
                    cuponFormateado['codigo'] ?? 'CUPON${cupon['id']}';
                cuponFormateado['empresa'] =
                    cuponFormateado['empresa'] ?? 'Arequipa GO';
                cuponFormateado['condiciones'] =
                    cuponFormateado['condiciones'] ??
                    'Válido según términos y condiciones.';

                return cuponFormateado;
              }).toList();

          return cuponesFormateados
              .map((data) => CuponModel.fromJson(data))
              .toList();
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print(e);
      return [];
    }
  }

  // Método para usar un cupón
  static Future<Map<String, dynamic>> usarCupon(int idCupon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      if (conductorJson == null) {
        return {'success': false, 'message': 'No se encontró el usuario'};
      }

      final conductorData = jsonDecode(conductorJson);
      if (!conductorData.containsKey('conductor')) {
        return {'success': false, 'message': 'Datos de conductor inválidos'};
      }

      final conductorInfo = conductorData['conductor'];
      if (!conductorInfo.containsKey('id_conductor')) {
        return {'success': false, 'message': 'ID de conductor no encontrado'};
      }

      final int idConductor = conductorInfo['id_conductor'];

      // Llamar a la API para usar el cupón
      final response = await http.post(
        Uri.parse('$cuponesBaseUrl/cupones/usar-codigo/$idConductor/$idCupon'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Cupón aplicado correctamente',
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error al usar el cupón',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}
