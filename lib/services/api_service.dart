import 'dart:convert';
import 'package:arequipagocreditos/models/cuota_financiamiento.dart';
import 'package:arequipagocreditos/models/financiamiento.dart';
import 'package:arequipagocreditos/models/puntuacion_model.dart';
import 'package:arequipagocreditos/models/cupon.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conductor_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ApiService {
  // Configuración de URLs
  static const String _localUrl = "http://192.168.100.2/arequipago-api/public/api";
  static const String _productionUrl = "https://magusemail.com/arequipago-api/public/api";
  
  // Cambiar este valor para alternar entre desarrollo y producción
  static const bool _useProduction = true;
  
  static String get baseUrl => _useProduction ? _productionUrl : _localUrl;

  // Método para probar conectividad
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test'), // Endpoint de prueba
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout de conexión');
        },
      );

      return {
        'success': true,
        'message': 'Conexión exitosa',
        'status': response.statusCode,
        'url': baseUrl,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'url': baseUrl,
      };
    }
  }

  static Future<Conductor?> login(String nroDocumento, String password) async {
    final url = Uri.parse('$baseUrl/auth/conductor');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nro_documento': nroDocumento, 'password': password}),
      ).timeout(
        const Duration(seconds: 30), // Timeout de 30 segundos
        onTimeout: () {
          throw Exception('Timeout de conexión');
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Conductor conductor = Conductor.fromJson(data);

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
  static Future<Conductor?> getLoggedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final conductorJson = prefs.getString('conductor');

    if (conductorJson != null) {
      final Map<String, dynamic> decodedData = jsonDecode(conductorJson);
      return Conductor.fromJson(decodedData);
    }

    return null;
  }

  // Método para obtener datos frescos del usuario desde el servidor
  static Future<Conductor?> refreshUserData() async {
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
        Conductor freshConductor = Conductor.fromJson(data);

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

  static Future<void> saveLoggedUser(Conductor conductor) async {
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

  static Future<List<Financiamiento>> fetchFinanciamientos(
    int idConductor,
    int tipo,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/list-financiamiento/$idConductor/$tipo'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((json) => Financiamiento.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los financiamientos');
    }
  }

  static Future<List<CuotaFinanciamiento>> fetchCuotas(
    int idFinanciamiento,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/financiamiento-detalle/$idFinanciamiento"),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((json) => CuotaFinanciamiento.fromJson(json)).toList();
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
  static Future<PuntuacionCredito?> getPuntuacionCredito() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      if (conductorJson == null) {
        return null;
      }

      final conductorData = jsonDecode(conductorJson);
      final int idConductor = conductorData['conductor']['id_conductor'];

      final response = await http.get(
        Uri.parse('$baseUrl/puntuacion-credito/$idConductor'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PuntuacionCredito.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<List<HistorialPuntos>> getHistorialPuntos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
      if (conductorJson == null) {
        return [];
      }

      final conductorData = jsonDecode(conductorJson);
      final int idConductor = conductorData['conductor']['id_conductor'];

      final response = await http.get(
        Uri.parse('$baseUrl/historial-puntos/$idConductor'),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((json) => HistorialPuntos.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Método para obtener cupones disponibles
  static Future<List<Cupon>> getCupones() async {
    try {
      // Simular datos ficticios para demostración
      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // Simular tiempo de carga

      final List<Map<String, dynamic>> cuponesData = [
        {
          'id': 1,
          'titulo': '2x1 en Pizza Familiar',
          'descripcion':
              'Lleva 2 pizzas familiares por el precio de 1. Válido en cualquier sucursal.',
          'categoria': 'Restaurantes',
          'descuento': 50.0,
          'tipo_descuento': 'porcentaje',
          'codigo': 'PIZZA2X1',
          'fecha_vencimiento':
              DateTime.now().add(const Duration(days: 15)).toIso8601String(),
          'es_activo': true,
          'imagen': 'https://via.placeholder.com/300x200',
          'empresa': 'Pizza Palace',
          'condiciones':
              'No válido con otras promociones. Mínimo S/ 50 de compra.',
          'limite_usos': 100,
          'usos_restantes': 87,
        },
        {
          'id': 2,
          'titulo': '30% OFF en Ropa de Temporada',
          'descripcion':
              'Descuento especial en toda la colección de primavera-verano.',
          'categoria': 'Tiendas',
          'descuento': 30.0,
          'tipo_descuento': 'porcentaje',
          'codigo': 'VERANO30',
          'fecha_vencimiento':
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'es_activo': true,
          'imagen': 'https://via.placeholder.com/300x200',
          'empresa': 'Fashion Store',
          'condiciones': 'Válido en tiendas participantes.',
          'limite_usos': null,
          'usos_restantes': null,
        },
        {
          'id': 3,
          'titulo': 'Lavado Premium Gratis',
          'descripcion': 'Servicio de lavado premium sin costo adicional.',
          'categoria': 'Servicios',
          'descuento': 25.0,
          'tipo_descuento': 'monto',
          'codigo': 'LAVADO25',
          'fecha_vencimiento':
              DateTime.now().add(const Duration(days: 10)).toIso8601String(),
          'es_activo': true,
          'imagen': 'https://via.placeholder.com/300x200',
          'empresa': 'AutoWash Pro',
          'condiciones': 'Solo para vehículos sedan y hatchback.',
          'limite_usos': 50,
          'usos_restantes': 23,
        },
        {
          'id': 4,
          'titulo': 'Entrada 2x1 al Cine',
          'descripcion':
              '2 entradas por el precio de 1 en funciones de lunes a jueves.',
          'categoria': 'Entretenimiento',
          'descuento': 50.0,
          'tipo_descuento': 'porcentaje',
          'codigo': 'CINE2X1',
          'fecha_vencimiento':
              DateTime.now().add(const Duration(days: 20)).toIso8601String(),
          'es_activo': true,
          'imagen': 'https://via.placeholder.com/300x200',
          'empresa': 'Cinemark',
          'condiciones': 'No válido en estrenos y funciones 3D.',
          'limite_usos': 200,
          'usos_restantes': 156,
        },
        {
          'id': 5,
          'titulo': 'Descuento en Combustible',
          'descripcion':
              'S/ 0.20 de descuento por galón en combustible premium.',
          'categoria': 'Servicios',
          'descuento': 0.20,
          'tipo_descuento': 'monto',
          'codigo': 'GASOLINA20',
          'fecha_vencimiento':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'es_activo': true,
          'imagen': 'https://via.placeholder.com/300x200',
          'empresa': 'Repsol',
          'condiciones': 'Mínimo 10 galones. Válido 24 horas.',
          'limite_usos': 500,
          'usos_restantes': 342,
        },
        {
          'id': 6,
          'titulo': 'Buffet Familiar Especial',
          'descripcion':
              'Buffet completo para 4 personas con bebidas incluidas.',
          'categoria': 'Restaurantes',
          'descuento': 40.0,
          'tipo_descuento': 'porcentaje',
          'codigo': 'BUFFET40',
          'fecha_vencimiento':
              DateTime.now()
                  .subtract(const Duration(days: 2))
                  .toIso8601String(), // Vencido
          'es_activo': false,
          'imagen': 'https://via.placeholder.com/300x200',
          'empresa': 'Restaurant El Dorado',
          'condiciones': 'Válido solo fines de semana.',
          'limite_usos': 80,
          'usos_restantes': 0,
        },
      ];

      return cuponesData.map((data) => Cupon.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }
}
