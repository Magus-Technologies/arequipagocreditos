import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/evento_models.dart';
import '../../theme/app_theme.dart';

/// Piezas visuales que comparten las pantallas de «Eventos».

/// Chip con el estado de una compra. Pendiente se ve distinto según haya subido ya la captura (ámbar = falta algo de tu parte,
/// azul = ya lo tiene el equipo).
class EventoEstadoChip extends StatelessWidget {
  final EventoCompraModel compra;

  const EventoEstadoChip({super.key, required this.compra});

  @override
  Widget build(BuildContext context) {
    final Color fondo;
    final Color texto;
    final IconData icono;
    switch (compra.estadoCompra) {
      case EstadoCompra.pendiente:
        if (compra.tieneCaptura) {
          fondo = Colors.blue.shade50;
          texto = Colors.blue.shade800;
          icono = Icons.hourglass_top_rounded;
        } else {
          fondo = Colors.orange.shade50;
          texto = Colors.orange.shade800;
          icono = Icons.upload_file_rounded;
        }
        break;
      case EstadoCompra.confirmado:
        fondo = Colors.green.shade50;
        texto = Colors.green.shade800;
        icono = Icons.check_circle_rounded;
        break;
      case EstadoCompra.rechazado:
        fondo = Colors.red.shade50;
        texto = Colors.red.shade700;
        icono = Icons.cancel_rounded;
        break;
      case EstadoCompra.anulado:
      case EstadoCompra.desconocido:
        fondo = Colors.grey.shade200;
        texto = Colors.grey.shade700;
        icono = Icons.block_rounded;
        break;
    }

    return Container(
      key: const Key('evento_estado_chip'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: texto),
          const SizedBox(width: 5),
          Text(
            compra.etiquetaEstado,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: texto),
          ),
        ],
      ),
    );
  }
}

/// Casilla de aceptación. Misma idea que la del pre-registro, pero con el texto que se le pasa (no el de tratamiento de datos).
class EventoAceptacionCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String texto;

  const EventoAceptacionCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                key: const Key('evento_acepta_terminos'),
                value: value,
                onChanged: (v) => onChanged(v ?? !value),
                activeColor: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón principal negro de ancho completo (el de las pantallas de pago del app). Con `cargando` muestra el spinner y no responde.
class EventoBotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;
  final IconData? icono;

  const EventoBotonPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.cargando = false,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: cargando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: cargando
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icono != null) ...[Icon(icono, size: 20), const SizedBox(width: 8)],
                  Flexible(
                    child: Text(
                      texto,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Botón para COMPRAR tickets: amarillo de la marca con degradado, sombra suave, un sello negro con el ticket a la izquierda y una
/// flecha a la derecha. Reemplaza al botón negro plano en el aviso del evento y en «Mis tickets» (el resto de pantallas de pago
/// sigue con [EventoBotonPrincipal]). `subtexto` es opcional: una línea chica bajo el título (p. ej. el precio por ticket).
class EventoBotonComprar extends StatelessWidget {
  final String texto;
  final String? subtexto;
  final VoidCallback? onPressed;

  const EventoBotonComprar({
    super.key,
    this.texto = 'Comprar tickets',
    this.subtexto,
    required this.onPressed,
  });

  static const Color _amarilloClaro = Color(0xFFFFE867);

  @override
  Widget build(BuildContext context) {
    final habilitado = onPressed != null;
    final radio = BorderRadius.circular(18);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radio,
        boxShadow: habilitado
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.55),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radio,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radio,
            gradient: habilitado
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_amarilloClaro, AppTheme.primary],
                  )
                : null,
            color: habilitado ? null : Colors.grey.shade300,
          ),
          child: InkWell(
            borderRadius: radio,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.confirmation_number_rounded, size: 20, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          texto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                        if (subtexto != null)
                          Text(
                            subtexto!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black.withValues(alpha: 0.65)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 22, color: Colors.black),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// «Cómo llegar»: abre el enlace del mapa del evento (Google Maps) en la aplicación de mapas del celular, o en el navegador si no hay. Si no
/// se puede abrir avisa con un mensaje en vez de quedarse mudo. `compacto` es un texto con ícono para ponerlo bajo el lugar; sin él es un
/// botón de ancho completo.
class EventoBotonMapa extends StatelessWidget {
  final String url;
  final bool compacto;

  /// Cómo se abre el enlace. Las pruebas lo cambian para no lanzar nada de verdad.
  static Future<bool> Function(Uri) abridor = (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  const EventoBotonMapa({super.key, required this.url, this.compacto = false});

  Future<void> _abrir(BuildContext context) async {
    final uri = Uri.tryParse(url);
    var abierto = false;
    if (uri != null) {
      try {
        abierto = await abridor(uri);
      } catch (_) {
        abierto = false;
      }
    }
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el mapa. Inténtalo de nuevo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compacto) {
      return TextButton.icon(
        key: const Key('evento_mapa_compacto'),
        onPressed: () => _abrir(context),
        icon: const Icon(Icons.directions_rounded, size: 18),
        label: const Text('Cómo llegar', style: TextStyle(fontWeight: FontWeight.w700)),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1A56DB),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        key: const Key('evento_boton_mapa'),
        onPressed: () => _abrir(context),
        icon: const Icon(Icons.directions_rounded, size: 20),
        label: const Text('Cómo llegar', style: TextStyle(fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Tarjeta blanca de las pantallas de «Eventos».
class EventoTarjeta extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const EventoTarjeta({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

/// Barra superior amarilla con el título, como «Mis órdenes de pago».
PreferredSizeWidget eventoAppBar(String titulo) {
  return AppBar(
    backgroundColor: AppTheme.brandYellow,
    foregroundColor: Colors.black,
    elevation: 0,
    title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  );
}
