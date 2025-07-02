import 'package:arequipagocreditos/components/components.dart';
import 'package:arequipagocreditos/models/conductor_model.dart';
import 'package:arequipagocreditos/screen/login_screen.dart';
import 'package:arequipagocreditos/services/api_service.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _isLoading = false;
  Conductor? _conductor;

  @override
  void initState() {
    super.initState();
    _loadConductor();
  }

  Future<void> _loadConductor() async {
    Conductor? conductor = await ApiService.getLoggedUser();
    setState(() {
      _conductor = conductor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        title: const Text(
          'Perfil del Cliente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tarjeta de perfil con foto
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primary,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _conductor != null
                        ? _conductor!.nombres
                        : 'Cargando...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _conductor != null
                        ? 'DNI: ${_conductor!.nroDocumento}'
                        : '',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tarjeta de datos del cliente
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InfoItem(
                    icon: Icons.phone,
                    label: 'Teléfono',
                    value: _conductor?.telefono ?? 'No disponible',
                  ),
                  _buildDivider(),
                  InfoItem(
                    icon: Icons.email,
                    label: 'Correo',
                    value: _conductor?.correo ?? 'No disponible',
                  ),
                  _buildDivider(),
                  InfoItem(
                    icon: Icons.location_on,
                    label: 'Dirección',
                    value: _conductor?.direccion ?? 'No disponible',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botón de Cerrar Sesión
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: "Cerrar Sesión",
                isLoading: _isLoading,
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: Colors.grey.shade300, thickness: 1),
    );
  }

  void _logout(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    await ApiService.logout();

    setState(() {
      _isLoading = false;
    });
    if(!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}
