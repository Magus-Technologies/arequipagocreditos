import '../../domain/entities/uso_cupon_entity.dart';

class UsoCuponModel extends UsoCuponEntity {
  const UsoCuponModel({
    required super.cuponId,
    required super.numero,
    required super.establecimiento,
    required super.tipoDescuento,
    required super.valorDescuento,
    required super.montoDescuento,
    super.precioNormal,
    super.montoPagar,
    required super.codigo,
    super.generadoAt,
    required super.venceAt,
    super.usosRestantes,
    super.horasVigencia,
  });

  factory UsoCuponModel.fromJson(Map<String, dynamic> json) {
    double? toDoubleOrNull(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? toIntOrNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    final horas = toIntOrNull(json['horas_vigencia']) ?? 24;
    final generado = DateTime.tryParse((json['generado_at'] ?? json['fecha_uso'] ?? '').toString());
    final id = toIntOrNull(json['cupon_id']) ?? 0;

    return UsoCuponModel(
      cuponId: id,
      numero: json['numero']?.toString() ?? id.toString().padLeft(6, '0'),
      establecimiento: json['establecimiento']?.toString() ?? '',
      tipoDescuento: json['tipo_descuento']?.toString() ?? 'monto_fijo',
      valorDescuento: toDoubleOrNull(json['valor_descuento']) ?? 0.0,
      montoDescuento: toDoubleOrNull(json['monto_descuento']) ?? 0.0,
      precioNormal: toDoubleOrNull(json['precio_normal']),
      montoPagar: toDoubleOrNull(json['monto_pagar']),
      codigo: json['codigo']?.toString() ?? '',
      generadoAt: generado,
      // Sin vencimiento en la respuesta (servidor antiguo): se toman las horas de vigencia desde ahora.
      venceAt: DateTime.tryParse((json['vence_at'] ?? '').toString()) ?? DateTime.now().add(Duration(hours: horas)),
      usosRestantes: toIntOrNull(json['usos_restantes']),
      horasVigencia: horas,
    );
  }
}
