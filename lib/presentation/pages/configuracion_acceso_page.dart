import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'crear_pin_page.dart';

/// Pantalla "Configuración de acceso" (Más > Configuración de acceso):
/// permite activar/desactivar PIN, reconocimiento facial y huella dactilar
/// para el ingreso rápido. Los 3 metodos comparten la misma credencial
/// guardada de forma segura (DNI + contraseña en FlutterSecureStorage) — el
/// celular es quien decide, al pedir authenticate(), cual biometria usar
/// segun lo que la persona ya tenga configurado en su equipo.
class ConfiguracionAccesoPage extends StatefulWidget {
  const ConfiguracionAccesoPage({super.key});

  @override
  State<ConfiguracionAccesoPage> createState() => _ConfiguracionAccesoPageState();
}

class _ConfiguracionAccesoPageState extends State<ConfiguracionAccesoPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _loadingCapabilities = true;
  bool _deviceHasBiometrics = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    await context.read<AuthProvider>().loadAccessMethodPrefs();
    bool hasBiometrics = false;
    try {
      hasBiometrics = await _localAuth.canCheckBiometrics;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _deviceHasBiometrics = hasBiometrics;
      _loadingCapabilities = false;
    });
  }

  Future<bool> _promptPasswordAndSave(AuthProvider authProvider) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? error;
    bool checking = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Activar ingreso rápido'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta es la MISMA contraseña con la que inicias sesión en la app (no es un PIN nuevo ni el del celular). '
                  'La necesitamos una sola vez para activar el ingreso rápido de forma segura.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  autofocus: true,
                  enabled: !checking,
                  decoration: InputDecoration(
                    labelText: 'Tu contraseña de la app',
                    errorText: error,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: checking ? null : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: checking
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final dni = authProvider.currentUser?.nroDocumento;
                      if (dni == null) {
                        Navigator.pop(dialogContext, false);
                        return;
                      }
                      setDialogState(() {
                        error = null;
                        checking = true;
                      });
                      final ok = await authProvider.verifyPasswordAndPrepareBiometric(
                        dni,
                        passwordController.text,
                      );
                      if (ok) {
                        await authProvider.acceptBiometricSetup();
                        if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                      } else {
                        setDialogState(() {
                          checking = false;
                          error = 'Contraseña incorrecta. Intenta de nuevo.';
                        });
                      }
                    },
              child: checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    return confirmed ?? false;
  }

  Future<bool> _confirmWithDeviceAuth() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Confirma tu identidad para activar esta opción',
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _onToggle({
    required bool value,
    required bool Function() get,
    required Future<void> Function(bool) set,
  }) async {
    if (_busy) return;
    final authProvider = context.read<AuthProvider>();
    setState(() => _busy = true);

    try {
      if (value) {
        if (!authProvider.hasBiometricCredentials) {
          final ready = await _promptPasswordAndSave(authProvider);
          if (!ready) return;
        } else {
          final confirmed = await _confirmWithDeviceAuth();
          if (!confirmed) return;
        }
      }
      await set(value);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// El PIN es un flujo distinto al de face/huella: activar requiere crear
  /// (y confirmar) un PIN de 4 dígitos propio de la app, no solo confirmar
  /// identidad con lo que ya esté guardado.
  Future<void> _onTogglePin(bool value) async {
    if (_busy) return;
    final authProvider = context.read<AuthProvider>();
    setState(() => _busy = true);

    try {
      if (!value) {
        await authProvider.setAccessMethodEnabled(pin: false);
        return;
      }

      if (!authProvider.hasBiometricCredentials) {
        final ready = await _promptPasswordAndSave(authProvider);
        if (!ready) return;
      }

      if (!mounted) return;
      final pin = await Navigator.push<String?>(
        context,
        MaterialPageRoute(builder: (_) => const CrearPinPage()),
      );
      if (pin == null) return; // el usuario canceló la creación

      await authProvider.createPin(pin);
      await authProvider.setAccessMethodEnabled(pin: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primary.withAlpha((0.8 * 255).toInt())],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Configuración de acceso',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                      ),
                      child: _loadingCapabilities
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                Text(
                                  'Elige cómo quieres ingresar a la app. El PIN es propio de la app; el reconocimiento facial y la huella usan la biometría que ya tengas configurada en tu celular.',
                                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 20),
                                _buildToggleRow(
                                  icon: Icons.grid_3x3_rounded,
                                  color: const Color(0xFF3B82F6),
                                  title: 'PIN',
                                  subtitle: authProvider.accessPinEnabled
                                      ? 'Ingresas con un PIN de 4 dígitos propio de la app'
                                      : 'Crea un PIN de 4 dígitos para ingresar rápido',
                                  enabled: true,
                                  value: authProvider.accessPinEnabled,
                                  onChanged: _onTogglePin,
                                ),
                                _buildToggleRow(
                                  icon: Icons.face_retouching_natural,
                                  color: const Color(0xFF8B5CF6),
                                  title: 'Reconocimiento facial',
                                  subtitle: _deviceHasBiometrics
                                      ? 'Usa el reconocimiento facial de tu celular'
                                      : 'No disponible en este dispositivo',
                                  enabled: _deviceHasBiometrics,
                                  value: authProvider.accessFaceEnabled,
                                  onChanged: (v) => _onToggle(
                                    value: v,
                                    get: () => authProvider.accessFaceEnabled,
                                    set: (val) => authProvider.setAccessMethodEnabled(face: val),
                                  ),
                                ),
                                _buildToggleRow(
                                  icon: Icons.fingerprint,
                                  color: const Color(0xFF10B981),
                                  title: 'Huella dactilar',
                                  subtitle: _deviceHasBiometrics
                                      ? 'Usa tu huella dactilar'
                                      : 'No disponible en este dispositivo',
                                  enabled: _deviceHasBiometrics,
                                  value: authProvider.accessFingerprintEnabled,
                                  onChanged: (v) => _onToggle(
                                    value: v,
                                    get: () => authProvider.accessFingerprintEnabled,
                                    set: (val) => authProvider.setAccessMethodEnabled(fingerprint: val),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool enabled,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha((0.12 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Switch(
            value: value && enabled,
            onChanged: (enabled && !_busy) ? onChanged : null,
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }
}
