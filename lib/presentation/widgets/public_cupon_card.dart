import 'package:flutter/material.dart';
import 'package:arequipagocreditos/data/models/cupon_public_model.dart';

class PublicCuponCard extends StatelessWidget {
  final CuponPublicModel cupon;
  final VoidCallback? onTap;

  const PublicCuponCard({super.key, required this.cupon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cupon.imagenBanner != null && cupon.imagenBanner!.isNotEmpty)
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      'https://arequipago-ventas.pe/storage/${cupon.imagenBanner!}',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey.shade200,
                        height: 120,
                        child: Icon(Icons.image_not_supported, color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cupon.titulo,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cupon.descripcion ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cupon.tipoDescuento != null
                                ? '${cupon.tipoDescuento} ${cupon.valor ?? ''}'
                                : cupon.valorFormated(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _CuponExt on CuponPublicModel {
  String valorFormated() {
    if (valor == null) return '';
    return tipoDescuento == 'porcentaje' ? '${valor!.replaceAll('.00', '')}%': valor!;
  }
}
