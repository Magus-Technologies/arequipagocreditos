import 'package:arequipagocreditos/core/utils/model_adapters.dart';
import 'package:arequipagocreditos/presentation/pages/cupones_page.dart';
import 'package:arequipagocreditos/presentation/pages/mi_nivel_page.dart';
import 'package:arequipagocreditos/presentation/pages/mis_financiamientos_page.dart';
import 'package:arequipagocreditos/presentation/pages/ordenes_pago_page.dart';
import 'package:arequipagocreditos/presentation/pages/perfil_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pestaña "Más" de la barra de navegación: agrupa el resto de los módulos
/// que no entran como pestaña propia (Cupones, Órdenes de Pago, Mi Nivel,
/// Mis Financiamientos) más el perfil del usuario.
class MasPage extends StatelessWidget {
  const MasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final conductorEntity = context.watch<AuthProvider>().currentUser;
    final conductor = conductorEntity != null
        ? ModelAdapters.conductorEntityToModel(conductorEntity)
        : null;

    final items = <_MasItem>[
      _MasItem(
        icon: Icons.confirmation_number,
        title: 'Cupones',
        color: AppTheme.primary,
        page: const CuponesPage(),
      ),
      _MasItem(
        icon: Icons.qr_code_2,
        title: 'Órdenes de Pago',
        color: const Color(0xFF7C3AED),
        page: const OrdenesPagoPage(),
      ),
      _MasItem(
        icon: Icons.emoji_events,
        title: 'Mi Nivel',
        color: const Color(0xFFB45309),
        page: const MiNivelPage(),
      ),
      if (conductor != null)
        _MasItem(
          icon: Icons.account_balance_wallet,
          title: 'Mis Financiamientos',
          color: const Color(0xFF6366F1),
          page: MisFinanciamientosPage(conductor: conductor),
        ),
      _MasItem(
        icon: Icons.person,
        title: 'Mi Perfil',
        color: const Color(0xFF10B981),
        page: const PerfilPage(),
      ),
    ];

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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.3 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.apps, color: Colors.black87, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Más opciones',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => items[index].build(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasItem {
  final IconData icon;
  final String title;
  final Color color;
  final Widget page;

  const _MasItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.page,
  });

  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha((0.12 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
