import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financiamiento_servicio_provider.dart';
import '../components/taller_card.dart';
import '../../theme/app_theme.dart';
import 'servicios_taller_detalle_page.dart';
import '../components/beneficios_search_bar.dart';

class ServiciosTallerPage extends StatefulWidget {
  const ServiciosTallerPage({super.key});

  @override
  State<ServiciosTallerPage> createState() => _ServiciosTallerPageState();
}

class _ServiciosTallerPageState extends State<ServiciosTallerPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FinanciamientoServicioProvider>();
      provider.loadTalleres();
      provider.setTallerSearchQuery('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Consumer<FinanciamientoServicioProvider>(
                    builder: (context, provider, child) {
                      if (provider.talleresLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.talleresError != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Error al cargar talleres',
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.talleresError!,
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => provider.loadTalleres(),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black87),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        );
                      }

                      final talleres = provider.filteredTalleres;

                      return Column(
                        children: [
                          BeneficiosSearchBar(
                            controller: _searchController,
                            searchQuery: _searchController.text,
                            onChanged: (value) {
                              setState(() {});
                              provider.setTallerSearchQuery(value);
                            },
                            onClear: () {
                              _searchController.clear();
                              setState(() {});
                              provider.setTallerSearchQuery('');
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Mostrando ${talleres.length} talleres',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: talleres.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No se encontraron talleres',
                                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () => provider.loadTalleres(),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                      itemCount: talleres.length,
                                      itemBuilder: (context, index) {
                                        final taller = talleres[index];
                                        return TallerCard(
                                          taller: taller,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ServiciosTallerDetallePage(
                                                  taller: taller,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.3 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Expanded(
                child: Text(
                  'Servicios de Taller',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.3 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha((0.3 * 255).toInt()), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.5 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_repair_service, color: Colors.black87, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Talleres Disponibles',
                        style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Selecciona un taller para ver sus servicios',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
