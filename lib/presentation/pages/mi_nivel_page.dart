import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/domain/entities/nivel_taller_entity.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/nivel_taller_provider.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';

class MiNivelPage extends StatefulWidget {
  const MiNivelPage({super.key});

  @override
  State<MiNivelPage> createState() => _MiNivelPageState();
}

class _MiNivelPageState extends State<MiNivelPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final nivelProvider = Provider.of<NivelTallerProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final clienteConductorId = authProvider.currentUser?.idConductor;
    if (clienteConductorId != null) {
      await nivelProvider.cargarNivel(clienteConductorId);
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
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
                        'Mi Nivel',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    Consumer<NivelTallerProvider>(
                      builder: (context, nivelProvider, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: nivelProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                    ),
                                  )
                                : const Icon(Icons.refresh, color: Colors.black87, size: 20),
                            onPressed: nivelProvider.isLoading ? null : _loadData,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    child: Consumer<NivelTallerProvider>(
                      builder: (context, nivelProvider, child) => _buildContent(nivelProvider),
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

  Widget _buildContent(NivelTallerProvider nivelProvider) {
    if (nivelProvider.isLoading && nivelProvider.nivel == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber, strokeWidth: 3),
            SizedBox(height: 16),
            Text('Cargando tu nivel...', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    if (nivelProvider.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(nivelProvider.errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final nivel = nivelProvider.nivel;
    if (nivel == null) {
      return const Center(
        child: Text('No se pudo cargar tu nivel', style: TextStyle(color: Colors.grey)),
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
            _NivelActualCard(nivel: nivel),
            const SizedBox(height: 20),
            _ProgresoNivelCard(nivel: nivel),
            const SizedBox(height: 20),
            _TablaNivelesCard(nivel: nivel),
          ],
        ),
      ),
    );
  }
}

String _svgParaNivel(String nivel) => 'images/nivel_$nivel.svg';

String _capitalizar(String texto) => texto.isEmpty ? texto : '${texto[0].toUpperCase()}${texto.substring(1)}';

class _NivelActualCard extends StatelessWidget {
  final NivelTallerEntity nivel;

  const _NivelActualCard({required this.nivel});

  @override
  Widget build(BuildContext context) {
    final tieneNivel = nivel.tieneNivel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha((0.05 * 255).toInt()), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: tieneNivel
                ? SvgPicture.asset(_svgParaNivel(nivel.nivelActual!))
                : Icon(Icons.emoji_events_outlined, size: 72, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 12),
          Text(
            tieneNivel ? 'Nivel ${_capitalizar(nivel.nivelActual!)}' : 'Aún sin nivel',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 4),
          Text(
            '${nivel.financiamientosFinalizados} financiamientos finalizados',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          if (tieneNivel) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _PorcentajeChip(
                  etiqueta: 'Talleres',
                  porcentaje: nivel.porcentajeInicialActualPara(categoriaNivelTaller),
                ),
                _PorcentajeChip(
                  etiqueta: 'Equipos celulares',
                  porcentaje: nivel.porcentajeInicialActualPara(categoriaNivelCelular),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Completa 3 financiamientos pagados para alcanzar tu primer nivel.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

class _PorcentajeChip extends StatelessWidget {
  final String etiqueta;
  final double? porcentaje;

  const _PorcentajeChip({required this.etiqueta, required this.porcentaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha((0.15 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        porcentaje != null ? '$etiqueta: ${porcentaje!.toStringAsFixed(0)}%' : '$etiqueta: —',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      ),
    );
  }
}

class _ProgresoNivelCard extends StatelessWidget {
  final NivelTallerEntity nivel;

  const _ProgresoNivelCard({required this.nivel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha((0.05 * 255).toInt()), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(nivel.esNivelMaximo ? Icons.stars : Icons.trending_up, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                nivel.esNivelMaximo ? '¡Nivel más alto alcanzado!' : 'Siguiente nivel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nivel.esNivelMaximo
                ? 'Ya tienes la mejor inicial disponible en talleres y equipos celulares.'
                : 'Te faltan ${nivel.financiamientosFaltantes} financiamientos finalizados para llegar a ${_capitalizar(nivel.siguienteNivel!)}.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: nivel.progresoSiguienteNivel,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

class _PorcentajeColumna extends StatelessWidget {
  final double? porcentaje;
  final bool esActual;

  const _PorcentajeColumna({required this.porcentaje, required this.esActual});

  @override
  Widget build(BuildContext context) {
    return Text(
      porcentaje != null ? '${porcentaje!.toStringAsFixed(0)}%' : '—',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: esActual ? const Color(0xFF1F2937) : Colors.grey.shade700,
      ),
    );
  }
}

class _TablaNivelesCard extends StatelessWidget {
  final NivelTallerEntity nivel;

  const _TablaNivelesCard({required this.nivel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha((0.05 * 255).toInt()), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tabla de niveles',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 4),
          Text(
            'Al reducir tu inicial, aumenta el valor de tus cuotas. Talleres y equipos celulares tienen su propio rango de cuotas.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 48, bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text('Talleres', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text('Celulares', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          ...nivel.niveles.map((info) {
            final esActual = info.nivel == nivel.nivelActual;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: esActual ? AppTheme.primary.withAlpha((0.12 * 255).toInt()) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: esActual ? AppTheme.primary : Colors.grey.shade200,
                    width: esActual ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 36, height: 36, child: SvgPicture.asset(_svgParaNivel(info.nivel))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capitalizar(info.nivel),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                          ),
                          Text(
                            '${info.financiamientosRequeridos} financiamientos finalizados',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          Expanded(
                            child: _PorcentajeColumna(
                              porcentaje: info.porcentajePara(categoriaNivelTaller),
                              esActual: esActual,
                            ),
                          ),
                          Expanded(
                            child: _PorcentajeColumna(
                              porcentaje: info.porcentajePara(categoriaNivelCelular),
                              esActual: esActual,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
