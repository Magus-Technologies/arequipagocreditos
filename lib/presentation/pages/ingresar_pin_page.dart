import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../components/pin_keypad.dart';
import '../providers/auth_provider.dart';
import 'main_shell_page.dart';
import 'login_page.dart';

/// Pantalla de acceso rápido: PIN propio de la app + biometría (huella/Face
/// ID) cuando está configurada. La usa:
///  - el bloqueo de acceso al abrir el app / volver del segundo plano
///    (`AppWrapper` en main.dart), y
///  - LoginPage cuando `accessPinEnabled && hasPinConfigured`.
/// Con biometría configurada se ofrece primero (estilo Yape) y el PIN queda
/// como alternativa; al revés, se muestra directo el teclado del PIN.
class IngresarPinPage extends StatefulWidget {
  const IngresarPinPage({super.key});

  @override
  State<IngresarPinPage> createState() => _IngresarPinPageState();
}

class _IngresarPinPageState extends State<IngresarPinPage> {
  static const _pinLength = 4;
  String _input = '';
  bool _error = false;
  bool _checking = false;
  String? _message;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometric());
  }

  /// Si hay biometría configurada, se ofrece de una (estilo Yape): si el
  /// usuario cancela o falla, queda el teclado del PIN.
  Future<void> _checkBiometric() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loadBiometricCredentialsStatus();
    await authProvider.loadAccessMethodPrefs();
    if (!mounted) return;

    final usaBiometria = authProvider.hasBiometricCredentials &&
        (authProvider.accessFaceEnabled || authProvider.accessFingerprintEnabled);
    if (!usaBiometria) return;

    final canAuth = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    if (!mounted) return;
    setState(() => _biometricAvailable = canAuth);
    if (canAuth) _unlockWithBiometrics();
  }

  Future<void> _unlockWithBiometrics() async {
    final authProvider = context.read<AuthProvider>();
    final estabaBloqueado = authProvider.isLocked;
    final ok = await authProvider.loginWithBiometrics(_localAuth);
    if (!mounted || !ok) return;
    if (estabaBloqueado) {
      // El wrapper raíz ya muestra el shell al desbloquearse.
      authProvider.unlock();
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShellPage()));
    }
  }

  Future<void> _onDigit(String d) async {
    if (_checking || _input.length >= _pinLength) return;
    setState(() {
      _error = false;
      _input += d;
    });
    if (_input.length == _pinLength) {
      await _verify();
    }
  }

  void _onDelete() {
    if (_checking || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _goToLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Future<void> _verify() async {
    setState(() => _checking = true);
    final authProvider = context.read<AuthProvider>();
    final estabaBloqueado = authProvider.isLocked;
    final result = await authProvider.loginWithPin(_input);

    if (!mounted) return;

    switch (result) {
      case PinLoginResult.success:
        if (estabaBloqueado) {
          // Desbloqueo del bloqueo de acceso: el wrapper raíz muestra el shell.
          authProvider.unlock();
          break;
        }
        final user = authProvider.currentUser;
        if (user != null && user.flag == 1) {
          _showPasswordChangeDialog();
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShellPage()));
        }
        break;
      case PinLoginResult.wrongPin:
        setState(() {
          _error = true;
          _input = '';
          _checking = false;
        });
        break;
      case PinLoginResult.lockedOut:
        setState(() {
          _message = 'Superaste el número de intentos. Ingresa tu contraseña para continuar.';
          _checking = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _goToLogin();
        break;
      case PinLoginResult.noCredentials:
        setState(() {
          _message = 'No se pudo verificar tu sesión. Inicia sesión nuevamente.';
          _checking = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _goToLogin();
        break;
    }
  }

  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cambio de Contraseña Requerido'),
        content: const Text('Para continuar, necesitas cambiar tu contraseña por una nueva.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToLogin();
            },
            child: const Text('Cambiar Contraseña'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dni = context.watch<AuthProvider>().currentUser?.nroDocumento;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
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
              const Text(
                'Ingresa tu PIN',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              if (dni != null) ...[
                const SizedBox(height: 4),
                Text('DNI: $dni', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
              const SizedBox(height: 28),
              PinDots(length: _pinLength, filled: _input.length, error: _error),
              if (_error) ...[
                const SizedBox(height: 8),
                const Text('PIN incorrecto', style: TextStyle(fontSize: 12, color: Colors.red)),
              ],
              const Spacer(),
              if (_checking)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                )
              else
                PinKeypad(onDigit: _onDigit, onDelete: _onDelete, enabled: !_checking),
              const SizedBox(height: 8),
              if (_biometricAvailable)
                TextButton.icon(
                  onPressed: _checking ? null : _unlockWithBiometrics,
                  icon: const Icon(Icons.fingerprint, size: 20, color: Colors.black87),
                  label: const Text('Usar huella / Face ID', style: TextStyle(color: Colors.black87)),
                ),
              TextButton(
                onPressed: _checking ? null : _goToLogin,
                child: const Text('Usar mi contraseña'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
