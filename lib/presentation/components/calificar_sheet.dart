import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// TK-0382: lo que el conductor eligió en la hoja de calificación.
class CalificacionElegida {
  final int puntuacion;
  final String? comentario;

  const CalificacionElegida({required this.puntuacion, this.comentario});
}

const List<String> _etiquetasPuntuacion = ['', 'Muy malo', 'Malo', 'Regular', 'Bueno', 'Excelente'];

/// Hoja inferior para calificar con estrellas (1 a 5) y un comentario opcional. Es la misma que usa el detalle del taller, pero reutilizable:
/// solo junta lo que el conductor eligió y lo devuelve; enviarlo al servidor lo hace quien la llama. Devuelve null si la cierra sin enviar.
Future<CalificacionElegida?> mostrarCalificarSheet(
  BuildContext context, {
  required String titulo,
  required String nombre,
}) {
  return showModalBottomSheet<CalificacionElegida>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _CalificarSheet(titulo: titulo, nombre: nombre),
  );
}

class _CalificarSheet extends StatefulWidget {
  final String titulo;
  final String nombre;

  const _CalificarSheet({required this.titulo, required this.nombre});

  @override
  State<_CalificarSheet> createState() => _CalificarSheetState();
}

class _CalificarSheetState extends State<_CalificarSheet> {
  final TextEditingController _comentario = TextEditingController();
  int _puntuacion = 0;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom + media.padding.bottom + 24, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(widget.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            Text(widget.nombre, style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return GestureDetector(
                  key: Key('calificar-estrella-${i + 1}'),
                  onTap: () => setState(() => _puntuacion = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _puntuacion ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFFFD700),
                      size: 44,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _puntuacion == 0 ? 'Toca las estrellas para calificar' : _etiquetasPuntuacion[_puntuacion],
              style: TextStyle(
                fontSize: 13,
                color: _puntuacion == 0 ? Colors.grey.shade500 : AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _comentario,
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Cuéntanos tu experiencia...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _puntuacion == 0
                    ? null
                    : () {
                        final texto = _comentario.text.trim();
                        Navigator.pop(
                          context,
                          CalificacionElegida(puntuacion: _puntuacion, comentario: texto.isEmpty ? null : texto),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('Enviar calificación', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cinco estrellas con el promedio (llenas, media y vacías). Se usa en la tarjeta y en el detalle del comercio.
class EstrellasPromedio extends StatelessWidget {
  final double promedio;
  final double size;
  final Color color;
  final Color colorVacia;

  const EstrellasPromedio({
    super.key,
    required this.promedio,
    this.size = 16,
    this.color = const Color(0xFFF59E0B),
    this.colorVacia = const Color(0xFFD1D5DB),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final IconData icono;
        final Color tono;
        if (i < promedio.floor()) {
          icono = Icons.star_rounded;
          tono = color;
        } else if (i < promedio && promedio - i >= 0.5) {
          icono = Icons.star_half_rounded;
          tono = color;
        } else {
          icono = Icons.star_outline_rounded;
          tono = colorVacia;
        }
        return Icon(icono, color: tono, size: size);
      }),
    );
  }
}
