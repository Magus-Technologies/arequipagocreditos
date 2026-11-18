import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/catalogo_models.dart';
import '../../data/models/conductor_estado_model.dart';
import '../../data/models/izipay_models.dart';
import '../../data/models/verificacion_registro_model.dart';
import '../../data/models/yape_models.dart';
import '../../domain/repositories/catalogos_repository.dart';

class CatalogosProvider extends ChangeNotifier {
  final CatalogosRepository catalogosRepository;

  CatalogosProvider({required this.catalogosRepository});

  List<UbigeoItemModel> _departamentos = [];
  List<UbigeoItemModel> get departamentos => _departamentos;
  bool _departamentosLoading = false;
  bool get departamentosLoading => _departamentosLoading;
  String? _departamentosError;
  String? get departamentosError => _departamentosError;

  List<UbigeoItemModel> _provincias = [];
  List<UbigeoItemModel> get provincias => _provincias;
  bool _provinciasLoading = false;
  bool get provinciasLoading => _provinciasLoading;
  String? _provinciasError;
  String? get provinciasError => _provinciasError;

  List<UbigeoItemModel> _distritos = [];
  List<UbigeoItemModel> get distritos => _distritos;
  bool _distritosLoading = false;
  bool get distritosLoading => _distritosLoading;
  String? _distritosError;
  String? get distritosError => _distritosError;

  List<PlataformaItemModel> _plataformas = [];
  List<PlataformaItemModel> get plataformas => _plataformas;
  bool _plataformasLoading = false;
  bool get plataformasLoading => _plataformasLoading;
  String? _plataformasError;
  String? get plataformasError => _plataformasError;

  /// Texto cuando no se pudo consultar en qué ciudades está habilitada la plataforma.
  static const String ubicacionesPlataformaErrorMensaje =
      'No pudimos consultar las ciudades de tu plataforma. Revisa tu conexión e inténtalo de nuevo.';

  // Ciudades donde está habilitada la plataforma elegida en el registro de conductor. Se FALLA CERRADO: si la consulta no se hizo o
  // falló, el registro no ofrece ninguna ciudad ni deja avanzar (la persona pagaría antes de que el servidor rechace la ciudad).
  // La única excepción es el 404 (servidor sin el endpoint nuevo), que el datasource entrega como «sin restricción».
  UbicacionPlataformaModel? _ubicacionesPlataforma;
  String? _ubicacionesPlataformaCodigo;
  bool _ubicacionesPlataformaLoading = false;
  bool _ubicacionesPlataformaCargada = false;
  String? _ubicacionesPlataformaError;
  int _ubicacionesPlataformaPeticion = 0;
  int _provinciasPeticion = 0;

  bool get ubicacionesPlataformaLoading => _ubicacionesPlataformaLoading;

  /// La consulta ya terminó bien para la plataforma pedida (con o sin restricción).
  bool get ubicacionesPlataformaCargada => _ubicacionesPlataformaCargada;

  /// Texto del fallo de la última consulta (null si salió bien, está en curso o aún no se hizo).
  String? get ubicacionesPlataformaError => _ubicacionesPlataformaError;

  /// La plataforma solo funciona en las ciudades que manda el servidor (y no en cualquier lugar).
  bool get ubicacionRestringida => _ubicacionesPlataforma?.restringido == true;

  UbicacionPlataformaModel? get ubicacionesPlataforma => _ubicacionesPlataforma;

  /// ¿Ya se consultó (o se está consultando) la ubicación de [plataforma]? Si la última consulta falló, es false: conviene reintentar.
  bool ubicacionesPlataformaListas(String? plataforma) =>
      plataforma != null &&
      _ubicacionesPlataformaCodigo == plataforma &&
      (_ubicacionesPlataformaLoading || _ubicacionesPlataformaCargada);

  /// Departamentos que puede elegir la persona al registrarse: los habilitados para su plataforma o, si no hay restricción, todos.
  /// Mientras no se sepa dónde está habilitada la plataforma (en curso, fallida o sin consultar) no se ofrece ninguno.
  List<UbigeoItemModel> get departamentosRegistro {
    if (ubicacionRestringida) return _ubicacionesPlataforma!.departamentosItems;
    return _ubicacionesPlataformaCargada ? _departamentos : const [];
  }

  bool get departamentosRegistroLoading =>
      _ubicacionesPlataformaLoading ||
      (_ubicacionesPlataformaCargada && !ubicacionRestringida && _departamentosLoading);

