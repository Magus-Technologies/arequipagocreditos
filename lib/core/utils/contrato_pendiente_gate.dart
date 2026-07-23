import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/financiamiento_entity.dart';
import '../../presentation/pages/signature/firma_documento_page.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/financiamiento_provider.dart';

class ContratoPendienteGate {
  static bool _dialogMostradoEnSesion = false;

  static FinanciamientoEntity? findContratoPendiente(List<FinanciamientoEntity> financiamientos) {
    for (final f in financiamientos) {
      if (!f.firmado &&
          f.estado.toLowerCase() == 'activo' &&
          (f.aprobado ?? 0) == 1 &&
          f.contratoUrl != null &&
          f.contratoUrl!.isNotEmpty) {
        return f;
      }
    }
    return null;
  }

  static Future<FinanciamientoEntity?> _loadPendiente(BuildContext context) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return null;
    final finProvider = context.read<FinanciamientoProvider>();
    await finProvider.loadFinanciamientos(idConductor: user.idConductor, tipo: user.tipo);
    return findContratoPendiente(finProvider.financiamientos);
  }

  static void _irAFirmar(BuildContext context, FinanciamientoEntity pendiente) {
    Navigator.push(
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
  }

  static Future<void> checkOnDashboard(BuildContext context) async {
    if (_dialogMostradoEnSesion) return;

    final pendiente = await _loadPendiente(context);
    if (pendiente == null || _dialogMostradoEnSesion) return;
    _dialogMostradoEnSesion = true;

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contrato pendiente', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Tienes un contrato pendiente por firmar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Después',
              style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _irAFirmar(context, pendiente);
            },
            child: const Text('Firmar ahora'),
          ),
        ],
      ),
    );
  }

  static Future<bool> ensureSinContratoPendiente(BuildContext context) async {
    final pendiente = await _loadPendiente(context);
    if (pendiente == null) return true;

    if (!context.mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contrato pendiente', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Tienes un contrato pendiente por firmar. Debes firmarlo antes de solicitar un nuevo servicio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _irAFirmar(context, pendiente);
            },
            child: const Text('Firmar ahora'),
          ),
        ],
      ),
    );
    return false;
  }
}
