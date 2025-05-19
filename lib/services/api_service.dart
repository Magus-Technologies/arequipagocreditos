import 'dart:convert';
import 'package:arequipagocreditos/models/cuota_financiamiento.dart';
import 'package:arequipagocreditos/models/financiamiento.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conductor_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ApiService {
  static const String baseUrl =
      "https://magusemail.com/arequipago-api/public/api";

  // static const String baseUrl =
  //     "http://192.168.100.2/arequipago-api/public/api";

  static Future<Conductor?> login(String nroDocumento, String password) async {
    final url = Uri.parse('$baseUrl/auth/conductor');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nro_documento': nroDocumento, 'password': password}),
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
}
