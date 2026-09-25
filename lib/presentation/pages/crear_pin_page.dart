import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import '../components/pin_keypad.dart';

/// Flujo de creación del PIN propio de la app (estilo Yape): 4 dígitos,
/// se piden dos veces (crear + confirmar) para evitar errores de tipeo.
/// Al terminar hace `Navigator.pop(context, pin)`; si se cancela, hace pop
/// con `null`. El caller (ConfiguracionAccesoPage) es quien llama a
/// `AuthProvider.createPin(pin)` con el resultado.
class CrearPinPage extends StatefulWidget {
  const CrearPinPage({super.key});

  @override
  State<CrearPinPage> createState() => _CrearPinPageState();
}

class _CrearPinPageState extends State<CrearPinPage> {
  static const _pinLength = 4;
  String _firstPin = '';
  String _currentInput = '';
  bool _confirming = false;
  bool _error = false;

  void _onDigit(String d) {
    if (_currentInput.length >= _pinLength) return;
    setState(() {
      _error = false;
      _currentInput += d;
    });
    if (_currentInput.length == _pinLength) {
      _handleComplete();
    }
  }

  void _onDelete() {
    if (_currentInput.isEmpty) return;
    setState(() => _currentInput = _currentInput.substring(0, _currentInput.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!_confirming) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _firstPin = _currentInput;
        _currentInput = '';
        _confirming = true;
      });
      return;
    }

    if (_currentInput == _firstPin) {
      final pin = _firstPin;
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) Navigator.pop(context, pin);
    } else {
      setState(() {
        _error = true;
        _currentInput = '';
        _confirming = false;
        _firstPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Logo de la app (mismo del login) sobre un badge amarillo de marca.
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha((0.16 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset('images/credigo_inicio.svg', height: 62),
              ),
              const SizedBox(height: 18),
              Text(
                _confirming ? 'Confirma tu PIN' : 'Crea tu PIN',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                _error
                    ? 'Los PIN no coinciden, intenta de nuevo'
                    : (_confirming
                        ? 'Ingresa nuevamente los mismos $_pinLength dígitos'
                        : 'Elige $_pinLength dígitos para tu ingreso rápido. Es un PIN propio de la app, no el del celular.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _error ? Colors.red : Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              PinDots(length: _pinLength, filled: _currentInput.length, error: _error),
              const Spacer(),
              PinKeypad(onDigit: _onDigit, onDelete: _onDelete),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
