import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/pages/perfil_page.dart';
import '../../presentation/providers/auth_provider.dart';

/// TK-0357: ventana flotante de los DATOS POR ACTUALIZAR (foto de perfil, DNI y SOAT de Flota).
///
/// Misma idea que [ContratoPendienteGate]: al abrir el dashboard, si el cliente tiene datos pendientes se le avisa una vez
/// por sesión y se le ofrece ir a su perfil. El aviso fijo (rojo) queda en el dashboard y en el perfil mientras haya algo
/// pendiente; con algo pendiente el servidor no le deja generar financiamientos.
///
/// La lista sale de `datos_pendientes` del perfil (login y `get-perfil-usuario`). Antes de mostrar nada se refresca el perfil
/// en silencio: así no se avisa de algo que ya subió en otra sesión.
class DatosPendientesGate {
  static bool _dialogMostradoEnSesion = false;

  static Future<void> checkOnDashboard(BuildContext context) async {
    if (_dialogMostradoEnSesion) return;

    final auth = context.read<AuthProvider>();
    try {
      await auth.refreshUserDataSilently();
    } catch (_) {
      // Sin conexión se usa lo último que se guardó.
    }
    if (!context.mounted) return;

    final pendientes = auth.currentUser?.datosPendientes ?? const <Map<String, dynamic>>[];
    if (pendientes.isEmpty) return;

    _dialogMostradoEnSesion = true;
    final actualizar = await showDialog<bool>(
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
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade500, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Datos por actualizar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No podrás solicitar un financiamiento hasta completar:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 10),
            for (final p in pendientes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '•  ${p['mensaje'] ?? ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red.shade800),
                ),
              ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Después'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Actualizar ahora'),
          ),
        ],
      ),
    );

    if (actualizar == true && context.mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PerfilPage()));
    }
  }
}
