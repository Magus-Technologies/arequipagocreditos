import 'package:flutter/material.dart';

class HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;
  final VoidCallback onTap;
  final double size;

  const HeaderIcon({
    super.key,
    this.icon = Icons.person,
    required this.onTap,
    this.imageUrl,
    this.size = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    // Contenedor base con sombra/borde que compartimos entre icon e imagen
    Widget child;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      child = ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            // Si falla la carga, mostramos el icono como fallback
            errorBuilder: (context, error, stackTrace) {
              return _buildIconFallback();
            },
            // Mientras carga mostramos un pequeño loader o el icono
            loadingBuilder: (context, widget, loadingProgress) {
              if (loadingProgress == null) return widget;
              return Center(
                child: SizedBox(
                  width: size * 0.5,
                  height: size * 0.5,
                  child: const CircularProgressIndicator(strokeWidth: 2.0),
                ),
              );
            },
          ),
        ),
      );
    } else {
      child = _buildIconFallback();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.15 * 255).toInt()),
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: Colors.white.withAlpha((0.3 * 255).toInt())),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // Centrar el contenido (imagen o icono)
        child: Center(child: child),
      ),
    );
  }

  Widget _buildIconFallback() {
    return Icon(icon, color: Colors.white, size: size * 0.5);
  }
}