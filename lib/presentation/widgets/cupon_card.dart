import 'package:arequipagocreditos/data/models/cupon_model.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../core/utils/cupon_utils.dart';

class CuponCard extends StatelessWidget {
  final CuponModel cupon;
  final VoidCallback onUsar;

  const CuponCard({
    super.key,
    required this.cupon,
    required this.onUsar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getGradientColors(),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del banner si está disponible
              if (cupon.imagenBanner != null && cupon.imagenBanner!.isNotEmpty)
                _buildBannerImage(),
              
              // Contenido principal
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerImage() {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Stack(
        children: [
          // Imagen del banner
          Image.network(
            'https://arequipago-ventas.pe/public/${cupon.imagenBanner!}',
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey.shade600,
                  size: 40,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
          // Overlay con gradiente para mejor legibilidad
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha((0.3 * 255).toInt()),
                  Colors.black.withAlpha((0.6 * 255).toInt()),
                ],
              ),
            ),
          ),
          // Badge de descuento sobre la imagen
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cupon.valorFormateado,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        // Patrón de fondo solo si no hay imagen
        if (cupon.imagenBanner == null || cupon.imagenBanner!.isEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: CuponPatternPainter(),
            ),
          ),
        // Contenido del cupón
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildDescription(),
              const SizedBox(height: 16),
              _buildFooter(),
              _buildStatusInfo(),
            ],
          ),
        ),
        // Botón de usar cupón
        if (cupon.puedeUsarse) _buildUseButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Icono de la categoría
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.3 * 255).toInt()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getCategoryIcon(),
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        // Información principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cupon.empresa ?? 'Arequipa GO',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                cupon.titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Badge de descuento solo si no hay imagen
        if (cupon.imagenBanner == null || cupon.imagenBanner!.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              cupon.valorFormateado,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      cupon.descripcion ?? 'Descripción no disponible',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  cupon.codigo ?? 'SIN CÓDIGO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Válido hasta:',
              style: TextStyle(
                color: Colors.white.withAlpha((0.8 * 255).toInt()),
                fontSize: 12,
              ),
            ),
            Text(
              app_date_utils.DateUtils.formatDate(cupon.fechaFin),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusInfo() {
    if (!cupon.puedeUsarse) {
      return Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  cupon.estaVencido ? 'Vencido' : 'No disponible',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildUseButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: ElevatedButton(
        onPressed: onUsar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Usar Cupón',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    // Paleta uniforme y sobria para todas las categorías
    return [const Color(0xFF1F2937), const Color(0xFF374151)];
  }

  IconData _getCategoryIcon() {
    String displayCategory = CuponUtils.getCategoryDisplayName(cupon.categoria);
    switch (displayCategory) {
      case 'Restaurantes':
        return Icons.restaurant;
      case 'Tiendas':
        return Icons.shopping_bag;
      case 'Servicios':
        return Icons.build;
      case 'Entretenimiento':
        return Icons.movie;
      default:
        return Icons.local_offer;
    }
  }
}

// Painter para el patrón de fondo del cupón
class CuponPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha((0.1 * 255).toInt())
      ..style = PaintingStyle.fill;

    // Crear un patrón de círculos
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
