import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_constants.dart';

/// Aviso de actualización del APP.
///
/// Cada plataforma usa el camino que le corresponde:
///
///  - **Android**: Google Play sabe por sí solo si hay una versión nueva
///    publicada (In-App Updates). No hay que avisarle nada al servidor: se
///    publica en Play y el aviso aparece. Solo se consulta al backend para
///    saber si esa actualización es OBLIGATORIA.
///  - **iOS**: Apple no tiene equivalente, así que el servidor decide y el
///    diálogo lo dibuja la app.
///
/// Los dos mecanismos nunca corren juntos en la misma plataforma: si lo
/// hicieran, en Android saldrían dos avisos por la misma actualización.
class ActualizacionAppGate {
  static bool _yaConsultadoEnSesion = false;

  static Future<void> verificar(BuildContext context) async {
    if (_yaConsultadoEnSesion) return;
    _yaConsultadoEnSesion = true;

    try {
      if (Platform.isAndroid) {
        await _verificarAndroid(context);
      } else {
        await _verificarPorBackend(context);
      }
    } catch (_) {
      // El aviso es secundario: si algo falla, no se molesta al usuario.
    }
  }

  // ====================== Android (Google Play) ======================

  /// Play detecta la versión nueva; el backend solo dice si es obligatoria.
  static Future<void> _verificarAndroid(BuildContext context) async {
    final AppUpdateInfo info;
    try {
      info = await InAppUpdate.checkForUpdate();
    } catch (_) {
      // Falla en compilaciones que no vienen de Play (debug, APK directo) o en
      // equipos sin Play Services. Ahí no hay actualización que ofrecer.
      return;
    }

    if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

    final obligatoria = await _esObligatoriaSegunBackend();

    if (obligatoria && info.immediateUpdateAllowed) {
      // Pantalla de Play a pantalla completa: no se puede seguir sin actualizar.
      await InAppUpdate.performImmediateUpdate();
      return;
    }

    if (info.flexibleUpdateAllowed) {
      // Se descarga en segundo plano y la persona sigue usando el app.
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
      return;
    }

    if (info.immediateUpdateAllowed) {
      await InAppUpdate.performImmediateUpdate();
    }
  }

  /// Consulta al backend SOLO para saber si la versión instalada quedó por
  /// debajo del mínimo permitido. Si no se puede consultar, se asume que no
  /// es obligatoria: nunca se bloquea el app por una falla de red.
  static Future<bool> _esObligatoriaSegunBackend() async {
    try {
      final datos = await _consultarBackend();
      return datos?['obligatoria'] == true;
    } catch (_) {
      return false;
    }
  }

  // ====================== iOS (decide el servidor) ======================

  static Future<void> _verificarPorBackend(BuildContext context) async {
    final data = await _consultarBackend();
    if (data == null || data['actualizacion_disponible'] != true) return;

    if (!context.mounted) return;
    await _mostrarDialogo(
      context,
      obligatoria: data['obligatoria'] == true,
      mensaje: data['mensaje']?.toString() ??
          'Hay una versión nueva de CrediGO disponible.',
      versionUltima: data['version_ultima']?.toString(),
      urlTienda: data['url']?.toString(),
    );
  }

  static Future<Map<String, dynamic>?> _consultarBackend() async {
    final info = await PackageInfo.fromPlatform();
    final plataforma = Platform.isIOS ? 'ios' : 'android';
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.appVersionEndpoint}'
      '?plataforma=$plataforma&version=${info.version}',
    );

    final response = await http
        .get(url, headers: ApiConstants.defaultHeaders)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;

    final body = json.decode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>?;
  }

  // ====================== Diálogo propio (iOS) ======================

  static Future<void> _mostrarDialogo(
    BuildContext context, {
    required bool obligatoria,
    required String mensaje,
    String? versionUltima,
    String? urlTienda,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !obligatoria,
      builder: (dialogContext) => PopScope(
        canPop: !obligatoria,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.system_update, size: 28, color: Colors.blue.shade700),
              ),
              const SizedBox(height: 16),
              Text(
                obligatoria ? 'Actualización requerida' : 'Actualización disponible',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
              ),
              if (versionUltima != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Versión $versionUltima',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _abrirTienda(dialogContext, urlTienda, obligatoria),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Actualizar ahora',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (!obligatoria)
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Después',
                    style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _abrirTienda(
    BuildContext context,
    String? urlTienda,
    bool obligatoria,
  ) async {
    if (urlTienda == null || urlTienda.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Busca CrediGO en la tienda de aplicaciones para actualizar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final abierto = await launchUrl(
      Uri.parse(urlTienda),
      mode: LaunchMode.externalApplication,
    );

    // Si la actualizacion es opcional, se cierra el dialogo al salir a la tienda.
    if (abierto && !obligatoria && context.mounted) Navigator.pop(context);
  }
}
