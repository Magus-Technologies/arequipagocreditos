import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/evento_formato.dart';
import '../../core/utils/evento_persona.dart';
import '../../data/models/evento_models.dart';
import '../components/evento_widgets.dart';
import '../providers/evento_provider.dart';
import 'evento_pago_page.dart';
import 'evento_terminos_page.dart';

/// «Mis tickets»: las compras de la persona, de la más nueva a la más vieja. Es la entrada fija desde el inicio.
/// Tocar una compra abre su detalle (pagar y subir la captura si está pendiente; ver el estado en los demás casos).
class EventoMisTicketsPage extends StatefulWidget {
  const EventoMisTicketsPage({super.key});

  @override
  State<EventoMisTicketsPage> createState() => _EventoMisTicketsPageState();
}

class _EventoMisTicketsPageState extends State<EventoMisTicketsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final persona = EventoPersona.de(context);
    if (persona == null) return;
    await context.read<EventoProvider>().cargarMisCompras(
          clienteConductorId: persona.id,
          nroDocumento: persona.documento,
        );
  }

  Future<void> _abrirCompra(EventoCompraModel compra) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventoPagoPage(compra: compra)));
    // Al volver puede haber cambiado de estado (cancelada, captura subida): se refresca la lista.
    if (mounted) await _cargar();
  }

  Future<void> _comprar() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventoTerminosPage()));
    if (mounted) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: eventoAppBar('Mis tickets'),
      body: SafeArea(
        top: false,
        child: Consumer<EventoProvider>(
          builder: (context, provider, _) {
            final compras = provider.compras;

            Widget cuerpo;
            if (provider.cargandoCompras && compras.isEmpty) {
              cuerpo = const Center(child: CircularProgressIndicator());
            } else if (provider.errorCompras != null && compras.isEmpty) {
              cuerpo = _error(provider.errorCompras!);
            } else {
              cuerpo = RefreshIndicator(
                onRefresh: _cargar,
                child: compras.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.all(16),
                        children: [_vacio()],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.all(16),
                        itemCount: compras.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _tarjetaCompra(compras[index]),
                      ),
              );
            }

            return Column(
              children: [
                Expanded(child: cuerpo),
                if (provider.evento != null) _barraComprar(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _barraComprar(EventoProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: provider.puedeComprar
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EventoBotonComprar(
                  key: const Key('evento_comprar_tickets'),
                  subtexto: provider.evento != null && provider.evento!.precioTicket > 0
                      ? '${EventoFormato.monto(provider.evento!.precioTicket)} por ticket'
                      : null,
                  onPressed: _comprar,
                ),
                const SizedBox(height: 8),
                Text(provider.textoCupo, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            )
          : Row(
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
    );
  }

  Widget _vacio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.confirmation_number_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          const Text(
            'Aún no has comprado tickets',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuando compres, tus tickets aparecerán aquí con su estado.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _error(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaCompra(EventoCompraModel compra) {
    final fecha = EventoFormato.fechaHora(compra.fechaHoraEvento);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('evento_compra_${compra.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirCompra(compra),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      compra.eventoNombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  EventoEstadoChip(compra: compra),
                ],
              ),
              if (fecha.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(fecha, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      EventoFormato.tickets(compra.cantidad),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    EventoFormato.monto(compra.montoTotal),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Código: ${compra.codigo}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, letterSpacing: 0.3),
              ),
              if (compra.estadoCompra == EstadoCompra.rechazado && compra.motivoRechazo != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Motivo: ${compra.motivoRechazo}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
