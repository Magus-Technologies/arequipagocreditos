import 'package:arequipagocreditos/components/components.dart';
import 'package:arequipagocreditos/components/main_modules.dart';
import 'package:arequipagocreditos/models/conductor_model.dart';
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
      backgroundColor: const Color(0xFFF8FAFC), // Cambio de color para mejor contraste
      body: SafeArea(
        child: Column(
          children: [
            // Header elegante - solo si conductor está cargado
            if (_conductor != null)
              Header(conductor: _conductor!),
            if (_conductor == null)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withAlpha((0.8 * 255).toInt()),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white.withAlpha((0.4 * 255).toInt()), width: 2),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cargando... ⏳',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Obteniendo información',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Contenido principal con scroll
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Sección de módulos principales
                      MainModules(),
                      // Financiamientos expandible - solo si conductor está cargado
                      if (_conductor != null)
                        ExpandableFinanciamientos(conductor: _conductor!),
                      if (_conductor == null)
                        Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha((0.08 * 255).toInt()),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Cargando información del usuario...',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
