/// Helper para mapear tipo_usuario a audiencia según el backend.
class AudienciaHelper {
  /// Mapea el tipo de usuario (int) a su audiencia (String).
  /// - 1 → conductores
  /// - 2 → clientes
  /// - 3 → clientes
  /// - 4 → pasajeros_go
  static String fromTipo(int tipo) {
    switch (tipo) {
      case 1:
        return 'conductores';
      case 2:
      case 3:
        return 'clientes';
      case 4:
        return 'pasajeros_go';
      default:
        return 'clientes';
    }
  }
}
