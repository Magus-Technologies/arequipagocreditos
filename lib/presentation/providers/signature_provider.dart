import 'package:flutter/material.dart';
import '../../domain/usecases/signature_usecases.dart';

class SignatureProvider extends ChangeNotifier {
  final FirmarUseCase _firmarUseCase;

  SignatureProvider({required FirmarUseCase firmarUseCase})
      : _firmarUseCase = firmarUseCase;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> firmar({
    required String tipo,
    required int id,
    required String firmaBase64,
    required String nroDocumento,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _firmarUseCase(
      tipo: tipo,
      id: id,
      firmaBase64: firmaBase64,
      nroDocumento: nroDocumento,
    );

    _isLoading = false;
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (data) {
        notifyListeners();
        return true;
      },
    );
  }
}
