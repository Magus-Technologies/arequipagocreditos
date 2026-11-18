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
import '../../data/models/izipay_models.dart';
import '../../data/models/verificacion_registro_model.dart';
import '../../theme/app_theme.dart';
import '../components/app_select.dart';
import '../components/pago_inscripcion_registro.dart';
import '../providers/auth_provider.dart';
import '../providers/catalogos_provider.dart';
import 'conductor_register_success_page.dart';
import 'conductor_yape_page.dart';
import 'pre_register_page.dart';

class ConductorRegisterPage extends StatefulWidget {
  const ConductorRegisterPage({super.key});

  @override
  State<ConductorRegisterPage> createState() => _ConductorRegisterPageState();
}

class _ConductorRegisterPageState extends State<ConductorRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 1;
  // 1 plataforma · 2 datos personales · 3 contacto y ubicación · 4 vehículo · 5 documentos · 6 pago de la inscripción (y se envía la solicitud).
  // La plataforma va primero porque define en qué ciudades se puede registrar la persona (paso 3).
  static const int _pasoPlataforma = 1;
  static const int _pasoDatosPersonales = 2;
  static const int _pasoContacto = 3;
  static const int _pasoVehiculo = 4;
  static const int _pasoDocumentos = 5;
  static const int _pasoPago = 6;
  final int _totalSteps = _pasoPago;
  bool _isPickingFile = false;

  static const List<String> _categoriasLicencia = [
    'A-I', 'A-IIa', 'A-IIb', 'A-IIIa', 'A-IIIb', 'A-IIIc',
    'B-I', 'B-IIa', 'B-IIb', 'B-IIc',
  ];
  static const List<String> _tiposVehiculo = ['Auto', 'Moto', 'Tuk-tuk', 'Otro'];

  // Paso 1: plataforma
  String? _plataforma;

  // Paso 2: datos personales
  final _tipoDocController = TextEditingController(text: 'DNI');
  final _nroDocController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _nroLicenciaController = TextEditingController();
  String? _categoriaLicencia;

  // Paso 3: contacto y ubicación
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
  // Si la ubicación elegida salió de la lista restringida de la plataforma (true) o del catálogo completo (false). Sirve para
  // descartar la elección cuando la persona cambia de plataforma y se pasa de un tipo de lista al otro.
  bool? _ubicacionDeListaRestringida;
  // Sube cada vez que se descarta una elección de ubicación: fuerza a los selectores a olvidar el valor que tenían.
  int _ubicacionGeneracion = 0;

  // ¿Ya existe un registro con estos datos? Se consulta al avanzar de los pasos 2 y 3. Guarda lo último que el servidor dijo que
  // está libre, para no repetir la consulta si la persona no lo cambió.
  bool _verificando = false;
  String? _documentoVerificado;
  String? _licenciaVerificada;
  String? _correoVerificado;

  // Paso 4: vehículo
  String? _tipoVehiculo;
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _colorController = TextEditingController();

  // Paso 5: documentos
  File? _docIdentidadAnverso;
  File? _docIdentidadReverso;
  File? _licenciaAnverso;
  File? _licenciaReverso;
  File? _fotoPerfil;
  // El pago de inscripción solo se registra al contado: no se ofrece financiarlo, por eso queda fijo en 'contado'.
  // Cómo se paga (Caja Arequipa o IziPay) se elige en el último paso (_metodoPago).
  final String _modalidadPago = 'contado';
  bool _aceptaTerminos = false;

  // Paso 6: pago de la inscripción, ANTES de enviar la solicitud. El monto depende de la plataforma y el departamento
  // elegidos, así que se consulta al entrar al paso. IziPay: QR + captura; Caja Arequipa: el código llega al enviar.
  InscripcionPagoInfoModel? _pagoInfo;
  bool _pagoInfoCargando = false;
  String? _pagoInfoError;
  String? _metodoPago;
  File? _capturaPago;
  final _operacionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalogos = context.read<CatalogosProvider>();
      // Un registro nuevo no hereda la restricción de ciudades de uno anterior.
      catalogos.limpiarUbicacionesPlataforma();
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
    _operacionController.dispose();
    super.dispose();
  }

  String? _validateCurrentStep() {
    bool empty(TextEditingController c) => c.text.trim().isEmpty;

    switch (_currentStep) {
      case _pasoPlataforma:
        if (_plataforma == null) return 'Selecciona la plataforma con la que trabajas';
        return null;
      case _pasoDatosPersonales:
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
      case _pasoContacto:
        if (!RegExp(r'^\d{9}$').hasMatch(_telefonoController.text.trim())) {
          return 'Ingresa un teléfono válido de 9 dígitos';
        }
        final correo = _correoController.text.trim();
        if (correo.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
          return 'Ingresa un correo electrónico válido';
        }
        final catalogos = context.read<CatalogosProvider>();
        if (catalogos.ubicacionesPlataformaLoading) {
          return 'Espera un momento: estamos consultando las ciudades de tu plataforma';
        }
        // Sin saber dónde está habilitada la plataforma (la consulta falló o no se hizo) no se avanza: se falla cerrado.
        if (!catalogos.ubicacionesPlataformaListas(_plataforma)) {
          return CatalogosProvider.ubicacionesPlataformaErrorMensaje;
        }
        if (catalogos.ubicacionRestringida && catalogos.departamentosRegistro.isEmpty) {
          return 'Tu plataforma aún no está habilitada en ninguna ciudad. Vuelve al paso 1 y elige otra plataforma';
        }
        if (_departamentoCodigo == null) return 'Selecciona tu departamento';
        if (_provinciaCodigo == null)    return 'Selecciona tu provincia';
        if (_distritoCodigo == null)     return 'Selecciona tu distrito';
        if (empty(_direccionController)) return 'Ingresa tu dirección exacta';
        final mapsError = _validateGoogleMapsUrl();
        if (mapsError != null) return mapsError;
        return null;
      case _pasoVehiculo:
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
      case _pasoDocumentos:
        if (_docIdentidadAnverso == null) return 'Adjunta el anverso de tu DNI';
        if (_docIdentidadReverso == null) return 'Adjunta el reverso de tu DNI';
        if (_licenciaAnverso == null)     return 'Adjunta el anverso de tu licencia de conducir';
        if (_licenciaReverso == null)     return 'Adjunta el reverso de tu licencia de conducir';
        if (!_aceptaTerminos) return 'Debes autorizar el tratamiento de datos personales';
        return null;
      case _pasoPago:
        if (_pagoInfoCargando) return 'Espera un momento: estamos calculando tu monto de inscripción';
        if (_pagoInfo == null) return _pagoInfoError ?? 'No pudimos calcular tu monto de inscripción. Inténtalo de nuevo';
        if (_pagoInfo!.monto <= 0) return null; // inscripción sin costo: no hay nada que pagar
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
    // OBLIGATORIO (igual que el pre-registro de pasajero y que la web):
    // sin ubicación no se puede registrar.
    if (raw.isEmpty) return 'Ingresa el link de Google Maps de tu dirección';

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

  Future<void> _nextStep() async {
    if (_verificando) return;

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
      // Si lo que falta es saber dónde está habilitada la plataforma, además se vuelve a consultar.
      if (_currentStep == _pasoContacto && !context.read<CatalogosProvider>().ubicacionesPlataformaListas(_plataforma)) {
        _cargarUbicacionesPlataforma();
      }
      return;
    }

    // Antes de avanzar de los datos personales y del contacto se pregunta si esos datos ya tienen un registro.
    if (_currentStep == _pasoDatosPersonales || _currentStep == _pasoContacto) {
      final puedeAvanzar = await _verificarYaRegistrado();
      if (!puedeAvanzar || !mounted) return;
    }

    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
      if (_currentStep == _pasoContacto) _prepararUbicaciones();
      if (_currentStep == _pasoPago) _cargarPagoInfo();
    } else {
      _submit();
    }
  }

  /// Pregunta al servidor si el documento y la licencia (paso 2) o el correo (paso 3) ya tienen un registro. Devuelve false si
  /// hay que quedarse en el paso: ya existe (se avisa con un diálogo) o la persona salió de la pantalla.
  /// Si la consulta falla (sin red, error del servidor) devuelve true: no se bloquea a nadie por eso, el servidor igual rechaza
  /// duplicados al enviar la solicitud.
  Future<bool> _verificarYaRegistrado() async {
    String? documento;
    String? licencia;
    String? correo;
    if (_currentStep == _pasoDatosPersonales) {
      final doc = _nroDocController.text.trim();
      final lic = _nroLicenciaController.text.trim();
      if (doc != _documentoVerificado) documento = doc;
      if (lic != _licenciaVerificada) licencia = lic;
    } else {
      final mail = _correoController.text.trim();
      if (mail.isNotEmpty && mail != _correoVerificado) correo = mail;
    }
    // Nada nuevo que preguntar (ya se verificó o el correo, que es opcional, está vacío).
    if (documento == null && licencia == null && correo == null) return true;

    setState(() => _verificando = true);
    final resultado = await context.read<CatalogosProvider>().verificarRegistroConductor(
          nroDocumento: documento,
          nroLicencia: licencia,
          correo: correo,
        );
    if (!mounted) return false;
    setState(() => _verificando = false);

    if (resultado == null) return true;
    if (resultado.registrado) {
      await _mostrarYaRegistrado(resultado);
      return false;
    }

    if (documento != null) _documentoVerificado = documento;
    if (licencia != null) _licenciaVerificada = licencia;
    if (correo != null) _correoVerificado = correo;
    return true;
  }

  Future<void> _mostrarYaRegistrado(VerificacionRegistroModel verificacion) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('registro_ya_registrado_dialogo'),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: Icon(
                verificacion.eliminado ? Icons.person_off_outlined : Icons.how_to_reg_outlined,
                color: Colors.black,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              verificacion.titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Text(
              verificacion.mensajeParaMostrar,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('registro_ya_registrado_entendido'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  /// Al elegir (o volver a elegir) la plataforma se consulta en qué ciudades está habilitada; la elección de ubicación que ya no
  /// valga se descarta cuando llega la respuesta.
  void _seleccionarPlataforma(String codigo) {
    final catalogos = context.read<CatalogosProvider>();
    final cambio = _plataforma != codigo;
    setState(() => _plataforma = codigo);
    // Si es la misma y su consulta ya salió bien (o está en curso) no se repite; si falló, tocarla de nuevo la reintenta.
    if (cambio || !catalogos.ubicacionesPlataformaListas(codigo)) _cargarUbicacionesPlataforma();
  }

  /// Al entrar al paso de ubicación la lista de ciudades debe estar lista: si la consulta no se hizo o falló, se vuelve a hacer.
  void _prepararUbicaciones() {
    if (!context.read<CatalogosProvider>().ubicacionesPlataformaListas(_plataforma)) _cargarUbicacionesPlataforma();
  }

  Future<void> _cargarUbicacionesPlataforma() async {
    final plataforma = _plataforma;
    if (plataforma == null) return;
    final catalogos = context.read<CatalogosProvider>();
    await catalogos.loadUbicacionesPlataforma(plataforma);
    // Si la persona eligió otra plataforma o salió mientras tanto, esta respuesta ya no aplica.
    if (!mounted || _plataforma != plataforma) return;
    _reconciliarUbicacion(catalogos);
  }

  /// Después de conocer las ciudades de la plataforma, deja la ubicación elegida solo si sigue siendo válida para ella; si no,
  /// la descarta para no enviar un departamento, provincia o distrito que la plataforma no admite.
  void _reconciliarUbicacion(CatalogosProvider catalogos) {
    // Si la consulta falló no se sabe qué vale: se deja todo como está y se valida cuando un reintento salga bien.
    if (!catalogos.ubicacionesPlataformaCargada) return;
    if (_departamentoCodigo == null) {
      _ubicacionDeListaRestringida = null;
      return;
    }

    final restringida = catalogos.ubicacionRestringida;
    final ubicaciones = catalogos.ubicacionesPlataforma;
    var descartarTodo = _ubicacionDeListaRestringida != restringida;
    var descartarDesdeProvincia = false;
    if (!descartarTodo && restringida && ubicaciones != null) {
      if (!ubicaciones.permiteDepartamento(_departamentoCodigo)) {
        descartarTodo = true;
      } else if (_provinciaCodigo != null && !ubicaciones.permiteProvincia(_departamentoCodigo, _provinciaCodigo)) {
        descartarDesdeProvincia = true;
      }
    }

    final departamentoVigente = descartarTodo ? null : _departamentoCodigo;
    setState(() {
      if (descartarTodo) {
        _departamentoCodigo = null;
        _departamentoNombre = null;
        _ubicacionDeListaRestringida = null;
      }
      if (descartarTodo || descartarDesdeProvincia) {
        _provinciaCodigo = null;
        _provinciaNombre = null;
        _distritoCodigo = null;
        _distritoNombre = null;
        _ubicacionGeneracion++;
      }
    });

    if (descartarTodo) catalogos.clearProvincias();
    if (descartarTodo || descartarDesdeProvincia) catalogos.clearDistritos();
    // Se mantiene el departamento: con una lista restringida sus provincias pueden ser otras que con la plataforma anterior.
    if (departamentoVigente != null && restringida) catalogos.loadProvinciasDelRegistro(departamentoVigente);
  }

  /// Monto de la inscripción y disponibilidad de IziPay. Se consulta cada vez que se entra al paso de pago, porque el monto
  /// depende de la plataforma y el departamento, que se pueden haber cambiado al volver atrás.
  Future<void> _cargarPagoInfo() async {
    setState(() {
      _pagoInfoCargando = true;
      _pagoInfoError = null;
    });
    try {
      final info = await context.read<CatalogosProvider>().fetchInscripcionPagoInfo(
            plataforma: _plataforma,
            departamento: _departamentoNombre,
            // Con el documento, el servidor dice si esta persona puede usar Yape cuando solo lo prueba una lista (modo de prueba).
            documento: _nroDocController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _pagoInfo = info;
        _pagoInfoCargando = false;
        if (_metodoPago == PagoInscripcionRegistro.metodoIzipay && !info.izipayDisponible) {
          _metodoPago = null;
          _capturaPago = null;
        }
        // Yape lo ofrece el servidor: si ya no lo ofrece (se apagó mientras la persona llenaba el registro), se descarta la elección.
        if (_metodoPago == PagoInscripcionRegistro.metodoYape && !info.yapeDisponible) {
          _metodoPago = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pagoInfoCargando = false;
        _pagoInfoError = 'No pudimos calcular tu monto de inscripción. Revisa tu conexión e inténtalo de nuevo.';
      });
    }
  }

  void _prevStep() {
    if (_verificando) return;
    if (_currentStep > _pasoPlataforma) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate() async {
    // El campo de fecha es un InkWell sobre un campo ignorado: no toma el foco. Si el apellido (u otro campo) lo tenía, Flutter se lo
    // devolvería al cerrar el calendario y reabriría el teclado. Se suelta antes de abrir.
    FocusManager.instance.primaryFocus?.unfocus();
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

    final pagaAlRegistrarse = _pagoInfo != null && _pagoInfo!.monto > 0 && _metodoPago != null;

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
      'google_maps_url': _googleMapsUrlController.text.trim(),
      'modalidad_pago_inscripcion': _modalidadPago,
      // El pago va dentro de la misma solicitud (solo si la inscripción tiene costo).
      if (pagaAlRegistrarse) 'metodo_pago_inscripcion': _metodoPago,
      if (pagaAlRegistrarse && _metodoPago == PagoInscripcionRegistro.metodoIzipay && _operacionController.text.trim().isNotEmpty)
        'numero_operacion': _operacionController.text.trim(),
      if (vehiculo.isNotEmpty) 'vehiculo': jsonEncode(vehiculo),
    };

    final files = <String, File>{};
    if (_docIdentidadAnverso != null) files['doc_identidad_anverso'] = _docIdentidadAnverso!;
    if (_docIdentidadReverso != null) files['doc_identidad_reverso'] = _docIdentidadReverso!;
    if (_licenciaAnverso != null) files['licencia'] = _licenciaAnverso!;
    if (_licenciaReverso != null) files['licencia_reverso'] = _licenciaReverso!;
    if (_fotoPerfil != null) files['foto_perfil'] = _fotoPerfil!;
    if (pagaAlRegistrarse && _metodoPago == PagoInscripcionRegistro.metodoIzipay && _capturaPago != null) {
      files['captura_pago'] = _capturaPago!;
    }

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
        // El código de Caja o la captura de IziPay que se acaban de registrar con la solicitud (con Yape: solo el aviso de que falta pagar).
        final inscripcion = responseData is Map && responseData['inscripcion'] is Map
            ? Map<String, dynamic>.from(responseData['inscripcion'] as Map)
            : null;

        if (pagaAlRegistrarse && _metodoPago == PagoInscripcionRegistro.metodoYape && conductorId != null) {
          // Yape: la solicitud ya quedó enviada; ahora afilia su Yape y paga. Se guardan los datos antes de reemplazar esta pantalla.
          final nroDocumento = _nroDocController.text.trim();
          final telefono = _telefonoController.text.trim();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConductorYapePage(
                conductorId: conductorId,
                nroDocumento: nroDocumento,
                telefonoInicial: telefono,
                // Pague o no, la persona termina en «Se envió tu solicitud» (sin pagar, desde «Ver el resultado» retoma el pago).
                alFinalizar: (ctx, pagada) => Navigator.pushReplacement(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => ConductorRegisterSuccessPage(conductorId: conductorId, inscripcion: inscripcion, yapePagado: pagada),
                  ),
                ),
              ),
            ),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConductorRegisterSuccessPage(conductorId: conductorId, inscripcion: inscripcion),
          ),
        );
      }
    } else if (mounted) {
      final msg = authProvider.errorMessage
          ?? (response != null ? (response['message'] ?? response['error']) : null)
          ?? 'Error al enviar la solicitud. Intente nuevamente.';
      // Yape se apagó en el servidor mientras la persona llenaba el registro: se descarta su elección y se vuelve a preguntar qué
      // métodos ofrece (si no, quedaría atascada con un método que ya no existe).
      if (_metodoPago == PagoInscripcionRegistro.metodoYape && msg.toString().contains('Yape no está disponible')) {
        setState(() => _metodoPago = null);
        _cargarPagoInfo();
      }
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
      case _pasoPlataforma: return 'Plataforma en la que trabajas';
      case _pasoDatosPersonales: return 'Información Personal';
      case _pasoContacto: return 'Contacto y Ubicación';
      case _pasoVehiculo: return 'Vehículo (Opcional)';
      case _pasoDocumentos: return 'Adjuntar Documentación';
      case _pasoPago: return 'Pago de Inscripción';
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
      case _pasoPlataforma:
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
      case _pasoDatosPersonales:
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
            AppSelect(
              label: 'Categoría de Licencia',
              icon: Icons.workspace_premium_outlined,
              value: _categoriaLicencia,
              options: _categoriasLicencia.map((c) => SelectOption(c, c)).toList(),
              onChanged: (val) => setState(() => _categoriaLicencia = val),
            ),
          ],
        );
      case _pasoContacto:
        // Con una plataforma restringida solo se ofrecen las ciudades que el servidor habilitó para ella.
        final restringida = catalogos.ubicacionRestringida;
        final sinCiudades = restringida && catalogos.departamentosRegistro.isEmpty;
        // No se pudo consultar dónde está habilitada la plataforma: no se ofrece ninguna ciudad hasta que un reintento salga bien.
        final consultaFallida = catalogos.ubicacionesPlataformaError != null;
        return Column(
          children: [
            _buildModernTextField(_telefonoController, 'Tu Teléfono', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            _buildModernTextField(_correoController, 'Correo Electrónico (Opcional)', Icons.mail_outline, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            if (consultaFallida)
              _buildErrorUbicaciones()
            else
            AppSelect(
              fieldKey: ValueKey('departamento-$_ubicacionGeneracion'),
              label: 'Departamento',
              icon: Icons.public_outlined,
              value: _departamentoCodigo,
              options: catalogos.departamentosRegistro.map((d) => SelectOption(d.codigo, d.nombre)).toList(),
              loading: catalogos.departamentosRegistroLoading,
              error: catalogos.departamentosRegistroError,
              onRetry: () => catalogos.loadDepartamentos(),
              placeholder: sinCiudades ? 'Tu plataforma aún no está habilitada en ninguna ciudad. Vuelve al paso 1 y elige otra plataforma.' : null,
              placeholderEsAviso: sinCiudades,
              avisoKey: const Key('ubicacion_sin_ciudades'),
              onChanged: (val) {
                final item = catalogos.departamentosRegistro.firstWhere((d) => d.codigo == val);
                setState(() {
                  _departamentoCodigo = val;
                  _departamentoNombre = item.nombre;
                  _provinciaCodigo = null;
                  _provinciaNombre = null;
                  _distritoCodigo = null;
                  _distritoNombre = null;
                  _ubicacionDeListaRestringida = restringida;
                });
                catalogos.clearDistritos();
                catalogos.loadProvinciasDelRegistro(val);
              },
            ),
            if (restringida && !sinCiudades)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Solo se muestran las ciudades habilitadas para tu plataforma.',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            AppSelect(
              fieldKey: ValueKey('provincia-$_departamentoCodigo-$_ubicacionGeneracion'),
              label: 'Provincia',
              icon: Icons.location_city_outlined,
              value: _provinciaCodigo,
              options: catalogos.provincias.map((p) => SelectOption(p.codigo, p.nombre)).toList(),
              loading: catalogos.provinciasLoading,
              error: catalogos.provinciasError,
              onRetry: () {
                if (_departamentoCodigo != null) catalogos.loadProvinciasDelRegistro(_departamentoCodigo!);
              },
              placeholder: _departamentoCodigo == null || consultaFallida
                  ? 'Selecciona primero el departamento'
                  : (restringida && catalogos.provincias.isEmpty ? 'Tu plataforma no tiene provincias habilitadas en este departamento' : null),
              onChanged: (val) {
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
            AppSelect(
              fieldKey: ValueKey('distrito-$_provinciaCodigo-$_ubicacionGeneracion'),
              label: 'Distrito',
              icon: Icons.map_outlined,
              value: _distritoCodigo,
              options: catalogos.distritos.map((d) => SelectOption(d.codigo, d.nombre)).toList(),
              loading: catalogos.distritosLoading,
              error: catalogos.distritosError,
              onRetry: () {
                if (_provinciaCodigo != null) catalogos.loadDistritos(_provinciaCodigo!);
              },
              placeholder: _provinciaCodigo == null || consultaFallida ? 'Selecciona primero la provincia' : null,
              onChanged: (val) {
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
              'Link Google Maps',
              Icons.location_on_outlined,
              keyboardType: TextInputType.url,
              helperText: 'Abre Maps, busca tu dirección, comparte y pega el enlace aquí',
            ),
          ],
        );
      case _pasoVehiculo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoNote('Si tienes vehículo, regístralo aquí. Esto define tu tarifa de inscripción.'),
            const SizedBox(height: 20),
            AppSelect(
              label: 'Tipo de Vehículo',
              icon: Icons.directions_car_outlined,
              value: _tipoVehiculo,
              options: _tiposVehiculo.map((t) => SelectOption(t, t)).toList(),
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
      case _pasoDocumentos:
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
            _buildInfoNote('En el siguiente paso pagarás tu inscripción y enviarás tu solicitud. Nuestro equipo la revisará junto con tu pago.'),
            const SizedBox(height: 20),
            PrivacyTermsCheckbox(
              onChanged: (val) {
                _aceptaTerminos = val;
              },
            ),
          ],
        );
      case _pasoPago:
        return PagoInscripcionRegistro(
          info: _pagoInfo,
          cargando: _pagoInfoCargando,
          error: _pagoInfoError,
          metodo: _metodoPago,
          captura: _capturaPago,
          operacionController: _operacionController,
          onMetodo: (metodo) => setState(() => _metodoPago = metodo),
          onElegirCaptura: () => _pickImage('captura'),
          onReintentar: _cargarPagoInfo,
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
            onTap: () => _seleccionarPlataforma(p.plataforma),
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

  /// Aviso (con «Reintentar») cuando no se pudo consultar en qué ciudades está habilitada la plataforma.
  Widget _buildErrorUbicaciones() {
    return Container(
      key: const Key('ubicacion_error_consulta'),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_outlined, color: Colors.red.shade400, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              CatalogosProvider.ubicacionesPlataformaErrorMensaje,
              style: TextStyle(fontSize: 13, color: Colors.red.shade700),
            ),
          ),
          TextButton(
            key: const Key('ubicacion_reintentar'),
            onPressed: _cargarUbicacionesPlataforma,
            child: const Text('Reintentar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
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
    // Ocupado: enviando la solicitud o consultando si ya existe un registro. Con el botón apagado no hay doble toque.
    final ocupado = authProvider.isLoading || _verificando;

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
                  onPressed: _verificando ? null : _prevStep,
                  child: Text(
                    _currentStep == _pasoPlataforma ? 'CANCELAR' : 'ATRÁS',
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
                  onPressed: ocupado ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: ocupado
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
