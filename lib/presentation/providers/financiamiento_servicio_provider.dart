import 'package:flutter/material.dart';
import '../../domain/usecases/create_financiamiento_usecase.dart';
import '../../domain/usecases/get_beneficios_servicios_usecase.dart';
import '../../domain/usecases/get_documentos_firmados_usecase.dart';
import '../../domain/entities/beneficio_servicio_entity.dart';
import '../../domain/entities/financiamiento_entity.dart';
import '../../domain/entities/documento_firmado_entity.dart';

class FinanciamientoServicioProvider with ChangeNotifier {
  final GetBeneficiosServiciosUseCase getBeneficiosServiciosUseCase;
  final CreateFinanciamientoUseCase createFinanciamientoUseCase;
  final GetDocumentosFirmadosUseCase getDocumentosFirmadosUseCase;

  FinanciamientoServicioProvider({
    required this.getBeneficiosServiciosUseCase,
    required this.createFinanciamientoUseCase,
    required this.getDocumentosFirmadosUseCase,
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
    required double montoCuota,
    required int cantidadCuotas,
    required int frecuenciaPagoId,
    required String fechaInicio,
    required double cuotaInicial,
    required String metodoPago,
    required String numeroOperacion,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final data = {
      'cliente_conductor_id': conductorId,
      'beneficio_id': beneficioId,
      'grupo_financiamiento_id': grupoId,
      'monto_total': montoTotal,
      'monto_cuota': montoCuota,
      'cantidad_cuotas': cantidadCuotas,
      'frecuencia_pago_id': frecuenciaPagoId,
      'moneda_id': 1, // Soles default
      'fecha_inicio': fechaInicio,
      'cuota_inicial': cuotaInicial,
      'metodo_pago_inicial': metodoPago,
      'numero_operacion_inicial': numeroOperacion,
    };

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
