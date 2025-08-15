import 'package:arequipagocreditos/data/models/puntuacion_model.dart';
import 'package:arequipagocreditos/presentation/components/historial_item.dart';
import 'package:arequipagocreditos/presentation/pages/pages.dart';
import 'package:flutter/material.dart';

class HistorialCard extends StatefulWidget {
   final List<HistorialPuntosModel> historial;

  const HistorialCard({super.key, required this.historial});

  @override
  State<HistorialCard> createState() => _HistorialCardState();
}

class _HistorialCardState extends State<HistorialCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Historial de puntaje',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.historial.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No hay historial disponible',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...(widget.historial.take(5).map((item) => HistorialItem(item: item))),
          if (widget.historial.length > 5)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistorialCompletoPage(
                      historial: widget.historial,
                    ),
                  ),
                );
              },
              child: const Text('Ver historial completo'),
            ),
        ],
      ),
    );
  }
}
