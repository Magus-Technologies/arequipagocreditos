import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/evento_formato.dart';
import '../../core/utils/evento_persona.dart';
import '../components/evento_widgets.dart';
import '../components/image_picker_modal.dart';
import '../providers/evento_provider.dart';
import '../widgets/image_full_screen_view.dart';
import 'evento_mis_tickets_page.dart';
import 'evento_pago_page.dart';

/// Paso 2: cuántos tickets, pago con el QR y la CAPTURA del pago. La captura es OBLIGATORIA: la compra solo se registra al enviarla
/// junto con la cantidad (5-nov, Rodrigo: «si o sí es obligatoria la captura»). Antes la compra se registraba primero y la captura
/// se subía después, y llegaban compras sin captura que ocupaban el cupo de la persona.
///
/// De 1 hasta lo que le queda de su tope por persona. Al enviar, pasa al detalle de la compra (en revisión).
class EventoCompraPage extends StatefulWidget {
  /// Cómo se elige la captura del pago (galería o cámara). Solo se cambia en pruebas: el selector real necesita el celular.
  final Future<File?> Function()? elegirCaptura;

  const EventoCompraPage({super.key, this.elegirCaptura});

  @override
  State<EventoCompraPage> createState() => _EventoCompraPageState();
}

class _EventoCompraPageState extends State<EventoCompraPage> {
  final ImagePicker _picker = ImagePicker();
  int _cantidad = 1;
  File? _captura;
  bool _eligiendo = false;
  bool _enviando = false;
  String? _error;

