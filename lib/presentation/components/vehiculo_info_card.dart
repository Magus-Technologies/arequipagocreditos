import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/presentation/components/components.dart';
import 'package:arequipagocreditos/presentation/components/edit_vehiculo_modal.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';

class VehiculoInfoCard extends StatelessWidget {
  final ConductorModel? conductor;

  const VehiculoInfoCard({
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
              Expanded(
                child: Text(
                  'Datos de Vehículo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  final initial = {
                    'placa': conductor?.placa,
                    'soat': conductor?.soat,
                    'revision_tecnica': conductor?.revisionTecnica,
                    'seguro_vehicular': conductor?.seguroVehicular,
                    'color': conductor?.color,
                    'anio': conductor?.anio,
                    'marca': conductor?.marca,
                    'modelo': conductor?.modelo,
                  };

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: EditVehiculoModal(initialData: initial),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          InfoItem(
            icon: Icons.directions_car,
            label: 'Placa',
            value: conductor?.placa ?? 'No disponible',
          ),
          _buildDivider(),
          InfoItem(
            icon: Icons.description,
            label: 'SOAT',
            value: conductor?.soat ?? 'No disponible',
          ),
          _buildDivider(),
          InfoItem(
            icon: Icons.location_on,
            label: 'Revisión Técnica',
            value: conductor?.revisionTecnica ?? 'No disponible',
          ),
          _buildDivider(),
          InfoItem(
            icon: Icons.badge,
            label: 'Seguro Vehicular',
            value: conductor?.seguroVehicular ?? 'No disponible',
          ),
          _buildDivider(),
          InfoItem(
            icon: Icons.color_lens,
            label: 'Color',
            value: conductor?.color ?? 'No disponible',
          ),
          _buildDivider(),
          InfoItem(
            icon: Icons.calendar_today,
            label: 'Año',
            value: conductor?.anio?.toString() ?? 'No disponible',
          ),
          _buildDivider(),
          InfoItem(
            icon: Icons.build,
            label: 'Marca',
            value: conductor?.marca ?? 'No disponible',
          ),
          _buildDivider(),
          InfoItem(
            icon: Icons.model_training,
            label: 'Modelo',
            value: conductor?.modelo ?? 'No disponible',
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
