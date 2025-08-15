import 'package:arequipagocreditos/data/models/cupon_model.dart';

import 'api_service.dart';

class CuponesService {
  static Future<List<CuponModel>> getCupones() async {
    try {
      return await ApiService.getCupones();
    } catch (e) {
      throw Exception('Error al cargar cupones: $e');
    }
  }

  static Future<Map<String, dynamic>> usarCupon(int idCupon) async {
    try {
      return await ApiService.usarCupon(idCupon);
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  static String getCategoryDisplayName(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'restaurantes':
      case 'comida':
      case 'food':
        return 'Restaurantes';
      case 'tiendas':
      case 'shopping':
        return 'Tiendas';
      case 'servicios':
      case 'services':
        return 'Servicios';
      case 'entretenimiento':
      case 'entertainment':
        return 'Entretenimiento';
      default:
        return 'Promociones';
    }
  }

  static List<CuponModel> filtrarCuponesPorCategoria(List<CuponModel> cupones, String categoria) {
    if (categoria == 'Todos') {
      return cupones;
    }
    return cupones.where((cupon) => getCategoryDisplayName(cupon.categoria) == categoria).toList();
  }
}
