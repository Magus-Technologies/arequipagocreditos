import 'package:arequipagocreditos/components/components.dart';
import 'package:arequipagocreditos/models/conductor_model.dart';
import 'package:arequipagocreditos/screen/login_screen.dart';
import 'package:arequipagocreditos/services/api_service.dart';
import 'package:arequipagocreditos/helpers/image_picker_helper.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _isLoading = false;
  bool _isUploadingImage = false;
  Conductor? _conductor;

  @override
  void initState() {
    super.initState();
    _loadConductor();
  }

  Future<void> _loadConductor() async {
    try {
      // Intentar obtener datos frescos del servidor
      Conductor? conductor = await ApiService.refreshUserData();
      
      setState(() {
        _conductor = conductor;
      });
    } catch (e) {
      // Si falla, usar datos del cache
      Conductor? conductor = await ApiService.getLoggedUser();
      setState(() {
        _conductor = conductor;
      });
    }
  }

  Future<void> _changeProfilePicture() async {
    if (_conductor?.fotoPerfilCambiada == true) {
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
      onSuccess: _loadConductor,
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
      onSuccess: _loadConductor,
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
                        // Container(
                        //   decoration: BoxDecoration(
                        //     color: Colors.white.withAlpha((0.3 * 255).toInt()),
                        //     borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   child: IconButton(
                        //     icon: const Icon(
                        //       Icons.settings,
                        //       color: Colors.black87,
                        //       size: 20,
                        //     ),
                        //     onPressed: () {
                        //       // Funcionalidad de configuración
                        //     },
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Avatar en el header
                    ProfileAvatar(
                      conductor: _conductor,
                      isUploadingImage: _isUploadingImage,
                      onChangeProfilePicture: _changeProfilePicture,
                    ),
                    const SizedBox(height: 16),
                    // Nombre y DNI en el header
                    Text(
                      _conductor != null ? _conductor!.nombres : 'Cargando...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.3 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _conductor != null ? 'DNI: ${_conductor!.nroDocumento}' : '',
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
                      child: _buildContent(),
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Estado de la foto de perfil
          _buildProfileStatusCard(),
          const SizedBox(height: 20),
          // Tarjeta de información personal
          PersonalInfoCard(conductor: _conductor),
          const SizedBox(height: 20),
          // Opciones adicionales
          // _buildOptionsCard(),
          // const SizedBox(height: 30),
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
              isLoading: _isLoading,
              onPressed: () => _logout(context),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileStatusCard() {
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
          if (_conductor?.fotoPerfilCambiada == true)
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

  // Widget _buildOptionsCard() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.08),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(
  //               Icons.tune,
  //               color: AppTheme.primary,
  //               size: 20,
  //             ),
  //             const SizedBox(width: 8),
  //             Text(
  //               'Opciones',
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.grey.shade800,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         _buildOptionItem(
  //           icon: Icons.privacy_tip_outlined,
  //           title: 'Privacidad',
  //           subtitle: 'Configurar opciones de privacidad',
  //           onTap: () {
  //             // Navegar a configuración de privacidad
  //           },
  //         ),
  //         _buildDivider(),
  //         _buildOptionItem(
  //           icon: Icons.notifications_outlined,
  //           title: 'Notificaciones',
  //           subtitle: 'Configurar notificaciones',
  //           onTap: () {
  //             // Navegar a configuración de notificaciones
  //           },
  //         ),
  //         _buildDivider(),
  //         _buildOptionItem(
  //           icon: Icons.help_outline,
  //           title: 'Ayuda',
  //           subtitle: 'Centro de ayuda y soporte',
  //           onTap: () {
  //             // Navegar a ayuda
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _logout(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    await ApiService.logout();

    setState(() {
      _isLoading = false;
    });
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}