  String? get departamentosRegistroError =>
      _ubicacionesPlataformaError ?? (_ubicacionesPlataformaCargada && !ubicacionRestringida ? _departamentosError : null);

  /// Consulta dónde está habilitada [plataforma]. Nunca lanza: si falla deja [ubicacionesPlataformaError] y no ofrece ciudades
  /// hasta que un reintento salga bien.
  Future<void> loadUbicacionesPlataforma(String plataforma) async {
    final peticion = ++_ubicacionesPlataformaPeticion;
    _ubicacionesPlataformaCodigo = plataforma;
    _ubicacionesPlataforma = null;
    _ubicacionesPlataformaCargada = false;
    _ubicacionesPlataformaError = null;
    _ubicacionesPlataformaLoading = true;
    notifyListeners();

    UbicacionPlataformaModel? ubicaciones;
    try {
      final result = await catalogosRepository.getUbicacionesPlataforma(plataforma);
      ubicaciones = result.fold((_) => null, (u) => u);
    } catch (_) {
      ubicaciones = null;
    }

    // Si mientras tanto se eligió otra plataforma, esta respuesta ya no vale.
    if (peticion != _ubicacionesPlataformaPeticion) return;
    _ubicacionesPlataforma = ubicaciones;
    _ubicacionesPlataformaCargada = ubicaciones != null;
    _ubicacionesPlataformaError = ubicaciones == null ? ubicacionesPlataformaErrorMensaje : null;
    _ubicacionesPlataformaLoading = false;
    notifyListeners();
  }

  /// Olvida lo consultado (al abrir un registro nuevo no debe quedar la restricción de uno anterior).
  void limpiarUbicacionesPlataforma() {
    _ubicacionesPlataformaPeticion++;
    _ubicacionesPlataforma = null;
    _ubicacionesPlataformaCodigo = null;
    _ubicacionesPlataformaCargada = false;
    _ubicacionesPlataformaError = null;
    _ubicacionesPlataformaLoading = false;
    notifyListeners();
  }

  /// Provincias del departamento elegido en el registro: con restricción salen de la lista que ya mandó el servidor (sin llamar
  /// al catálogo global); sin restricción se consultan como siempre.
  Future<void> loadProvinciasDelRegistro(String codigoDepartamento) async {
    final ubicaciones = _ubicacionesPlataforma;
    if (ubicaciones != null && ubicaciones.restringido) {
      _provinciasPeticion++;
      _provincias = ubicaciones.provinciasDe(codigoDepartamento);
      _provinciasLoading = false;
      _provinciasError = null;
      notifyListeners();
      return;
    }
    await loadProvincias(codigoDepartamento);
  }

