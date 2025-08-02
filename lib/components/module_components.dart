import 'package:flutter/material.dart';

class ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget? badge;

  const ModuleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withAlpha((0.8 * 255).toInt()),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withAlpha((0.4 * 255).toInt()),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Patrón decorativo de fondo
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.1 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -10,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.05 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono con contenedor elegante
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha((0.3 * 255).toInt()),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Título con mejor tipografía
                  Text(
                    title,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: badge!,
              ),
          ],
        ),
      ),
    );
  }
}