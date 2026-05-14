import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/taller_model.dart';
import '../providers/financiamiento_servicio_provider.dart';
import '../components/beneficio_servicio_card.dart';
import '../../theme/app_theme.dart';
import 'calculo_financiamiento_page.dart';
import '../components/beneficios_search_bar.dart';

class ServiciosTallerDetallePage extends StatefulWidget {
  final TallerModel taller;

  const ServiciosTallerDetallePage({
    super.key,
    required this.taller,
  });

  @override
  State<ServiciosTallerDetallePage> createState() => _ServiciosTallerDetallePageState();
}

class _ServiciosTallerDetallePageState extends State<ServiciosTallerDetallePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FinanciamientoServicioProvider>();
      provider.loadBeneficiosServicios(tallerId: widget.taller.id);
      provider.setBeneficioSearchQuery('');
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
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Error al cargar servicios',
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.error!,
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => provider.loadBeneficiosServicios(tallerId: widget.taller.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.black87,
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        );
                      }

                      final servicios = provider.filteredBeneficios;

                      return Column(
                        children: [
                          BeneficiosSearchBar(
                            controller: _searchController,
                            searchQuery: _searchController.text,
                            onChanged: (value) {
                              setState(() {}); // Re-build to update search icon visibility
                              provider.setBeneficioSearchQuery(value);
                            },
                            onClear: () {
                              _searchController.clear();
                              setState(() {});
                              provider.setBeneficioSearchQuery('');
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Encontrados ${servicios.length} servicios',
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
                            child: servicios.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No se encontraron servicios',
                                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () => provider.loadBeneficiosServicios(tallerId: widget.taller.id),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                      itemCount: servicios.length,
                                      itemBuilder: (context, index) {
                                        final servicio = servicios[index];
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.taller.nombreComercial,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.taller.googleMapsUrl != null && widget.taller.googleMapsUrl!.isNotEmpty) ...[
                const SizedBox(width: 8),
                _HeaderActionButton(
                  icon: Icons.map_outlined,
                  color: Colors.white,
                  backgroundColor: const Color(0xFF4285F4),
                  onTap: () => launchUrl(Uri.parse(widget.taller.googleMapsUrl!)),
                ),
              ],
              if (widget.taller.whatsappUrl != null && widget.taller.whatsappUrl!.isNotEmpty) ...[
                const SizedBox(width: 8),
                _HeaderActionButton(
                  icon: FontAwesomeIcons.whatsapp,
                  color: Colors.white,
                  backgroundColor: const Color(0xFF25D366),
                  onTap: () => launchUrl(Uri.parse(widget.taller.whatsappUrl!)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha((0.3 * 255).toInt()), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.3 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.build, color: Colors.black87, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Servicios disponibles',
                        style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Selecciona un servicio para financiarlo',
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

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withAlpha((0.3 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
      ),
    );
  }
}
