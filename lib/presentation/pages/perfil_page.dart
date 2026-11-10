import 'package:arequipagocreditos/presentation/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../components/components.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/model_adapters.dart';
import '../providers/auth_provider.dart';
import '../components/mis_documentos_card.dart';
import '../../data/datasources/documentos_pendientes_remote_datasource.dart';
import 'actualizar_datos_page.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key, this.documentosServicio});

  /// Solo para pruebas: el servicio que consulta y sube los documentos de «Mis documentos».
  final DocumentosPendientesRemoteDataSource? documentosServicio;

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

  Future<void> _changeProfilePicture() async {
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

        // Toda la pantalla es UNA sola lista que se desliza: la cabecera (foto, nombre, DNI) sube junto con el resto, ya no queda
        // fija ocupando media pantalla con un recuadro pequeño para deslizar. La hoja blanca siempre llega hasta abajo
        // (SliverFillRemaining) y el contenido va arriba, no centrado.
        return Scaffold(
          backgroundColor: AppTheme.primary,
          body: RefreshIndicator(
            onRefresh: () => _refrescar(authProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildCabecera(conductor)),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildHoja(authProvider, conductor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Cabecera amarilla: volver + título, y debajo la foto con el nombre y el DNI a su lado (alineados a la izquierda).
  Widget _buildCabecera(conductor) {
    return Container(
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
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 10, 16, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Perfil del Cliente',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileAvatar(
                conductor: conductor,
                isUploadingImage: _isUploadingImage,
                onChangeProfilePicture: _changeProfilePicture,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      conductor?.nombres ?? 'Cargando...',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.35 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        conductor != null ? 'DNI: ${conductor.nroDocumento}' : '',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Hoja blanca con las secciones, de arriba hacia abajo: avisos, foto, información personal, vehículo y cerrar sesión.
  Widget _buildHoja(AuthProvider authProvider, conductor) {
    final abajo = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 20, 16, 28 + abajo),
      child:
          authProvider.isLoading
              ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // TK-0357: datos por actualizar (foto de perfil, DNI, SOAT); sin ellos no puede generar financiamientos.
                  DatosPendientesBanner(
                    pendientes: authProvider.currentUser?.datosPendientes ?? const [],
                    margin: const EdgeInsets.only(bottom: 16),
                    onActualizar: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ActualizarDatosPage()),
                    ),
                  ),
                  _buildEstadoFoto(conductor),
                  const SizedBox(height: 16),
                  // Tarjeta de información personal (Común para todos)
                  PersonalInfoCard(conductor: conductor),
                  const SizedBox(height: 16),
                  // Tarjeta condicional según el tipo
                  if (conductor?.tipo == 4)
                    PreregistroInfoCard(conductor: conductor)
                  else
                    VehiculoInfoCard(conductor: conductor),
                  // Los documentos que su formulario del dashboard también tiene: subirlos o cambiarlos desde aquí (quedan en revisión).
                  MisDocumentosCard(servicio: widget.documentosServicio),
                  const SizedBox(height: 24),
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
                  // Solo pasajeros (tipo 4) pueden solicitar eliminación de cuenta
                  if (conductor?.tipo == 4) ...[
                    const SizedBox(height: 12),
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
                  ],
                ],
              ),
    );
  }

  /// Al deslizar hacia abajo: vuelve a pedir el perfil al servidor y avisa de los documentos del vehículo vencidos o por vencer.
  Future<void> _refrescar(AuthProvider authProvider) async {
    await authProvider.refreshUserDataFromRemote();
    if (!mounted) return;

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
                        builder: (context) => const WelcomePage(),
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

  /// Estado de la foto de perfil en una franja compacta, con el botón al lado (antes era una tarjeta alta con dos recuadros).
  Widget _buildEstadoFoto(conductor) {
    final personalizada = conductor?.fotoPerfilCambiada == true;
    final color = personalizada ? Colors.green : Colors.blue;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(personalizada ? Icons.check_circle : Icons.photo_camera_outlined, color: color.shade600, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  personalizada ? 'Foto personalizada' : 'Personaliza tu foto',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color.shade800),
                ),
                const SizedBox(height: 2),
                Text(
                  personalizada ? 'Ya cambiaste tu foto de perfil.' : 'Toca la cámara de tu foto o usa el botón.',
                  style: TextStyle(fontSize: 12, color: color.shade700, height: 1.25),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _isUploadingImage ? null : _changeProfilePicture,
            style: TextButton.styleFrom(foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(horizontal: 10)),
            child: Text(personalizada ? 'Cambiar' : 'Editar', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (route) => false,
    );
  }
}
