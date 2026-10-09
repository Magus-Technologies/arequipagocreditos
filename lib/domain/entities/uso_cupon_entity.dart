/// Un uso de cupón ya confirmado (TK-0359): el código único de 24 h que el conductor muestra en el establecimiento y lo que vio
/// al confirmar (descuento, precio normal y lo que paga en el local).
class UsoCuponEntity {
  final int cuponId;
  final String numero;
  final String establecimiento;
  final String tipoDescuento; // 'monto_fijo' o 'porcentaje'
  final double valorDescuento;
  final double montoDescuento;
  final double? precioNormal;
  final double? montoPagar;

  /// Vacío si el servidor es anterior al código de 24 h (la pantalla muestra solo «Cupón usado»).
  final String codigo;
  final DateTime? generadoAt;
  final DateTime venceAt;
  final int? usosRestantes;
  final int horasVigencia;

  const UsoCuponEntity({
    required this.cuponId,
    required this.numero,
    required this.establecimiento,
    required this.tipoDescuento,
    required this.valorDescuento,
    required this.montoDescuento,
    this.precioNormal,
    this.montoPagar,
    required this.codigo,
    this.generadoAt,
    required this.venceAt,
    this.usosRestantes,
    this.horasVigencia = 24,
  });

  bool get tieneCodigo => codigo.isNotEmpty;

  /// El código sigue vigente (no pasaron las 24 h).
  bool get vigente => venceAt.isAfter(DateTime.now());

  Duration get restante => vigente ? venceAt.difference(DateTime.now()) : Duration.zero;

  /// «5 h 12 min» / «40 min» / «menos de 1 min».
  String get restanteTexto {
    final minutos = restante.inMinutes;
    if (minutos < 1) return 'menos de 1 min';
    if (minutos < 60) return '$minutos min';
    return '${minutos ~/ 60} h ${(minutos % 60).toString().padLeft(2, '0')} min';
  }

  /// «S/10.00» si se pudo calcular en soles; si no, el porcentaje del cupón («10% OFF»).
  String get descuentoTexto {
    if (montoDescuento > 0) return 'S/${montoDescuento.toStringAsFixed(2)}';
    if (tipoDescuento == 'porcentaje') {
      return '${valorDescuento.toStringAsFixed(valorDescuento % 1 == 0 ? 0 : 2)}% OFF';
    }
    return 'S/${valorDescuento.toStringAsFixed(2)}';
  }
}
