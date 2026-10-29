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
import '../../data/models/izipay_models.dart';
import '../../theme/app_theme.dart';
import '../components/catalogo_dropdown.dart';
import '../components/pago_inscripcion_registro.dart';
import '../providers/auth_provider.dart';
import '../providers/catalogos_provider.dart';

class PreRegisterPage extends StatefulWidget {
  const PreRegisterPage({super.key});

  @override
  State<PreRegisterPage> createState() => _PreRegisterPageState();
}

class _PreRegisterPageState extends State<PreRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 1;
  // 3 pasos mientras la inscripción de pasajeros sea GRATIS (hoy). Si el servidor dice que en su ciudad tiene precio, se suma un
  // 4.º paso de pago antes de enviar; así los campos de pago salen solos cuando se decida cobrar, sin otra versión del app.
  int _totalSteps = 3;
  bool _isPickingFile = false;

  // Costo de la inscripción (se consulta al llegar al paso 3). Solo cobra si el servidor responde que el monto es de pasajeros.
  InscripcionPagoInfoModel? _pagoInfo;
  bool _costoComprobado = false;
  bool _comprobandoCosto = false;
  String? _costoError;
  Future<void>? _costoFuture;
  String? _metodoPago;
  File? _capturaPago;
  final _operacionController = TextEditingController();

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
  // Ubicación: se ELIGE de los catálogos (departamento → provincia → distrito) como en el registro de conductores. Antes quedaba
  // fija en «AREQUIPA» para todos y, con precios por ciudad, un pasajero de Lima habría pagado como uno de Arequipa.
  final _departamentoController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _distritoController = TextEditingController();
  String? _departamentoCodigo;
  String? _provinciaCodigo;
  String? _distritoCodigo;
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CatalogosProvider>().loadDepartamentos();
    });
  }

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
    _operacionController.dispose();
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
        if (_departamentoCodigo == null)      return 'Selecciona tu departamento';
        if (_provinciaCodigo == null)         return 'Selecciona tu provincia';
        if (_distritoCodigo == null)          return 'Selecciona tu distrito';
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
          // TK-0414: la foto de perfil es obligatoria al registrarse (en iOS sigue opcional, como el resto de los documentos).
          if (_fotoPerfil == null) return 'Sube tu foto de perfil (rostro claro)';
          if (_docDni == null)     return 'Adjunta tu DNI o CE';
          if (_docRecibo == null)  return 'Adjunta el recibo de luz o agua';
          if (_docSustento == null) return 'Adjunta el sustento de ingresos';
        }
        if (!_aceptaTerminos) return 'Debes autorizar el tratamiento de datos personales';
        return null;
      case 4:
        if (_pagoInfo == null) return _costoError ?? 'No pudimos calcular tu monto de inscripción. Inténtalo de nuevo';
        if (_metodoPago == null) return 'Elige cómo vas a pagar tu inscripción';
        if (_metodoPago == PagoInscripcionRegistro.metodoIzipay && _capturaPago == null) {
          return 'Adjunta la captura de tu pago por IziPay';
        }
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

  void _avisar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _nextStep() async {
    final error = _validateCurrentStep();
    if (error != null) {
      _avisar(error);
      return;
    }

    if (_currentStep == 2) {
      setState(() => _currentStep++);
      // Se averigua ya el costo de la inscripción para saber si habrá un paso de pago; no frena a la persona.
      _comprobarCosto();
      return;
    }

    if (_currentStep == 3) {
      await _comprobarCosto();
      if (!mounted) return;
      if (!_costoComprobado) {
        _avisar(_costoError ?? 'No pudimos comprobar el costo de tu inscripción. Revisa tu conexión e inténtalo de nuevo.');
        return;
      }
      if (_totalSteps > 3) {
        setState(() => _currentStep = 4);
      } else {
        _submit(); // inscripción gratuita: se envía como siempre
      }
      return;
    }

    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  /// Consulta el costo de la inscripción de pasajeros según su ciudad. Si es 0 (hoy), todo sigue igual: 3 pasos y sin pago.
  /// Solo se cobra si el servidor confirma que el monto es el de pasajeros (un servidor anterior respondería el de un conductor).
  Future<void> _comprobarCosto() {
    if (_costoComprobado) return Future.value();
    return _costoFuture ??= _consultarCosto().whenComplete(() => _costoFuture = null);
  }

  Future<void> _consultarCosto() async {
    if (mounted) {
      setState(() {
        _comprobandoCosto = true;
        _costoError = null;
      });
    }
    final departamento = _departamentoController.text.trim();
    try {
      final info = await context.read<CatalogosProvider>().fetchInscripcionPagoInfo(
            tipo: 'pasajero',
            departamento: departamento,
          );
      if (!mounted) return;
      // Si mientras tanto cambió de departamento, esta respuesta ya no vale: se vuelve a consultar al seguir.
      if (departamento != _departamentoController.text.trim()) {
        setState(() => _comprobandoCosto = false);
        return;
      }
      final cobra = info.esCobroDePasajero;
      setState(() {
        _pagoInfo = cobra ? info : null;
        _costoComprobado = true;
        _comprobandoCosto = false;
        _totalSteps = cobra ? 4 : 3;
        if (!cobra || (_metodoPago == PagoInscripcionRegistro.metodoIzipay && !info.izipayDisponible)) {
          _metodoPago = null;
          _capturaPago = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      // No se pudo averiguar el costo (sin señal un instante, un servidor que todavía no lo conoce…): el registro sigue como
      // siempre, sin paso de pago, y NO se bloquea a la persona por una consulta de más. Si en verdad tiene costo, el servidor
      // rechaza el envío con un aviso y se la lleva al paso de pago (ver _llevarAlPagoSiElServidorLoPide).
      setState(() {
        _comprobandoCosto = false;
        _costoComprobado = true;
        _pagoInfo = null;
        _totalSteps = 3;
      });
    }
  }

  /// Frase con la que el servidor avisa que la inscripción tiene costo y falta el pago (PasajeroAppController::preRegistro).
  static const String _avisoCostoDelServidor = 'tiene un costo';

  /// Si el servidor rechazó el envío porque la inscripción tiene costo (la consulta previa no pudo saberlo), se vuelve a consultar
  /// y se lleva a la persona al paso de pago. Devuelve true si la llevó.
  Future<bool> _llevarAlPagoSiElServidorLoPide(String mensaje) async {
    if (!mensaje.contains(_avisoCostoDelServidor)) return false;
    setState(() => _costoComprobado = false);
    await _comprobarCosto();
    if (!mounted || _totalSteps <= 3) return false;
    setState(() => _currentStep = 4);
    _avisar('La inscripción tiene un costo: elige cómo pagarla para enviar tu solicitud.');
    return true;
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
          if (type == 'captura') _capturaPago = file;
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

    // Solo con una inscripción de pago: gratis (hoy) no se manda nada de esto y el registro sale como siempre.
    final pagaAlRegistrarse = _pagoInfo != null && _pagoInfo!.monto > 0 && _metodoPago != null;

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
      if (pagaAlRegistrarse) 'metodo_pago_inscripcion': _metodoPago,
      if (pagaAlRegistrarse &&
          _metodoPago == PagoInscripcionRegistro.metodoIzipay &&
          _operacionController.text.trim().isNotEmpty)
        'numero_operacion': _operacionController.text.trim(),
    };

    final files = <String, File>{};
    if (pagaAlRegistrarse && _metodoPago == PagoInscripcionRegistro.metodoIzipay && _capturaPago != null) {
      files['captura_pago'] = _capturaPago!;
    }
    if (_fotoPerfil != null) files['foto_perfil'] = _fotoPerfil!;
    if (_docSustento != null) files['doc_sustento_ingreso'] = _docSustento!;
    if (_docRecibo != null) files['doc_recibo_servicios'] = _docRecibo!;
    if (_docBoletas != null) files['doc_boletas_pago'] = _docBoletas!;
    if (_docDni != null) files['doc_dni_ce'] = _docDni!;

    final response = await authProvider.preRegister(data, files);

    if (response != null && response['success'] == true) {
      if (mounted) {
        // Con pago al registrarse: el código de Caja (vale 24 h) o la captura de IziPay que se acaban de registrar.
        final responseData = response['data'];
        final inscripcion = responseData is Map && responseData['inscripcion'] is Map
            ? Map<String, dynamic>.from(responseData['inscripcion'] as Map)
            : null;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => FadeIn(
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('¡Excelente!', style: TextStyle(fontWeight: FontWeight.bold)),
              content: _buildExitoContent(response['message'] ?? 'Su solicitud ha sido enviada.', inscripcion),
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
      if (await _llevarAlPagoSiElServidorLoPide(msg.toString())) return;
      if (!mounted) return;
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

  /// Cuerpo del aviso «solicitud enviada». Con una inscripción de pago agrega lo que la persona debe hacer ahora.
  Widget _buildExitoContent(String mensaje, Map<String, dynamic>? inscripcion) {
    if (inscripcion == null) return Text(mensaje);

    final monto = double.tryParse((inscripcion['monto'] ?? '0').toString()) ?? 0;
    final orden = inscripcion['orden_pago'] is Map ? Map<String, dynamic>.from(inscripcion['orden_pago'] as Map) : null;
    final codigo = orden?['codigo']?.toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mensaje),
        const SizedBox(height: 14),
        if (codigo != null && codigo.isNotEmpty) ...[
          const Text('Tu código de pago de inscripción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            key: const Key('exito_codigo_caja'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
            child: Text(
              codigo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paga S/ ${monto.toStringAsFixed(2)} en un agente o agencia de Caja Arequipa con este código. Vale 24 horas.',
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ] else
          Text(
            'Recibimos la captura de tu pago de S/ ${monto.toStringAsFixed(2)}. La validaremos junto con tu solicitud.',
            key: const Key('exito_captura_izipay'),
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
      ],
    );
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
      case 4: return 'Pago de inscripción';
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

  /// Departamento → provincia → distrito, elegidos de los catálogos (igual que el registro de conductores). El departamento decide
  /// el precio de la inscripción cuando lo tenga, así que ya no puede quedar fijo para todos.
  List<Widget> _buildUbicacion() {
    final catalogos = context.watch<CatalogosProvider>();

    return [
      CatalogoDropdown(
        label: 'Departamento',
        icon: Icons.public_outlined,
        value: _departamentoCodigo,
        items: catalogos.departamentos.map((d) => DropdownMenuItem(value: d.codigo, child: Text(d.nombre))).toList(),
        loading: catalogos.departamentosLoading,
        error: catalogos.departamentosError,
        onRetry: () => catalogos.loadDepartamentos(),
        onChanged: (val) {
          if (val == null) return;
          final item = catalogos.departamentos.firstWhere((d) => d.codigo == val);
          setState(() {
            _departamentoCodigo = val;
            _departamentoController.text = item.nombre;
            _provinciaCodigo = null;
            _provinciaController.clear();
            _distritoCodigo = null;
            _distritoController.clear();
            // El costo de la inscripción depende del departamento: se vuelve a consultar al llegar al paso 3.
            _costoComprobado = false;
            _pagoInfo = null;
            _totalSteps = 3;
            _metodoPago = null;
            _capturaPago = null;
          });
          catalogos.clearDistritos();
          catalogos.loadProvincias(val);
        },
      ),
      const SizedBox(height: 20),
      CatalogoDropdown(
        label: 'Provincia',
        icon: Icons.location_city_outlined,
        value: _provinciaCodigo,
        items: catalogos.provincias.map((p) => DropdownMenuItem(value: p.codigo, child: Text(p.nombre))).toList(),
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
            _provinciaController.text = item.nombre;
            _distritoCodigo = null;
            _distritoController.clear();
          });
          catalogos.loadDistritos(val);
        },
      ),
      const SizedBox(height: 20),
      CatalogoDropdown(
        label: 'Distrito',
        icon: Icons.map_outlined,
        value: _distritoCodigo,
        items: catalogos.distritos.map((d) => DropdownMenuItem(value: d.codigo, child: Text(d.nombre))).toList(),
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
            _distritoController.text = item.nombre;
          });
        },
      ),
      const SizedBox(height: 20),
    ];
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
            ..._buildUbicacion(),
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
      case 4:
        // Pago de la inscripción: solo existe si el servidor dijo que en su ciudad tiene precio.
        return PagoInscripcionRegistro(
          info: _pagoInfo,
          cargando: _comprobandoCosto,
          error: _costoError,
          metodo: _metodoPago,
          captura: _capturaPago,
          operacionController: _operacionController,
          onMetodo: (metodo) => setState(() {
            _metodoPago = metodo;
            if (metodo != PagoInscripcionRegistro.metodoIzipay) _capturaPago = null;
          }),
          onElegirCaptura: () => _pickImage('captura'),
          onReintentar: _comprobarCosto,
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
                onPressed: (authProvider.isLoading || _comprobandoCosto) ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: (authProvider.isLoading || _comprobandoCosto)
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
        color: AppTheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
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
