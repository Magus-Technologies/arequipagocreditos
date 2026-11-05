import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/evento_formato.dart';
import '../../core/utils/evento_persona.dart';
import '../../data/models/evento_models.dart';
import '../components/evento_ticket_acciones.dart';
import '../components/evento_ticket_card.dart';
import '../components/evento_widgets.dart';
import '../components/image_picker_modal.dart';
import '../providers/evento_provider.dart';
import '../widgets/image_full_screen_view.dart';
import 'evento_terminos_page.dart';

/// Paso 3: pagar con el QR y subir la captura. También es el detalle de una compra ya hecha (en revisión, confirmada,
/// rechazada o anulada). El estado se vuelve a pedir al abrir y con «jalar para actualizar», porque el personal la confirma o
/// la rechaza desde la web.
class EventoPagoPage extends StatefulWidget {
  final EventoCompraModel compra;

  const EventoPagoPage({super.key, required this.compra});

  @override
  State<EventoPagoPage> createState() => _EventoPagoPageState();
}

class _EventoPagoPageState extends State<EventoPagoPage> {
  final ImagePicker _picker = ImagePicker();
  bool _subiendo = false;
  bool _cancelando = false;

  /// Sube cada vez que se reemplaza la captura: si el servidor reutiliza la misma URL, la imagen en caché no se queda vieja.
  int _versionCaptura = 0;

