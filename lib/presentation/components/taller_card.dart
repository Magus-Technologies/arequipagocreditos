import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/taller_model.dart';
import '../../theme/app_theme.dart';

class TallerCard extends StatelessWidget {
  final TallerModel taller;
  final VoidCallback onTap;

  const TallerCard({super.key, required this.taller, required this.onTap});

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
              // Logo del taller
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primary.withAlpha((0.2 * 255).toInt()),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: taller.logo != null && taller.logo!.isNotEmpty
                    ? Image.network(
                        '${ApiConstants.imagenesBaseUrl}/${taller.logo!}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.home_repair_service,
                          color: Color(0xFF3B82F6),
                          size: 30,
                        ),
                      )
                    : const Icon(
                        Icons.home_repair_service,
                        color: Color(0xFF3B82F6),
                        size: 30,
                      ),
              ),
              const SizedBox(width: 14),
              // Info del taller
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taller.nombreComercial,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (taller.direccion != null && taller.direccion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              taller.direccion!,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (taller.whatsapp != null && taller.whatsapp!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_android, size: 13, color: const Color(0xFF25D366)),
                          const SizedBox(width: 3),
                          Text(
                            taller.whatsapp!,
                            style: const TextStyle(
                              fontSize: 12, 
                              color: Color(0xFF25D366),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha((0.15 * 255).toInt()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${taller.serviciosCount} servicios',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (taller.googleMapsUrl != null && taller.googleMapsUrl!.isNotEmpty)
                          _ActionButton(
                            icon: Icons.map,
                            label: 'Mapa',
                            color: const Color(0xFF4285F4),
                            onTap: () => launchUrl(Uri.parse(taller.googleMapsUrl!)),
                          ),
                        if (taller.whatsappUrl != null && taller.whatsappUrl!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _ActionButton(
                            icon: FontAwesomeIcons.whatsapp,
                            label: 'Chat',
                            color: const Color(0xFF25D366),
                            onTap: () => launchUrl(Uri.parse(taller.whatsappUrl!)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Flecha
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha((0.2 * 255).toInt())),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
