import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/catalogo_models.dart';
import '../../data/models/conductor_estado_model.dart';
import '../../data/models/izipay_models.dart';
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
    _provinciasLoading = true;
    _provinciasError = null;
    _provincias = [];
    notifyListeners();

    final result = await catalogosRepository.getProvincias(codigoDepartamento);
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

  void clearProvincias() {
    _provincias = [];
    _provinciasError = null;
    notifyListeners();
  }

  void clearDistritos() {
    _distritos = [];
    _distritosError = null;
    notifyListeners();
  }
}
