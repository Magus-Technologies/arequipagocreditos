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
      backgroundColor: AppTheme.primary,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SizedBox(
                  height: 48,
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
              ),
              Expanded(
                child: Consumer<NivelTallerProvider>(
                  builder: (context, nivelProvider, child) => _buildContent(nivelProvider),
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
      return _fallbackSurface(const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber, strokeWidth: 3),
            SizedBox(height: 16),
            Text('Cargando tu nivel...', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ));
    }

    if (nivelProvider.hasError) {
      return _fallbackSurface(Center(
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
      ));
    }

    final nivel = nivelProvider.nivel;
    if (nivel == null) {
      return _fallbackSurface(const Center(
        child: Text('No se pudo cargar tu nivel', style: TextStyle(color: Colors.grey)),
      ));
    }

    return _buildNivelContent(nivel);
  }

  Widget _fallbackSurface(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }

  Widget _buildNivelContent(NivelTallerEntity nivel) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: 152,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
        ),
        Positioned.fill(
          top: 160,
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primary,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _TablaNivelesCard(nivel: nivel),
            ),
          ),
        ),
        Positioned(
          left: 20,
          top: 18,
          right: 142,
          child: _ProgresoNivelHero(nivel: nivel),
        ),
        Positioned(
          top: -7,
          right: 0,
          width: 176,
          height: 188,
          child: IgnorePointer(
            child: Image.asset(
              'images/oso_polar_nivel.png',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      ],
    );
  }
}

String _svgParaNivel(String nivel) => 'images/nivel_$nivel.svg';

String _capitalizar(String texto) => texto.isEmpty ? texto : '${texto[0].toUpperCase()}${texto.substring(1)}';

const double _anchoInsigniaNivel = 36;
const double _espacioInsigniaNivel = 12;
const double _anchoColumnasPorcentajeNivel = 120;

class _ProgresoNivelHero extends StatelessWidget {
  final NivelTallerEntity nivel;

  const _ProgresoNivelHero({required this.nivel});

  @override
  Widget build(BuildContext context) {
    final esNivelMaximo = nivel.esNivelMaximo;
    final financiamientosFaltantes = nivel.financiamientosFaltantes ?? 0;
    final objetivo = esNivelMaximo
        ? ''
        : (nivel.siguienteNivel!.toLowerCase() == 'plata' ? 'a la ' : 'al ') +
            _capitalizar(nivel.siguienteNivel!);
    final textoFinanciamientos = financiamientosFaltantes == 1
        ? ' financiamiento finalizado para llegar '
        : ' financiamientos finalizados para llegar ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xFF161616),
              fontSize: 13,
              height: 1.3,
            ),
            children: [
              if (esNivelMaximo)
                const TextSpan(
                  text: '¡Ya alcanzaste el nivel más alto!',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              if (!esNivelMaximo) ...[
                const TextSpan(text: 'Te faltan '),
                TextSpan(
                  text: financiamientosFaltantes.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: textoFinanciamientos + objetivo + '.',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 148,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: nivel.progresoSiguienteNivel,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      ],
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
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 6),
            child: Row(
              children: [
                const SizedBox(width: _anchoInsigniaNivel),
                const SizedBox(width: _espacioInsigniaNivel),
                const Expanded(child: SizedBox.shrink()),
                SizedBox(
                  width: _anchoColumnasPorcentajeNivel,
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
                    SizedBox(width: _anchoInsigniaNivel, height: _anchoInsigniaNivel, child: SvgPicture.asset(_svgParaNivel(info.nivel))),
                    const SizedBox(width: _espacioInsigniaNivel),
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
                      width: _anchoColumnasPorcentajeNivel,
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
