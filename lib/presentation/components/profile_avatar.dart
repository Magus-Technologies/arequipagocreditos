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
    final String? imageUrl = conductor?.fotoPerfil;

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
            if (imageUrl != null && imageUrl.trim().isNotEmpty) {
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
                child: imageUrl != null && imageUrl.trim().isNotEmpty
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

        // Botón de cámara (si no ha cambiado la foto)
        if (conductor?.fotoPerfilCambiada != true)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: isUploadingImage
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: onChangeProfilePicture,
                      ),
              ),
            ),
          ),

        // Indicador de foto cambiada
        if (conductor?.fotoPerfilCambiada == true)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
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