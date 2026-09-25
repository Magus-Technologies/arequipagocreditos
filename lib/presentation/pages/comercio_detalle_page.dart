import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/contrato_pendiente_gate.dart';
import '../../domain/entities/comercio_entity.dart';
import '../components/beneficio_servicio_card.dart';
import '../providers/auth_provider.dart';
import '../providers/financiamiento_servicio_provider.dart';
import '../../theme/app_theme.dart';
import 'calculo_financiamiento_page.dart';

/// TK-0314 — COMERCIOS GO: servicios de un comercio afiliado.
///
/// Es el equivalente de ServiciosTallerDetallePage. El backend devuelve el
/// mismo contrato para los dos, así que se reutiliza la misma tarjeta de
/// servicio y el mismo flujo de solicitud (cálculo de financiamiento).
class ComercioDetallePage extends StatefulWidget {
  final ComercioEntity comercio;

  const ComercioDetallePage({super.key, required this.comercio});

  @override
  State<ComercioDetallePage> createState() => _ComercioDetallePageState();
}

class _ComercioDetallePageState extends State<ComercioDetallePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FinanciamientoServicioProvider>();
      final conductorId = context.read<AuthProvider>().currentUser?.idConductor;
      provider.loadBeneficiosServicios(
        comercioId: widget.comercio.id,
        clienteConductorId: conductorId,
      );
      provider.setBeneficioSearchQuery('');
    });
  }

  Future<void> _abrir(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _solicitar(dynamic servicio) async {
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

    final puedeContinuar = await ContratoPendienteGate.ensureSinContratoPendiente(context);
    if (!puedeContinuar || !mounted) return;

    context.read<FinanciamientoServicioProvider>().selectService(servicio);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalculoFinanciamientoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comercio = widget.comercio;
    final titulo = comercio.nombreComercial?.isNotEmpty == true
        ? comercio.nombreComercial!
        : comercio.razonSocial;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCabecera(comercio, titulo),
          Expanded(
            child: Consumer<FinanciamientoServicioProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return _buildMensaje(provider.error!, Icons.error_outline, Colors.redAccent);
                }

                final servicios = provider.beneficios;
                if (servicios.isEmpty) {
                  return _buildMensaje(
                    'Este comercio todavía no tiene servicios disponibles.',
                    Icons.storefront_outlined,
                    Colors.grey,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: servicios.length,
                  itemBuilder: (context, index) {
                    final servicio = servicios[index];
                    return BeneficioServicioCard(
                      servicio: servicio,
                      onTap: () => _solicitar(servicio),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabecera(ComercioEntity comercio, String titulo) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: comercio.logo != null && comercio.logo!.isNotEmpty
                ? Image.network(
                    comercio.logo!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _logoPlaceholder(),
                  )
                : _logoPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                if (comercio.categoriaNombre != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      comercio.categoriaNombre!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                if (comercio.direccion != null && comercio.direccion!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            comercio.direccion!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (comercio.whatsappUrl != null && comercio.whatsappUrl!.isNotEmpty)
                      _accion(Icons.chat_bubble_outline, 'WhatsApp', () => _abrir(comercio.whatsappUrl)),
                    if (comercio.googleMapsUrl != null && comercio.googleMapsUrl!.isNotEmpty)
                      _accion(Icons.map_outlined, 'Cómo llegar', () => _abrir(comercio.googleMapsUrl)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppTheme.primary.withAlpha((0.15 * 255).toInt()),
      child: const Icon(Icons.storefront, color: Colors.black54),
    );
  }

  Widget _accion(IconData icono, String texto, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icono, size: 14, color: Colors.black87),
              const SizedBox(width: 4),
              Text(texto, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMensaje(String texto, IconData icono, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 44, color: color.withAlpha((0.6 * 255).toInt())),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
