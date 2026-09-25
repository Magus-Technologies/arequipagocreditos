import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/presentation/components/image_preview.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  final ConductorModel? conductor;
  final bool isUploadingImage;
  final VoidCallback onChangeProfilePicture;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.conductor,
    required this.isUploadingImage,
    required this.onChangeProfilePicture,
    this.size = 88.0,
  });

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = (size / 2) - 4; // ajuste interno
    final String heroTag = 'profile-avatar-${conductor?.idConductor ?? 'anon'}';
    final String imageUrl = ApiConstants.normalizeUrl(conductor?.fotoPerfil);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Círculo de fondo con degradado
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primary,
                AppTheme.primary.withAlpha((0.7 * 255).toInt()),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha((0.3 * 255).toInt()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        // Avatar con imagen o icono; envuelto en GestureDetector/Hero
        GestureDetector(
          onTap: () {
            if (imageUrl.trim().isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ImagePreview(imageUrl: imageUrl, heroTag: heroTag),
                ),
              );
            } else {
              // Si no hay imagen, abrimos el selector
              onChangeProfilePicture();
            }
          },
          child: Hero(
            tag: heroTag,
            child: Container(
              width: size - 8,
              height: size - 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.04 * 255).toInt()),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl.trim().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: size - 8,
                        height: size - 8,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: size - 8,
                          height: size - 8,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => _fallbackIcon(avatarRadius),
                      )
                    : _fallbackIcon(avatarRadius),
              ),
            ),
          ),
        ),

        // Botón de cámara: siempre disponible, el usuario puede cambiar su
        // foto las veces que quiera (antes se ocultaba tras el primer cambio).
        // Tamaño fijo con InkWell (no IconButton): Material 3 le impone a
        // IconButton un área táctil mínima de 48x48 aunque se le pase
        // `constraints: BoxConstraints()`, por eso antes se veía gigante
        // tapando media foto.
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: isUploadingImage ? null : onChangeProfilePicture,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.15 * 255).toInt()),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUploadingImage
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackIcon(double avatarRadius) {
    return Container(
      width: avatarRadius * 2,
      height: avatarRadius * 2,
      color: Colors.transparent,
      child: Center(
        child: Icon(Icons.person, size: avatarRadius, color: Colors.white),
      ),
    );
  }
}