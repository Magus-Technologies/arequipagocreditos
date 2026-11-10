import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/evento_invitado.dart';
import '../components/evento_widgets.dart';
import '../providers/evento_provider.dart';
import 'evento_compra_page.dart';
import 'evento_mis_tickets_page.dart';

/// Paso de la compra para quien NO tiene cuenta (o no puede entrar con ella): sus datos. Nombre completo, DNI o carné de extranjería y
/// celular son obligatorios; el correo es opcional. Se guardan en el celular para no pedirlos de nuevo y para que «Mis tickets»
/// funcione sin iniciar sesión (TK-0450). Solo se llega aquí desde un evento PÚBLICO.
///
/// Las reglas son las mismas que valida el servidor, así el error se ve acá y no después de subir la captura del pago.
class EventoInvitadoDatosPage extends StatefulWidget {
  const EventoInvitadoDatosPage({super.key});

  @override
  State<EventoInvitadoDatosPage> createState() => _EventoInvitadoDatosPageState();
}

class _EventoInvitadoDatosPageState extends State<EventoInvitadoDatosPage> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _documento = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  bool _guardando = false;

  /// Una compra que ya llegó al tope por persona no sigue: se avisa y se manda a «Mis tickets».
  String? _aviso;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rellenar());
  }

  @override
  void dispose() {
    _nombre.dispose();
    _documento.dispose();
    _telefono.dispose();
    _correo.dispose();
    super.dispose();
  }

  /// Si el celular ya conoce a esta persona (compró antes), sus datos salen escritos.
  Future<void> _rellenar() async {
    final provider = context.read<EventoProvider>();
    await provider.restaurarInvitado();
    if (!mounted) return;
    final guardado = provider.invitado;
    if (guardado == null) return;

    // Lo que la persona ya haya escrito mientras tanto no se pisa.
    if (_nombre.text.isEmpty) _nombre.text = guardado.nombre;
    if (_documento.text.isEmpty) _documento.text = guardado.documento;
    if (_telefono.text.isEmpty) _telefono.text = guardado.telefono;
    if (_correo.text.isEmpty) _correo.text = guardado.correo ?? '';
  }

  Future<void> _continuar() async {
    if (_guardando || !(_formulario.currentState?.validate() ?? false)) return;

    final provider = context.read<EventoProvider>();
    setState(() {
      _guardando = true;
      _aviso = null;
    });

    final datos = EventoInvitado.normalizado(
      nombre: _nombre.text,
      documento: _documento.text,
      telefono: _telefono.text,
      correo: _correo.text,
    );
    await provider.identificarInvitado(datos);
    // Sus compras de este evento (si ya compró antes con estos datos) definen cuántos tickets le quedan.
    await provider.cargarMisComprasInvitado();
    if (!mounted) return;

    if (!provider.puedeComprar) {
      setState(() {
        _guardando = false;
        _aviso = provider.evento == null ? 'Este evento ya no está disponible.' : provider.mensajeTope;
      });
      return;
    }

    // Reemplaza esta pantalla: los datos ya se guardaron y volver a ellos desde la compra no tiene sentido.
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const EventoCompraPage()));
  }

  void _verMisTickets() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const EventoMisTicketsPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: eventoAppBar('Tus datos'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formulario,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EventoTarjeta(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 22),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Para comprar sin cuenta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Necesitamos tus datos para generar tu ticket y avisarte cuando confirmemos tu pago. '
                              'Con tu documento y tu celular podrás ver tus tickets en este app, sin iniciar sesión.',
                              style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      EventoTarjeta(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              key: const Key('invitado_nombre'),
                              controller: _nombre,
                              enabled: !_guardando,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: _decoracion('Nombre completo', Icons.badge_outlined),
                              validator: EventoInvitadoValidador.nombre,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              key: const Key('invitado_documento'),
                              controller: _documento,
                              enabled: !_guardando,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(15)],
                              decoration: _decoracion('DNI o carné de extranjería', Icons.credit_card_outlined),
                              validator: EventoInvitadoValidador.documento,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              key: const Key('invitado_telefono'),
                              controller: _telefono,
                              enabled: !_guardando,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()\-]')), LengthLimitingTextInputFormatter(20)],
                              decoration: _decoracion('Celular', Icons.phone_outlined),
                              validator: EventoInvitadoValidador.telefono,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              key: const Key('invitado_correo'),
                              controller: _correo,
                              enabled: !_guardando,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              decoration: _decoracion('Correo (opcional)', Icons.mail_outline),
                              validator: EventoInvitadoValidador.correo,
                              onFieldSubmitted: (_) => _continuar(),
                            ),
                          ],
                        ),
                      ),
                      if (_aviso != null) ...[
                        const SizedBox(height: 14),
                        _cajaAviso(_aviso!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: EventoBotonPrincipal(
                key: const Key('invitado_continuar'),
                texto: 'Continuar',
                cargando: _guardando,
                onPressed: _continuar,
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _cajaAviso(String texto) {
    return Container(
      key: const Key('invitado_aviso'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.orange.shade800),
              const SizedBox(width: 10),
              Expanded(child: Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const Key('invitado_ver_mis_tickets'),
              onPressed: _verMisTickets,
              icon: const Icon(Icons.confirmation_number_outlined, size: 18),
              label: const Text('Ver mis tickets'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade900, side: BorderSide(color: Colors.orange.shade300)),
            ),
          ),
        ],
      ),
    );
  }
}
