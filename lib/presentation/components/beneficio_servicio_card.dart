import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/beneficio_servicio_entity.dart';
import '../../theme/app_theme.dart';
import '../widgets/image_full_screen_view.dart';

class BeneficioServicioCard extends StatelessWidget {
  final BeneficioServicioEntity servicio;
  final VoidCallback onTap;

  const BeneficioServicioCard({
    super.key,
    required this.servicio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildDivider(),
                const SizedBox(height: 12),
                _buildFinancialInfo(),
                const SizedBox(height: 12),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen del servicio
        GestureDetector(
          onTap: () => _showImageFullScreen(context),
          child: Hero(
            tag: 'servicio_image_${servicio.id}',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
                border: Border.all(
                  color: AppTheme.primary.withAlpha((0.3 * 255).toInt()),
                  width: 2,
                ),
              ),
              child: servicio.imagen != null && servicio.imagen!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        '${ApiConstants.imagenesBaseUrl}/${servicio.imagen!}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.home_repair_service,
                            color: AppTheme.primary,
                            size: 32,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.home_repair_service,
                      color: AppTheme.primary,
                      size: 32,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Información del servicio
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                servicio.nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                servicio.descripcion,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.primary.withAlpha((0.3 * 255).toInt()),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            'Cuota Inicial',
            '${servicio.moneda} ${servicio.cuotaInicial.toStringAsFixed(2)}',
            Icons.credit_card,
            AppTheme.bgContacto,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            'Cuotas',
            '${servicio.cantidadCuotas}x',
            Icons.calendar_month,
            AppTheme.title,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            _formatFrequency(servicio.frecuenciaPago),
            '${servicio.moneda} ${servicio.cuotaMensual.toStringAsFixed(2)}',
            Icons.schedule,
            AppTheme.btnColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: servicio.disponible ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: servicio.disponible ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                servicio.disponible ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: servicio.disponible ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                servicio.disponible ? 'Disponible' : 'No disponible',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: servicio.disponible ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: AppTheme.primary.withAlpha((0.15 * 255).toInt()),
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'ADQUIRIR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  void _showImageFullScreen(BuildContext context) {
    if (servicio.imagen == null || servicio.imagen!.isEmpty) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageFullScreenView(
          imageUrl: '${ApiConstants.imagenesBaseUrl}/${servicio.imagen!}',
          heroTag: 'servicio_image_${servicio.id}',
          title: servicio.nombre,
        ),
      ),
    );
  }
}

String _formatFrequency(String? freq) {
  if (freq == null || freq.isEmpty) return 'Cuota';
  final f = freq.trim();
  return f[0].toUpperCase() + f.substring(1);
}
