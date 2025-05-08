import 'package:arequipagocreditos/components/components.dart';
import 'package:arequipagocreditos/services/api_service.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  void _changePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final newPassword = _passwordController.text.trim();

    if (newPassword.isEmpty) {
      setState(() {
        _errorMessage = 'La contraseña no puede estar vacía';
        _isLoading = false;
      });
      return;
    }

    final result = await ApiService.updatePassword(newPassword);

    setState(() {
      _isLoading = false;
    });

    _showAlert(result['message'], result['success']);
  }

  void _showAlert(String message, bool success) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(success ? "Éxito" : "Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (success) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                  );
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
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
              const Text(
                'Cambia tu contraseña',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                hint: 'Nueva contraseña',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 10),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustomButton(
                  text: "Guardar contraseña",
                  isLoading: _isLoading,
                  onPressed: _changePassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
