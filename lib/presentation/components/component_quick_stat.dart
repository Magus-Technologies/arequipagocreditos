import 'package:flutter/material.dart';

class ComponentQuickStat extends StatefulWidget {
  final String emoji;
  final String label;
  final String value;
  final Color? primaryColor;
  final Color? secondaryColor;
  final VoidCallback? onTap;

  const ComponentQuickStat({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    this.primaryColor,
    this.secondaryColor,
    this.onTap,
  });

  @override
  State<ComponentQuickStat> createState() => _ComponentQuickStatState();
}

class _ComponentQuickStatState extends State<ComponentQuickStat> {
  // Lista de gradientes predefinidos para variedad
  static const List<List<Color>> gradientPresets = [
    [Color(0xFF667eea), Color(0xFF764ba2)], // Azul-Púrpura
    [Color(0xFFf093fb), Color(0xFFf5576c)], // Rosa-Rojo
    [Color(0xFF4facfe), Color(0xFF00f2fe)], // Azul-Cian
    [Color(0xFF43e97b), Color(0xFF38f9d7)], // Verde-Turquesa
    [Color(0xFFfa709a), Color(0xFFfee140)], // Rosa-Amarillo
  ];

  @override
  Widget build(BuildContext context) {
    // Determinar colores basado en el emoji o usar colores personalizados
    List<Color> gradientColors;
    if (widget.primaryColor != null && widget.secondaryColor != null) {
      gradientColors = [widget.primaryColor!, widget.secondaryColor!];
    } else {
      // Seleccionar gradiente basado en el emoji
      int index = widget.emoji.hashCode.abs() % gradientPresets.length;
      gradientColors = gradientPresets[index];
    }

    return Container(
      width: 280, // Más ancho como los banners de la imagen
      height: 90, // Más alto para mejor proporción
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withAlpha((0.3 * 255).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withAlpha((0.2 * 255).toInt()),
          child: Stack(
            children: [
              // Patrón de fondo sutil
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.white.withAlpha((0.1 * 255).toInt()),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Círculos decorativos
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha((0.1 * 255).toInt()),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha((0.05 * 255).toInt()),
                  ),
                ),
              ),
              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icono con diseño moderno
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha((0.3 * 255).toInt()),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Contenido del banner
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.label.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Flecha indicadora
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
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
