import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/evento_formato.dart';
import '../../core/utils/evento_persona.dart';
import '../../data/models/evento_invitado.dart';
import '../../data/models/evento_models.dart';
import '../components/evento_widgets.dart';
import '../providers/evento_provider.dart';
import 'evento_pago_page.dart';
import 'evento_terminos_page.dart';

/// «Mis tickets»: las compras de la persona, de la más nueva a la más vieja. Es la entrada fija desde el inicio.
/// Tocar una compra abre su detalle (pagar y subir la captura si está pendiente; ver el estado en los demás casos).
///
/// Sin sesión (TK-0450) son las compras del INVITADO: si el celular ya conoce sus datos (compró antes) salen sus tickets, con la opción
/// «No soy yo»; si no, se le pide su documento y su celular para buscarlos.
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
    final provider = context.read<EventoProvider>();
    final persona = EventoPersona.de(context);
    if (persona == null) {
      // Invitado (sin sesión): se leen sus datos guardados en el celular y, si los hay, sus compras.
      await provider.restaurarInvitado();
      await provider.cargarMisComprasInvitado();
      return;
    }
    await provider.cargarMisCompras(
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
            final invitado = EventoPersona.de(context) == null ? provider.invitado : null;
            final esInvitado = EventoPersona.de(context) == null;

            Widget cuerpo;
            if (esInvitado && invitado == null) {
              // Sin sesión y sin datos guardados: se buscan sus tickets con su documento y su celular.
              cuerpo = const _ConsultaInvitado();
            } else if (provider.cargandoCompras && compras.isEmpty) {
              cuerpo = const Center(child: CircularProgressIndicator());
            } else if (provider.errorCompras != null && compras.isEmpty) {
              cuerpo = _error(provider.errorCompras!);
            } else if (invitado != null) {
              cuerpo = RefreshIndicator(
                onRefresh: _cargar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _cabeceraInvitado(provider, invitado),
                    const SizedBox(height: 12),
                    if (compras.isEmpty) _vacio(),
                    for (var i = 0; i < compras.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _tarjetaCompra(compras[i]),
                    ],
                  ],
                ),
              );
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

  /// De quién son los tickets que se ven (sin sesión) y cómo dejar de verlos si no es la persona.
  Widget _cabeceraInvitado(EventoProvider provider, EventoInvitado invitado) {
    final titulo = invitado.nombre.trim().isEmpty ? 'Tickets del documento ${invitado.documento}' : 'Tickets de ${invitado.nombre}';
    return EventoTarjeta(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  key: const Key('evento_invitado_titulo'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Documento ${invitado.documento} · celular ${invitado.telefono}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('evento_invitado_olvidar'),
              onPressed: () => _olvidar(provider),
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('No soy yo · borrar mis datos'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _olvidar(EventoProvider provider) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Borrar tus datos de este celular?'),
        content: const Text(
          'Dejarás de ver estos tickets aquí. Tus compras siguen registradas: podrás verlas de nuevo con tu documento y tu celular.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Volver')),
          TextButton(
            key: const Key('evento_invitado_olvidar_confirmar'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Sí, borrar'),
          ),
        ],
      ),
    );
    if (confirmar == true) await provider.olvidarInvitado();
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

/// «Consulta tus tickets»: para quien compró sin cuenta en otro momento (o en otro celular) y no tiene guardados sus datos aquí. Con su
/// documento y su celular el servidor devuelve sus compras; si hay, esos datos quedan guardados en este celular.
class _ConsultaInvitado extends StatefulWidget {
  const _ConsultaInvitado();

  @override
  State<_ConsultaInvitado> createState() => _ConsultaInvitadoState();
}

class _ConsultaInvitadoState extends State<_ConsultaInvitado> {
  final _formulario = GlobalKey<FormState>();
  final _documento = TextEditingController();
  final _telefono = TextEditingController();
  bool _buscando = false;
  String? _error;

  @override
  void dispose() {
    _documento.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    if (_buscando || !(_formulario.currentState?.validate() ?? false)) return;
    final provider = context.read<EventoProvider>();
    setState(() {
      _buscando = true;
      _error = null;
    });

    final resultado = await provider.consultarTicketsDeInvitado(documento: _documento.text, telefono: _telefono.text);
    if (!mounted) return;
    setState(() {
      _buscando = false;
      _error = resultado.ok ? null : resultado.mensaje;
    });
  }

  InputDecoration _decoracion(String etiqueta, IconData icono) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: _formulario,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: EventoTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Consulta tus tickets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Si compraste sin iniciar sesión, escribe el documento y el celular con los que compraste para ver tus tickets.',
                style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('consulta_documento'),
                controller: _documento,
                enabled: !_buscando,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                decoration: _decoracion('DNI o carné de extranjería', Icons.credit_card_outlined),
                validator: EventoInvitadoValidador.documento,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('consulta_telefono'),
                controller: _telefono,
                enabled: !_buscando,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: _decoracion('Celular', Icons.phone_outlined),
                validator: EventoInvitadoValidador.telefono,
                onFieldSubmitted: (_) => _buscar(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  key: const Key('consulta_error'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_error!, style: TextStyle(fontSize: 13, color: Colors.red.shade800)),
                ),
              ],
              const SizedBox(height: 16),
              EventoBotonPrincipal(
                key: const Key('consulta_buscar'),
                texto: 'Ver mis tickets',
                icono: Icons.search_rounded,
                cargando: _buscando,
                onPressed: _buscar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
