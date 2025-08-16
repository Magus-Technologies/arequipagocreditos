import 'package:arequipagocreditos/data/models/resumen_crediticio_model.dart';
import 'package:arequipagocreditos/domain/usecases/get_resumen_crediticio_usecase.dart';
import 'package:flutter/material.dart';

class ResumenCrediticioProvider extends ChangeNotifier {
  final GetResumenCrediticioUseCase _getResumenCrediticioUseCase;

  ResumenCrediticioProvider({
    required GetResumenCrediticioUseCase getResumenCrediticioUseCase,
  })  : _getResumenCrediticioUseCase = getResumenCrediticioUseCase;

  ResumenCrediticio? resumen;
  bool loading = false;
  String? error;


  Future<void> fetchResumen(int conductorId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      resumen = await _getResumenCrediticioUseCase(conductorId);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }
}
