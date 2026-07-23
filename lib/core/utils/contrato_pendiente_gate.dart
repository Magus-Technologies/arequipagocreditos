import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/financiamiento_entity.dart';
import '../../presentation/pages/signature/firma_documento_page.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/financiamiento_provider.dart';

class ContratoPendienteGate {
  static bool _dialogMostradoEnSesion = false;

  static List<FinanciamientoEntity> findContratosPendientes(List<FinanciamientoEntity> financiamientos) {
    return financiamientos
        .where((f) =>
            !f.firmado &&
            f.estado.toLowerCase() == 'activo' &&
            (f.aprobado ?? 0) == 1 &&
            f.contratoUrl != null &&
            f.contratoUrl!.isNotEmpty)
        .toList();
  }

  static FinanciamientoEntity? findContratoPendiente(List<FinanciamientoEntity> financiamientos) {
    final pendientes = findContratosPendientes(financiamientos);
    return pendientes.isEmpty ? null : pendientes.first;
  }

  static Future<List<FinanciamientoEntity>> _loadPendientes(BuildContext context) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return [];
    final finProvider = context.read<FinanciamientoProvider>();
    await finProvider.loadFinanciamientos(idConductor: user.idConductor, tipo: user.tipo);
    return findContratosPendientes(finProvider.financiamientos);
  }

  static String _mensaje(int cantidad, {required bool esGate}) {
    final base = cantidad == 1
        ? 'Tienes un contrato pendiente por firmar.'
        : 'Tienes $cantidad contratos pendientes por firmar.';
    if (!esGate) return base;
    return cantidad == 1
        ? '$base Debes firmarlo antes de solicitar un nuevo servicio.'
        : '$base Debes firmarlos antes de solicitar un nuevo servicio.';
  }

  static Future<bool> _mostrarDialog(
    BuildContext context, {
    required int cantidad,
    required bool esGate,
  }) async {
    final firmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_edu, color: Colors.orange.shade800, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Contrato pendiente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _mensaje(cantidad, esGate: esGate),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Firmar ahora', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                esGate ? 'Cancelar' : 'Después',
                style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
    return firmar == true;
  }

  static Future<void> _cicloDialogos(
    BuildContext context, {
    required List<FinanciamientoEntity> pendientesIniciales,
    required bool esGate,
  }) async {
    var pendientes = pendientesIniciales;
    while (pendientes.isNotEmpty) {
      if (!context.mounted) return;
      final firmar = await _mostrarDialog(context, cantidad: pendientes.length, esGate: esGate);
      if (!firmar || !context.mounted) return;

      final pendiente = pendientes.first;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FirmaDocumentoPage(
            title: 'Contrato de Financiamiento',
            pdfUrl: pendiente.contratoUrl!,
            tipo: 'contrato',
            id: pendiente.idFinanciamiento,
          ),
        ),
      );

      if (!context.mounted) return;
      pendientes = await _loadPendientes(context);
    }
  }

  static Future<void> checkOnDashboard(BuildContext context) async {
    if (_dialogMostradoEnSesion) return;

    final pendientes = await _loadPendientes(context);
    if (pendientes.isEmpty || _dialogMostradoEnSesion) return;
    _dialogMostradoEnSesion = true;

    if (!context.mounted) return;
    await _cicloDialogos(context, pendientesIniciales: pendientes, esGate: false);
  }

  static Future<bool> ensureSinContratoPendiente(BuildContext context) async {
    final pendientes = await _loadPendientes(context);
    if (pendientes.isEmpty) return true;

    if (!context.mounted) return false;
    await _cicloDialogos(context, pendientesIniciales: pendientes, esGate: true);
    return false;
  }
}
