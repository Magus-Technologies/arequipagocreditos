import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/evento_mis_tickets_page.dart';
import '../pages/eventos_page.dart';
import '../providers/evento_provider.dart';

/// Pastilla chica y translúcida (la misma en el inicio y en la bienvenida): ícono + una palabra.
class _Pastilla extends StatelessWidget {
  final Key llave;
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const _Pastilla({required this.llave, required this.icono, required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha((0.15 * 255).toInt()),
      shape: StadiumBorder(side: BorderSide(color: Colors.white.withAlpha((0.35 * 255).toInt()))),
      child: InkWell(
        key: llave,
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 13, color: Colors.black87),
              const SizedBox(width: 5),
              Text(texto, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entrada chica a los eventos, en la parte de arriba del inicio (bajo el saludo). Reemplaza a la tarjeta «Eventos» que ocupaba un lugar
/// fijo entre los módulos: ahora solo aparece cuando hay algo que ver y no ocupa nada si no.
///
///  - Con un evento disponible (activo): «Eventos» → la lista de eventos (desde ahí se compra y se llega a «Mis tickets»).
///  - Con el evento ya empezado (el servidor deja de mandarlo como activo) pero con una compra pendiente o confirmada: «Mis tickets» →
///    directo a sus tickets, para llegar a su código en la puerta o terminar de subir su captura.
///  - Sin ninguna de las dos cosas: nada.
///
/// Se alimenta de lo que ya precarga [EventoGate.precargar] al abrir el inicio; no pide nada por su cuenta.
class EventoAccesoChip extends StatelessWidget {
  const EventoAccesoChip({super.key});

  @override
  Widget build(BuildContext context) {
    final acceso = context.select<EventoProvider, ({bool hay, bool soloTickets})>(
      (p) => (hay: p.hayAccesoFijo, soloTickets: p.accesoSoloPorCompra),
    );
    if (!acceso.hay) return const SizedBox.shrink();

    final soloTickets = acceso.soloTickets;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: _Pastilla(
        llave: const Key('evento_acceso_chip'),
        icono: soloTickets ? Icons.confirmation_number_outlined : Icons.celebration,
        texto: soloTickets ? 'Mis tickets' : 'Eventos',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => soloTickets ? const EventoMisTicketsPage() : const EventosPage()),
        ),
      ),
    );
  }
}

/// Lo mismo para quien NO inició sesión (pantalla de bienvenida): una pastilla «Eventos» arriba, solo si hay un evento PÚBLICO disponible
/// (activo y cuyo día no terminó). Sin evento no se ve nada: ya no hay un botón fijo «EVENTOS» debajo de «INICIAR SESIÓN».
///
/// No pide nada por su cuenta: usa el evento que ya trae `EventoInvitadoAviso` al abrir la bienvenida.
class EventoPublicoChip extends StatelessWidget {
  const EventoPublicoChip({super.key});

  @override
  Widget build(BuildContext context) {
    final hay = context.select<EventoProvider, bool>((p) => p.eventoPublico != null && !p.eventoPublico!.esPrivado);
    if (!hay) return const SizedBox.shrink();

    return _Pastilla(
      llave: const Key('welcome_eventos'),
      icono: Icons.celebration,
      texto: 'Eventos',
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventosPage())),
    );
  }
}
