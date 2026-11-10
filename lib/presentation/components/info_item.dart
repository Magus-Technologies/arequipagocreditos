import 'package:flutter/material.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';

/// Una fila de información del perfil: ícono en un recuadro de color, la etiqueta pequeña y el valor debajo.
///
/// Todo va alineado ARRIBA (no centrado verticalmente): con un valor de varias líneas, como una dirección, el ícono se queda
/// junto a la primera línea. `trailing` es un aviso opcional a la derecha (p. ej. «Vencido» en un documento).
class InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final Widget? trailing;

  const InfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.trailing,
  });

  static const String sinDato = 'No disponible';

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppTheme.primary;
    // Sobre el amarillo de la marca el ícono va oscuro; con otro color (verde, naranja…) va del mismo color.
    final colorIcono = color == null ? Colors.black87 : color!;
    // Un dato vacío (no solo nulo) también es «No disponible»: antes quedaba una línea en blanco.
    final texto = value.trim().isEmpty ? sinDato : value;
    final vacio = texto == sinDato;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: base.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: colorIcono),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.2),
              ),
              const SizedBox(height: 2),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: vacio ? FontWeight.w400 : FontWeight.w600,
                  fontStyle: vacio ? FontStyle.italic : FontStyle.normal,
                  color: vacio ? Colors.grey.shade500 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}
