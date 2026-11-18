/// Respuesta de `POST /app/conductores/verificar-registro`: si ya existe un registro con el documento, la licencia o el correo.
///
/// El servidor responde siempre 200; [registrado] en true significa que la persona NO debe seguir con el registro.
class VerificacionRegistroModel {
  final bool registrado;

  /// Qué dato ya existe: `documento`, `licencia` o `correo` (null si no hay coincidencia).
  final String? campo;

  /// El registro existente fue dado de baja (eliminado): se explica distinto a «ya estás registrado».
  final bool eliminado;

  /// Texto del servidor para mostrarle a la persona.
  final String? message;

  const VerificacionRegistroModel({required this.registrado, this.campo, this.eliminado = false, this.message});

  factory VerificacionRegistroModel.fromJson(Map<String, dynamic> json) {
    bool aBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';
    final texto = json['message']?.toString().trim();
    final campo = json['campo']?.toString().trim();
    return VerificacionRegistroModel(
      registrado: aBool(json['registrado']),
      campo: campo == null || campo.isEmpty ? null : campo,
      eliminado: aBool(json['eliminado']),
      message: texto == null || texto.isEmpty ? null : texto,
    );
  }

  String get titulo => eliminado ? 'Registro dado de baja' : 'Ya estás registrado';

  /// El mensaje del servidor; si no llegó uno, un texto genérico según el dato repetido.
  String get mensajeParaMostrar {
    if (message != null) return message!;
    final dato = switch (campo) {
      'documento' => 'este documento',
      'licencia' => 'esta licencia',
      'correo' => 'este correo',
      _ => 'estos datos',
    };
    return eliminado
        ? 'Ya existe un registro con $dato y fue dado de baja. Comunícate con nosotros para ayudarte.'
        : 'Ya existe un registro con $dato. Inicia sesión o comunícate con nosotros si necesitas ayuda.';
  }
}
