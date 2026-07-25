import 'package:flutter/material.dart';
import '../../core/utils/audiencia_helper.dart';
import '../../data/models/taller_model.dart';
import '../../domain/usecases/create_financiamiento_usecase.dart';
import '../../domain/usecases/get_beneficios_servicios_usecase.dart';
import '../../domain/usecases/get_documentos_firmados_usecase.dart';
import '../../domain/entities/beneficio_servicio_entity.dart';
import '../../domain/entities/financiamiento_entity.dart';
import '../../domain/entities/documento_firmado_entity.dart';
import '../../domain/repositories/beneficios_comercial_repository.dart';

class FinanciamientoServicioProvider with ChangeNotifier {
  final GetBeneficiosServiciosUseCase getBeneficiosServiciosUseCase;
  final CreateFinanciamientoUseCase createFinanciamientoUseCase;
  final GetDocumentosFirmadosUseCase getDocumentosFirmadosUseCase;
  final BeneficiosComercialRepository beneficiosRepository;

  FinanciamientoServicioProvider({
    required this.getBeneficiosServiciosUseCase,
    required this.createFinanciamientoUseCase,
    required this.getDocumentosFirmadosUseCase,
    required this.beneficiosRepository,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _audiencia;

  List<BeneficioServicioEntity> _beneficios = [];
  List<BeneficioServicioEntity> get beneficios => _beneficios;

  BeneficioServicioEntity? _selectedService;
  BeneficioServicioEntity? get selectedService => _selectedService;

  VarianteEntity? _selectedVariante;
  VarianteEntity? get selectedVariante => _selectedVariante;

  /// true cuando lo seleccionado es un beneficio comercial (no un servicio de
  /// taller). Los beneficios solo se adquieren financiados.
  bool _esBeneficioComercial = false;
  bool get esBeneficioComercial => _esBeneficioComercial;

  TallerModel? _selectedTaller;
  TallerModel? get selectedTaller => _selectedTaller;

  ListadoDocumentosEntity? _documentosFirmados;
  ListadoDocumentosEntity? get documentosFirmados => _documentosFirmados;

  List<TallerModel> _talleres = [];
  List<TallerModel> get talleres => _talleres;

  bool _talleresLoading = false;
  bool get talleresLoading => _talleresLoading;

  String? _talleresError;
  String? get talleresError => _talleresError;

  List<TallerGrupo> _grupos = [];
  List<TallerGrupo> get grupos => _grupos;

  String _tallerSearchQuery = '';
  String _beneficioSearchQuery = '';

  void setTallerSearchQuery(String query) {
    _tallerSearchQuery = query;
    notifyListeners();
  }

  void setBeneficioSearchQuery(String query) {
    _beneficioSearchQuery = query;
    notifyListeners();
  }

  List<TallerModel> get filteredTalleres {
    if (_tallerSearchQuery.isEmpty) return _talleres;
    return _talleres.where((taller) =>
      taller.nombreComercial.toLowerCase().contains(_tallerSearchQuery.toLowerCase()) ||
      (taller.direccion?.toLowerCase().contains(_tallerSearchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  List<BeneficioServicioEntity> get filteredBeneficios {
    if (_beneficioSearchQuery.isEmpty) return _beneficios;
    return _beneficios.where((servicio) =>
      servicio.nombre.toLowerCase().contains(_beneficioSearchQuery.toLowerCase()) ||
      servicio.descripcion.toLowerCase().contains(_beneficioSearchQuery.toLowerCase())
    ).toList();
  }

  /// Configura la audiencia del usuario actual
  void setAudiencia(int tipoUsuario) {
    _audiencia = AudienciaHelper.fromTipo(tipoUsuario);
  }

  Future<void> loadBeneficiosServicios({int? tallerId, int? clienteConductorId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getBeneficiosServiciosUseCase(tallerId: tallerId, audiencia: _audiencia, clienteConductorId: clienteConductorId);
    
    result.fold(
      (failure) => _error = failure.message,
      (beneficios) {
        // Filtro local como respaldo
        if (_audiencia != null) {
          _beneficios = beneficios.where((b) => b.esVisiblePara(_audiencia!)).toList();
        } else {
          _beneficios = beneficios;
        }
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTalleres() async {
    _talleresLoading = true;
    _talleresError = null;
    notifyListeners();

    final result = await beneficiosRepository.getTalleres();

    result.fold(
      (failure) => _talleresError = failure.message,
      (list) => _talleres = list,
    );

    _talleresLoading = false;
    notifyListeners();
  }

  Future<void> loadTalleresAgrupados() async {
    _talleresLoading = true;
    _talleresError = null;
    notifyListeners();

    final result = await beneficiosRepository.getTalleresAgrupados(audiencia: _audiencia);

    result.fold(
      (failure) => _talleresError = failure.message,
      (response) {
        _grupos = response.grupos;
        // También llenamos _talleres como lista plana para el buscador
        _talleres = response.grupos.expand((g) => g.talleres).toList();
      },
    );

    _talleresLoading = false;
    notifyListeners();
  }

  /// Filtra grupos por búsqueda, devolviendo solo los grupos que tienen coincidencias.
  List<TallerGrupo> get filteredGrupos {
    if (_tallerSearchQuery.isEmpty) return _grupos;
    return _grupos
        .map((g) {
          final matches = g.talleres.where((t) =>
            t.nombreComercial.toLowerCase().contains(_tallerSearchQuery.toLowerCase()) ||
            (t.direccion?.toLowerCase().contains(_tallerSearchQuery.toLowerCase()) ?? false),
          ).toList();
          if (matches.isEmpty) return null;
          return TallerGrupo(nombre: g.nombre, total: matches.length, talleres: matches);
        })
        .whereType<TallerGrupo>()
        .toList();
  }

  void selectService(BeneficioServicioEntity service) {
    _selectedService = service;
    _selectedVariante = null;
    _esBeneficioComercial = false;
    notifyListeners();
  }

  /// Selecciona un beneficio comercial (no viene de un taller) junto con la
  /// variante elegida por el cliente, si el beneficio ofrece variantes.
  void selectBeneficioComercial(
    BeneficioServicioEntity beneficio, {
    VarianteEntity? variante,
  }) {
    _selectedService = beneficio;
    _selectedVariante = variante;
    _selectedTaller = null;
    _esBeneficioComercial = true;
    notifyListeners();
  }

  Future<BeneficioServicioEntity?> loadBeneficioDetalle({
    required int beneficioId,
    int? clienteConductorId,
  }) async {
    final result = await beneficiosRepository.getBeneficioDetalle(
      beneficioId: beneficioId,
      clienteConductorId: clienteConductorId,
    );

    return result.fold(
      (failure) {
        _error = failure.message;
        return null;
      },
      (beneficio) => beneficio,
    );
  }

  void setSelectedTaller(TallerModel taller) {
    _selectedTaller = taller;
  }

  Future<Map<String, dynamic>?> calificarTaller({
    required int tallerId,
    required int clienteConductorId,
    required int puntuacion,
    String? comentario,
    int? financiamientoId,
  }) async {
    try {
      return await beneficiosRepository.calificarTaller(
        tallerId: tallerId,
        clienteConductorId: clienteConductorId,
        puntuacion: puntuacion,
        comentario: comentario,
        financiamientoId: financiamientoId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadDocumentosFirmados(int conductorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getDocumentosFirmadosUseCase(conductorId);
    
    result.fold(
      (failure) => _error = failure.message,
      (docs) => _documentosFirmados = docs,
    );

    _isLoading = false;
    notifyListeners();
  }

  // Calculation methods
  double calculateCuotaInicial(double precio, double porcentaje) {
    return precio * (porcentaje / 100);
  }

  double calculateMontoAFinanciar(double precio, double cuotaInicial) {
    return precio - cuotaInicial;
  }

  double calculateCuotaMonto(double montoAFinanciar, int cuotas, double interes) {
    if (cuotas <= 0) return 0;
    return (montoAFinanciar * (1 + interes / 100)) / cuotas;
  }

  Future<FinanciamientoEntity?> createFinanciamiento({
    required int conductorId,
    required int beneficioId,
    required int grupoId,
    required double montoTotal,
    required double cuotaInicial,
    required String metodoPago,
    String? numeroOperacion,
    // Financiado-only fields (omitted for contado)
    double montoCuota = 0,
    int cantidadCuotas = 0,
    int frecuenciaPagoId = 1,
    String? fechaInicio,
    // Required only when tipo_pago = 3
    String? modalidadPago,
    // Contrato/firma
    String? firmaBase64,
    String? nroDocumento,
    // Variante elegida por el cliente (beneficios con variantes).
    // El backend deriva de ella todos los importes; lo que se envie aca es
    // solo referencial.
    int? varianteId,
    int? monedaId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final Map<String, dynamic> data = {
      'cliente_conductor_id': conductorId,
      'beneficio_id': beneficioId,
      'grupo_financiamiento_id': grupoId,
      'monto_total': montoTotal,
      'cuota_inicial': cuotaInicial,
      'metodo_pago_inicial': metodoPago,
      'moneda_id': monedaId ?? 1,
    };

    if (varianteId != null) data['variante_id'] = varianteId;

    if (modalidadPago != null) data['modalidad_pago'] = modalidadPago;

    if (cantidadCuotas > 0) {
      data['monto_cuota'] = montoCuota;
      data['cantidad_cuotas'] = cantidadCuotas;
      data['frecuencia_pago_id'] = frecuenciaPagoId;
      if (fechaInicio != null) data['fecha_inicio'] = fechaInicio;
    }

    if (numeroOperacion != null && numeroOperacion.isNotEmpty) {
      data['numero_operacion_inicial'] = numeroOperacion;
    }

    if (firmaBase64 != null && firmaBase64.isNotEmpty) {
      data['firma_base64'] = firmaBase64;
    }

    if (nroDocumento != null && nroDocumento.isNotEmpty) {
      data['nro_documento'] = nroDocumento;
    }

    final result = await createFinanciamientoUseCase(data);
    
    _isLoading = false;
    notifyListeners();

    return result.fold(
      (failure) {
        _error = failure.message;
        return null;
      },
      (financiamiento) => financiamiento,
    );
  }
}
