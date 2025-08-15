class ApiConstants {
  // Base URLs
  static const String baseUrlLocal = "http://192.168.100.2/arequipago-api/public/api";
  static const String baseUrlProduction = "https://magusemail.com/arequipago-api/public/api";
  static const String cuponesBaseUrl = "https://arequipago-ventas.pe/ajs";
  static const String puntajeBaseUrl = "https://arequipago-ventas.pe";
  
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
  static const String financiamientosEndpoint = '/list-financiamiento/{id}/{tipo}';
  static const String cuotasEndpoint = '/financiamiento-detalle/{id}';
  static const String puntajeEndpoint = '/obtenerPuntajeYDatos';
  static const String cuponesEndpoint = '/cupones/verificar/{tipo}/{id}';
  static const String usarCuponEndpoint = '/cupones/usar-codigo/{idConductor}/{idCupon}';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
