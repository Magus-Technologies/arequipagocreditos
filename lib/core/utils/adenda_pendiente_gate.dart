import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/documento_firmado_entity.dart';
import '../../presentation/pages/signature/firma_documento_page.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/financiamiento_servicio_provider.dart';

/// TK-0355: ventana flotante de las ADENDAS pendientes de firma (Yango / InDriver).
///
/// Es la misma idea que [ContratoPendienteGate], pero la adenda se firma POR SEPARADO del contrato: lleva su propia firma
/// (`POST /app/firmar/adenda-yango|adenda-indriver/{id}`) y después aparece firmada en «Mis documentos». Al abrir el
/// dashboard, si el cliente tiene adendas por firmar, se le muestra el aviso con «Firmar ahora» (abre el PDF de la adenda y
/// el lienzo de firma) o «Después» (la sigue viendo pendiente en Mis documentos).
///
/// La lista sale de `GET /app/documentos-firmados/{id}`: las adendas pendientes traen `tipo == 'adenda'`, `firmado == false`,
/// `tipoFirma` y `adendaId`.
class AdendaPendienteGate {
  static bool _dialogMostradoEnSesion = false;

  static List<DocumentoFirmadoEntity> findPendientes(List<DocumentoFirmadoEntity> documentos) {
    return documentos
        .where((d) =>
            d.tipo == 'adenda' &&
            !d.firmado &&
            d.tipoFirma != null &&
            d.adendaId != null &&
            d.contratoUrl != null &&
            d.contratoUrl!.isNotEmpty)
        .toList();
  }

  static Future<List<DocumentoFirmadoEntity>> _loadPendientes(BuildContext context) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return [];
    final provider = context.read<FinanciamientoServicioProvider>();
    await provider.loadDocumentosFirmados(user.idConductor);
    return findPendientes(provider.documentosFirmados?.documentos ?? []);
  }

  static String _mensaje(List<DocumentoFirmadoEntity> pendientes) {
    if (pendientes.length == 1) {
      return 'Tienes una adenda pendiente por firmar:\n${pendientes.first.nombreDocumento}.';
    }
    return 'Tienes ${pendientes.length} adendas pendientes por firmar.';
  }

  static Future<bool> _mostrarDialog(BuildContext context, List<DocumentoFirmadoEntity> pendientes) async {
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
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_edu, color: Colors.deepPurple.shade400, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Adenda pendiente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _mensaje(pendientes),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Revísala y fírmala para que quede registrada. Es una firma aparte de la de tu contrato.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.4),
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
              child: const Text('Después', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    return firmar == true;
  }

  /// Muestra el aviso y, mientras el cliente acepte, lo lleva a firmar cada adenda pendiente.
  static Future<void> _cicloDialogos(BuildContext context, List<DocumentoFirmadoEntity> pendientesIniciales) async {
    var pendientes = pendientesIniciales;
    while (pendientes.isNotEmpty) {
      if (!context.mounted) return;
      final firmar = await _mostrarDialog(context, pendientes);
      if (!firmar || !context.mounted) return;

      final adenda = pendientes.first;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FirmaDocumentoPage(
            title: adenda.nombreDocumento,
            pdfUrl: adenda.contratoUrl!,
            tipo: adenda.tipoFirma!,
            id: adenda.adendaId!,
          ),
        ),
      );

      if (!context.mounted) return;
      final despues = await _loadPendientes(context);
      // Si siguen las mismas (cerró la pantalla sin firmar) no se insiste: la ve pendiente en Mis documentos.
      final mismas = despues.length == pendientes.length;
      pendientes = mismas ? <DocumentoFirmadoEntity>[] : despues;
    }
  }

  /// Al abrir el dashboard: una sola vez por sesión.
  static Future<void> checkOnDashboard(BuildContext context) async {
    if (_dialogMostradoEnSesion) return;

    final pendientes = await _loadPendientes(context);
    if (pendientes.isEmpty || _dialogMostradoEnSesion) return;
    _dialogMostradoEnSesion = true;

    if (!context.mounted) return;
    await _cicloDialogos(context, pendientes);
  }
}
