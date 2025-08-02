import 'package:flutter/material.dart';
import 'package:arequipagocreditos/models/conductor_model.dart';

class ProfileInfo extends StatelessWidget {
  final Conductor? conductor;

  const ProfileInfo({
    super.key,
    required this.conductor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          conductor != null ? conductor!.nombres : 'Cargando...',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            conductor != null ? 'DNI: ${conductor!.nroDocumento}' : '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildProfileStatusMessage(),
      ],
    );
  }

  Widget _buildProfileStatusMessage() {
    if (conductor?.fotoPerfilCambiada == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 6),
            Text(
              'Foto de perfil personalizada',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Puedes personalizar tu foto',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Toca el ícono de cámara (solo una vez)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
  }
}
