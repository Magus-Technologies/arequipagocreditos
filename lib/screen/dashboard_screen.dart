import 'package:arequipagocreditos/models/conductor_model.dart';
import 'package:arequipagocreditos/screen/financiamineto_screen.dart';
import 'package:arequipagocreditos/screen/perfil_screen.dart';
import 'package:arequipagocreditos/services/api_service.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Conductor? _conductor;

  @override
  void initState() {
    super.initState();
    _loadConductor();
  }

  void _loadConductor() async {
    Conductor? conductor = await ApiService.getLoggedUser();
    setState(() {
      _conductor = conductor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        title: Row(
          children: [
            Image.asset('images/logo.png', height: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _conductor != null
                    ? 'Hola, ${_conductor!.nombres}'
                    : 'Hola, Cargando...',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow:
                    TextOverflow
                        .ellipsis, // Agrega puntos suspensivos si es muy largo
                maxLines: 1, // Limita a una línea
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PerfilScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financiamientos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _conductor == null
                ? const Center(
                  child: CircularProgressIndicator(),
                ) // Muestra cargando
                : Expanded(
                  child: FinanciamientoList(
                    idConductor: _conductor?.idConductor ?? 0,
                    tipo: _conductor?.tipo ?? 1,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
