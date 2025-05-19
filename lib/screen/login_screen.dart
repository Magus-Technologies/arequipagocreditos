import 'package:arequipagocreditos/components/components.dart';
import 'package:arequipagocreditos/screen/change_password_screen.dart';
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
            ],
          ),
        ),
      ),
    );
  }
}
