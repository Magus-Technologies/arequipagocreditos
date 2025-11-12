import 'package:arequipagocreditos/presentation/pages/auth_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../components/components.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/model_adapters.dart';
import '../providers/auth_provider.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Refrescar datos del usuario al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  Future<void> _changeProfilePicture(bool fotoPerfilCambiada) async {
    if (fotoPerfilCambiada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ya has cambiado tu foto de perfil anteriormente"),
        ),
      );
      return;
    }

    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return ImagePickerModal(
            onGalleryTap: () {
              Navigator.of(context).pop();
              _handleImagePick(ImageSource.gallery);
            },
            onFileTap: () {
              Navigator.of(context).pop();
              _handleFilePickerSelection();
            },
            onCameraTap: () {
              Navigator.of(context).pop();
              _handleImagePick(ImageSource.camera);
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al abrir selector de imagen")),
        );
      }
    }
  }

  void _handleImagePick(ImageSource source) {
    ImagePickerHelper.pickImage(
      source: source,
      setLoading: (loading) => setState(() => _isUploadingImage = loading),
      onSuccess: () => context.read<AuthProvider>().checkAuthStatus(),
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
      context: context,
    );
  }

  void _handleFilePickerSelection() {
    ImagePickerHelper.pickImageWithFilePicker(
      setLoading: (loading) => setState(() => _isUploadingImage = loading),
      onSuccess: () => context.read<AuthProvider>().checkAuthStatus(),
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final conductorEntity = authProvider.currentUser;
        final conductor = conductorEntity != null 
            ? ModelAdapters.conductorEntityToModel(conductorEntity) 
            : null;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withAlpha((0.8 * 255).toInt()),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header moderno
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // AppBar personalizado
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.3 * 255).toInt()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Perfil del Cliente',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48), // Para balancear el AppBar
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Avatar en el header
                        ProfileAvatar(
                          conductor: conductor,
                          isUploadingImage: _isUploadingImage,
                          onChangeProfilePicture: () => _changeProfilePicture(
                            conductor?.fotoPerfilCambiada ?? false
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Nombre y DNI en el header
                        Text(
                          conductor?.nombres ?? 'Cargando...',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 8
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            conductor != null ? 'DNI: ${conductor.nroDocumento}' : '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Contenido principal
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: _buildContent(authProvider, conductor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(AuthProvider authProvider, conductor) {
    if (authProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Estado de la foto de perfil
          _buildProfileStatusCard(conductor),
          const SizedBox(height: 20),
          // Tarjeta de información personal
          PersonalInfoCard(conductor: conductor),
          const SizedBox(height: 20),
          // Botón de Cerrar Sesión
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withAlpha((0.2 * 255).toInt()),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomButton(
              text: "Cerrar Sesión",
              isLoading: authProvider.isLoading,
              onPressed: () => _logout(context),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileStatusCard(conductor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Estado de la Foto de Perfil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (conductor?.fotoPerfilCambiada == true)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foto personalizada',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Has personalizado tu foto de perfil correctamente',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Puedes personalizar tu foto',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toca el ícono de cámara en tu avatar (solo una vez)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthBottomNav()),
      (route) => false,
    );
  }
}
