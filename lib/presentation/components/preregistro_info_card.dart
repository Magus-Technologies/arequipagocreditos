import 'package:flutter/material.dart';
import '../../domain/entities/conductor_entity.dart';
import '../../theme/app_theme.dart';
import 'info_item.dart';
import 'package:url_launcher/url_launcher.dart';

class PreregistroInfoCard extends StatelessWidget {
  final ConductorEntity? conductor;

  const PreregistroInfoCard({super.key, this.conductor});

  Future<void> _abrirDocumento(String? urlStr) async {
    if (urlStr == null || urlStr.isEmpty) return;
    final url = Uri.parse(urlStr);
    try {
      // Ignoramos canLaunchUrl porque en Android 11+ siempre da false 
      // si no se ha configurado <queries> en el AndroidManifest.xml.
      // launchUrl() funciona directamente para URLs web.
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('No se pudo abrir la url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = conductor?.documentos ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      // ... previous code for decoration ...
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_ind,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Datos de Pre-registro',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InfoItem(
            icon: Icons.monetization_on,
            label: 'Ingreso Mensual',
            value: conductor?.ingresoNetoMensual ?? 'No disponible',
            color: Colors.green,
          ),
          const Divider(height: 30),
          InfoItem(
            icon: Icons.verified_user,
            label: 'Estado de Aprobación',
            value: (conductor?.estadoAprobacion ?? 'Pendiente').toUpperCase(),
            color: _getStatusColor(conductor?.estadoAprobacion),
          ),
          const Divider(height: 30),
          InfoItem(
            icon: Icons.contact_emergency,
            label: 'Contacto de Emergencia',
            value: conductor?.contactoEmergencia?['nombre_completo'] ?? 'No disponible',
            color: Colors.orange,
          ),
          if (conductor?.contactoEmergencia?['telefono'] != null)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: Text(
                'Tel: ${conductor!.contactoEmergencia!['telefono']}',
                style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            ),
          
          if (docs.isNotEmpty) ...[
            const Divider(height: 40),
            const Text(
              'Documentos Adjuntos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            ...docs.map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _abrirDocumento(doc['url']?.toString()),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          _getFileIcon(doc['extension']), 
                          size: 18, 
                          color: Colors.blue.shade700
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (doc['tipo_documento'] ?? 'Documento').toString().replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13, 
                              color: Colors.blue, // Azul para indicar que es clickeable
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Icon(Icons.download_rounded, size: 18, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  IconData _getFileIcon(String? extension) {
    if (extension == 'pdf') return Icons.picture_as_pdf;
    return Icons.image;
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'aprobado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
