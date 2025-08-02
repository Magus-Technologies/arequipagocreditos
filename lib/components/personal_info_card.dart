import 'package:flutter/material.dart';
import 'package:arequipagocreditos/components/components.dart';
import 'package:arequipagocreditos/models/conductor_model.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';

class PersonalInfoCard extends StatelessWidget {
  final Conductor? conductor;

  const PersonalInfoCard({
    super.key,
    required this.conductor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InfoItem(
            icon: Icons.phone,
            label: 'Teléfono',
            value: conductor?.telefono ?? 'No disponible',
          ),
          _buildDivider(),
          InfoItem(
            icon: Icons.email,
            label: 'Correo',
            value: conductor?.correo ?? 'No disponible',
          ),
          _buildDivider(),
          InfoItem(
            icon: Icons.location_on,
            label: 'Dirección',
            value: conductor?.direccion ?? 'No disponible',
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: Colors.grey.shade300, thickness: 1),
    );
  }
}
