class ApiConstants {
  // Base URLs
  static const String baseUrlLocal =
      "http://192.168.100.50/arequipago-api/public/api";

  /// Dominio raíz del backend. ÚNICO lugar donde se define el host: el resto
  /// de las URLs (api, storage, políticas) se derivan de acá.
  /// Se puede sobreescribir al compilar sin tocar código:
  ///   flutter build apk --dart-define=API_DOMAIN=https://otro-dominio.pe
  /// http://credigo.test/ local
  static const String baseDomain = String.fromEnvironment(
    'API_DOMAIN',
    defaultValue: 'https://arequipago-ventas.pe',
  );

  static const String baseUrlProduction = "$baseDomain/api";
  static const String storageUrl = "$baseDomain/storage";


  static const String imagenesBaseUrl = storageUrl;
  static const String politicaPrivacidadUrl = "$baseDomain/politica-privacidad";


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
  static const String conductorPreRegistroEndpoint = '/app/conductores/pre-registro';
  static const String conductorEstadoEndpoint = '/app/conductores/{id}/estado';
  static const String izipayInfoEndpoint = '/app/inscripcion/izipay-info/{id}';
  static const String ordenCajaInscripcionEndpoint = '/app/inscripcion/orden-caja/{id}';
  static const String izipayCapturaEndpoint = '/app/inscripcion/izipay-captura';
  static const String ubigeoDepartamentosEndpoint = '/ubicaciones/departamentos';
  static const String ubigeoProvinciasEndpoint = '/ubicaciones/provincias/{codigo}';
  static const String ubigeoDistritosEndpoint = '/ubicaciones/distritos/{codigo}';
  static const String plataformasEndpoint = '/app/plataformas';
  static const String deleteAccountEndpoint = '/app/conductor/eliminar-cuenta';
  static const String pagarCuotaEndpoint = '/app/pagar-cuota';
  static const String reporteCuotaEndpoint = '/app/reporte-cuota/{id}';
  static const String perfilUsuarioEndpoint = '/app/get-perfil-usuario/{id}/{tipo}';
  static const String financiamientosEndpoint = '/app/list-financiamiento/{id}/{tipo}';
  static const String cuotasEndpoint = '/app/financiamientos/{id}';
  static const String beneficiosEndpoint = '/app/promociones/beneficios';
  static const String serviciosTalleresBannersEndpoint = '/app/promociones/servicios/banners';
  static const String appVersionEndpoint = '/app/version';
  static const String ordenesPagoEndpoint = '/app/clientes/{clienteId}/ordenes-pago';
  static const String talleresListEndpoint = '/app/talleres-list';
  static const String talleresListServiciosEndpoint = '/app/talleres-list/servicios';
  static const String talleresCalificarEndpoint = '/app/talleres-list/{id}/calificar';
  static const String miNivelTallerEndpoint = '/app/talleres/mi-nivel/{clienteConductorId}';
  static const String comerciosListEndpoint = '/app/comercios-list';
  static const String comerciosCategoriasEndpoint = '/app/comercios-list/categorias';

  static const String cuponesEndpoint = '/app/promociones/cupones/listar';
  static const String firmarEndpoint = '/app/firmar/{tipo}/{id}';

  static const String resumenCrediticioEndpoint = '/app/resumen-crediticio';
  static const String puntajeEndpoint = '/app/puntaje-crediticio/detalle';
  static const String usarCuponEndpoint = '/app/promociones/cupones/{id}/uso';

  static const String notificationsEndpoint = '/notifications/{id}/{tipo}';
  static const String markAsReadEndpoint = '/notifications/{notificationId}/{id}/{tipo}/read';
  static const String readAllNotificationsEndpoint = '/notifications/read-all/{id}/{tipo}';
  static const String deleteNotificationEndpoint = '/notifications/{notificationId}/{id}/{tipo}';
  /// Borra las notificaciones ya leidas; con ?todas=1 borra tambien las no leidas.
  static const String deleteAllNotificationsEndpoint = '/notifications/delete-all/{id}/{tipo}';
  
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
