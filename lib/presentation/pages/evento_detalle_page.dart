import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/evento_formato.dart';
import '../../core/utils/evento_gate.dart';
import '../../data/models/evento_models.dart';
import '../../theme/app_theme.dart';
import '../components/evento_widgets.dart';
import '../providers/evento_provider.dart';
import 'evento_mis_tickets_page.dart';
import 'evento_terminos_page.dart';

/// Detalle de un evento de la lista: banner, fecha, lugar, precio y descripción.
///
/// Solo el evento que está EN VENTA (el activo más próximo, el mismo que anuncia el aviso del inicio) ofrece «Comprar tickets»: la
/// compra del app siempre es sobre ese. Un evento ya realizado se ve como recuerdo, sin compra. Si la persona ya compró tickets de
/// este evento, queda el acceso a «Mis tickets».
class EventoDetallePage extends StatefulWidget {
  final EventoModel evento;
  final bool realizado;

  const EventoDetallePage({super.key, required this.evento, required this.realizado});

  @override
  State<EventoDetallePage> createState() => _EventoDetallePageState();
}

class _EventoDetallePageState extends State<EventoDetallePage> {
  @override
  void initState() {
    super.initState();
    // El evento en venta y las compras de la persona: sin esto el botón de compra no sabría si este evento es el activo.
    if (!widget.realizado) WidgetsBinding.instance.addPostFrameCallback((_) => EventoGate.precargar(context));
  }

  @override
  Widget build(BuildContext context) {
    final evento = widget.evento;
    final fecha = EventoFormato.fechaHora(evento.fechaHora);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: eventoAppBar(widget.realizado ? 'Evento realizado' : 'Evento'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _banner(evento),
            const SizedBox(height: 16),
            EventoTarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _etiqueta(),
                  const SizedBox(height: 12),
                  Text(
                    evento.nombre,
                    key: const Key('evento_detalle_nombre'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.15),
                  ),
                  if (fecha.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _dato(Icons.calendar_month_rounded, 'Fecha y hora', fecha),
                  ],
                  if (evento.lugar != null) ...[
                    const SizedBox(height: 12),
                    _dato(Icons.place_rounded, 'Lugar', evento.lugar!),
                    // «Cómo llegar» debajo del lugar, alineado con su texto (ícono de 34 px + 12 de separación).
                    if (evento.tieneMapa)
                      Padding(
                        padding: const EdgeInsets.only(left: 46, top: 2),
                        child: Align(alignment: Alignment.centerLeft, child: EventoBotonMapa(url: evento.mapaUrl!, compacto: true)),
                      ),
                  ],
                  if (!widget.realizado && evento.precioTicket > 0) ...[
                    const SizedBox(height: 12),
                    _dato(Icons.confirmation_number_rounded, 'Ticket', '${EventoFormato.monto(evento.precioTicket)} por persona'),
                  ],
                  if (evento.descripcion != null) ...[
                    const Divider(height: 28),
                    Text(
                      evento.descripcion!,
                      key: const Key('evento_detalle_descripcion'),
                      style: TextStyle(fontSize: 14, height: 1.45, color: Colors.grey.shade800),
                    ),
                  ],
                ],
              ),
            ),
            if (!widget.realizado) ...[
              const SizedBox(height: 16),
              _compra(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _etiqueta() {
    final realizado = widget.realizado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: realizado ? Colors.grey.shade200 : Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        realizado ? 'EVENTO REALIZADO' : 'PRÓXIMO EVENTO',
        key: const Key('evento_detalle_etiqueta'),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: realizado ? Colors.grey.shade700 : AppTheme.primary,
        ),
      ),
    );
  }

  Widget _dato(IconData icono, String etiqueta, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icono, size: 18, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              const SizedBox(height: 1),
              Text(valor, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.25)),
            ],
          ),
        ),
      ],
    );
  }

  /// «Comprar tickets» solo si este es el evento en venta y a la persona le quedan tickets; si ya compró, el acceso a «Mis tickets».
  Widget _compra(BuildContext context) {
    return Consumer<EventoProvider>(
      builder: (context, provider, _) {
        final enVenta = provider.evento?.id == widget.evento.id;
        final tieneCompras = provider.compras.any((c) => c.eventoId == widget.evento.id && c.ocupaCupo);

        return Column(
          children: [
            if (enVenta && provider.puedeComprar)
              EventoBotonComprar(
                key: const Key('evento_detalle_comprar'),
                subtexto: widget.evento.precioTicket > 0 ? '${EventoFormato.monto(widget.evento.precioTicket)} por ticket' : null,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventoTerminosPage())),
              )
            else if (enVenta)
              Text(
                provider.mensajeTope,
                key: const Key('evento_detalle_tope'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            if (tieneCompras) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('evento_detalle_mis_tickets'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventoMisTicketsPage())),
                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                label: const Text('Ver mis tickets'),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _banner(EventoModel evento) {
    final url = evento.bannerUrl;
    final Widget contenido = url == null
        ? Container(
            height: 180,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE867), AppTheme.primary],
              ),
            ),
            child: const Icon(Icons.celebration_rounded, size: 64, color: Colors.black87),
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 460),
            child: CachedNetworkImage(
              imageUrl: url,
              width: double.infinity,
              fit: BoxFit.contain,
              memCacheWidth: 1200,
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (context, url) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => Container(
                height: 140,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported_outlined, color: Colors.black26, size: 40),
              ),
            ),
          );

    return ClipRRect(
      key: const Key('evento_detalle_banner'),
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(color: Colors.white, child: contenido),
    );
  }
}
