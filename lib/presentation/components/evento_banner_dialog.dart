import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/utils/evento_formato.dart';
import '../../data/models/evento_models.dart';
import '../../theme/app_theme.dart';
import 'evento_widgets.dart';

/// Aviso que sale al entrar al inicio cuando hay un evento activo: el banner, el nombre y la fecha.
/// Cierra con `true` si la persona quiere comprar (toca el banner o el botón) y con `false`/null si dice «Ahora no».
///
/// Con `invitado` es el aviso de ANTES de iniciar sesión (pantalla de bienvenida): lleva la etiqueta «NUEVO EVENTO» sobre el banner,
/// no muestra el lugar ni el precio (eso queda detrás del inicio de sesión) y el botón dice «Ver más detalle · Inicia sesión para
/// continuar». Cierra con `true` si la persona quiere iniciar sesión.
class EventoBannerDialog extends StatelessWidget {
  final EventoModel evento;
  final bool invitado;

  const EventoBannerDialog({super.key, required this.evento, this.invitado = false});

  @override
  Widget build(BuildContext context) {
    final pantalla = MediaQuery.of(context).size;
    final ancho = math.min(420.0, pantalla.width - 36);
    final fecha = EventoFormato.fechaHora(evento.fechaHora);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: ancho,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                key: const Key('evento_banner'),
                onTap: () => Navigator.of(context).pop(true),
                child: Stack(
                  children: [
                    _banner(pantalla.height * 0.5),
                    if (invitado)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                          child: const Text(
                            'NUEVO EVENTO',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.9, color: AppTheme.primary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.nombre,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (fecha.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(fecha, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ],
                    if (!invitado && evento.lugar != null) ...[
                      const SizedBox(height: 2),
                      Text(evento.lugar!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ],
                    const SizedBox(height: 16),
                    EventoBotonComprar(
                      key: Key(invitado ? 'evento_invitado_boton' : 'evento_banner_comprar'),
                      texto: invitado ? 'Ver más detalle' : 'Comprar tickets',
                      subtexto: invitado
                          ? 'Inicia sesión para continuar'
                          : (evento.precioTicket > 0 ? '${EventoFormato.monto(evento.precioTicket)} por ticket' : null),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  key: const Key('evento_banner_ahora_no'),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Ahora no'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner(double altoMaximo) {
    final url = evento.bannerUrl;
    if (url == null) return _bannerSinImagen();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: altoMaximo),
      child: CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        fit: BoxFit.contain,
        memCacheWidth: 1200,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (context, url) => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => _bannerSinImagen(),
      ),
    );
  }

  /// Si el banner no carga (sin conexión, archivo borrado) el aviso sigue siendo útil: se ve el nombre y el botón.
  Widget _bannerSinImagen() {
    return Container(
      height: 120,
      color: AppTheme.primary,
      alignment: Alignment.center,
      child: const Icon(Icons.celebration, size: 56, color: Colors.black87),
    );
  }
}
