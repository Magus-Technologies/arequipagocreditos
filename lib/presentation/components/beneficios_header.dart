import 'package:flutter/material.dart';
import '../../domain/entities/beneficio_entity.dart';

class BeneficiosHeader extends StatelessWidget {
  final List<BeneficioComercialEntity> beneficiosFiltrados;
  final bool isNav;
  const BeneficiosHeader({
    super.key,
    required this.beneficiosFiltrados,
    this.isNav = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // AppBar personalizado
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.3 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: !isNav
                    ? IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black87,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
              ),
              const Expanded(
                child: Text(
                  'Beneficios Comerciales',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Espacio para balancear el título
            ],
          ),
          const SizedBox(height: 20),
          // Información de beneficios disponibles
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.3 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha((0.3 * 255).toInt()),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.5 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Beneficios',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${beneficiosFiltrados.where((b) => b.disponible).length} disponibles',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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