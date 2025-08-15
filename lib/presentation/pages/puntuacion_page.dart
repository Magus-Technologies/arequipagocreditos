import 'package:arequipagocreditos/data/models/puntuacion_model.dart';
import 'package:arequipagocreditos/presentation/components/historial_card.dart';
import 'package:arequipagocreditos/presentation/components/proximo_nivel_card.dart';
import 'package:arequipagocreditos/presentation/components/puntaje_card.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/services/api_service.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:provider/provider.dart';

class PuntuacionPage extends StatefulWidget {
  const PuntuacionPage({super.key});

  @override
  State<PuntuacionPage> createState() => _PuntuacionPageState();
}

class _PuntuacionPageState extends State<PuntuacionPage>
    with TickerProviderStateMixin {
  PuntuacionModel? _puntuacion;
  List<HistorialPuntosModel> _historial = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final puntuacion = await ApiService.getPuntuacionCredito();
      final historial = await ApiService.getHistorialPuntos();

      setState(() {
        _puntuacion = puntuacion;
        _historial = historial;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar los datos de puntuación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary,
              AppTheme.primary.withAlpha((0.8 * 255).toInt()),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header moderno
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // AppBar personalizado
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black87,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Puntaje Crediticio',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.3 * 255).toInt()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: authProvider.isLoading 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh,
                                      color: Colors.black87,
                                      size: 20,
                                    ),
                                onPressed: authProvider.isLoading ? null : _loadData,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Contenido principal
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Cargando puntaje...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_puntuacion == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay datos de puntuación',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'No se pudieron cargar los datos de tu puntuación crediticia.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PuntajeCard(puntuacion: _puntuacion!, scaleAnimation: _scaleAnimation),
            const SizedBox(height: 20),
            ProximoNivelCard(puntuacion: _puntuacion!),
            const SizedBox(height: 20),
            HistorialCard(historial: _historial),
          ],
        ),
      ),
    );
  }
}
