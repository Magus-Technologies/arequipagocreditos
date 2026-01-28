import 'package:arequipagocreditos/presentation/components/components.dart';
import 'package:arequipagocreditos/presentation/pages/pages.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MainModules extends StatelessWidget {
  const MainModules({super.key});

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Servicios Principales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Grid de módulos 2x1 más grandes y atractivos
          Row(
            children: [
              // Beneficios
              Expanded(
                child: SizedBox(
                  height: 160,
                  child: ModuleCard(
                    icon: Icons.analytics,
                    title: 'Beneficios',
                    backgroundColor: const Color(0xFF1F2937), // Negro elegante
                    iconColor: Colors.white,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BeneficiosPage(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Cupones
              Expanded(
                child: SizedBox(
                  height: 160,
                  child: ModuleCard(
                    icon: Icons.card_giftcard,
                    title: 'Cupones',
                    backgroundColor: AppTheme.primary, // Amarillo corporativo
                    iconColor: Colors.black87, // Texto negro sobre amarillo
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CuponesPage(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Indicador de "Próximamente más servicios"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upcoming, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Próximamente más servicios',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
