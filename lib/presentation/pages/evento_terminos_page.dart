import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/evento_formato.dart';
import '../../data/models/evento_models.dart';
import '../components/evento_widgets.dart';
import '../providers/evento_provider.dart';
import 'evento_compra_page.dart';
import 'evento_mis_tickets_page.dart';

/// Paso 1 de la compra: términos y política de privacidad del evento. Sin marcar la casilla no se avanza.
/// Con el tope por persona ya alcanzado no deja comprar y manda a «Mis tickets».
class EventoTerminosPage extends StatefulWidget {
  const EventoTerminosPage({super.key});

  @override
  State<EventoTerminosPage> createState() => _EventoTerminosPageState();
}

class _EventoTerminosPageState extends State<EventoTerminosPage> {
  bool _acepta = false;

  void _continuar() {
    // Reemplaza esta pantalla: los términos ya se aceptaron y volver a ellos desde la compra no tiene sentido.
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const EventoCompraPage()));
  }

  void _verMisTickets() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const EventoMisTicketsPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: eventoAppBar('Términos y condiciones'),
      body: SafeArea(
        top: false,
        child: Consumer<EventoProvider>(
          builder: (context, provider, _) {
            final evento = provider.evento;
            if (evento == null) return _sinEvento();

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _resumen(evento),
                        const SizedBox(height: 14),
                        _seccion(
                          key: const Key('evento_terminos_texto'),
                          titulo: 'Términos y condiciones',
                          texto: evento.terminos,
                        ),
                        const SizedBox(height: 14),
                        _seccion(
                          key: const Key('evento_privacidad_texto'),
                          titulo: 'Política de privacidad',
                          texto: evento.politicaPrivacidad,
                        ),
                      ],
                    ),
                  ),
                ),
                _barraInferior(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sinEvento() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'Este evento ya no está disponible.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Volver')),
          ],
        ),
      ),
    );
  }

  Widget _resumen(EventoModel evento) {
    final fecha = EventoFormato.fechaHora(evento.fechaHora);
    return EventoTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(evento.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (evento.descripcion != null) ...[
            const SizedBox(height: 8),
            Text(
              evento.descripcion!,
              key: const Key('evento_descripcion'),
              style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey.shade800),
            ),
          ],
          if (fecha.isNotEmpty) ...[
            const SizedBox(height: 10),
            _dato(Icons.event, fecha),
          ],
          if (evento.lugar != null) ...[
            const SizedBox(height: 4),
            _dato(Icons.place_outlined, evento.lugar!),
            if (evento.tieneMapa)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Align(alignment: Alignment.centerLeft, child: EventoBotonMapa(url: evento.mapaUrl!, compacto: true)),
              ),
          ],
          const SizedBox(height: 4),
          _dato(Icons.confirmation_number_outlined, 'Ticket: ${EventoFormato.monto(evento.precioTicket)}'),
        ],
      ),
    );
  }

  Widget _dato(IconData icono, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(child: Text(texto, style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ],
    );
  }

  /// El texto largo conserva sus saltos de línea tal cual los escribió el administrador.
  Widget _seccion({required Key key, required String titulo, required String? texto}) {
    return EventoTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            texto ?? 'No hay información registrada.',
            key: key,
            style: TextStyle(fontSize: 13, height: 1.5, color: texto == null ? Colors.grey : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _barraInferior(EventoProvider provider) {
    final bloqueado = !provider.puedeComprar;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: bloqueado
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.orange.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.mensajeTope,
                        key: const Key('evento_tope_alcanzado'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                EventoBotonPrincipal(texto: 'Ver mis tickets', icono: Icons.confirmation_number, onPressed: _verMisTickets),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EventoAceptacionCheckbox(
                  value: _acepta,
                  onChanged: (v) => setState(() => _acepta = v),
                  texto: 'He leído y acepto los términos y condiciones y la política de privacidad',
                ),
                const SizedBox(height: 12),
                EventoBotonPrincipal(
                  texto: 'Continuar',
                  onPressed: _acepta ? _continuar : null,
                ),
              ],
            ),
    );
  }
}
