class ApiConstants {
  // Base URLs
  static const String baseUrlLocal =
      "http://192.168.100.50/arequipago-api/public/api";
  static const String baseUrlProduction =
      "https://arequipago-ventas.pe/api";
  static const String storageUrl =
      "https://arequipago-ventas.pe/storage";


  static const String imagenesBaseUrl = "https://arequipago-ventas.pe/storage";
  static const String politicaPrivacidadUrl = "https://arequipago-ventas.pe/politica-privacidad";


  // Environment
  static const bool useProduction = true;
  static String get baseUrl => useProduction ? baseUrlProduction : baseUrlLocal;

  // Endpoints
  static const String loginEndpoint = '/app/auth/conductor';
  static const String validateDniEndpoint = '/app/validate-dni';
  static const String resetPasswordEndpoint = '/app/reset-password';
  static const String uploadProfilePictureEndpoint = '/app/upload-profile-picture';
  static const String updatePasswordConductorEndpoint = '/app/update-password-conductor';
  static const String updateDatosUsuarioEndpoint = '/app/update-datos-usuario';
  static const String perfilPasajeroEndpoint = '/app/pasajeros/{id}';
  static const String preRegistroEndpoint = '/app/pasajeros/pre-registro';
  static const String deleteAccountEndpoint = '/app/conductor/eliminar-cuenta';
  static const String pagarCuotaEndpoint = '/app/pagar-cuota';
  static const String reporteCuotaEndpoint = '/app/reporte-cuota/{id}';
  static const String perfilUsuarioEndpoint = '/app/get-perfil-usuario/{id}/{tipo}';
  static const String financiamientosEndpoint = '/app/list-financiamiento/{id}/{tipo}';
  static const String cuotasEndpoint = '/app/financiamientos/{id}';
  static const String beneficiosEndpoint = '/app/promociones/beneficios';

  static const String cuponesEndpoint = '/app/promociones/cupones/listar';
  static const String firmarEndpoint = '/app/firmar/{tipo}/{id}';

  static const String resumenCrediticioEndpoint = '/app/resumen-crediticio';
  static const String puntajeEndpoint = '/app/puntaje-crediticio/detalle';
  static const String usarCuponEndpoint = '/app/promociones/cupones/{id}/uso';

  static const String notificationsEndpoint = '/notifications/{id}/{tipo}';
  static const String markAsReadEndpoint = '/notifications/{notificationId}/{id}/{tipo}/read';
  static const String readAllNotificationsEndpoint = '/notifications/read-all/{id}/{tipo}';
  static const String deleteNotificationEndpoint = '/notifications/{notificationId}/{id}/{tipo}';
  
  // New endpoints for financing flow
  static const String createFinanciamientoEndpoint = '/app/financiamientos';
  static const String documentosFirmadosEndpoint = '/app/documentos-firmados/{id}';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Normaliza una URL relativa anteponiendo el host base (sin /api)
  static String normalizeUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // El host base es la URL raíz sin el segmento /api
    final uri = Uri.parse(baseUrl);
    final hostBase = '${uri.scheme}://${uri.host}';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$hostBase/$cleanPath';
  }
}
