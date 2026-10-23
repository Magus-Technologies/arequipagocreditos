import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Imagen de un nivel de fidelización (la que ve el conductor en «Mi nivel»).
///
/// TK-0390: los niveles los administra el Director desde el panel. Si el nivel tiene una imagen subida
/// (`imagenUrl`) se usa esa, así un cambio en el panel se ve en el app sin publicar otra versión. Si no,
/// la que trae el app para los niveles de siempre (Pollito, Bronce, Plata, Oro), y para un nivel nuevo sin
/// imagen, una medalla genérica. Si la imagen subida no carga (sin internet), también se usa la local.
class NivelInsignia extends StatelessWidget {
  final String codigo;
  final String? imagenUrl;
  final double tamano;

  const NivelInsignia({
    super.key,
    required this.codigo,
    this.imagenUrl,
    this.tamano = 36,
  });

  /// Imagen incluida en el app para los niveles de siempre; null para los que crea el Director.
  static String? assetPara(String codigo) {
    switch (codigo) {
      case 'pollito':
        return 'images/nivel_pollito.webp';
      case 'bronce':
      case 'plata':
      case 'oro':
        return 'images/nivel_$codigo.svg';
      default:
        return null;
    }
  }

  Widget _local() {
    final asset = assetPara(codigo);
    if (asset == null) {
      return Icon(Icons.workspace_premium_rounded, size: tamano * 0.85, color: const Color(0xFFF59E0B));
    }
    if (asset.endsWith('.svg')) {
      return SvgPicture.asset(asset, width: tamano, height: tamano);
    }
    return Image.asset(asset, width: tamano, height: tamano, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final url = imagenUrl;
    return SizedBox(
      width: tamano,
      height: tamano,
      child: (url == null || url.isEmpty)
          ? _local()
          : Image.network(
              url,
              width: tamano,
              height: tamano,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _local(),
              loadingBuilder: (context, child, progreso) => progreso == null ? child : _local(),
            ),
    );
  }
}
