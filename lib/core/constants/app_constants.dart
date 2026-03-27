class AppConstants {
  // App Info
  static const String appName = 'Arequipa GO Créditos';
  static const String appVersion = '1.1.0';
  
  // Storage Keys
  static const String userStorageKey = 'conductor_v2';
  static const String themeStorageKey = 'theme_mode';
  static const String languageStorageKey = 'language';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxHistorialItems = 100;
  
  // UI Constants
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const double defaultPadding = 16.0;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  static const int dniLength = 15;
  
  // File Upload
  static const int maxImageSizeInBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  
  // Puntaje Scale
  static const int minPuntaje = 0;
  static const int maxPuntaje = 100;
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
}
