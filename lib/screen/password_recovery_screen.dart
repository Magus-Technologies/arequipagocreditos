import 'package:flutter/material.dart';
import 'package:arequipagocreditos/components/components.dart';
import 'package:arequipagocreditos/services/api_service.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:arequipagocreditos/screen/reset_password_screen.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final TextEditingController _dniController = TextEditingController();
  bool _isLoading = false;

  void _validateDni() async {
    if (_dniController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor ingrese su DNI")),
      );
      return;
    }

    setState(() => _isLoading = true);

    String dni = _dniController.text.trim();
    
    Map<String, dynamic> result = await ApiService.validateDniForPasswordRecovery(dni);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      // DNI válido, navegar a la pantalla de cambio de contraseña
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(dni: dni),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "DNI no encontrado")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/logo.png', height: 150),
              const SizedBox(height: 40),
              const Text(
                'Recuperar Contraseña',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ingrese su DNI para continuar con la recuperación de contraseña',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _dniController,
                hint: 'DNI',
                icon: Icons.person,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustomButton(
                  text: "CONTINUAR",
                  isLoading: _isLoading,
                  onPressed: _validateDni,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
