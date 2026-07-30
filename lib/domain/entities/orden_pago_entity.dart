/// Orden de pago: el código que la persona lleva a Caja Arequipa para pagar.
///
/// Hay dos clases de código y la diferencia manda toda la UI:
///  - TEMPORAL (inscripción, ventas, cuotas vencidas agrupadas): vence a las 24h.
///  - PERMANENTE (financiamiento, cuota inicial, excedente, penalidad): sin
///    vencimiento, se usa durante todo el contrato.
///
/// Cuando [fechaExpiracion] es null el código es permanente y la vista no debe
/// mostrar contador, ni "vence", ni colores de alerta.
class OrdenPagoEntity {
  final int id;
  final String codigo;
  final int tipoPagoId;
  final String concepto;
  final double monto;
  final String moneda;
  final String estado;
  final bool pagable;
  final bool esTemporal;
  final DateTime? fechaExpiracion;
  final DateTime? fechaCreacion;
  final String voucherUrl;

  const OrdenPagoEntity({
    required this.id,
    required this.codigo,
    required this.tipoPagoId,
    required this.concepto,
    required this.monto,
    required this.moneda,
    required this.estado,
    required this.pagable,
    required this.esTemporal,
    required this.fechaExpiracion,
    required this.fechaCreacion,
    required this.voucherUrl,
  });

  bool get esPermanente => fechaExpiracion == null;

  /// Tiempo que le queda al código. Null si es permanente.
  ///
  /// Se calcula contra [fechaExpiracion], que es absoluta, y no contra los
  /// `horas_restantes` que envía el backend: ese valor es una foto del momento
  /// de la consulta y queda viejo si la pantalla se deja abierta.
  Duration? restante([DateTime? ahora]) {
    if (fechaExpiracion == null) return null;
    final diff = fechaExpiracion!.difference(ahora ?? DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool expirada([DateTime? ahora]) {
    if (fechaExpiracion == null) return false;
    return !fechaExpiracion!.isAfter(ahora ?? DateTime.now());
  }

  /// True cuando al código temporal le quedan menos de 6 horas.
  ///
  /// El umbral de 6h es el mismo que usa el panel web, para que el operador y
  /// la persona vean la misma urgencia.
  bool porVencer([DateTime? ahora]) {
    final r = restante(ahora);
    return r != null && r > Duration.zero && r.inHours < 6;
  }

  bool get estaPagada => estado == 'pagada';
  bool get estaAnulada => estado == 'anulada' || estado == 'rechazada';
}

/// Contadores que acompañan al listado.
class ResumenOrdenesEntity {
  final int pagables;
  final int vencidas;

  const ResumenOrdenesEntity({required this.pagables, required this.vencidas});
}

class ListadoOrdenesPagoEntity {
  final List<OrdenPagoEntity> ordenes;
  final ResumenOrdenesEntity resumen;

  const ListadoOrdenesPagoEntity({required this.ordenes, required this.resumen});
}
