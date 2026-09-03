import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/catalogos_provider.dart';
import 'conductor_register_success_page.dart';
import 'pre_register_page.dart';

class ConductorRegisterPage extends StatefulWidget {
  const ConductorRegisterPage({super.key});

  @override
  State<ConductorRegisterPage> createState() => _ConductorRegisterPageState();
}

class _ConductorRegisterPageState extends State<ConductorRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 1;
  final int _totalSteps = 5;
  bool _isPickingFile = false;

  static const List<String> _categoriasLicencia = [
    'A-I', 'A-IIa', 'A-IIb', 'A-IIIa', 'A-IIIb', 'A-IIIc',
    'B-I', 'B-IIa', 'B-IIb', 'B-IIc',
  ];
  static const List<String> _tiposVehiculo = ['Auto', 'Moto', 'Tuk-tuk', 'Otro'];

  // Controllers Step 1
  final _tipoDocController = TextEditingController(text: 'DNI');
  final _nroDocController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _nroLicenciaController = TextEditingController();
  String? _categoriaLicencia;
  String? _plataforma;

  // Controllers Step 2
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _googleMapsUrlController = TextEditingController();
  String? _departamentoCodigo;
  String? _departamentoNombre;
  String? _provinciaCodigo;
  String? _provinciaNombre;
  String? _distritoCodigo;
  String? _distritoNombre;

  // Controllers Step 3
  String? _tipoVehiculo;
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _colorController = TextEditingController();

  // Step 4
  File? _docIdentidadAnverso;
  File? _docIdentidadReverso;
  File? _licenciaAnverso;
  File? _licenciaReverso;
  File? _fotoPerfil;
  // El pago de inscripción solo se registra al contado (ver
  // "Modalidad de pago de inscripción" más abajo) — no se ofrece la opción
  // de financiarlo, por eso queda fijo en 'contado' en vez de null.
  String? _modalidadPago = 'contado';
  bool _aceptaTerminos = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalogos = context.read<CatalogosProvider>();
      catalogos.loadDepartamentos();
      catalogos.loadPlataformas();
    });
  }

  @override
  void dispose() {
    _tipoDocController.dispose();
    _nroDocController.dispose();
    _nombresController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _fechaNacimientoController.dispose();
    _nroLicenciaController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    _googleMapsUrlController.dispose();
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  String? _validateCurrentStep() {
    bool empty(TextEditingController c) => c.text.trim().isEmpty;

    switch (_currentStep) {
      case 1:
        if (empty(_nroDocController))          return 'Ingresa tu DNI o número de documento';
        if (empty(_nombresController))         return 'Ingresa tus nombres completos';
        if (empty(_apellidoPaternoController)) return 'Ingresa tu apellido paterno';
        if (empty(_fechaNacimientoController)) return 'Selecciona tu fecha de nacimiento';
        final fecha = DateTime.tryParse(_fechaNacimientoController.text.trim());
        if (fecha == null || DateTime.now().difference(fecha).inDays < 365 * 18) {
          return 'Debes ser mayor de 18 años';
        }
        if (empty(_nroLicenciaController))     return 'Ingresa tu número de licencia';
        if (_categoriaLicencia == null)        return 'Selecciona la categoría de tu licencia';
        return null;
      case 2:
        if (_plataforma == null) return 'Selecciona la plataforma con la que trabajas';
        return null;
      case 3:
        if (!RegExp(r'^\d{9}$').hasMatch(_telefonoController.text.trim())) {
          return 'Ingresa un teléfono válido de 9 dígitos';
        }
        final correo = _correoController.text.trim();
        if (correo.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
          return 'Ingresa un correo electrónico válido';
        }
        if (_departamentoCodigo == null) return 'Selecciona tu departamento';
        if (_provinciaCodigo == null)    return 'Selecciona tu provincia';
        if (_distritoCodigo == null)     return 'Selecciona tu distrito';
        if (empty(_direccionController)) return 'Ingresa tu dirección exacta';
        final mapsError = _validateGoogleMapsUrl();
        if (mapsError != null) return mapsError;
        return null;
      case 4:
        if (!empty(_placaController)) {
          if (_tipoVehiculo == null || empty(_marcaController) || empty(_modeloController)) {
            return 'Completa los datos del vehículo (tipo, marca y modelo)';
          }
        }
        final anioText = _anioController.text.trim();
        if (anioText.isNotEmpty) {
          final anio = int.tryParse(anioText);
          if (anio == null || anio < 1990 || anio > 2027) {
            return 'Ingresa un año de vehículo válido (1990-2027)';
          }
        }
        return null;
      case 5:
        if (_docIdentidadAnverso == null) return 'Adjunta el anverso de tu DNI';
        if (_docIdentidadReverso == null) return 'Adjunta el reverso de tu DNI';
        if (_licenciaAnverso == null)     return 'Adjunta el anverso de tu licencia de conducir';
        if (_licenciaReverso == null)     return 'Adjunta el reverso de tu licencia de conducir';
        if (_modalidadPago == null)       return 'Selecciona la modalidad de pago de inscripción';
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
    final maxDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: DateTime(1900),
      lastDate: maxDate,
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
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: Platform.isIOS ? FileType.any : FileType.custom,
        allowedExtensions: Platform.isIOS ? null : ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
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
          if (type == 'dni_anverso') _docIdentidadAnverso = file;
          if (type == 'dni_reverso') _docIdentidadReverso = file;
          if (type == 'licencia_anverso') _licenciaAnverso = file;
          if (type == 'licencia_reverso') _licenciaReverso = file;
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _submit() async {
    final authProvider = context.read<AuthProvider>();

    final vehiculo = <String, String>{};
    if (_tipoVehiculo != null) vehiculo['tipo_vehiculo'] = _tipoVehiculo!;
    if (_placaController.text.trim().isNotEmpty) vehiculo['placa'] = _placaController.text.trim();
    if (_marcaController.text.trim().isNotEmpty) vehiculo['marca'] = _marcaController.text.trim();
    if (_modeloController.text.trim().isNotEmpty) vehiculo['modelo'] = _modeloController.text.trim();
    if (_anioController.text.trim().isNotEmpty) vehiculo['anio'] = _anioController.text.trim();
    if (_colorController.text.trim().isNotEmpty) vehiculo['color'] = _colorController.text.trim();

    final data = {
      'tipo_doc': _tipoDocController.text,
      'nro_documento': _nroDocController.text.trim(),
      'nombres': _nombresController.text.trim(),
      'apellido_paterno': _apellidoPaternoController.text.trim(),
      'apellido_materno': _apellidoMaternoController.text.trim(),
      'fecha_nacimiento': _fechaNacimientoController.text.trim(),
      'nro_licencia': _nroLicenciaController.text.trim(),
      'categoria_licencia': _categoriaLicencia,
      'plataforma': _plataforma,
      'telefono': _telefonoController.text.trim(),
      'correo': _correoController.text.trim(),
      'departamento': _departamentoNombre,
      'provincia': _provinciaNombre,
      'distrito': _distritoNombre,
      'direccion_detallada': _direccionController.text.trim(),
      if (_googleMapsUrlController.text.trim().isNotEmpty)
        'google_maps_url': _googleMapsUrlController.text.trim(),
      'modalidad_pago_inscripcion': _modalidadPago,
      if (vehiculo.isNotEmpty) 'vehiculo': jsonEncode(vehiculo),
    };

    final files = <String, File>{};
    if (_docIdentidadAnverso != null) files['doc_identidad_anverso'] = _docIdentidadAnverso!;
    if (_docIdentidadReverso != null) files['doc_identidad_reverso'] = _docIdentidadReverso!;
    if (_licenciaAnverso != null) files['licencia'] = _licenciaAnverso!;
    if (_licenciaReverso != null) files['licencia_reverso'] = _licenciaReverso!;
    if (_fotoPerfil != null) files['foto_perfil'] = _fotoPerfil!;

    final response = await authProvider.conductorPreRegister(data, files);

    if (response != null && response['success'] == true) {
      final responseData = response['data'];
      final int? conductorId = responseData is Map
          ? int.tryParse('${responseData['id']}')
          : null;

      if (conductorId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(AppConstants.conductorPreRegistroIdKey, conductorId);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConductorRegisterSuccessPage(conductorId: conductorId),
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
                'Registro de Conductor',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const SizedBox(width: 48),
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
      case 2: return 'Plataforma en la que trabajas';
      case 3: return 'Contacto y Ubicación';
      case 4: return 'Vehículo (Opcional)';
      case 5: return 'Adjuntar Documentación';
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
    final catalogos = context.watch<CatalogosProvider>();
    switch (_currentStep) {
      case 1:
        return Column(
          children: [
            _buildModernTextField(
              _nroDocController,
              'DNI / Nro Documento',
              Icons.badge_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _buildModernTextField(_nombresController, 'Nombres Completos', Icons.person_outline),
            const SizedBox(height: 20),
            _buildModernTextField(_apellidoPaternoController, 'Apellido Paterno', Icons.account_circle_outlined),
            const SizedBox(height: 20),
            _buildModernTextField(_apellidoMaternoController, 'Apellido Materno (Opcional)', Icons.account_circle_outlined),
            const SizedBox(height: 20),
            InkWell(
              onTap: _selectDate,
              child: IgnorePointer(
                child: _buildModernTextField(_fechaNacimientoController, 'Fecha de Nacimiento', Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 20),
            _buildModernTextField(_nroLicenciaController, 'Número de Licencia', Icons.card_membership_outlined),
            const SizedBox(height: 20),
            _buildModernDropdown(
              value: _categoriaLicencia,
              label: 'Categoría de Licencia',
              icon: Icons.workspace_premium_outlined,
              items: _categoriasLicencia,
              onChanged: (val) => setState(() => _categoriaLicencia = val),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona la plataforma en la que trabajas:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildPlataformaCards(catalogos),
          ],
        );
      case 3:
        return Column(
          children: [
            _buildModernTextField(_telefonoController, 'Tu Teléfono', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            _buildModernTextField(_correoController, 'Correo Electrónico (Opcional)', Icons.mail_outline, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildCatalogoDropdown(
              label: 'Departamento',
              icon: Icons.public_outlined,
              value: _departamentoCodigo,
              items: catalogos.departamentos
                  .map((d) => DropdownMenuItem(value: d.codigo, child: Text(d.nombre)))
                  .toList(),
              loading: catalogos.departamentosLoading,
              error: catalogos.departamentosError,
              onRetry: () => catalogos.loadDepartamentos(),
              onChanged: (val) {
                if (val == null) return;
                final item = catalogos.departamentos.firstWhere((d) => d.codigo == val);
                setState(() {
                  _departamentoCodigo = val;
                  _departamentoNombre = item.nombre;
                  _provinciaCodigo = null;
                  _provinciaNombre = null;
                  _distritoCodigo = null;
                  _distritoNombre = null;
                });
                catalogos.clearDistritos();
                catalogos.loadProvincias(val);
              },
            ),
            const SizedBox(height: 20),
            _buildCatalogoDropdown(
              label: 'Provincia',
              icon: Icons.location_city_outlined,
              value: _provinciaCodigo,
              items: catalogos.provincias
                  .map((p) => DropdownMenuItem(value: p.codigo, child: Text(p.nombre)))
                  .toList(),
              loading: catalogos.provinciasLoading,
              error: catalogos.provinciasError,
              onRetry: () {
                if (_departamentoCodigo != null) catalogos.loadProvincias(_departamentoCodigo!);
              },
              placeholder: _departamentoCodigo == null ? 'Selecciona primero el departamento' : null,
              onChanged: (val) {
                if (val == null) return;
                final item = catalogos.provincias.firstWhere((p) => p.codigo == val);
                setState(() {
                  _provinciaCodigo = val;
                  _provinciaNombre = item.nombre;
                  _distritoCodigo = null;
                  _distritoNombre = null;
                });
                catalogos.loadDistritos(val);
              },
            ),
            const SizedBox(height: 20),
            _buildCatalogoDropdown(
              label: 'Distrito',
              icon: Icons.map_outlined,
              value: _distritoCodigo,
              items: catalogos.distritos
                  .map((d) => DropdownMenuItem(value: d.codigo, child: Text(d.nombre)))
                  .toList(),
              loading: catalogos.distritosLoading,
              error: catalogos.distritosError,
              onRetry: () {
                if (_provinciaCodigo != null) catalogos.loadDistritos(_provinciaCodigo!);
              },
              placeholder: _provinciaCodigo == null ? 'Selecciona primero la provincia' : null,
              onChanged: (val) {
                if (val == null) return;
                final item = catalogos.distritos.firstWhere((d) => d.codigo == val);
                setState(() {
                  _distritoCodigo = val;
                  _distritoNombre = item.nombre;
                });
              },
            ),
            const SizedBox(height: 20),
            _buildModernTextField(_direccionController, 'Dirección exacta', Icons.home_outlined),
            const SizedBox(height: 20),
            _buildModernTextField(
              _googleMapsUrlController,
              'Link Google Maps (Opcional)',
              Icons.location_on_outlined,
              keyboardType: TextInputType.url,
              helperText: 'Abre Maps, busca tu dirección, comparte y pega el enlace aquí',
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoNote('Si tienes vehículo, regístralo aquí. Esto define tu tarifa de inscripción.'),
            const SizedBox(height: 20),
            _buildModernDropdown(
              value: _tipoVehiculo,
              label: 'Tipo de Vehículo',
              icon: Icons.directions_car_outlined,
              items: _tiposVehiculo,
              onChanged: (val) => setState(() => _tipoVehiculo = val),
            ),
            const SizedBox(height: 20),
            _buildModernTextField(_placaController, 'Placa', Icons.pin_outlined),
            const SizedBox(height: 20),
            _buildModernTextField(_marcaController, 'Marca', Icons.branding_watermark_outlined),
            const SizedBox(height: 20),
            _buildModernTextField(_modeloController, 'Modelo', Icons.commute_outlined),
            const SizedBox(height: 20),
            _buildModernTextField(_anioController, 'Año', Icons.event_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            _buildModernTextField(_colorController, 'Color', Icons.palette_outlined),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Carga de Documentación'),
            const Text('Formatos admitidos: JPG, PNG o PDF', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildModernFileTile('DNI (Anverso)', _docIdentidadAnverso, () => _pickFile('dni_anverso')),
            _buildModernFileTile('DNI (Reverso)', _docIdentidadReverso, () => _pickFile('dni_reverso')),
            _buildModernFileTile('Licencia de Conducir (Anverso)', _licenciaAnverso, () => _pickFile('licencia_anverso')),
            _buildModernFileTile('Licencia de Conducir (Reverso)', _licenciaReverso, () => _pickFile('licencia_reverso')),
            _buildModernFileTile('Foto de Perfil (Opcional)', _fotoPerfil, () => _pickImage('perfil')),
            const SizedBox(height: 20),
            _buildSectionTitle('Modalidad de pago de inscripción'),
            const SizedBox(height: 12),
            _buildModalidadCard(
              'contado',
              'Al contado',
              'Un solo pago con código en agentes Caja Arequipa',
              Icons.payments_outlined,
            ),
            const SizedBox(height: 20),
            _buildInfoNote('Tu solicitud será revisada. Una vez aprobada, recibirás tu código de pago de Caja Arequipa.'),
            const SizedBox(height: 20),
            PrivacyTermsCheckbox(
              onChanged: (val) {
                _aceptaTerminos = val;
              },
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildInfoNote(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlataformaCards(CatalogosProvider catalogos) {
    if (catalogos.plataformasLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          children: [
            Icon(Icons.smartphone_outlined, color: Colors.black87, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cargando plataformas...',
                style: TextStyle(fontSize: 15, color: Colors.black45),
              ),
            ),
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black45),
            ),
          ],
        ),
      );
    }
    if (catalogos.plataformasError != null) {
      return InkWell(
        onTap: () => catalogos.loadPlataformas(),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.refresh, color: Colors.red.shade400, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error al cargar las plataformas. Toca para reintentar',
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: catalogos.plataformas.map((p) {
        final bool selected = _plataforma == p.plataforma;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _plataforma = p.plataforma),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? Colors.black.withValues(alpha: 0.04) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? Colors.black : Colors.grey[300]!,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  _buildPlataformaLogo(p.logo, p.nombrePlataforma),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      p.nombrePlataforma.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selected ? Colors.black : Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlataformaLogo(String? logo, String nombre) {
    final String inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    final Widget fallback = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          inicial,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54),
        ),
      ),
    );

    if (logo == null || logo.isEmpty) return fallback;

    final url = ApiConstants.normalizeUrl(logo);
    final isSvg = url.toLowerCase().endsWith('.svg');

    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: isSvg
          ? SvgPicture.network(
              url,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => const SizedBox.shrink(),
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  inicial,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54),
                ),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  inicial,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54),
                ),
              ),
            ),
    );
  }

  Widget _buildModalidadCard(String value, String title, String subtitle, IconData icon) {
    final bool selected = _modalidadPago == value;
    return InkWell(
      onTap: () => setState(() => _modalidadPago = value),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Colors.black.withValues(alpha: 0.04) : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey[200]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.black : Colors.black45),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? Colors.black : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, String? helperText}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45),
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 11, color: Colors.black45),
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

  Widget _buildCatalogoDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required bool loading,
    required String? error,
    required VoidCallback onRetry,
    required ValueChanged<String?> onChanged,
    String? placeholder,
  }) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cargando...',
                style: const TextStyle(fontSize: 15, color: Colors.black45),
              ),
            ),
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black45),
            ),
          ],
        ),
      );
    }
    if (error != null) {
      return InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.refresh, color: Colors.red.shade400, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error al cargar $label. Toca para reintentar',
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (placeholder != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black26, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                placeholder,
                style: const TextStyle(fontSize: 14, color: Colors.black38),
              ),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      items: items,
      isExpanded: true,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
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

  Widget _buildModernDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
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
              width: 1,
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
                    style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold),
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
