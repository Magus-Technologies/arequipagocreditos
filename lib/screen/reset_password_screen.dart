import 'package:flutter/material.dart';
import 'package:arequipagocreditos/components/components.dart';
import 'package:arequipagocreditos/services/api_service.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String dni;

  const ResetPasswordScreen({super.key, required this.dni});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _resetPassword() async {
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor complete todos los campos")),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La contraseña debe tener al menos 6 caracteres")),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result = await ApiService.resetPassword(widget.dni, newPassword);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success']) {
      // Mostrar mensaje de éxito y volver al login
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Contraseña restablecida"),
          content: const Text("Su contraseña ha sido restablecida exitosamente. Ahora puede iniciar sesión con su nueva contraseña."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver a recovery screen
                Navigator.of(context).pop(); // Volver a login screen
              },
              child: const Text("Aceptar"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Error al restablecer la contraseña")),
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
                'Nueva Contraseña',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'DNI: ${widget.dni}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ingrese su nueva contraseña',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _newPasswordController,
                hint: 'Nueva contraseña',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _confirmPasswordController,
                hint: 'Confirmar contraseña',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustomButton(
                  text: "RESTABLECER CONTRASEÑA",
                  isLoading: _isLoading,
                  onPressed: _resetPassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
