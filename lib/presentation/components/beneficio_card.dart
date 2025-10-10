import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/beneficio_entity.dart';
import '../../theme/app_theme.dart';

class BeneficioCard extends StatelessWidget {
  final BeneficioComercialEntity beneficio;
  final VoidCallback onTap;

  const BeneficioCard({
    super.key,
    required this.beneficio,
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
                // Cabecera con imagen y título
                _buildHeader(),
                
                const SizedBox(height: 16),
                _buildDivider(),
                const SizedBox(height: 12),
                
                // Información financiera
                _buildFinancialInfo(),
                
                const SizedBox(height: 12),
                
                // Estado de disponibilidad y botón de acción
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen del beneficio
        Container(
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
          child: beneficio.imagen != null && beneficio.imagen!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    '${ApiConstants.imagenesBaseUrl}/${beneficio.imagen!}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                        size: 32,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.card_giftcard,
                  color: AppTheme.primary,
                  size: 32,
                ),
        ),
        const SizedBox(width: 16),
        
        // Información del beneficio
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                beneficio.nombre,
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
                beneficio.descripcion,
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
            '${beneficio.moneda} ${beneficio.cuotaInicial.toStringAsFixed(2)}',
            Icons.monetization_on,
            AppTheme.bgContacto,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            'Cuotas',
            '${beneficio.cantidadCuotas}x',
            Icons.calendar_month,
            AppTheme.title,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            'Mensual',
            '${beneficio.moneda} ${beneficio.cuotaMensual.toStringAsFixed(2)}',
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
            color: beneficio.disponible ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: beneficio.disponible ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                beneficio.disponible ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: beneficio.disponible ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                beneficio.disponible ? 'Disponible' : 'No disponible',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: beneficio.disponible ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: AppTheme.primary.withAlpha((0.1 * 255).toInt()),
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Ver detalles',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}