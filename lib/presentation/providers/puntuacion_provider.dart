import 'package:flutter/material.dart';
import '../../data/models/puntuacion_model.dart';
import '../../domain/usecases/puntuacion_usecases.dart';

class PuntuacionProvider with ChangeNotifier {
  final GetPuntuacionUseCase _getPuntuacionUseCase;
  final GetHistorialPuntosUseCase _getHistorialPuntosUseCase;
  final GetBeneficiosUseCase _getBeneficiosUseCase;
  final ActualizarPuntuacionUseCase _actualizarPuntuacionUseCase;

  PuntuacionProvider({
    required GetPuntuacionUseCase getPuntuacionUseCase,
    required GetHistorialPuntosUseCase getHistorialPuntosUseCase,
    required GetBeneficiosUseCase getBeneficiosUseCase,
    required ActualizarPuntuacionUseCase actualizarPuntuacionUseCase,
  })  : _getPuntuacionUseCase = getPuntuacionUseCase,
        _getHistorialPuntosUseCase = getHistorialPuntosUseCase,
        _getBeneficiosUseCase = getBeneficiosUseCase,
        _actualizarPuntuacionUseCase = actualizarPuntuacionUseCase;

  PuntuacionModel? _puntuacion;
  List<HistorialPuntosModel> _historial = [];
  List<BeneficioModel> _beneficios = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  PuntuacionModel? get puntuacion => _puntuacion;
  List<HistorialPuntosModel> get historial => _historial;
  List<BeneficioModel> get beneficios => _beneficios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar puntuación
  Future<void> getPuntuacion(int idConductor, int tipo) async {
    try {
      _setLoading(true);
      _error = null;
      final result = await _getPuntuacionUseCase.call(idConductor, tipo);
      result.fold(
        (failure) {
          _error = failure.message;
        },
        (puntuacionEntity) {
          _puntuacion = PuntuacionModel(
            id: puntuacionEntity.id,
            tipoCliente: puntuacionEntity.tipoCliente,
            idConductor: puntuacionEntity.idConductor,
            puntajeActual: puntuacionEntity.puntajeActual,
            totalFinanciamientos: puntuacionEntity.totalFinanciamientos,
            totalRetrasos: puntuacionEntity.totalRetrasos,
            fechaActualizacion: puntuacionEntity.fechaActualizacion,
            fechaCreacion: puntuacionEntity.fechaCreacion,
          );
        },
      );
    } catch (e) {
      _error = 'Error inesperado: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Cargar historial de puntos
  Future<void> getHistorialPuntos(int idConductor, int tipo) async {
    try {
      _setLoading(true);
      _error = null;
      final result = await _getHistorialPuntosUseCase.call(idConductor, tipo);
      result.fold(
        (failure) {
          _error = failure.message;
        },
        (historialEntities) {
          _historial = historialEntities.map((entity) => HistorialPuntosModel(
            id: entity.id,
            puntajeAnterior: entity.puntajeAnterior,
            puntajeNuevo: entity.puntajeNuevo,
            puntosPerdidos: entity.puntosPerdidos,
            motivo: entity.motivo,
            fechaReferencia: entity.fechaReferencia,
            numeroCuota: entity.numeroCuota,
            montoCuota: entity.montoCuota,
            fechaVencimiento: entity.fechaVencimiento,
            fechaPago: entity.fechaPago,
            idFinanciamiento: entity.idFinanciamiento,
            nombreProducto: entity.nombreProducto,
            estadoCuota: entity.estadoCuota,
            origen: entity.origen,
          )).toList();
        },
      );
    } catch (e) {
      _error = 'Error inesperado: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Cargar beneficios
  Future<void> getBeneficios(int puntaje) async {
    try {
      _setLoading(true);
      _error = null;
      final result = await _getBeneficiosUseCase.call(puntaje);
      result.fold(
        (failure) {
          _error = failure.message;
        },
        (beneficioEntities) {
          _beneficios = beneficioEntities.map((entity) => BeneficioModel(
            titulo: entity.titulo,
            descripcion: entity.descripcion,
            icono: entity.icono,
            activo: entity.activo,
          )).toList();
        },
      );
    } catch (e) {
      _error = 'Error inesperado: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar puntuación
  Future<void> actualizarPuntuacion(int idConductor, int nuevoPuntaje, int tipo) async {
    try {
      _setLoading(true);
      _error = null;
      final result = await _actualizarPuntuacionUseCase.call(idConductor, nuevoPuntaje, tipo);
      result.fold(
        (failure) {
          _error = failure.message;
        },
        (success) {
          getPuntuacion(idConductor, tipo);
        },
      );
    } catch (e) {
      _error = 'Error inesperado: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Cargar todos los datos
  Future<void> loadAllData(int idConductor, int tipo) async {
    await Future.wait([
      getPuntuacion(idConductor, tipo),
      getHistorialPuntos(idConductor, tipo),
    ]);
    if (_puntuacion != null) {
      await getBeneficios(_puntuacion!.puntajeActual);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}