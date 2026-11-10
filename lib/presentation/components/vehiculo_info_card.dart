import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/presentation/components/edit_vehiculo_modal.dart';
import 'package:arequipagocreditos/presentation/components/info_item.dart';
import 'package:arequipagocreditos/presentation/components/perfil_seccion_card.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';

class VehiculoInfoCard extends StatelessWidget {
  final ConductorModel? conductor;

  const VehiculoInfoCard({
    super.key,
    required this.conductor,
  });

  Future<void> _editar(BuildContext context) async {
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
  }

  /// Dos datos lado a lado (el vehículo tiene muchos datos cortos: así ocupan la mitad de alto).
  Widget _par(Widget izquierda, [Widget? derecha]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: izquierda),
        const SizedBox(width: 12),
        Expanded(child: derecha ?? const SizedBox.shrink()),
      ],
    );
  }

  /// Un documento del vehículo: su fecha de vencimiento y, a la derecha, si está vigente, por vencer o vencido.
  Widget _documento({required IconData icon, required String label, required String? valor}) {
    final estado = estadoVencimiento(valor);

    return InfoItem(
      icon: icon,
      label: label,
      value: fechaLegible(valor),
      trailing: estado == null ? null : EtiquetaVencimiento(estado: estado),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PerfilSeccionCard(
      titulo: 'Datos del vehículo',
      icono: Icons.directions_car_outlined,
      trailing: TextButton.icon(
        onPressed: () => _editar(context),
        icon: const Icon(Icons.edit_outlined, size: 17),
        label: const Text('Editar'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.black87,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      children: [
        _par(
          InfoItem(icon: Icons.pin_outlined, label: 'Placa', value: conductor?.placa ?? InfoItem.sinDato),
          InfoItem(icon: Icons.sell_outlined, label: 'Marca', value: conductor?.marca ?? InfoItem.sinDato),
        ),
        _par(
          InfoItem(icon: Icons.directions_car_outlined, label: 'Modelo', value: conductor?.modelo ?? InfoItem.sinDato),
          InfoItem(icon: Icons.calendar_today_outlined, label: 'Año', value: conductor?.anio?.toString() ?? InfoItem.sinDato),
        ),
        _par(
          InfoItem(icon: Icons.palette_outlined, label: 'Color', value: conductor?.color ?? InfoItem.sinDato),
        ),
        _documento(icon: Icons.verified_user_outlined, label: 'SOAT (vencimiento)', valor: conductor?.soat),
        _documento(icon: Icons.build_circle_outlined, label: 'Revisión técnica (vencimiento)', valor: conductor?.revisionTecnica),
        _documento(icon: Icons.shield_outlined, label: 'Seguro vehicular (vencimiento)', valor: conductor?.seguroVehicular),
      ],
    );
  }
}
