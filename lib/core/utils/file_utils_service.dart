import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileUtilsService {
  /// Guarda un archivo PDF en el almacenamiento local del dispositivo
  static Future<String> savePdfToFile(List<int> pdfBytes, {String? fileName}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = fileName ?? 'documento_$timestamp';
      final file = File('${directory.path}/$name.pdf');

      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      throw Exception('Error al guardar PDF: $e');
    }
  }

  /// Guarda cualquier archivo en el almacenamiento local
  static Future<String> saveFile(List<int> bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      throw Exception('Error al guardar archivo: $e');
    }
  }

  /// Elimina un archivo del almacenamiento local
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si un archivo existe
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el tamaño de un archivo en bytes
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Obtiene el directorio de documentos de la aplicación
  static Future<String> getDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
