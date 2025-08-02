import 'package:arequipagocreditos/models/puntuacion_model.dart';
import 'package:flutter/material.dart';

class HistorialItem extends StatefulWidget {
  final HistorialPuntos item;

  const HistorialItem({super.key, required this.item});

  @override
  State<HistorialItem> createState() => _HistorialItemState();
}

class _HistorialItemState extends State<HistorialItem> {
  bool get isPositivo => widget.item.tipo == 'suma';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isPositivo
                      ? Colors.green.withAlpha((0.1 * 255).toInt())
                      : Colors.red.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositivo ? Icons.add : Icons.remove,
              color: isPositivo ? Colors.green : Colors.red,
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
          Text(
            '${isPositivo ? '+' : '-'}${widget.item.puntos}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositivo ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
