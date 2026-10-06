import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/promo_taller_banner_model.dart';
import '../../theme/app_theme.dart';

class ServiciosTallerPromocionesDialog extends StatefulWidget {
  final List<PromoTallerBannerModel> banners;

  const ServiciosTallerPromocionesDialog({super.key, required this.banners});

  @override
  State<ServiciosTallerPromocionesDialog> createState() =>
      _ServiciosTallerPromocionesDialogState();
}

class _ServiciosTallerPromocionesDialogState
    extends State<ServiciosTallerPromocionesDialog> {
  late final PageController _pageController;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.banners.length,
                      onPageChanged: (index) =>
                          setState(() => _paginaActual = index),
                      itemBuilder: (context, index) {
                        final banner = widget.banners[index];
                        return Image.network(
                          ApiConstants.normalizeUrl(banner.rutaImagen),
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No se pudo cargar este flyer.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: IconButton(
                          tooltip: 'Cerrar promociones',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.banners.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Semantics(
                  liveRegion: true,
                  label:
                      'Flyer ${_paginaActual + 1} de ${widget.banners.length}',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.banners.length, (index) {
                      final seleccionado = index == _paginaActual;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: seleccionado ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: seleccionado
                              ? AppTheme.primary
                              : Colors.white.withAlpha(180),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
