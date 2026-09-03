import 'package:flutter/material.dart';

class ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget? badge;

  const ModuleCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final onColor = iconColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withAlpha((0.85 * 255).toInt()),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withAlpha((0.35 * 255).toInt()),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Detalle decorativo sutil, sin competir con el contenido
            Positioned(
              top: -18,
              right: -18,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.08 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withAlpha((0.30 * 255).toInt()),
                                  Colors.white.withAlpha((0.12 * 255).toInt()),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withAlpha((0.35 * 255).toInt()),
                                width: 1,
                              ),
                            ),
                            child: Icon(icon, size: 22, color: onColor),
                          ),
                          // Puntito decorativo, detalle sutil tipo "highlight"
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.55 * 255).toInt()),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: onColor.withAlpha((0.7 * 255).toInt()),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: onColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: onColor.withAlpha((0.75 * 255).toInt()),
                        fontSize: 11,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null)
              Positioned(top: 8, right: 8, child: badge!),
          ],
        ),
      ),
    );
  }
}
