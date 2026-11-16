/// Pagar la inscripción con Yape (GMoney). El SERVIDOR decide en qué paso va el pago (`paso`) y trae los montos y mensajes ya
/// listos: el app solo dibuja la pantalla que corresponde, nunca decide si algo se pagó.
class YapeAfiliacionModel {
  /// Estado de la afiliación en GMoney: pending | confirmed | rejected | expired | cancelled | failed…
  final String estado;

  /// Celular enmascarado (`***4321`): el servidor nunca devuelve el número completo.
  final String? celular;

  /// Enlace que abre la app de Yape para aprobar. Solo viene mientras la afiliación espera la aprobación.
  final String? link;

  /// Hasta cuándo se puede aprobar en Yape (vigencia de la solicitud).
  final DateTime? expiraAt;

  const YapeAfiliacionModel({required this.estado, this.celular, this.link, this.expiraAt});

  factory YapeAfiliacionModel.fromJson(Map<String, dynamic> json) {
    return YapeAfiliacionModel(
      estado: (json['estado'] ?? '').toString(),
      celular: json['celular']?.toString(),
      link: json['link']?.toString(),
      expiraAt: DateTime.tryParse((json['expira_at'] ?? '').toString()),
    );
  }
}

class YapeCobroModel {
  /// Estado del cobro: pendiente | enviado | exitoso | denegado | vencido | error…
  final String estado;
  final double monto;

  /// Texto para el conductor cuando el cobro no salió (saldo insuficiente, cuenta que no recibe cobros…).
  final String? mensaje;

  const YapeCobroModel({required this.estado, required this.monto, this.mensaje});

  factory YapeCobroModel.fromJson(Map<String, dynamic> json) {
    return YapeCobroModel(
      estado: (json['estado'] ?? '').toString(),
      monto: double.tryParse((json['monto'] ?? '0').toString()) ?? 0,
      mensaje: json['mensaje']?.toString(),
    );
  }
}

class YapeInscripcionEstadoModel {
  static const String pasoNoDisponible = 'no_disponible';
  static const String pasoPagada = 'pagada';
  static const String pasoAfiliar = 'afiliar';
  static const String pasoAprobarEnYape = 'aprobar_en_yape';
  static const String pasoCobrar = 'cobrar';
  static const String pasoProcesando = 'procesando';

  /// ¿El servidor ofrece pagar con Yape ahora? (interruptor encendido y credenciales de GMoney).
  final bool disponible;

  /// Qué pantalla corresponde: afiliar | aprobar_en_yape | cobrar | procesando | pagada | no_disponible.
  final String paso;

  /// Lo que se paga: la inscripción, el costo por usar Yape (0 si lo asume Arequipa Go) y el total que se cobra.
  final double monto;
  final double recargo;
  final double total;

  final YapeAfiliacionModel? afiliacion;
  final YapeCobroModel? cobro;
  final String? mensaje;

  const YapeInscripcionEstadoModel({
    required this.disponible,
    required this.paso,
    required this.monto,
    this.recargo = 0,
    required this.total,
    this.afiliacion,
    this.cobro,
    this.mensaje,
  });

  /// Pantallas en las que el app solo espera una respuesta de Yape y consulta cada pocos segundos.
  bool get esperando => paso == pasoAprobarEnYape || paso == pasoProcesando;

  bool get pagada => paso == pasoPagada;

  /// ¿Hay un pago con Yape por hacer (o en camino)? Con el servidor apagado, ya pagada o un plan que no se puede pagar así, no.
  bool get puedePagarse => disponible && (paso == pasoAfiliar || paso == pasoAprobarEnYape || paso == pasoCobrar || paso == pasoProcesando);

  bool get tieneRecargo => recargo > 0;

  factory YapeInscripcionEstadoModel.fromJson(Map<String, dynamic> json) {
    final afiliacion = json['afiliacion'];
    final cobro = json['cobro'];
    final monto = double.tryParse((json['monto'] ?? '0').toString()) ?? 0;
    final recargo = double.tryParse((json['recargo'] ?? '0').toString()) ?? 0;
    return YapeInscripcionEstadoModel(
      disponible: json['disponible'] == true,
      paso: (json['paso'] ?? pasoNoDisponible).toString(),
      monto: monto,
      recargo: recargo,
      total: double.tryParse((json['total'] ?? '${monto + recargo}').toString()) ?? monto + recargo,
      afiliacion: afiliacion is Map ? YapeAfiliacionModel.fromJson(Map<String, dynamic>.from(afiliacion)) : null,
      cobro: cobro is Map ? YapeCobroModel.fromJson(Map<String, dynamic>.from(cobro)) : null,
      mensaje: json['mensaje']?.toString(),
    );
  }
}
