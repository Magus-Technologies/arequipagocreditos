import 'package:arequipagocreditos/data/models/puntuacion_model.dart';
import 'package:flutter/material.dart';

class PuntajeCard extends StatefulWidget {
  final PuntuacionModel puntuacion;
  final Animation<double> scaleAnimation;
  const PuntajeCard({super.key, required this.puntuacion, required this.scaleAnimation});

  @override
  State<PuntajeCard> createState() => _PuntajeCardState();
}

class _PuntajeCardState extends State<PuntajeCard> {
  Color _getPuntajeColor() {
    final puntaje = widget.puntuacion.puntajeActual;
    if (puntaje >= 80) return Colors.green;
    if (puntaje >= 60) return Colors.orange;
    if (puntaje >= 40) return Colors.yellow.shade700;
    return Colors.red;
  }

  String _getNivelTexto() {
    final puntaje = widget.puntuacion.puntajeActual;
    if (puntaje >= 80) return 'Excelente';
    if (puntaje >= 60) return 'Bueno';
    if (puntaje >= 40) return 'Regular';
    if (puntaje >= 20) return 'Malo';
    return 'Crítico';
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.08 * 255).toInt()),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Puntaje crediticio',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: widget.puntuacion.puntajeActual / 100, // Cambiar de 1000 a 100
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getPuntajeColor(),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${widget.puntuacion.puntajeActual}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getPuntajeColor(),
                      ),
                    ),
                    Text(
                      'PUNTOS',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getPuntajeColor().withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getNivelTexto(),
                style: TextStyle(
                  color: _getPuntajeColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0', style: TextStyle(color: Colors.grey.shade600)),
                Text('100', style: TextStyle(color: Colors.grey.shade600)), // Cambiar de 1000 a 100
              ],
            ),
          ],
        ),
      ),
    );
  }
}
