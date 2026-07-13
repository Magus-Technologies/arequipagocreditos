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
    // Refrescar datos desde el servidor para garantizar tener toda la info de pasajeros/vehiculos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUserDataFromRemote();
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
      onSuccess: () => context.read<AuthProvider>().refreshUserDataSilently(),
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      },
      context: context,
    );
  }

  void _handleFilePickerSelection() {
    ImagePickerHelper.pickImageWithFilePicker(
      setLoading: (loading) => setState(() => _isUploadingImage = loading),
      onSuccess: () => context.read<AuthProvider>().refreshUserDataSilently(),
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
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
        final conductor =
            conductorEntity != null
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
                                color: Colors.white.withAlpha(
                                  (0.3 * 255).toInt(),
                                ),
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
                            const SizedBox(
                              width: 48,
                            ), // Para balancear el AppBar
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Avatar en el header
                        ProfileAvatar(
                          conductor: conductor,
                          isUploadingImage: _isUploadingImage,
                          onChangeProfilePicture:
                              () => _changeProfilePicture(
                                conductor?.fotoPerfilCambiada ?? false,
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
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            conductor != null
                                ? 'DNI: ${conductor.nroDocumento}'
                                : '',
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
                          decoration: const BoxDecoration(color: Colors.white),
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
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await authProvider.refreshUserDataFromRemote();
        if (!context.mounted) return;

        // Try to read server-provided alerts first
        final server = await authProvider.getServerDocumentAlerts();
        List<String> expired = server['expired'] ?? [];
        List<String> near = server['near'] ?? [];

        // Fallback to client-side calculations if backend doesn't provide alerts
        if ((expired.isEmpty) && (near.isEmpty)) {
          expired = authProvider.getExpiredVehicleDocuments();
          near = authProvider.getNearExpiryVehicleDocuments(7);
        }

        if (expired.isNotEmpty || near.isNotEmpty) {
          final parts = <String>[];
          if (expired.isNotEmpty) parts.add('Vencidos: ${expired.join(', ')}');
          if (near.isNotEmpty) {
            parts.add('A vencer en los próximos 7 días: ${near.join(', ')}');
          }
          if (!mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder:
                (context) => AlertDialog(
                  title: const Text('Aviso de documentos'),
                  content: Text(parts.join('\n')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Estado de la foto de perfil
            _buildProfileStatusCard(conductor),
            const SizedBox(height: 20),
            // Tarjeta de información personal (Común para todos)
            PersonalInfoCard(conductor: conductor),
            const SizedBox(height: 10),

            // Tarjeta condicional según el tipo
            if (conductor?.tipo == 4)
              PreregistroInfoCard(conductor: conductor)
            else
              VehiculoInfoCard(conductor: conductor),

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
            // Solo pasajeros (tipo 4) pueden solicitar eliminación de cuenta
            if (conductor?.tipo == 4)
              TextButton(
                onPressed: () => _showDeleteAccountDialog(context),
                child: const Text(
                  "Eliminar Cuenta",
                  style: TextStyle(
                    color: Colors.red,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('¿Eliminar tu cuenta?'),
            content: const Text(
              'Esta acción solicitará la eliminación permanente de tus datos y acceso a la plataforma. Tu sesión se cerrará de inmediato.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext); // Cerrar el diálogo

                  // Mostrar indicador de carga en la página
                  final authProvider = context.read<AuthProvider>();
                  final success = await authProvider.deleteAccount();

                  if (!context.mounted) return;

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Solicitud de eliminación procesada con éxito.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Navegar al inicio después de un breve momento
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthBottomNav(),
                      ),
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          authProvider.errorMessage ??
                              'Error al procesar la solicitud',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'SOLICITAR ELIMINACIÓN',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
              Icon(Icons.photo_camera, color: AppTheme.primary, size: 20),
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
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
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
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
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
