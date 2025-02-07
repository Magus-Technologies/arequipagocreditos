import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conductor.dart';

class ApiService {
  static const String baseUrl = "https://tu-servidor.com/api"; // Reemplaza con tu URL

  // Método POST para el login
  static Future<Conductor?> login(String nroDocumento, String password) async {
    final url = Uri.parse('$baseUrl/login');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nro_documento': nroDocumento, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Conductor.fromJson(data);
      } else {
        return null; // Manejar error de credenciales incorrectas
      }
    } catch (e) {
      print("Error en la petición: $e");
      return null;
    }
  }
}
