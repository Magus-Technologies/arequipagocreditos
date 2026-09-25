import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/comercio_entity.dart';

const Color _comercioAccent = Color(0xFFC2410C);

class ComercioCard extends StatelessWidget {
  final ComercioEntity comercio;
  final VoidCallback? onTap;

  const ComercioCard({super.key, required this.comercio, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.07 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _comercioAccent.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _comercioAccent.withAlpha((0.2 * 255).toInt()), width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: comercio.logo != null && comercio.logo!.isNotEmpty
                    ? Image.network(
                        '${ApiConstants.imagenesBaseUrl}/${comercio.logo!}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.storefront, color: _comercioAccent, size: 30),
                      )
                    : const Icon(Icons.storefront, color: _comercioAccent, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comercio.nombreParaMostrar,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (comercio.direccion != null && comercio.direccion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              comercio.direccion!,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Wrap y no Row: con un rubro largo más el chip de servicios,
                    // la fila se desbordaba en teléfonos angostos. Así los
                    // elementos bajan de línea en vez de recortarse.
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (comercio.categoriaNombre != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                constraints: const BoxConstraints(maxWidth: 160),
                                decoration: BoxDecoration(
                                  color: _comercioAccent.withAlpha((0.15 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  comercio.categoriaNombre!,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            // TK-0314: adelanta que el comercio tiene algo para solicitar.
                            if (comercio.serviciosCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha((0.12 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  comercio.serviciosCount == 1
                                      ? '1 servicio'
                                      : '${comercio.serviciosCount} servicios',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (comercio.googleMapsUrl != null && comercio.googleMapsUrl!.isNotEmpty)
                              _ActionIcon(
                                icon: const Icon(Icons.map, size: 14, color: Color(0xFF4285F4)),
                                color: const Color(0xFF4285F4),
                                onTap: () => launchUrl(Uri.parse(comercio.googleMapsUrl!)),
                              ),
                            if (comercio.whatsappUrl != null && comercio.whatsappUrl!.isNotEmpty)
                              _ActionIcon(
                                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 14, color: Color(0xFF25D366)),
                                color: const Color(0xFF25D366),
                                onTap: () => launchUrl(Uri.parse(comercio.whatsappUrl!)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha((0.2 * 255).toInt())),
        ),
        child: icon,
      ),
    );
  }
}
