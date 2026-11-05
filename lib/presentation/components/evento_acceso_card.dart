import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../pages/evento_mis_tickets_page.dart';
import '../providers/evento_provider.dart';

/// Entrada fija y discreta del inicio a «Mis tickets». Existe porque el aviso con el banner sale una sola vez por sesión.
///
/// Se ve mientras haya un evento activo. Con el evento ya empezado el servidor deja de mandarlo como activo; entonces se ve solo
/// si la persona tiene una compra pendiente o confirmada (para llegar a su código o terminar de subir su captura), con el texto
/// «Mis tickets · nombre del evento». Sin ninguna de las dos cosas no ocupa nada.
class EventoAccesoCard extends StatelessWidget {
  const EventoAccesoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final acceso = context.select<EventoProvider, ({String? nombre, bool soloPorCompra})>(
      (p) => (nombre: p.nombreAccesoFijo, soloPorCompra: p.accesoSoloPorCompra),
    );
    final evento = acceso.nombre;
    if (evento == null) return const SizedBox.shrink();
    final titulo = acceso.soloPorCompra ? 'Mis tickets · $evento' : evento;
    final subtitulo = acceso.soloPorCompra ? 'Revisa tu compra y tu código' : 'Compra tus tickets o revisa tu compra';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: const Key('evento_acceso_card'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EventoMisTicketsPage()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withAlpha((0.6 * 255).toInt())),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha((0.25 * 255).toInt()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.celebration, size: 20, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                      ),
                      Text(
                        subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
