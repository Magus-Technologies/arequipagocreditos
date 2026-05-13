import 'package:flutter/material.dart';
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

  List<BeneficioServicioEntity> _beneficios = [];
  List<BeneficioServicioEntity> get beneficios => _beneficios;

  BeneficioServicioEntity? _selectedService;
  BeneficioServicioEntity? get selectedService => _selectedService;

  ListadoDocumentosEntity? _documentosFirmados;
  ListadoDocumentosEntity? get documentosFirmados => _documentosFirmados;

  List<TallerModel> _talleres = [];
  List<TallerModel> get talleres => _talleres;

  bool _talleresLoading = false;
  bool get talleresLoading => _talleresLoading;

  String? _talleresError;
  String? get talleresError => _talleresError;

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

  Future<void> loadBeneficiosServicios({int? tallerId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getBeneficiosServiciosUseCase(tallerId: tallerId);
    
    result.fold(
      (failure) => _error = failure.message,
      (beneficios) => _beneficios = beneficios,
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

  void selectService(BeneficioServicioEntity service) {
    _selectedService = service;
    notifyListeners();
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
      'moneda_id': 1,
    };

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
