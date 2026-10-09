import 'uso_cupon_entity.dart';

class CuponEntity {
  final int id;
  final String titulo;
  final String? descripcion;
  final String categoria;
  final double valor;
  final String tipoDescuento; // 'monto_fijo' o 'porcentaje'
  final String? codigo;
  final DateTime fechaFin;
  final bool esActivo;
  final String? imagenBanner;
  final String? empresa;
  final String? condiciones;
  final int? limiteUsosConductor;
  final int usosRealizados;
  final bool puedeUsar;
  final String estado;
  final DateTime? fechaAsignacion;
  final List<String>? visiblePara;

  // TK-0359: lo que el servidor manda para el resumen y el código de 24 h.
  /// N.° de cupón (el de la promoción, con ceros: 000125).
  final String? numero;
  /// Nombre del establecimiento (campo propio del cupón; si no se llenó, el servidor manda el título).
  final String? establecimiento;
  final double? precioNormal;
  /// Descuento en soles y lo que se paga en el local, calculados por el servidor (null = no se pueden calcular: porcentaje sin precio).
  final double? montoDescuentoEstimado;
  final double? montoPagarEstimado;
  /// 'disponible' | 'usado' | 'codigo_vencido'.
  final String estadoUso;
  /// El código generado por este conductor si todavía no vence (para «Ver código»).
  final UsoCuponEntity? usoVigente;

  const CuponEntity({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.categoria,
    required this.valor,
    required this.tipoDescuento,
    this.codigo,
    required this.fechaFin,
    required this.esActivo,
    this.imagenBanner,
    this.empresa,
    this.condiciones,
    this.limiteUsosConductor,
    required this.usosRealizados,
    required this.puedeUsar,
    required this.estado,
    this.fechaAsignacion,
    this.visiblePara,
    this.numero,
    this.establecimiento,
    this.precioNormal,
    this.montoDescuentoEstimado,
    this.montoPagarEstimado,
    this.estadoUso = 'disponible',
    this.usoVigente,
  });

  /// Retorna true si este cupón es visible para la audiencia dada.
  bool esVisiblePara(String audiencia) {
    if (visiblePara == null) return true;
    return visiblePara!.contains(audiencia);
  }

  // `puedeUsar` es lo que decide el servidor: además del límite de usos, no deja generar otro código mientras haya uno vigente.
  bool get puedeUsarse => estado == "activo" && !estaVencido && tieneUsosDisponibles && puedeUsar && usoVigente == null;

  /// N.° de cupón con seis dígitos (000125); si el servidor no lo manda se arma con el id.
  String get numeroFormateado => numero ?? id.toString().padLeft(6, '0');

  String get nombreEstablecimiento {
    final propio = establecimiento?.trim() ?? '';
    return propio.isNotEmpty ? propio : titulo;
  }

  bool get tieneCodigoVigente => usoVigente != null && usoVigente!.vigente;

  bool get codigoVencido => estadoUso == 'codigo_vencido';
  
  bool get estaVencido => DateTime.now().isAfter(fechaFin);
  
  bool get tieneUsosDisponibles {
    if (limiteUsosConductor == null) return true;
    return (usosRealizados) < limiteUsosConductor!;
  }
  
  int get usosRestantes {
    if (limiteUsosConductor == null) return -1; // Ilimitado
    return limiteUsosConductor! - usosRealizados;
  }
  
  String get valorFormateado {
    if (tipoDescuento == 'porcentaje') {
      return '${valor.toInt()}% OFF';
    } else {
      return 'S/. ${valor.toStringAsFixed(2)}';
    }
  }
}
