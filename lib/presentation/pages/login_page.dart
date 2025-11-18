import 'package:arequipagocreditos/presentation/pages/pages.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(
        _dniController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  String? _validateDni(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su DNI';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'El DNI solo debe contener números';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su contraseña';
    }
    if (value.length < 3) {
      return 'La contraseña debe tener al menos 3 caracteres';
    }
    return null;
  }

  void _showPasswordChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Cambio de Contraseña Requerido'),
            content: const Text(
              'Para continuar, necesitas cambiar tu contraseña por una nueva.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PasswordRecoveryPage(),
                    ),
                  );
                },
                child: const Text('Cambiar Contraseña'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // altura del teclado (0 si no está visible)
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Manejar navegación después del login exitoso
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (authProvider.isAuthenticated &&
                authProvider.currentUser != null) {
              final user = authProvider.currentUser!;
              if (user.flag == 1) {
                _showPasswordChangeDialog(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardPage(),
                  ),
                );
              }
            }
            if (authProvider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authProvider.errorMessage!),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
              authProvider.clearError();
            }
          });

          return AnimatedPadding(
            // Empuja todo hacia arriba cuando aparece el teclado para evitar overflow
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        // Permite desplazar el formulario si la pantalla queda pequeña
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 8),
                            Image.asset('images/logo.png', height: 150),
                            const SizedBox(height: 40),
                            TextFormField(
                              controller: _dniController,
                              keyboardType: TextInputType.number,
                              maxLength: 15,
                              validator: _validateDni,
                              decoration: const InputDecoration(
                                hintText: 'DNI',
                                prefixIcon: Icon(Icons.person),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: _validatePassword,
                              decoration: InputDecoration(
                                hintText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    authProvider.isLoading
                                        ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                      Colors.white,
                                                    ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Iniciando sesión...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                        : const Text(
                                          'INICIAR SESIÓN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const Spacer(),
                                TextButton(
                                  onPressed:
                                      authProvider.isLoading
                                          ? null
                                          : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const PasswordRecoveryPage(),
                                              ),
                                            );
                                          },
                                  child: const Text(
                                    "¿Olvidó su contraseña?",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Crédito visible pero discreto (pill encima del botón WhatsApp)
                            InkWell(
                              onTap: () async {
                                final url = Uri.parse('https://magustechnologies.com/');
                                if (!await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                )) {
                                  throw Exception('Could not launch $url');
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.code, size: 14, color: Colors.black54),
                                    SizedBox(width: 8),
                                    Text(
                                      'Desarrollado por ',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'MagusTechnologies',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 80), // Espacio para evitar colisión con WhatsApp
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Botón de WhatsApp fijo abajo
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24, // AnimatedPadding ya empuja todo cuando hay teclado
                  child: Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 2,
                      ),
                      icon: const FaIcon(FontAwesomeIcons.whatsapp),
                      label: const Text(
                        'Contáctame por WhatsApp',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () async {
                        final url = Uri.parse(
                          'https://wa.me/51982934377?text=Hola,%20tengo%20una%20consulta',
                        );
                        if (!await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        )) {
                          throw Exception('Could not launch $url');
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}