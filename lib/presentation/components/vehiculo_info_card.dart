import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/presentation/components/components.dart';
import 'package:arequipagocreditos/presentation/components/edit_vehiculo_modal.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';

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
                onPressed: () async {
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

                  final saved = await showModalBottomSheet<bool?>(
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

                  // Si el modal devolvió true (guardado), mostrar alertas si aplica
                  if (saved == true) {
                    // El widget pudo haberse desmontado mientras el modal estaba abierto.
                    // Verificar mounted antes de buscar ancestros o mostrar diálogos.
                    if (!context.mounted) return;

                    // Prefer server-provided alerts; si no existen, fallback al cálculo cliente
                    final authProvider = context.read<AuthProvider>();
                    final server = await authProvider.getServerDocumentAlerts();
                    List<String> expired = server['expired'] ?? [];
                    List<String> near = server['near'] ?? [];

                    if (expired.isEmpty && near.isEmpty) {
                      expired = authProvider.getExpiredVehicleDocuments();
                      near = authProvider.getNearExpiryVehicleDocuments(7);
                    }

                    if (expired.isNotEmpty || near.isNotEmpty) {
                      final parts = <String>[];
                      if (expired.isNotEmpty) parts.add('Vencidos: ${expired.join(', ')}');
                      if (near.isNotEmpty) parts.add('A vencer en los próximos 7 días: ${near.join(', ')}');
                      // Volver a comprobar mounted justo antes de mostrar el diálogo
                      if (!context.mounted) return;
                      showDialog<void>(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) => AlertDialog(
                          title: const Text('Aviso de documentos'),
                          content: Text(parts.join('\n')),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                          ],
                        ),
                      );
                    }
                  }
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
