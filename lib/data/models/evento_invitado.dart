import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

/// Quien compra tickets de un evento PÚBLICO sin tener cuenta (o sin poder entrar con ella): el servidor lo reconoce por su documento
/// y su teléfono, sin sesión. Sus datos se guardan en el celular para no pedírselos de nuevo y para que «Mis tickets» funcione sin
/// iniciar sesión (TK-0450).
class EventoInvitado {
  final String nombre;
  final String documento;
  final String telefono;
  final String? correo;

  const EventoInvitado({
    required this.nombre,
    required this.documento,
    required this.telefono,
    this.correo,
  });

  /// Con los datos ya limpios: espacios de más fuera, documento en mayúsculas, teléfono solo con dígitos (y un «+» inicial si lo trae) y
  /// correo vacío = sin correo.
  factory EventoInvitado.normalizado({
    required String nombre,
    required String documento,
    required String telefono,
    String? correo,
  }) {
    final mail = correo?.trim() ?? '';
    return EventoInvitado(
      nombre: nombre.trim().replaceAll(RegExp(r'\s+'), ' '),
      documento: documento.trim().toUpperCase(),
      telefono: EventoInvitadoValidador.limpiarTelefono(telefono),
      correo: mail.isEmpty ? null : mail,
    );
  }

  factory EventoInvitado.fromJson(Map<String, dynamic> json) {
    final correo = json['correo']?.toString().trim() ?? '';
    return EventoInvitado(
      nombre: json['nombre']?.toString() ?? '',
      documento: json['documento']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      correo: correo.isEmpty ? null : correo,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'documento': documento,
        'telefono': telefono,
        'correo': correo,
      };

  /// Con nombre, documento y teléfono válidos se puede COMPRAR. Quien solo consultó sus tickets (documento + teléfono) no trae nombre:
  /// para comprar se le pide.
  bool get puedeComprar =>
      EventoInvitadoValidador.nombre(nombre) == null &&
      EventoInvitadoValidador.documento(documento) == null &&
      EventoInvitadoValidador.telefono(telefono) == null;

  /// Con documento y teléfono válidos se pueden CONSULTAR sus tickets.
  bool get puedeConsultar =>
      EventoInvitadoValidador.documento(documento) == null && EventoInvitadoValidador.telefono(telefono) == null;

  EventoInvitado copyWith({String? nombre, String? documento, String? telefono, String? correo}) => EventoInvitado(
        nombre: nombre ?? this.nombre,
        documento: documento ?? this.documento,
        telefono: telefono ?? this.telefono,
        correo: correo ?? this.correo,
      );

  @override
  bool operator ==(Object other) =>
      other is EventoInvitado &&
      other.nombre == nombre &&
      other.documento == documento &&
      other.telefono == telefono &&
      other.correo == correo;

  @override
  int get hashCode => Object.hash(nombre, documento, telefono, correo);
}

/// Las mismas reglas que valida el servidor (nombre de 3 a 200 letras, documento de 6 a 15 letras o números, teléfono de 7 a 15 dígitos,
/// correo opcional): así la persona ve el error en el formulario y no después de subir la captura. Devuelven el mensaje, o null si está bien.
class EventoInvitadoValidador {
  static const String _sinNombre = 'Escribe tu nombre completo.';

  static String? nombre(String? valor) {
    final texto = (valor ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (texto.isEmpty) return _sinNombre;
    if (texto.length < 3) return 'Tu nombre es muy corto: escribe tu nombre completo.';
    if (texto.length > 200) return 'Tu nombre es muy largo.';
    return null;
  }

  static String? documento(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Escribe tu DNI o carné de extranjería.';
    if (!RegExp(r'^[A-Za-z0-9]{6,15}$').hasMatch(texto)) {
      return 'Tu documento debe tener entre 6 y 15 letras o números, sin espacios.';
    }
    return null;
  }

  /// «+51 959 123 456», «959-123-456» y «(054) 123456» valen: se comparan solo los dígitos.
  static String limpiarTelefono(String valor) {
    final texto = valor.trim();
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    return texto.startsWith('+') ? '+$digitos' : digitos;
  }

  static String? telefono(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Escribe tu número de celular.';
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (digitos.length < 7 || digitos.length > 15) return 'Tu celular debe tener entre 7 y 15 números.';
    return null;
  }

  /// Opcional: vacío está bien.
  static String? correo(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return null;
    if (texto.length > 120 || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(texto)) {
      return 'Escribe un correo válido (o déjalo vacío).';
    }
    return null;
  }
}

/// Dónde se guardan los datos del invitado en el celular. Se reemplaza en pruebas.
abstract class EventoInvitadoAlmacen {
  Future<EventoInvitado?> leer();

  Future<void> guardar(EventoInvitado invitado);

  Future<void> borrar();
}

class EventoInvitadoAlmacenLocal implements EventoInvitadoAlmacen {
  const EventoInvitadoAlmacenLocal();

  @override
  Future<EventoInvitado?> leer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(AppConstants.eventoInvitadoKey);
      if (texto == null || texto.isEmpty) return null;

      final json = jsonDecode(texto);
      if (json is! Map) return null;
      final invitado = EventoInvitado.fromJson(Map<String, dynamic>.from(json));
      return invitado.puedeConsultar ? invitado : null;
    } catch (_) {
      // Un dato guardado ilegible se trata como «no hay datos»: la persona los escribe de nuevo.
      return null;
    }
  }

  @override
  Future<void> guardar(EventoInvitado invitado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.eventoInvitadoKey, jsonEncode(invitado.toJson()));
  }

  @override
  Future<void> borrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.eventoInvitadoKey);
  }
}
