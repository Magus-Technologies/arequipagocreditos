import 'package:arequipagocreditos/core/utils/model_adapters.dart';
import 'package:arequipagocreditos/presentation/components/components.dart';
import 'package:arequipagocreditos/presentation/pages/pages.dart';
import 'package:arequipagocreditos/presentation/pages/servicios_taller_page.dart';
import 'package:arequipagocreditos/presentation/pages/documentos_firmados_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainModules extends StatelessWidget {
  const MainModules({super.key});

  static const double _cardHeight = 128;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final conductorEntity = authProvider.currentUser;
    final tipo = conductorEntity?.tipo ?? 0;
    final esPasajero = tipo == 4;
    final conductor = conductorEntity != null
        ? ModelAdapters.conductorEntityToModel(conductorEntity)
        : null;

    final modulos = <_ModuloConfig>[
      _ModuloConfig(
        icon: Icons.workspace_premium,
        title: 'Beneficios',
        subtitle: 'Descuentos y promociones',
        backgroundColor: const Color(0xFF1F2937),
        iconColor: Colors.white,
        page: const BeneficiosPage(),
      ),
      _ModuloConfig(
        icon: Icons.confirmation_number,
        title: 'Cupones',
        subtitle: 'Tus cupones disponibles',
        backgroundColor: AppTheme.primary,
        iconColor: Colors.black87,
        page: const CuponesPage(),
      ),
      if (!esPasajero)
        _ModuloConfig(
          icon: Icons.directions_car_filled,
          title: 'Servicios Taller / Repuestos',
          subtitle: 'Agenda tu servicio',
          backgroundColor: const Color(0xFF3B82F6),
          iconColor: Colors.white,
          page: const ServiciosTallerPage(),
        ),
      _ModuloConfig(
        icon: Icons.fact_check,
        title: 'Mis Documentos',
        subtitle: 'Contratos y archivos',
        backgroundColor: const Color(0xFF10B981),
        iconColor: Colors.white,
        page: const DocumentosFirmadosPage(),
      ),
      _ModuloConfig(
        icon: Icons.qr_code_2,
        title: 'Órdenes de Pago',
        subtitle: 'Códigos para Caja Arequipa',
        backgroundColor: const Color(0xFF7C3AED),
        iconColor: Colors.white,
        page: const OrdenesPagoPage(),
      ),
      _ModuloConfig(
        icon: Icons.emoji_events,
        title: 'Mi Nivel',
        subtitle: 'Bronce, Plata y Oro',
        backgroundColor: const Color(0xFFB45309),
        iconColor: Colors.white,
        page: const MiNivelPage(),
      ),
      if (conductor != null)
        _ModuloConfig(
          icon: Icons.account_balance_wallet,
          title: 'Mis Financiamientos',
          subtitle: 'Tus créditos activos',
          backgroundColor: const Color(0xFF6366F1),
          iconColor: Colors.white,
          page: MisFinanciamientosPage(conductor: conductor),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Título de la sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.dashboard, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Servicios Principales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Accede fácilmente a lo que necesitas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Grid de módulos: se reordena solo, sin dejar huecos desalineados
          for (int i = 0; i < modulos.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: _cardHeight,
                    child: modulos[i].build(context),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: i + 1 < modulos.length
                      ? SizedBox(
                          height: _cardHeight,
                          child: modulos[i + 1].build(context),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          const _WhatsAppBanner(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Banner promocional de beneficios. El contacto por WhatsApp vive aparte,
/// como botón flotante persistente en `MainShellPage` — no se duplica acá.
class _WhatsAppBanner extends StatelessWidget {
  const _WhatsAppBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha((0.18 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withAlpha((0.35 * 255).toInt())),
      ),
      child: Row(
        children: [
          Icon(Icons.stars_rounded, color: Colors.amber.shade800, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aprovecha tus beneficios exclusivos',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Conoce todo lo que tienes para ti',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuloConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color iconColor;
  final Widget page;

  const _ModuloConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.iconColor,
    required this.page,
  });

  Widget build(BuildContext context) {
    return ModuleCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}