  /// El `RepaintBoundary` que envuelve al ticket: de ahí sale la imagen para compartir.
  final GlobalKey _ticketKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recargar());
  }

  Future<void> _recargar() async {
    final persona = EventoPersona.de(context);
    if (persona == null) return;
    await context.read<EventoProvider>().cargarMisCompras(
          clienteConductorId: persona.id,
          nroDocumento: persona.documento,
        );
  }

  void _aviso(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _elegirCaptura(EventoCompraModel compra) async {
    if (_subiendo) return;

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
    if (origen == null || !mounted) return;

    setState(() => _subiendo = true);
    try {
      final XFile? imagen = await _picker.pickImage(source: origen, imageQuality: 70, maxWidth: 1600);
      if (imagen == null || !mounted) return;

      final archivo = File(imagen.path);
      if (archivo.lengthSync() > AppConstants.maxImageSizeInBytes) {
        if (mounted) _aviso('El archivo supera el tamaño máximo de 5 MB. Elige uno más liviano.', error: true);
        return;
      }

      final resultado = await context.read<EventoProvider>().subirCaptura(compra.id, archivo);
      if (!mounted) return;
      if (resultado.ok) {
        setState(() => _versionCaptura++);
        _aviso('Captura enviada. Estamos revisando tu pago.');
      } else {
        _aviso(resultado.mensaje!, error: true);
      }
    } catch (_) {
      if (mounted) _aviso('No pudimos abrir la imagen. Inténtalo de nuevo.', error: true);
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _cancelar(EventoCompraModel compra) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cancelar la compra?'),
        content: Text(
          'Se anulará tu compra de ${EventoFormato.tickets(compra.cantidad)} y se liberarán para que puedas volver a comprar.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Volver')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _cancelando = true);
    final resultado = await context.read<EventoProvider>().cancelarCompra(compra.id);
    if (!mounted) return;
    setState(() => _cancelando = false);
    if (resultado.ok) {
      _aviso('Compra cancelada.');
    } else {
      _aviso(resultado.mensaje!, error: true);
    }
  }

  Future<void> _copiarCodigo(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (mounted) _aviso('Código copiado');
  }

  void _ampliar(String url, String tag, String titulo) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ImageFullScreenView(imageUrl: url, heroTag: tag, title: titulo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: eventoAppBar('Pago de tickets'),
      body: SafeArea(
        top: false,
        child: Consumer<EventoProvider>(
          builder: (context, provider, _) {
            final compra = provider.compraPorId(widget.compra.id) ?? widget.compra;
            final pendiente = compra.estadoCompra == EstadoCompra.pendiente;
            final confirmado = compra.estadoCompra == EstadoCompra.confirmado;
            final lugar = provider.evento?.id == compra.eventoId ? provider.evento?.lugar : null;

            // Margen lateral de las tarjetas: el ticket va con el suyo adentro del `RepaintBoundary` (para que la imagen que se
            // comparte lleve su sombra completa).
            Widget conMargen(Widget hijo) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: hijo);

            return RefreshIndicator(
              onRefresh: _recargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 28),
                children: [
                  // Confirmada: el estado va DENTRO del ticket (una tarjeta menos). Las demás conservan su tarjeta de estado.
                  if (!confirmado) ...[
                    conMargen(_tarjetaEstado(compra)),
                    const SizedBox(height: 10),
                  ],
                  // Pendiente y confirmada se ven como ticket de entrada (con QR cuando ya está confirmada); rechazada y anulada
                  // no tienen ticket válido y quedan con el resumen simple.
                  if (pendiente || confirmado)
                    RepaintBoundary(
                      key: _ticketKey,
                      child: Container(
                        color: const Color(0xFFF5F6F8),
                        padding: const EdgeInsets.all(8),
                        child: EventoTicketCard(
                          compra: compra,
                          conEstado: confirmado,
                          lugar: lugar,
                          onCopiarCodigo: () => _copiarCodigo(compra.codigo),
                        ),
                      ),
                    )
                  else
                    conMargen(_tarjetaResumen(compra)),
                  // Descargar o compartir: solo con el ticket confirmado (uno pendiente no sirve para entrar).
                  if (confirmado) ...[
                    const SizedBox(height: 2),
                    conMargen(EventoTicketAcciones(compra: compra, capturaKey: _ticketKey)),
                  ],
                  // El QR para PAGAR solo para una compra vieja sin captura: las nuevas ya se registran pagadas y con captura.
                  if (pendiente && !compra.tieneCaptura && compra.qrUrl != null) ...[
                    const SizedBox(height: 10),
                    conMargen(_tarjetaQr(compra)),
                  ],
                  if (pendiente) ...[
                    const SizedBox(height: 10),
                    conMargen(_tarjetaCaptura(compra)),
                  ],
                  if (compra.estadoCompra == EstadoCompra.rechazado && provider.puedeComprar) ...[
                    const SizedBox(height: 10),
                    conMargen(
                      EventoBotonPrincipal(
                        texto: 'Comprar de nuevo',
                        icono: Icons.refresh,
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const EventoTerminosPage()),
                        ),
                      ),
                    ),
                  ],
                  if (compra.puedeCancelar) ...[
                    const SizedBox(height: 10),
                    conMargen(
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          key: const Key('evento_cancelar_compra'),
                          onPressed: _cancelando || provider.enviando ? null : () => _cancelar(compra),
                          icon: _cancelando
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.close),
                          label: const Text('Cancelar compra'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Qué le toca a la persona según el estado.
  (IconData, String) _mensajeEstado(EventoCompraModel c) {
    switch (c.estadoCompra) {
      case EstadoCompra.pendiente:
        return c.tieneCaptura
            ? (Icons.hourglass_top_rounded, 'Recibimos tu captura. Estamos revisando tu pago; aquí verás cuando esté confirmado.')
            : (Icons.qr_code_2, 'Paga con el QR y sube la captura del pago.');
      case EstadoCompra.confirmado:
        return (Icons.check_circle_outline, 'Tu pago fue confirmado. ¡Te esperamos en el evento!');
      case EstadoCompra.rechazado:
        return (Icons.cancel_outlined, 'No pudimos validar tu pago.');
      case EstadoCompra.anulado:
        return (Icons.block, 'Esta compra fue anulada.');
      case EstadoCompra.desconocido:
        return (Icons.info_outline, 'Estado de la compra: ${c.etiquetaEstado}.');
    }
  }

  Widget _tarjetaEstado(EventoCompraModel compra) {
    final (icono, mensaje) = _mensajeEstado(compra);
    final rechazado = compra.estadoCompra == EstadoCompra.rechazado;
    return EventoTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventoEstadoChip(compra: compra),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, size: 20, color: Colors.black54),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje,
                  key: const Key('evento_mensaje_estado'),
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
          if (rechazado) ...[
            if (compra.motivoRechazo != null) ...[
              const SizedBox(height: 10),
              Text(
                'Motivo: ${compra.motivoRechazo}',
                key: const Key('evento_motivo_rechazo'),
                style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Puedes comprar tus tickets de nuevo.',
              key: const Key('evento_puede_comprar_de_nuevo'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaResumen(EventoCompraModel compra) {
    final pendiente = compra.estadoCompra == EstadoCompra.pendiente;
    final fecha = EventoFormato.fechaHora(compra.fechaHoraEvento);
    return EventoTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(compra.eventoNombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (fecha.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(fecha, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
          const Divider(height: 24),
          _fila('Tickets', '${compra.cantidad} × ${EventoFormato.monto(compra.precioUnitario)}'),
          const SizedBox(height: 8),
          _fila(
            pendiente ? 'Monto a pagar' : 'Monto',
            EventoFormato.monto(compra.montoTotal),
            destacado: true,
            key: const Key('evento_monto'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Código de compra', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
              Text(
                compra.codigo,
                key: const Key('evento_codigo'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              IconButton(
                key: const Key('evento_copiar_codigo'),
                tooltip: 'Copiar código',
                visualDensity: VisualDensity.compact,
                onPressed: compra.codigo.isEmpty ? null : () => _copiarCodigo(compra.codigo),
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor, {bool destacado = false, Key? key}) {
    return Row(
      children: [
        Expanded(child: Text(etiqueta, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        Text(valor, key: key, style: TextStyle(fontSize: destacado ? 20 : 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _tarjetaQr(EventoCompraModel compra) {
    final qr = compra.qrUrl!;
    final tag = 'evento_qr_${compra.id}';
    return EventoTarjeta(
      child: Column(
        children: [
          const Text('Paga con el QR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GestureDetector(
            key: const Key('evento_qr'),
            onTap: () => _ampliar(qr, tag, 'QR de pago'),
            child: Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  qr,
                  height: 260,
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
          const SizedBox(height: 12),
          Text(
            'Paga el monto exacto de ${EventoFormato.monto(compra.montoTotal)} y sube la captura del pago.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _urlCaptura(String url) {
    if (_versionCaptura == 0) return url;
    return '$url${url.contains('?') ? '&' : '?'}v=$_versionCaptura';
  }

  Widget _tarjetaCaptura(EventoCompraModel compra) {
    final tag = 'evento_captura_${compra.id}';
    final url = compra.tieneCaptura ? _urlCaptura(compra.capturaUrl!) : null;
    return EventoTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Captura del pago', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (url != null)
            GestureDetector(
              key: const Key('evento_captura_vista_previa'),
              onTap: () => _ampliar(url, tag, 'Captura del pago'),
              child: Hero(
                tag: tag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    memCacheWidth: 1000,
                    placeholder: (context, url) => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 120,
                      alignment: Alignment.center,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.black26, size: 40),
                    ),
                  ),
                ),
              ),
            )
          else
            Text(
              'Todavía no subiste la captura de tu pago.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          if (compra.puedeSubirCaptura) ...[
            const SizedBox(height: 14),
            EventoBotonPrincipal(
              key: const Key('evento_subir_captura'),
              texto: compra.tieneCaptura ? 'Cambiar captura del pago' : 'Subir captura del pago',
              icono: Icons.upload_rounded,
              cargando: _subiendo,
              onPressed: () => _elegirCaptura(compra),
            ),
          ],
        ],
      ),
    );
  }
}