  /// ¿Ya existe un registro con ese documento, licencia o correo? Devuelve null si no se pudo consultar (sin red, error del
  /// servidor, respuesta rara): en ese caso NO se debe bloquear a la persona, porque el servidor igual rechaza duplicados al enviar.
  Future<VerificacionRegistroModel?> verificarRegistroConductor({String? nroDocumento, String? nroLicencia, String? correo}) async {
    try {
      final result = await catalogosRepository.verificarRegistroConductor(
        nroDocumento: nroDocumento,
        nroLicencia: nroLicencia,
        correo: correo,
      );
      return result.fold((_) => null, (v) => v);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadDepartamentos() async {
    _departamentosLoading = true;
    _departamentosError = null;
    notifyListeners();

    final result = await catalogosRepository.getDepartamentos();
    result.fold(
      (failure) => _departamentosError = failure.message,
      (list) => _departamentos = list,
    );

    _departamentosLoading = false;
    notifyListeners();
  }

  Future<void> loadProvincias(String codigoDepartamento) async {
    final peticion = ++_provinciasPeticion;
    _provinciasLoading = true;
    _provinciasError = null;
    _provincias = [];
    notifyListeners();

    final result = await catalogosRepository.getProvincias(codigoDepartamento);
    // Si mientras tanto se pidió otro departamento (o se pasó a la lista de la plataforma), esta respuesta ya no vale.
    if (peticion != _provinciasPeticion) return;
    result.fold(
      (failure) => _provinciasError = failure.message,
      (list) => _provincias = list,
    );

    _provinciasLoading = false;
    notifyListeners();
  }

  Future<void> loadDistritos(String codigoProvincia) async {
    _distritosLoading = true;
    _distritosError = null;
    _distritos = [];
    notifyListeners();

    final result = await catalogosRepository.getDistritos(codigoProvincia);
    result.fold(
      (failure) => _distritosError = failure.message,
      (list) => _distritos = list,
    );

    _distritosLoading = false;
    notifyListeners();
  }

  Future<void> loadPlataformas() async {
    _plataformasLoading = true;
    _plataformasError = null;
    notifyListeners();

    final result = await catalogosRepository.getPlataformas();
    result.fold(
      (failure) => _plataformasError = failure.message,
      (list) => _plataformas = list,
    );

    _plataformasLoading = false;
    notifyListeners();
  }

  Future<ConductorEstadoModel> fetchConductorEstado(int conductorId) async {
    final result = await catalogosRepository.getConductorEstado(conductorId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (estado) => estado,
    );
  }

  /// Emite el codigo de Caja Arequipa. Se llama cuando la persona elige ese
  /// metodo, no antes: el codigo vence a las 24h.
  Future<ConductorEstadoModel> generarOrdenCajaArequipa(int clienteId) async {
    final result = await catalogosRepository.generarOrdenCajaArequipa(clienteId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (estado) => estado,
    );
  }

  /// Monto de inscripción y disponibilidad de IziPay para el paso de pago del pre-registro (aún no existe el registro).
  ///
  /// Con [documento], si Yape salió «Próximamente» se pregunta aparte si ESA persona puede usarlo (modo de prueba del servidor: solo una
  /// lista lo prueba). Si esa pregunta falla, Yape queda como «Próximamente»: nunca se habilita por error.
  Future<InscripcionPagoInfoModel> fetchInscripcionPagoInfo({String? plataforma, String? departamento, String? tipo, String? documento}) async {
    final result = await catalogosRepository.getInscripcionPagoInfo(plataforma: plataforma, departamento: departamento, tipo: tipo);
    final info = result.fold(
      (failure) => throw Exception(failure.message),
      (info) => info,
    );

    if (documento == null || documento.trim().isEmpty || !info.yapeProximamente) return info;

    try {
      final acceso = await catalogosRepository.getYapeAcceso(nroDocumento: documento.trim());
      return acceso.fold((_) => info, (puede) => puede ? info.conYapeHabilitado() : info);
    } catch (_) {
      return info;
    }
  }

  Future<IzipayInfoModel> fetchIzipayInfo(int clienteId) async {
    final result = await catalogosRepository.getIzipayInfo(clienteId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (info) => info,
    );
  }

  Future<Map<String, dynamic>> subirCapturaIzipay({
    required int clienteConductorId,
    required String nroDocumento,
    required File captura,
    String? numeroOperacion,
  }) async {
    final result = await catalogosRepository.subirCapturaIzipay(
      clienteConductorId: clienteConductorId,
      nroDocumento: nroDocumento,
      captura: captura,
      numeroOperacion: numeroOperacion,
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (response) => response,
    );
  }

  /// En qué paso va el pago de la inscripción con Yape (el servidor decide; el app solo dibuja). Lanza con el texto para la persona.
  Future<YapeInscripcionEstadoModel> fetchYapeInscripcionEstado({required int clienteId, required String nroDocumento}) async {
    final result = await catalogosRepository.getYapeInscripcionEstado(clienteId: clienteId, nroDocumento: nroDocumento);
    return result.fold((failure) => throw Exception(failure.message), (estado) => estado);
  }

  /// Afilia el Yape de la persona: devuelve el estado con el enlace que abre Yape para aprobar.
  Future<YapeInscripcionEstadoModel> afiliarYapeInscripcion({
    required int clienteId,
    required String nroDocumento,
    required String celular,
  }) async {
    final result = await catalogosRepository.afiliarYapeInscripcion(clienteId: clienteId, nroDocumento: nroDocumento, celular: celular);
    return result.fold((failure) => throw Exception(failure.message), (estado) => estado);
  }

  /// Pide el cobro de la inscripción al Yape ya afiliado.
  Future<YapeInscripcionEstadoModel> cobrarYapeInscripcion({required int clienteId, required String nroDocumento}) async {
    final result = await catalogosRepository.cobrarYapeInscripcion(clienteId: clienteId, nroDocumento: nroDocumento);
    return result.fold((failure) => throw Exception(failure.message), (estado) => estado);
  }

  void clearProvincias() {
    _provinciasPeticion++;
    _provincias = [];
    _provinciasLoading = false;
    _provinciasError = null;
    notifyListeners();
  }

  void clearDistritos() {
    _distritos = [];
    _distritosError = null;
    notifyListeners();
  }
}
