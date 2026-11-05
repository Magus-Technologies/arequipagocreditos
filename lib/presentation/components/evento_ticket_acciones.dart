import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/evento_models.dart';
import '../providers/evento_provider.dart';

/// Cómo se comparte un archivo (hoja de compartir del celular: WhatsApp, correo, Drive…). Solo se cambia en pruebas.
typedef CompartirArchivo = Future<void> Function(File archivo, String texto);

/// Cómo se guarda un archivo con el diálogo «Guardar como» del sistema (elige carpeta, p. ej. Descargas). Devuelve dónde quedó, o null
/// si la persona canceló. Solo se cambia en pruebas.
typedef GuardarArchivo = Future<String?> Function(String nombre, Uint8List bytes);

/// De dónde sale el PDF del ticket: lo ARMA EL SERVIDOR (su diseño se cambia allá, sin publicar otra versión del app). Devuelve los
/// bytes o lanza [ErrorDeTicket] con el mensaje que se le muestra a la persona. Solo se cambia en pruebas.
typedef ObtenerPdfTicket = Future<Uint8List> Function();

/// Un error de los que se le dicen a la persona tal cual (p. ej. «Revisa tu conexión» o lo que respondió el servidor).
class ErrorDeTicket implements Exception {
  final String mensaje;

  const ErrorDeTicket(this.mensaje);
}

/// Descargar o compartir el ticket: PDF para guardar, PDF para compartir e imagen para compartir.
///
/// - «Descargar PDF» baja el PDF del servidor y abre el «Guardar como» del sistema (no pide permisos de almacenamiento).
/// - «Compartir PDF» baja el mismo PDF y abre la hoja de compartir del celular.
/// - «Compartir imagen» saca una foto del ticket tal como se ve en pantalla (no necesita conexión).
///
/// Solo se ofrece con el ticket CONFIRMADO (uno pendiente no sirve para entrar). `capturaKey` es la llave del `RepaintBoundary` que
/// envuelve al ticket en pantalla.
class EventoTicketAcciones extends StatefulWidget {
  final EventoCompraModel compra;
  final GlobalKey capturaKey;
  final CompartirArchivo? compartir;
  final GuardarArchivo? guardar;
  final ObtenerPdfTicket? obtenerPdf;

  /// Carpeta donde se arma el archivo antes de compartirlo (por defecto, la temporal de la app). Solo se cambia en pruebas.
  final Future<Directory> Function()? carpetaTemporal;

  const EventoTicketAcciones({
    super.key,
    required this.compra,
    required this.capturaKey,
    this.compartir,
    this.guardar,
    this.obtenerPdf,
    this.carpetaTemporal,
  });

  @override
  State<EventoTicketAcciones> createState() => _EventoTicketAccionesState();
}

class _EventoTicketAccionesState extends State<EventoTicketAcciones> {
  /// La acción en curso (null = ninguna): los otros botones se bloquean mientras tanto.
  String? _ocupado;

  Future<void> _compartirReal(File archivo, String texto) async {
    await Share.shareXFiles([XFile(archivo.path)], text: texto);
  }

  Future<String?> _guardarReal(String nombre, Uint8List bytes) {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Guardar ticket',
      fileName: nombre,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
  }

  /// Pide el PDF al servidor con la persona de la sesión.
  Future<Uint8List> _obtenerPdfReal() async {
    final resultado = await context.read<EventoProvider>().descargarTicketPdf(widget.compra.id);
    if (!resultado.ok) throw ErrorDeTicket(resultado.mensaje!);
    return resultado.data!;
  }

  void _aviso(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(texto), backgroundColor: error ? Colors.redAccent : Colors.green, behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _ejecutar(String accion, Future<void> Function() trabajo) async {
    if (_ocupado != null) return;
    setState(() => _ocupado = accion);
    try {
      await trabajo();
    } on ErrorDeTicket catch (e) {
      _aviso(e.mensaje, error: true);
    } catch (_) {
      _aviso('No pudimos preparar el ticket. Inténtalo de nuevo.', error: true);
    } finally {
      if (mounted) setState(() => _ocupado = null);
    }
  }

  Future<Uint8List> _pdf() => (widget.obtenerPdf ?? _obtenerPdfReal)();

  /// «ticket-EV-K7M2QX.pdf» (el mismo nombre que le pone el servidor).
  String _nombre(String extension) {
    final codigo = widget.compra.codigo.replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '');
    return 'ticket-${codigo.isEmpty ? widget.compra.id : codigo}.$extension';
  }

  Future<File> _enTemporal(String nombre, Uint8List bytes) async {
    final carpeta = await (widget.carpetaTemporal ?? getTemporaryDirectory)();
    return File('${carpeta.path}${Platform.pathSeparator}$nombre').writeAsBytes(bytes, flush: true);
  }

  String get _textoCompartir => 'Mi ticket para ${widget.compra.eventoNombre} (código ${widget.compra.codigo})';

  Future<void> _descargarPdf() => _ejecutar('descargar', () async {
        final bytes = await _pdf();
        final destino = await (widget.guardar ?? _guardarReal)(_nombre('pdf'), bytes);
        if (destino != null) _aviso('Ticket guardado en PDF.');
      });

  Future<void> _compartirPdf() => _ejecutar('pdf', () async {
        final bytes = await _pdf();
        final archivo = await _enTemporal(_nombre('pdf'), bytes);
        await (widget.compartir ?? _compartirReal)(archivo, _textoCompartir);
      });

  Future<void> _compartirImagen() => _ejecutar('imagen', () async {
        final frontera = widget.capturaKey.currentContext?.findRenderObject();
        if (frontera is! RenderRepaintBoundary) throw StateError('El ticket todavía no se dibujó');
        // Tres veces la resolución de la pantalla: nítida al verla en el chat y al ampliarla.
        final imagen = await frontera.toImage(pixelRatio: 3);
        final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
        if (datos == null) throw StateError('No se pudo armar la imagen');
        final archivo = await _enTemporal(_nombre('png'), datos.buffer.asUint8List());
        await (widget.compartir ?? _compartirReal)(archivo, _textoCompartir);
      });

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('evento_ticket_acciones'),
      children: [
        Expanded(child: _boton('descargar', const Key('evento_ticket_descargar_pdf'), Icons.download_rounded, 'Descargar PDF', _descargarPdf)),
        const SizedBox(width: 8),
        Expanded(child: _boton('pdf', const Key('evento_ticket_compartir_pdf'), Icons.picture_as_pdf_rounded, 'Compartir PDF', _compartirPdf)),
        const SizedBox(width: 8),
        Expanded(child: _boton('imagen', const Key('evento_ticket_compartir_imagen'), Icons.image_rounded, 'Compartir imagen', _compartirImagen)),
      ],
    );
  }

  Widget _boton(String accion, Key llave, IconData icono, String texto, VoidCallback onPressed) {
    final cargando = _ocupado == accion;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: llave,
        borderRadius: BorderRadius.circular(14),
        onTap: _ocupado != null ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              cargando
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(icono, size: 22, color: _ocupado != null ? Colors.grey.shade400 : Colors.black87),
              const SizedBox(height: 4),
              Text(
                texto,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: _ocupado != null ? Colors.grey.shade500 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
