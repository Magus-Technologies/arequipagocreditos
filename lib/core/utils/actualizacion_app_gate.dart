import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_constants.dart';

/// Aviso de actualización del APP.
///
/// El servidor decide si hay versión nueva y si es obligatoria (configurable
/// desde credigo sin publicar una versión nueva en las tiendas). Funciona igual
/// en Android y en iOS porque el diálogo lo dibuja la app, no la tienda.
class ActualizacionAppGate {
  static bool _yaConsultadoEnSesion = false;

  static Future<void> verificar(BuildContext context) async {
    if (_yaConsultadoEnSesion) return;
    _yaConsultadoEnSesion = true;

    try {
      final info = await PackageInfo.fromPlatform();
      final plataforma = Platform.isIOS ? 'ios' : 'android';
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.appVersionEndpoint}'
        '?plataforma=$plataforma&version=${info.version}',
      );

      final response = await http
          .get(url, headers: ApiConstants.defaultHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
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
    } catch (_) {
      // Si falla la consulta no se molesta al usuario: el aviso es secundario.
    }
  }

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
