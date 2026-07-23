import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class PreRegisterPage extends StatefulWidget {
  const PreRegisterPage({super.key});

  @override
  State<PreRegisterPage> createState() => _PreRegisterPageState();
}

class _PreRegisterPageState extends State<PreRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 1;
  final int _totalSteps = 3;
  bool _isPickingFile = false;

  // Controllers Step 1
  final _tipoDocController = TextEditingController(text: 'DNI');
  final _nroDocController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();

  // Controllers Step 2
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _ingresoMensualController = TextEditingController();
  final _departamentoController = TextEditingController(text: 'AREQUIPA');
  final _provinciaController = TextEditingController(text: 'AREQUIPA');
  final _distritoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _googleMapsUrlController = TextEditingController();

  // Controllers Step 3
  final _emergenciaNombreController = TextEditingController();
  final _emergenciaTelefonoController = TextEditingController();
  final _emergenciaParentescoController = TextEditingController();

  // Files
  File? _fotoPerfil;
  File? _docSustento;
  File? _docRecibo;
  File? _docBoletas;
  File? _docDni;
  bool _aceptaTerminos = false; // controlled via callback from child widget

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nroDocController.dispose();
    _nombresController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _fechaNacimientoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _ingresoMensualController.dispose();
    _departamentoController.dispose();
    _provinciaController.dispose();
    _distritoController.dispose();
    _direccionController.dispose();
    _googleMapsUrlController.dispose();
    _emergenciaNombreController.dispose();
    _emergenciaTelefonoController.dispose();
    _emergenciaParentescoController.dispose();
    super.dispose();
  }

  String? _validateCurrentStep() {
    bool empty(TextEditingController c) => c.text.trim().isEmpty;

    switch (_currentStep) {
      case 1:
        if (Platform.isAndroid && empty(_nroDocController)) return 'Ingresa tu DNI o número de documento';
        if (empty(_nombresController))         return 'Ingresa tus nombres completos';
        if (empty(_apellidoPaternoController)) return 'Ingresa tu apellido paterno';
        if (empty(_apellidoMaternoController)) return 'Ingresa tu apellido materno';
        if (empty(_fechaNacimientoController)) return 'Selecciona tu fecha de nacimiento';
        return null;
      case 2:
        if (empty(_telefonoController))       return 'Ingresa tu teléfono';
        if (empty(_correoController))         return 'Ingresa tu correo electrónico';
        if (empty(_ingresoMensualController)) return 'Ingresa tu ingreso neto aproximado';
        if (empty(_distritoController))       return 'Ingresa tu distrito de residencia';
        if (empty(_direccionController))      return 'Ingresa tu dirección exacta';
        if (empty(_googleMapsUrlController))  return 'Ingresa el link de Google Maps de tu dirección';
        final mapsError = _validateGoogleMapsUrl();
        if (mapsError != null) return mapsError;
        return null;
      case 3:
        if (empty(_emergenciaNombreController))    return 'Ingresa el nombre del contacto de emergencia';
        if (empty(_emergenciaTelefonoController))  return 'Ingresa el teléfono del contacto de emergencia';
        if (empty(_emergenciaParentescoController)) return 'Ingresa el parentesco del contacto de emergencia';
        if (Platform.isAndroid) {
          if (_docDni == null)     return 'Adjunta tu DNI o CE';
          if (_docRecibo == null)  return 'Adjunta el recibo de luz o agua';
          if (_docSustento == null) return 'Adjunta el sustento de ingresos';
        }
        if (!_aceptaTerminos) return 'Debes autorizar el tratamiento de datos personales';
        return null;
    }
    return null;
  }

  String? _validateGoogleMapsUrl() {
    final raw = _googleMapsUrlController.text.trim();
    if (raw.isEmpty) return null;

    final match = RegExp(r'https?://\S+').firstMatch(raw);
    if (match != null && match.group(0) != raw) {
      _googleMapsUrlController.text = match.group(0)!;
    }

    final uri = Uri.tryParse(_googleMapsUrlController.text.trim());
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return 'El link de Google Maps no es válido. Abre Maps, comparte tu ubicación y pega el enlace.';
    }
    return null;
  }

  void _nextStep() {
    final error = _validateCurrentStep();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.black87),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fechaNacimientoController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage(String type) async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (image != null) {
        final file = File(image.path);
        if (file.lengthSync() > AppConstants.maxPhotoSizeInBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El archivo supera el tamaño máximo de 4 MB. Elige uno más liviano.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        setState(() {
          if (type == 'perfil') _fotoPerfil = file;
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  Future<void> _pickFile(String type) async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);

    try {
      // iOS doesn't handle FileType.custom with extensions well for photo library items
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: Platform.isIOS ? FileType.any : FileType.custom,
        allowedExtensions: Platform.isIOS ? null : ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        // On iOS, HEIC/HEIF photos are valid; files without a recognizable
        // extension (iCloud temp paths) are allowed through — the OS picker
        // already restricts what is selectable with FileType.any.
        final dotIndex = path.lastIndexOf('.');
        final ext = dotIndex >= 0 ? path.substring(dotIndex + 1).toLowerCase() : null;
        const allowed = ['jpg', 'jpeg', 'png', 'pdf', 'heic', 'heif'];
        if (ext != null && !allowed.contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Solo se permiten archivos JPG, PNG, PDF o HEIC'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        final file = File(path);
        if (file.lengthSync() > AppConstants.maxImageSizeInBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El archivo supera el tamaño máximo de 5 MB. Elige uno más liviano.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        setState(() {
          if (type == 'sustento') _docSustento = file;
          if (type == 'recibo') _docRecibo = file;
          if (type == 'boletas') _docBoletas = file;
          if (type == 'dni') _docDni = file;
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _submit() async {
    final authProvider = context.read<AuthProvider>();

    final data = {
      'tipo_doc': _tipoDocController.text,
      'nro_documento': _nroDocController.text,
      'nombres': _nombresController.text,
      'apellido_paterno': _apellidoPaternoController.text,
      'apellido_materno': _apellidoMaternoController.text,
      'fecha_nacimiento': _fechaNacimientoController.text,
      'telefono': _telefonoController.text,
      'correo': _correoController.text,
      'ingreso_neto_mensual': _ingresoMensualController.text,
      'departamento': _departamentoController.text,
      'provincia': _provinciaController.text,
      'distrito': _distritoController.text,
      'direccion_detallada': _direccionController.text,
      if (_googleMapsUrlController.text.trim().isNotEmpty)
        'google_maps_url': _googleMapsUrlController.text.trim(),
      'emergencia_nombre': _emergenciaNombreController.text,
      'emergencia_telefono': _emergenciaTelefonoController.text,
      'emergencia_parentesco': _emergenciaParentescoController.text,
    };

    final files = <String, File>{};
    if (_fotoPerfil != null) files['foto_perfil'] = _fotoPerfil!;
    if (_docSustento != null) files['doc_sustento_ingreso'] = _docSustento!;
    if (_docRecibo != null) files['doc_recibo_servicios'] = _docRecibo!;
    if (_docBoletas != null) files['doc_boletas_pago'] = _docBoletas!;
    if (_docDni != null) files['doc_dni_ce'] = _docDni!;

    final response = await authProvider.preRegister(data, files);

    if (response != null && response['success'] == true) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => FadeIn(
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('¡Excelente!', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text(response['message'] ?? 'Su solicitud ha sido enviada.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('ENTENDIDO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }
    } else if (mounted) {
      final msg = authProvider.errorMessage
          ?? (response != null ? (response['message'] ?? response['error']) : null)
          ?? 'Error al enviar la solicitud. Intente nuevamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          color: AppTheme.primary,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.9)],
          ),
        ),
        child: Column(
          children: [
            _buildTopNav(),
            _buildStepperHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: _buildCurrentStepView(),
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.topCenter,
                child: child,
              ),
              child: MediaQuery.of(context).viewInsets.bottom > 0
                  ? const SizedBox.shrink()
                  : _buildBottomButtonsFooter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
            ),
            const Expanded(
              child: Text(
                'Registro de Pasajero',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const SizedBox(width: 48), // Balance for back button
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Padding(
      padding: keyboardOpen
          ? const EdgeInsets.fromLTRB(40, 0, 40, 12)
          : const EdgeInsets.fromLTRB(40, 10, 40, 30),
      child: Column(
        children: [
          if (!keyboardOpen)
          Row(
            children: List.generate(_totalSteps, (index) {
              int stepNum = index + 1;
              bool isActive = stepNum <= _currentStep;
              
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: isActive ? Colors.black : Colors.black12, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$stepNum',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black38,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (index < _totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: stepNum < _currentStep ? Colors.black : Colors.black12,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          if (!keyboardOpen) const SizedBox(height: 16),
          Text(
            _getStepSubtitle(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 1: return 'Información Personal';
      case 2: return 'Contacto y Ubicación';
      case 3: return 'Adjuntar Documentación';
      default: return '';
    }
  }

  Widget _buildCurrentStepView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_currentStep),
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Column(
          children: [
            _buildModernTextField(
              _nroDocController, 
              Platform.isIOS ? 'Nro Documento (Opcional)' : 'DNI / Nro Documento', 
              Icons.badge_outlined, 
              keyboardType: TextInputType.number
            ),
            const SizedBox(height: 20),
            _buildModernTextField(_nombresController, 'Nombres Completos', Icons.person_outline),
            const SizedBox(height: 20),
            _buildModernTextField(_apellidoPaternoController, 'Apellido Paterno', Icons.account_circle_outlined),
            const SizedBox(height: 20),
            _buildModernTextField(_apellidoMaternoController, 'Apellido Materno', Icons.account_circle_outlined),
            const SizedBox(height: 20),
            InkWell(
              onTap: _selectDate,
              child: IgnorePointer(
                child: _buildModernTextField(_fechaNacimientoController, 'Fecha de Nacimiento', Icons.calendar_today_outlined),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            _buildModernTextField(_telefonoController, 'Tu Teléfono', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            _buildModernTextField(_correoController, 'Correo Electrónico', Icons.mail_outline, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildModernTextField(_ingresoMensualController, 'Ingreso Neto Aproximado', Icons.monetization_on_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            _buildModernTextField(_distritoController, 'Distrito de residencia', Icons.map_outlined),
            const SizedBox(height: 20),
            _buildModernTextField(_direccionController, 'Dirección exacta', Icons.home_outlined),
            const SizedBox(height: 20),
            TextFormField(
              controller: _googleMapsUrlController,
              keyboardType: TextInputType.url,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Link Google Maps',
                labelStyle: const TextStyle(color: Colors.black45),
                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.black87, size: 22),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.black54),
                  tooltip: 'Abrir Google Maps',
                  onPressed: () async {
                    try {
                      final Uri uri = Platform.isIOS
                          ? Uri.parse('comgooglemaps://')
                          : Uri.parse('geo:0,0');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (_) {
                      try {
                        await launchUrl(
                          Uri.parse('https://www.google.com/maps/search/'),
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo abrir Google Maps')),
                          );
                        }
                      }
                    }
                  },
                ),
                helperText: 'Abre Maps, busca tu dirección, comparte y pega el enlace aquí',
                helperStyle: const TextStyle(fontSize: 11, color: Colors.black45),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
              ),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Contacto de Emergencia'),
            const SizedBox(height: 12),
            _buildModernTextField(_emergenciaNombreController, 'Nombre completo', Icons.contact_emergency_outlined),
            const SizedBox(height: 16),
            _buildModernTextField(_emergenciaTelefonoController, 'Teléfono', Icons.phone_callback_outlined),
            const SizedBox(height: 16),
            _buildModernTextField(_emergenciaParentescoController, 'Parentesco', Icons.family_restroom_outlined),
            const SizedBox(height: 30),
            _buildSectionTitle('Carga de Documentación'),
            const Text('Formatos admitidos: JPG, PNG o PDF', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildModernFileTile(
              Platform.isIOS ? 'Foto de Perfil (Opcional)' : 'Foto de Perfil (Rostro claro)', 
              _fotoPerfil, 
              () => _pickImage('perfil')
            ),
            _buildModernFileTile(
              Platform.isIOS ? 'DNI o CE (Opcional)' : 'DNI o CE (Ambos lados)', 
              _docDni, 
              () => _pickFile('dni')
            ),
            _buildModernFileTile(
              Platform.isIOS ? 'Recibo de Luz/Agua (Opcional)' : 'Recibo de Luz o Agua', 
              _docRecibo, 
              () => _pickFile('recibo')
            ),
            _buildModernFileTile(
              Platform.isIOS ? 'Sustento de Ingresos (Opcional)' : 'Sustento de Ingresos', 
              _docSustento, 
              () => _pickFile('sustento')
            ),
            _buildModernFileTile('Boletas de Pago (Opcional)', _docBoletas, () => _pickFile('boletas')),
            const SizedBox(height: 20),
            _buildPrivacyTerms(),
          ],
        );
      default:
        return const SizedBox();
    }
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45),
        prefixIcon: Icon(icon, color: Colors.black87, size: 22),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildModernFileTile(String label, File? file, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: file != null ? Colors.green.withValues(alpha: 0.05) : Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: file != null ? Colors.green : Colors.grey[200]!, 
              width: 1
            ),
          ),
          child: Row(
            children: [
              Icon(
                file != null ? Icons.check_circle : Icons.cloud_upload_outlined, 
                color: file != null ? Colors.green : Colors.black45,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (file != null)
                      Text(
                        file.path.split('/').last, 
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyTerms() {
    return PrivacyTermsCheckbox(
      onChanged: (val) {
        // Solo actualizamos la variable sin llamar a setState del padre
        _aceptaTerminos = val;
      },
    );
  }

  Widget _buildBottomButtonsFooter() {
    final authProvider = context.watch<AuthProvider>();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 55,
              child: TextButton(
                onPressed: _prevStep,
                child: Text(
                  _currentStep == 1 ? 'CANCELAR' : 'ATRÁS', 
                  style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: authProvider.isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _currentStep == _totalSteps ? 'ENVIAR SOLICITUD' : 'SIGUIENTE',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// Widget aislado para el checkbox de política de privacidad.
// Al tener su propio State, su setState no afecta al padre.
class PrivacyTermsCheckbox extends StatefulWidget {
  final ValueChanged<bool> onChanged;

  const PrivacyTermsCheckbox({super.key, required this.onChanged});

  @override
  State<PrivacyTermsCheckbox> createState() => _PrivacyTermsCheckboxState();
}

class _PrivacyTermsCheckboxState extends State<PrivacyTermsCheckbox> {
  bool _checked = false;

  void _toggle(bool? val) {
    setState(() => _checked = val ?? !_checked);
    widget.onChanged(_checked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF176).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFDD835).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: _checked,
              onChanged: _toggle,
              activeColor: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggle(!_checked),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                  children: [
                    const TextSpan(
                      text: 'Autorizo el tratamiento de datos personales para finalidades acorde a la prestación del servicio, conforme al siguiente enlace: ',
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: InkWell(
                        onTap: () async {
                          final url = Uri.parse(ApiConstants.politicaPrivacidadUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text(
                          'Política de Privacidad',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
