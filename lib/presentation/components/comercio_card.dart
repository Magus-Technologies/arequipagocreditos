import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/comercio_entity.dart';

const Color _comercioAccent = Color(0xFFC2410C);

/// Tarjeta de un comercio en el listado de Comercios GO: logo, nombre con sus estrellas, rubro, dirección y, abajo, cuántos servicios
/// tiene y los accesos al mapa y al WhatsApp. Tocar la tarjeta abre sus servicios.
class ComercioCard extends StatelessWidget {
  final ComercioEntity comercio;
  final VoidCallback? onTap;

  const ComercioCard({super.key, required this.comercio, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tieneMapa = comercio.googleMapsUrl != null && comercio.googleMapsUrl!.isNotEmpty;
    final tieneWhatsapp = comercio.whatsappUrl != null && comercio.whatsappUrl!.isNotEmpty;
    final tieneDireccion = comercio.direccion != null && comercio.direccion!.isNotEmpty;
    final mostrarPie = comercio.serviciosCount > 0 || tieneMapa || tieneWhatsapp;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFEAE4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Logo(logo: comercio.logo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              comercio.nombreParaMostrar,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937), height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // TK-0382: las estrellas que le ponen los conductores, como en los talleres.
                          if (comercio.tieneCalificaciones) ...[
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 2),
                                Text(
                                  '${comercio.promedioCalificacion.toStringAsFixed(1)} (${comercio.totalCalificaciones})',
                                  key: const Key('comercio-card-calificacion'),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      if (comercio.categoriaNombre != null && comercio.categoriaNombre!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          comercio.categoriaNombre!,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _comercioAccent),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (tieneDireccion) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                comercio.direccion!,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.25),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (mostrarPie) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // TK-0314: adelanta que el comercio tiene algo para solicitar. Expanded + Align: toma todo el espacio que
                            // dejan los botones y la píldora queda a la izquierda con su ancho natural (sin recortarse).
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: comercio.serviciosCount > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.local_offer_rounded, size: 12, color: Color(0xFF15803D)),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                comercio.serviciosCount == 1 ? '1 servicio' : '${comercio.serviciosCount} servicios',
                                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            if (tieneMapa)
                              _ActionIcon(
                                icon: const Icon(Icons.map_outlined, size: 16, color: Color(0xFF4285F4)),
                                color: const Color(0xFF4285F4),
                                onTap: () => launchUrl(Uri.parse(comercio.googleMapsUrl!)),
                              ),
                            if (tieneMapa && tieneWhatsapp) const SizedBox(width: 8),
                            if (tieneWhatsapp)
                              _ActionIcon(
                                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Color(0xFF25D366)),
                                color: const Color(0xFF25D366),
                                onTap: () => launchUrl(Uri.parse(comercio.whatsappUrl!)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? logo;

  const _Logo({required this.logo});

  @override
  Widget build(BuildContext context) {
    const icono = Icon(Icons.storefront_rounded, color: _comercioAccent, size: 28);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _comercioAccent.withAlpha((0.08 * 255).toInt()),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _comercioAccent.withAlpha((0.18 * 255).toInt())),
      ),
      clipBehavior: Clip.antiAlias,
      child: logo != null && logo!.isNotEmpty
          ? Image.network(
              '${ApiConstants.imagenesBaseUrl}/${logo!}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => icono,
            )
          : icono,
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final Widget icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha((0.1 * 255).toInt()),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 36, height: 36, child: Center(child: icon)),
      ),
    );
  }
}
