import 'package:flutter/material.dart';

/// TK-0357: aviso rojo de los datos por actualizar (foto de perfil, DNI y SOAT de Flota).
///
/// El servidor manda la lista en `datos_pendientes` (cada item trae `mensaje` y `descripcion`). Mientras haya algo
/// pendiente el cliente no puede generar financiamientos: el aviso lo dice y, si se pasa [onActualizar], ofrece ir
/// a actualizarlo. Sin pendientes no dibuja nada.
class DatosPendientesBanner extends StatelessWidget {
  const DatosPendientesBanner({
    super.key,
    required this.pendientes,
    this.onActualizar,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 4),
  });

  final List<Map<String, dynamic>> pendientes;
  final VoidCallback? onActualizar;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (pendientes.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const Key('datos_pendientes_banner'),
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tienes datos por actualizar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                ),
                const SizedBox(height: 2),
                Text(
                  'No podrás solicitar un financiamiento hasta completarlos.',
                  style: TextStyle(fontSize: 12.5, color: Colors.red.shade700, height: 1.3),
                ),
                const SizedBox(height: 8),
                for (final p in pendientes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: TextStyle(color: Colors.red.shade700)),
                        Expanded(
                          child: Text(
                            (p['mensaje'] ?? '').toString(),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (onActualizar != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onActualizar,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        foregroundColor: Colors.red.shade800,
                      ),
                      child: const Text('Actualizar ahora', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
