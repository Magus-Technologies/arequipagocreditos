class CuponUtils {
  /// Obtiene el nombre para mostrar de una categoría de cupón
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

  /// Obtiene el icono apropiado para una categoría de cupón
  static String getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'restaurantes':
      case 'comida':
      case 'food':
        return '🍽️';
      case 'tiendas':
      case 'shopping':
        return '🛍️';
      case 'servicios':
      case 'services':
        return '🔧';
      case 'entretenimiento':
      case 'entertainment':
        return '🎉';
      default:
        return '🎁';
    }
  }

  /// Obtiene el color apropiado para una categoría de cupón
  static String getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'restaurantes':
      case 'comida':
      case 'food':
        return '#FF6B6B'; // Rojo
      case 'tiendas':
      case 'shopping':
        return '#4ECDC4'; // Verde azulado
      case 'servicios':
      case 'services':
        return '#45B7D1'; // Azul
      case 'entretenimiento':
      case 'entertainment':
        return '#96CEB4'; // Verde
      default:
        return '#FFEAA7'; // Amarillo
    }
  }
}
