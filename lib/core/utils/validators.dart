import '../constants/app_constants.dart';

class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return 'La contraseña debe tener al menos ${AppConstants.minPasswordLength} caracteres';
    }
    
    if (value.length > AppConstants.maxPasswordLength) {
      return 'La contraseña no puede tener más de ${AppConstants.maxPasswordLength} caracteres';
    }
    
    return null;
  }
  
  static String? validateDni(String? value) {
    if (value == null || value.isEmpty) {
      return 'El DNI es requerido';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'El DNI solo debe contener números';
    }
    
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }
    
    if (value.length != 9) {
      return 'El teléfono debe tener 9 dígitos';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'El teléfono solo debe contener números';
    }
    
    if (!value.startsWith('9')) {
      return 'El teléfono debe empezar con 9';
    }
    
    return null;
  }
  
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }
  
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName debe ser un número válido';
    }
    
    return null;
  }
  
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numericValidation = validateNumeric(value, fieldName);
    if (numericValidation != null) return numericValidation;
    
    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName debe ser mayor a 0';
    }
    
    return null;
  }
}
