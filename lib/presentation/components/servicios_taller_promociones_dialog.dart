import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/promo_taller_banner_model.dart';
import '../../theme/app_theme.dart';

/// Diálogo flotante con los flyers de promociones (puntos para pasar de uno a otro).
/// Lo usan Servicios de Taller y Comercios GO: cada pantalla le pasa sus propios flyers.
///
/// El recuadro toma la FORMA de cada flyer (horizontal, cuadrado o vertical) en vez de ser siempre 16:9: una imagen que no era 16:9
/// salía con bordes. Con un tope de alto para que un flyer muy vertical no se salga de la pantalla (ahí queda completo, con bordes
/// a los lados).
class ServiciosTallerPromocionesDialog extends StatefulWidget {
  final List<PromoTallerBannerModel> banners;

  const ServiciosTallerPromocionesDialog({super.key, required this.banners});

  /// Proporción (ancho / alto) mientras la imagen todavía no se midió: la de siempre, 16:9.
  static const double proporcionInicial = 16 / 9;

  /// Límites para que un flyer extremo (una tira muy larga o una historia muy alta) no deje un recuadro absurdo.
  static const double proporcionMinima = 0.5;
  static const double proporcionMaxima = 2.4;

  /// Proporción con la que se arma el recuadro: la de la imagen, dentro de los límites.
  static double proporcionAjustada(double? proporcion) {
    if (proporcion == null || proporcion.isNaN || proporcion <= 0) {
      return proporcionInicial;
    }
    return proporcion.clamp(proporcionMinima, proporcionMaxima).toDouble();
  }

  /// Alto del recuadro para un ancho y una proporción, sin pasar de `altoMaximo`.
  static double altoDelRecuadro({
    required double ancho,
    required double proporcion,
    required double altoMaximo,
  }) {
    return math.min(ancho / proporcionAjustada(proporcion), altoMaximo);
  }

  @override
  State<ServiciosTallerPromocionesDialog> createState() =>
      _ServiciosTallerPromocionesDialogState();
}

class _ServiciosTallerPromocionesDialogState
    extends State<ServiciosTallerPromocionesDialog> {
  late final PageController _pageController;
  int _paginaActual = 0;

  /// Proporción medida de cada flyer (por posición), a medida que se van cargando.
  final Map<int, double> _proporciones = {};

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

  void _alMedir(int indice, double proporcion) {
    if (_proporciones[indice] == proporcion) return;
    // Puede avisar mientras Flutter arma la pantalla (imagen que ya estaba en caché): se espera al cuadro siguiente.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _proporciones[indice] = proporcion);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pantalla = MediaQuery.of(context).size;
    final ancho = math.min(460.0, pantalla.width - 36);
    final alto = ServiciosTallerPromocionesDialog.altoDelRecuadro(
      ancho: ancho,
      proporcion: _proporciones[_paginaActual] ??
          ServiciosTallerPromocionesDialog.proporcionInicial,
      altoMaximo: pantalla.height * 0.7,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        width: ancho,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: alto,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.banners.length,
                      onPageChanged: (index) =>
                          setState(() => _paginaActual = index),
                      itemBuilder: (context, index) {
                        final banner = widget.banners[index];
                        // Con caché en disco: si el flyer ya se bajó (el app lo precarga al abrirse) sale al instante, también
                        // en los siguientes arranques. Image.network solo guardaba en memoria y lo bajaba de nuevo cada vez.
                        return CachedNetworkImage(
                          imageUrl: ApiConstants.normalizeUrl(banner.rutaImagen),
                          fit: BoxFit.contain,
                          memCacheWidth: 1400,
                          fadeInDuration: const Duration(milliseconds: 120),
                          imageBuilder: (context, imageProvider) =>
                              MedidorProporcionImagen(
                            imagen: imageProvider,
                            onProporcion: (p) => _alMedir(index, p),
                            child: Image(
                              image: imageProvider,
                              fit: BoxFit.contain,
                            ),
                          ),
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Center(
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

/// Avisa la proporción (ancho / alto) de la imagen en cuanto Flutter la tiene, y muestra `child` sin cambios.
class MedidorProporcionImagen extends StatefulWidget {
  final ImageProvider imagen;
  final ValueChanged<double> onProporcion;
  final Widget child;

  const MedidorProporcionImagen({
    super.key,
    required this.imagen,
    required this.onProporcion,
    required this.child,
  });

  @override
  State<MedidorProporcionImagen> createState() =>
      _MedidorProporcionImagenState();
}

class _MedidorProporcionImagenState extends State<MedidorProporcionImagen> {
  ImageStream? _flujo;
  late final ImageStreamListener _oyente;

  @override
  void initState() {
    super.initState();
    _oyente = ImageStreamListener((info, _) {
      final ancho = info.image.width;
      final alto = info.image.height;
      if (ancho > 0 && alto > 0) widget.onProporcion(ancho / alto);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _flujo?.removeListener(_oyente);
    _flujo = widget.imagen.resolve(createLocalImageConfiguration(context))
      ..addListener(_oyente);
  }

  @override
  void dispose() {
    _flujo?.removeListener(_oyente);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
