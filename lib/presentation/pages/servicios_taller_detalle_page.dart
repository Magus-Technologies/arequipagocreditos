import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/contrato_pendiente_gate.dart';
import '../../data/models/taller_model.dart';
import '../providers/financiamiento_servicio_provider.dart';
import '../providers/auth_provider.dart';
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
  bool _horarioExpanded = false;
  late double _localPromedio;
  late int _localTotal;

  static const _diasOrden = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
  static const _diasLabels = {
    'lunes': 'Lunes',
    'martes': 'Martes',
    'miercoles': 'Miércoles',
    'jueves': 'Jueves',
    'viernes': 'Viernes',
    'sabado': 'Sábado',
    'domingo': 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _localPromedio = widget.taller.promedioCalificacion;
    _localTotal = widget.taller.totalCalificaciones;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FinanciamientoServicioProvider>();
      final conductorId = context.read<AuthProvider>().currentUser?.idConductor;
      provider.setSelectedTaller(widget.taller);
      provider.loadBeneficiosServicios(
        tallerId: widget.taller.id,
        clienteConductorId: conductorId,
      );
      provider.setBeneficioSearchQuery('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCalificarSheet() {
    final provider = context.read<FinanciamientoServicioProvider>();
    final conductorId = context.read<AuthProvider>().currentUser?.idConductor;

    if (conductorId == null) return;

    int selectedRating = 0;
    final comentarioController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Calificar taller',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                widget.taller.nombreComercial,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFFFD700),
                        size: 44,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                selectedRating == 0
                    ? 'Toca las estrellas para calificar'
                    : ['', 'Muy malo', 'Malo', 'Regular', 'Bueno', 'Excelente'][selectedRating],
                style: TextStyle(
                  fontSize: 13,
                  color: selectedRating == 0 ? Colors.grey.shade500 : AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: comentarioController,
                decoration: InputDecoration(
                  labelText: 'Comentario (opcional)',
                  hintText: 'Cuéntanos tu experiencia...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedRating == 0
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(sheetCtx);
                          final result = await provider.calificarTaller(
                            tallerId: widget.taller.id,
                            clienteConductorId: conductorId,
                            puntuacion: selectedRating,
                            comentario: comentarioController.text.trim().isEmpty
                                ? null
                                : comentarioController.text.trim(),
                          );
                          if (!mounted) return;
                          if (result != null) {
                            setState(() {
                              _localPromedio = (result['promedio_calificacion'] as num?)?.toDouble() ?? _localPromedio;
                              _localTotal = (result['total_calificaciones'] as num?)?.toInt() ?? _localTotal;
                            });
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                result != null
                                    ? '¡Gracias por tu calificación!'
                                    : 'No se pudo enviar la calificación.',
                              ),
                              backgroundColor: result != null ? Colors.green.shade600 : Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text(
                    'Enviar calificación',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                                onPressed: () => provider.loadBeneficiosServicios(
                                  tallerId: widget.taller.id,
                                  clienteConductorId: context.read<AuthProvider>().currentUser?.idConductor,
                                ),
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
                              setState(() {});
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
                                    onRefresh: () => provider.loadBeneficiosServicios(
                                      tallerId: widget.taller.id,
                                      clienteConductorId: context.read<AuthProvider>().currentUser?.idConductor,
                                    ),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                      itemCount: servicios.length,
                                      itemBuilder: (context, index) {
                                        final servicio = servicios[index];
                                        return BeneficioServicioCard(
                                          servicio: servicio,
                                          onTap: () async {
                                            final alertas = servicio.clienteAlertas;
                                            if (alertas != null && !alertas.puedeSolicitar) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(alertas.motivoPrincipal ?? 'No puedes adquirir este servicio en este momento.'),
                                                  backgroundColor: Colors.redAccent,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              );
                                              return;
                                            }
                                            final puedeContinuar =
                                                await ContratoPendienteGate.ensureSinContratoPendiente(context);
                                            if (!puedeContinuar || !context.mounted) return;
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
    final taller = widget.taller;
    final tieneHorario = taller.horarioAtencion != null && taller.horarioAtencion!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Top row: back + name + action buttons
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
                  taller.nombreComercial,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (taller.googleMapsUrl != null && taller.googleMapsUrl!.isNotEmpty) ...[
                const SizedBox(width: 8),
                _HeaderActionButton(
                  icon: const Icon(Icons.map_outlined, color: Colors.white, size: 20),
                  backgroundColor: const Color(0xFF4285F4),
                  onTap: () => launchUrl(Uri.parse(taller.googleMapsUrl!)),
                ),
              ],
              if (taller.whatsappUrl != null && taller.whatsappUrl!.isNotEmpty) ...[
                const SizedBox(width: 8),
                _HeaderActionButton(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20),
                  backgroundColor: const Color(0xFF25D366),
                  onTap: () => launchUrl(Uri.parse(taller.whatsappUrl!)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Rating + calificar row
          _buildRatingRow(taller),
          const SizedBox(height: 10),

          // Servicios disponibles card
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

          // Horario de atención (expandable)
          if (tieneHorario) ...[
            const SizedBox(height: 10),
            _buildHorarioSection(taller.horarioAtencion!),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingRow(TallerModel taller) {
    final promedio = _localPromedio;
    final total = _localTotal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).toInt()),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha((0.3 * 255).toInt())),
      ),
      child: Row(
        children: [
          // Stars: llenas en amarillo oscuro, vacías en blanco para contrastar con fondo amarillo
          ...List.generate(5, (i) {
            final IconData icon;
            final Color color;
            if (i < promedio.floor()) {
              icon = Icons.star_rounded;
              color = const Color(0xFFE65100); // naranja oscuro — visible sobre amarillo
            } else if (i < promedio && promedio - i >= 0.5) {
              icon = Icons.star_half_rounded;
              color = const Color(0xFFE65100);
            } else {
              icon = Icons.star_outline_rounded;
              color = Colors.white70;
            }
            return Icon(icon, color: color, size: 18);
          }),
          const SizedBox(width: 6),
          Text(
            total > 0 ? '${promedio.toStringAsFixed(1)} ($total)' : 'Sin calificaciones',
            style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showCalificarSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.08 * 255).toInt()),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline_rounded, size: 15, color: Color(0xFFF9A825)),
                  SizedBox(width: 4),
                  Text(
                    'Calificar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorarioSection(Map<String, dynamic> horario) {
    return GestureDetector(
      onTap: () => setState(() => _horarioExpanded = !_horarioExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.2 * 255).toInt()),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha((0.3 * 255).toInt())),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Colors.black87, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Horario de atención',
                  style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(
                  _horarioExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.black54,
                  size: 20,
                ),
              ],
            ),
            if (_horarioExpanded) ...[
              const SizedBox(height: 10),
              ..._diasOrden.map((dia) {
                final diaData = horario[dia] as Map<String, dynamic>?;
                if (diaData == null) return const SizedBox.shrink();
                final cerrado = diaData['cerrado'] == true;
                final label = _diasLabels[dia] ?? dia;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          label,
                          style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (cerrado)
                        const Text(
                          'Cerrado',
                          style: TextStyle(color: Color(0xFFE53935), fontSize: 12),
                        )
                      else ...[
                        Text(
                          '${diaData['apertura'] ?? ''} – ${diaData['cierre'] ?? ''}',
                          style: const TextStyle(color: Colors.black87, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final Widget icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
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
        icon: icon,
        onPressed: onTap,
      ),
    );
  }
}
