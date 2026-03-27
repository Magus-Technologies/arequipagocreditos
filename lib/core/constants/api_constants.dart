class ApiConstants {
  // Base URLs
  static const String baseUrlLocal =
      "http://192.168.100.50/arequipago-api/public/api";
  static const String baseUrlProduction =
      "https://magusemail.com/arequipago-api/public/api";
  static const String storageUrl =
      "https://arequipago-ventas.pe/storage";

  // Deprecated URLs (Unified into baseUrlProduction)
  static const String apiBaseUrl = "https://arequipago-ventas.pe/api";
  static const String imagenesBaseUrl = "https://arequipago-ventas.pe/storage";

  // Environment
  static const bool useProduction = true;
  static String get baseUrl => useProduction ? baseUrlProduction : baseUrlLocal;

  // Endpoints
  static const String loginEndpoint = '/auth/conductor';
  static const String refreshUserEndpoint = '/conductor/{dni}/refresh';
  static const String updatePasswordEndpoint = '/update-password';
  static const String validateDniEndpoint = '/validate-dni';
  static const String resetPasswordEndpoint = '/reset-password';
  static const String uploadProfilePictureEndpoint = '/upload-profile-picture';
  static const String financiamientosEndpoint =
      '/list-financiamiento/{id}/{tipo}';
  static const String cuotasEndpoint = '/app/financiamientos/{id}';
  static const String beneficiosEndpoint = '/app/promociones/beneficios';

  static const String cuponesEndpoint = '/app/promociones/cupones/listar';

  static const String resumenCrediticioEndpoint = '/app/resumen-crediticio';
  static const String puntajeEndpoint = '/app/puntaje-crediticio/detalle';
  static const String usarCuponEndpoint = '/app/promociones/cupones/{id}/uso';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
