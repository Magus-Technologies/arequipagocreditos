import 'package:arequipagocreditos/data/models/puntuacion_model.dart';
import 'package:flutter/material.dart';

class HistorialItem extends StatefulWidget {
  final HistorialPuntosModel item;

  const HistorialItem({super.key, required this.item});

  @override
  State<HistorialItem> createState() => _HistorialItemState();
}

class _HistorialItemState extends State<HistorialItem> {
  bool get isPositivo => widget.item.tipo == 'suma';
  bool get isNegativo => widget.item.tipo == 'resta';
  bool get isNeutro => widget.item.tipo == 'neutro';

  Color get iconColor {
    if (isPositivo) return Colors.green;
    if (isNegativo) return Colors.red;
    return Colors.grey; // Para estados neutros (pendientes)
  }

  Color get backgroundColor {
    if (isPositivo) return Colors.green.withAlpha((0.1 * 255).toInt());
    if (isNegativo) return Colors.red.withAlpha((0.1 * 255).toInt());
    return Colors.grey.withAlpha((0.1 * 255).toInt()); // Para estados neutros
  }

  IconData get iconData {
    if (isPositivo) return Icons.add;
    if (isNegativo) return Icons.remove;
    return Icons.schedule; // Icono de reloj para cuotas pendientes
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.descripcion,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${widget.item.fecha.day}/${widget.item.fecha.month}/${widget.item.fecha.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (!isNeutro) // Solo mostrar puntos si no es neutro
            Text(
              '${isPositivo ? '+' : ''}${widget.item.puntos}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            )
          else
            Text(
              'Pendiente',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
