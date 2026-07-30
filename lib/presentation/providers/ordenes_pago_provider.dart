import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/orden_pago_entity.dart';
import '../../domain/usecases/get_ordenes_pago_usecase.dart';

class OrdenesPagoProvider extends ChangeNotifier {
  final GetOrdenesPagoUseCase getOrdenesPagoUseCase;

  OrdenesPagoProvider({required this.getOrdenesPagoUseCase});

  List<OrdenPagoEntity> _ordenes = [];
  ResumenOrdenesEntity _resumen =
      const ResumenOrdenesEntity(pagables: 0, vencidas: 0);
  bool _isLoading = false;
  String _errorMessage = '';
  bool _incluirHistorial = false;

  List<OrdenPagoEntity> get ordenes => _ordenes;
  ResumenOrdenesEntity get resumen => _resumen;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get incluirHistorial => _incluirHistorial;
  bool get isEmpty => _ordenes.isEmpty && !_isLoading && !hasError;

  /// Órdenes que la persona puede pagar ahora mismo.
  List<OrdenPagoEntity> get activas =>
      _ordenes.where((o) => o.pagable).toList();

  /// Pagadas, vencidas y anuladas. Solo se llenan con [incluirHistorial].
  List<OrdenPagoEntity> get historial =>
      _ordenes.where((o) => !o.pagable).toList();

  /// Códigos temporales a los que les quedan menos de 6 horas.
  ///
  /// Se calcula acá y no se usa `resumen.por_vencer_24h` del backend: como todo
  /// código temporal vive 24h, ese contador da positivo desde el primer segundo
  /// y el aviso terminaría mostrándose siempre. El umbral de 6h es el que usa
  /// el panel web.
  int get porVencer => _ordenes.where((o) => o.pagable && o.porVencer()).length;

  Future<void> cargar({
    required int clienteId,
    bool? incluirHistorial,
  }) async {
    if (incluirHistorial != null) {
      _incluirHistorial = incluirHistorial;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    final result = await getOrdenesPagoUseCase(
      clienteId: clienteId,
      incluirHistorial: _incluirHistorial,
    );

    result.fold(
      (Failure failure) {
        _errorMessage = failure.message;
        _ordenes = [];
      },
      (listado) {
        _ordenes = listado.ordenes;
        _resumen = listado.resumen;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> alternarHistorial(int clienteId) async {
    await cargar(clienteId: clienteId, incluirHistorial: !_incluirHistorial);
  }
}
