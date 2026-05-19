import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arequipagocreditos/data/models/notification_model.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationDetailPage extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final data = notification.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              data.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Fecha
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            // Imagen
            if (data.hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  data.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Mensaje
            Text(
              data.message,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            // Enlace
            if (data.hasLink)
              _ActionTile(
                icon: Icons.link,
                label: 'Abrir enlace',
                subtitle: data.link!,
                onTap: () => _launchUrl(data.link!),
              ),
            // Archivo adjunto
            if (data.hasFile)
              _ActionTile(
                icon: Icons.attach_file,
                label: data.fileName ?? 'Archivo adjunto',
                subtitle: 'Toca para descargar',
                onTap: () => _launchUrl(data.fileUrl!),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha((0.08 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withAlpha((0.2 * 255).toInt()),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: onTap,
      ),
    );
  }
}