  /// El error es de los que dejan en duda si la compra se registró: se ofrece ir a «Mis tickets» a comprobarlo.
  bool _incierto = false;

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  Future<File?> _elegirCapturaReal() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ImagePickerModal(
        title: 'Captura del pago',
        onGalleryTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
        onCameraTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
        onFileTap: null,
      ),
    );
    if (origen == null || !mounted) return null;

    try {
      final XFile? imagen = await _picker.pickImage(source: origen, imageQuality: 70, maxWidth: 1600);
      if (imagen == null || !mounted) return null;

      final archivo = File(imagen.path);
      if (archivo.lengthSync() > AppConstants.maxImageSizeInBytes) {
        _aviso('El archivo supera el tamaño máximo de 5 MB. Elige uno más liviano.');
        return null;
      }
      return archivo;
    } catch (_) {
      if (mounted) _aviso('No pudimos abrir la imagen. Inténtalo de nuevo.');
      return null;
    }
  }

  Future<void> _elegir() async {
    if (_eligiendo || _enviando) return;
    setState(() => _eligiendo = true);
    try {
      final archivo = await (widget.elegirCaptura ?? _elegirCapturaReal)();
      if (!mounted) return;
      if (archivo != null) setState(() => _captura = archivo);
    } finally {
      if (mounted) setState(() => _eligiendo = false);
    }
  }

  Future<void> _enviar(int cantidad) async {
    final captura = _captura;
    // Bandera propia y síncrona: dos toques seguidos no llegan a mandar dos compras. Sin captura no se manda nada.
    if (_enviando || captura == null) return;
    setState(() {
      _enviando = true;
      _error = null;
      _incierto = false;
    });

    final resultado = await context.read<EventoProvider>().registrarCompra(cantidad, captura);
    if (!mounted) return;

    if (resultado.ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => EventoPagoPage(compra: resultado.data!)),
      );
      return;
    }
    setState(() {
      _enviando = false;
      _error = resultado.mensaje;
      _incierto = resultado.incierto;
    });
  }

  Future<void> _recargarEvento() async {
    final persona = EventoPersona.de(context);
    if (persona == null) return;
    await context.read<EventoProvider>().cargarActivo(clienteConductorId: persona.id, nroDocumento: persona.documento);
  }

  void _verMisTickets() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const EventoMisTicketsPage()));
  }

  void _ampliarQr(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ImageFullScreenView(imageUrl: url, heroTag: 'evento_qr_pagar', title: 'QR de pago')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: eventoAppBar('Comprar tickets'),
      body: SafeArea(
        top: false,
        child: Consumer<EventoProvider>(
          builder: (context, provider, _) {
            final evento = provider.evento;
            if (evento == null) return _sinEvento();

            final disponibles = provider.ticketsDisponibles;
            // Si el cupo cambió mientras la pantalla estaba abierta, la cantidad elegida se ajusta sola.
            final cantidad = disponibles < 1 ? 1 : math.min(math.max(_cantidad, 1), disponibles);
            final total = cantidad * evento.precioTicket;
            final puedeEnviar = disponibles >= 1 && _captura != null && !_enviando;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EventoTarjeta(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(evento.nombre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              if (evento.fechaHora != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  EventoFormato.fechaHora(evento.fechaHora),
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        EventoTarjeta(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _titulo('1', '¿Cuántos tickets?'),
                              const SizedBox(height: 14),
                              _selector(cantidad, disponibles),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  provider.textoCupo,
                                  key: const Key('evento_texto_cupo'),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                              const Divider(height: 28),
                              _fila('Precio por ticket', EventoFormato.monto(evento.precioTicket)),
                              const SizedBox(height: 8),
                              _fila('Total a pagar', EventoFormato.monto(total), destacado: true, key: const Key('evento_total')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _tarjetaQr(evento.qrUrl, total),
                        const SizedBox(height: 14),
                        _tarjetaCaptura(),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          _cajaError(),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EventoBotonComprar(
                        key: const Key('evento_enviar_compra'),
                        texto: _enviando ? 'Enviando…' : 'Enviar compra',
                        onPressed: puedeEnviar ? () => _enviar(cantidad) : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _captura == null
                            ? 'Sin la captura de tu pago no se registra la compra.'
                            : 'Tu compra se registra con esta captura y nuestro equipo la valida.',
                        key: const Key('evento_aviso_captura'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _captura == null ? Colors.orange.shade800 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _titulo(String numero, String texto) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
          child: Text(numero, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
      ],
    );
  }

  /// El QR para pagar: sin él la persona no puede pagar. Llega con el evento cuando la persona está identificada.
  Widget _tarjetaQr(String? qr, double total) {
    return EventoTarjeta(
      child: Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: _titulo('2', 'Paga con el QR')),
          const SizedBox(height: 12),
          if (qr != null) ...[
            GestureDetector(
              key: const Key('evento_qr_pagar'),
              onTap: () => _ampliarQr(qr),
              child: Hero(
                tag: 'evento_qr_pagar',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    qr,
                    height: 240,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      alignment: Alignment.center,
                      child: const Icon(Icons.qr_code_2, size: 72, color: Colors.black26),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Toca el QR para ampliarlo', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            Text(
              'Paga el monto exacto de ${EventoFormato.monto(total)}.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
          ] else ...[
            Icon(Icons.qr_code_2, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No pudimos cargar el QR de pago.',
              key: const Key('evento_sin_qr'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            TextButton(
              key: const Key('evento_reintentar_qr'),
              onPressed: _recargarEvento,
              child: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }

  /// La captura del pago: obligatoria. Con una elegida se ve la vista previa y se puede cambiar.
  Widget _tarjetaCaptura() {
    final captura = _captura;
    return EventoTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo('3', 'Sube la captura de tu pago'),
          const SizedBox(height: 12),
          if (captura != null)
            ClipRRect(
              key: const Key('evento_captura_elegida'),
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                captura,
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image_outlined, color: Colors.black26, size: 40),
                ),
              ),
            )
          else
            Text(
              'Después de pagar, adjunta la captura del pago. Es obligatoria.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              key: const Key('evento_elegir_captura'),
              onPressed: _eligiendo || _enviando ? null : _elegir,
              icon: _eligiendo
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(captura == null ? Icons.add_photo_alternate_outlined : Icons.swap_horiz_rounded),
              label: Text(captura == null ? 'Elegir captura del pago' : 'Cambiar captura'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cajaError() {
    return Container(
      key: const Key('evento_error_compra'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 20, color: Colors.red.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_error!, style: TextStyle(fontSize: 13, color: Colors.red.shade800)),
              ),
            ],
          ),
          if (_incierto) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                key: const Key('evento_error_ver_mis_tickets'),
                onPressed: _verMisTickets,
                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                label: const Text('Ver mis tickets'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade800,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ),
          ],
        ],
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

  Widget _selector(int cantidad, int disponibles) {
    final puedeBajar = cantidad > 1 && !_enviando;
    final puedeSubir = cantidad < disponibles && !_enviando;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _botonCantidad(
          key: const Key('evento_cantidad_menos'),
          icono: Icons.remove,
          tooltip: 'Quitar un ticket',
          // Parten de la cantidad guardada (no de la que se dibujó), así dos toques seguidos suman dos aunque no haya habido repintado.
          onPressed: puedeBajar ? () => setState(() => _cantidad = math.max(1, math.min(_cantidad, disponibles) - 1)) : null,
        ),
        SizedBox(
          width: 90,
          child: Text(
            '$cantidad',
            key: const Key('evento_cantidad'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
        _botonCantidad(
          key: const Key('evento_cantidad_mas'),
          icono: Icons.add,
          tooltip: 'Agregar un ticket',
          onPressed: puedeSubir ? () => setState(() => _cantidad = math.min(disponibles, math.max(_cantidad, 1) + 1)) : null,
        ),
      ],
    );
  }

  Widget _botonCantidad({
    required Key key,
    required IconData icono,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton.filled(
      key: key,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icono),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade200,
        disabledForegroundColor: Colors.grey.shade400,
        minimumSize: const Size(48, 48),
      ),
    );
  }

  Widget _fila(String etiqueta, String valor, {bool destacado = false, Key? key}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: TextStyle(fontSize: destacado ? 15 : 14, fontWeight: destacado ? FontWeight.bold : FontWeight.w500),
          ),
        ),
        Text(
          valor,
          key: key,
          style: TextStyle(fontSize: destacado ? 20 : 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
