import 'package:arequipagocreditos/models/puntuacion_model.dart';
import 'package:flutter/material.dart';

class ProximoNivelCard extends StatefulWidget {
  final PuntuacionCredito puntuacion;

  const ProximoNivelCard({super.key, required this.puntuacion});

  @override
  State<ProximoNivelCard> createState() => _ProximoNivelCardState();
}

class _ProximoNivelCardState extends State<ProximoNivelCard> {
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
              Icon(Icons.trending_up, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Siguiente nivel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Te faltan ${widget.puntuacion.puntosRestantes} puntos para alcanzar ${widget.puntuacion.siguienteNivel} puntos',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (widget.puntuacion.puntaje / widget.puntuacion.siguienteNivel),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }
}
