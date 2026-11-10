import 'package:flutter/material.dart';
import '../../domain/entities/conductor_entity.dart';
import 'info_item.dart';
import 'perfil_seccion_card.dart';
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
    final contacto = conductor?.contactoEmergencia;
    final telefonoContacto = contacto?['telefono']?.toString();

    return PerfilSeccionCard(
      titulo: 'Datos de pre-registro',
      icono: Icons.assignment_ind_outlined,
      children: [
        InfoItem(
          icon: Icons.monetization_on_outlined,
          label: 'Ingreso mensual',
          value: conductor?.ingresoNetoMensual ?? InfoItem.sinDato,
          color: Colors.green,
        ),
        InfoItem(
          icon: Icons.verified_user_outlined,
          label: 'Estado de aprobación',
          value: (conductor?.estadoAprobacion ?? 'Pendiente').toUpperCase(),
          color: _getStatusColor(conductor?.estadoAprobacion),
        ),
        InfoItem(
          icon: Icons.contact_emergency_outlined,
          label: 'Contacto de emergencia',
          value: [
            contacto?['nombre_completo']?.toString() ?? InfoItem.sinDato,
            if (telefonoContacto != null) 'Tel: $telefonoContacto',
          ].join('\n'),
          color: Colors.orange,
        ),
        if (docs.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Documentos adjuntos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              ...docs.map((doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _abrirDocumento(doc['url']?.toString()),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(_getFileIcon(doc['extension']), size: 18, color: Colors.blue.shade700),
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
          ),
      ],
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
