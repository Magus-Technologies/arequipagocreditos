import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  final ConductorModel? conductor;
  final bool isUploadingImage;
  final VoidCallback onChangeProfilePicture;

  const ProfileAvatar({
    super.key,
    required this.conductor,
    required this.isUploadingImage,
    required this.onChangeProfilePicture,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Círculo de fondo con degradado
        Container(
          width: 88,
          height: 88,
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
        // Avatar con imagen
        CircleAvatar(
          radius: 42,
          backgroundColor: Colors.transparent,
          child: conductor?.fotoPerfil != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(42),
                  child: CachedNetworkImage(
                    imageUrl: conductor!.fotoPerfil!,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(42),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(42),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(42),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
        ),
        // Botón de cámara mejorado
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
                    ? const Padding(
                        padding: EdgeInsets.all(8),
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
}
