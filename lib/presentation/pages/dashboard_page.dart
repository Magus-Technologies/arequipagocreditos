import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/components.dart';
import '../components/main_modules.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/actualizacion_app_gate.dart';
import '../../core/utils/contrato_pendiente_gate.dart';
import '../../core/utils/model_adapters.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // El aviso de actualizacion va primero: si es obligatorio, bloquea el uso.
      await ActualizacionAppGate.verificar(context);
      if (mounted) {
        ContratoPendienteGate.checkOnDashboard(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final conductorEntity = authProvider.currentUser;
        final conductor = conductorEntity != null 
            ? ModelAdapters.conductorEntityToModel(conductorEntity) 
            : null;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final uri = Uri.parse(
                'https://wa.me/51982934377?text=Hola,%20tengo%20una%20consulta',
              );
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo abrir WhatsApp')),
                  );
                }
              }
            },
            backgroundColor: const Color(0xFF25D366),
            tooltip: 'Contactar por WhatsApp',
            child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Header elegante - solo si conductor está cargado
                if (conductor != null)
                  Header(conductor: conductor),
                if (conductor == null)
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
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await authProvider.refreshUserDataFromRemote();
                      },
                      color: AppTheme.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            // Sección de módulos principales
                            MainModules(),
                            // Financiamientos expandible - solo si conductor está cargado
                            if (conductor != null)
                              ExpandableFinanciamientos(conductor: conductor),
                            if (conductor == null)
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
