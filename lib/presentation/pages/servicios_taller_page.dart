import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financiamiento_servicio_provider.dart';
import '../components/beneficio_servicio_card.dart';
import '../../theme/app_theme.dart';
import 'calculo_financiamiento_page.dart';

class ServiciosTallerPage extends StatefulWidget {
  const ServiciosTallerPage({super.key});

  @override
  State<ServiciosTallerPage> createState() => _ServiciosTallerPageState();
}

class _ServiciosTallerPageState extends State<ServiciosTallerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanciamientoServicioProvider>().loadBeneficiosServicios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios de Taller', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Consumer<FinanciamientoServicioProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.loadBeneficiosServicios(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.beneficios.isEmpty) {
            return const Center(child: Text('No hay servicios disponibles en este momento.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.beneficios.length,
            itemBuilder: (context, index) {
              final servicio = provider.beneficios[index];
              return BeneficioServicioCard(
                servicio: servicio,
                onTap: () {
                  provider.selectService(servicio);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalculoFinanciamientoPage(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
