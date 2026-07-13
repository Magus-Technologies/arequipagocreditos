import 'package:flutter/material.dart';
import '../../domain/entities/cupon_entity.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../theme/app_theme.dart';

class CuponPublicDetailPage extends StatelessWidget {
  final CuponEntity cupon;
  const CuponPublicDetailPage({super.key, required this.cupon});

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImagePage(
          imageUrl: imageUrl,
          heroTag: 'cupon_banner_${cupon.id}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primary.withAlpha((0.85 * 255).toInt())],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Banner con overlay y badge
              if (cupon.imagenBanner != null && cupon.imagenBanner!.isNotEmpty)
                GestureDetector(
                  onTap: () => _openFullScreenImage(
                    context,
                    'https://arequipago-ventas.pe/storage/${cupon.imagenBanner!}',
                  ),
                  child: SizedBox(
                    height: 260,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Hero(
                            tag: 'cupon_banner_${cupon.id}',
                            child: Image.network(
                              'https://arequipago-ventas.pe/storage/${cupon.imagenBanner!}',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withAlpha((0.25 * 255).toInt()),
                                  Colors.black.withAlpha((0.6 * 255).toInt()),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.3 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
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
                  ),
                ),

              // Contenido en tarjeta redondeada
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Empresa y título
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.local_offer, color: Colors.black54),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cupon.empresa ?? 'Arequipa GO', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(cupon.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Descripción
                          Text(
                            cupon.descripcion ?? 'Sin descripción',
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 20),

                          // Detalles adicionales
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tipo de descuento', style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text(cupon.tipoDescuento),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Válido hasta', style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text(app_date_utils.DateUtils.formatDate(cupon.fechaFin)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Código del cupón
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.code, color: Colors.black54),
                                      const SizedBox(width: 8),
                                      Text(cupon.codigo ?? 'CUPON${cupon.id}'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenImagePage extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  const _FullScreenImagePage({required this.imageUrl, required this.heroTag});

  @override
  State<_FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<_FullScreenImagePage> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset.abs() / 300)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() => _dragOffset += details.delta.dy);
        },
        onVerticalDragEnd: (details) {
          if (_dragOffset.abs() > 100 || details.velocity.pixelsPerSecond.dy.abs() > 600) {
            Navigator.pop(context);
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: Stack(
          children: [
            Center(
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: Hero(
                  tag: widget.heroTag,
                  child: InteractiveViewer(
                    child: Image.network(widget.imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
