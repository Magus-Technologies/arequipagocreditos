import 'package:arequipagocreditos/components/components.dart';
import 'package:arequipagocreditos/screen/change_password_screen.dart';
import 'package:arequipagocreditos/screen/password_recovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/services/api_service.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:arequipagocreditos/models/conductor_model.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isTestingConnection = false;

  void _testConnection() async {
    setState(() => _isTestingConnection = true);

    final result = await ApiService.testConnection();

    if (!mounted) return;

    setState(() => _isTestingConnection = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
        action: result['success'] ? null : SnackBarAction(
          label: 'Ver detalles',
          textColor: Colors.white,
          onPressed: () {
            _showConnectionDetails(result);
          },
        ),
      ),
    );
  }

  void _showConnectionDetails(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Conexión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL: ${result['url']}'),
            const SizedBox(height: 8),
            Text('Estado: ${result['success'] ? 'Exitoso' : 'Fallido'}'),
            const SizedBox(height: 8),
            Text('Mensaje: ${result['message']}'),
            if (result['status'] != null) ...[
              const SizedBox(height: 8),
              Text('Código HTTP: ${result['status']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _login() async {
    setState(() => _isLoading = true);

    String dni = _dniController.text.trim();
    String password = _passwordController.text.trim();

    Conductor? conductor = await ApiService.login(dni, password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (conductor != null) {
      if (conductor.flag == 1) {
        _showPasswordChangeDialog();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Credenciales incorrectas")));
    }
  }

  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Cambio de contraseña"),
            content: const Text(
              "Debes cambiar tu contraseña antes de continuar.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Redirigir a pantalla de cambio de contraseña
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen(),
                    ),
                  );
                },
                child: const Text("Aceptar"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/logo.png', height: 150),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _dniController,
                hint: 'DNI',
                icon: Icons.person,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                hint: 'Contraseña',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustomButton(
                  text: "INICIAR SESIÓN",
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PasswordRecoveryScreen(),
                    ),
                  );
                },
                child: const Text(
                  "¿Olvidó su contraseña?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Botón de prueba de conectividad
              // TextButton.icon(
              //   onPressed: _isTestingConnection ? null : _testConnection,
              //   icon: _isTestingConnection 
              //     ? const SizedBox(
              //         width: 16, 
              //         height: 16, 
              //         child: CircularProgressIndicator(
              //           strokeWidth: 2, 
              //           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              //         ),
              //       )
              //     : const Icon(Icons.wifi_find, color: Colors.white),
              //   label: Text(
              //     _isTestingConnection ? "Probando..." : "Probar Conexión",
              //     style: const TextStyle(
              //       color: Colors.white,
              //       fontSize: 14,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
