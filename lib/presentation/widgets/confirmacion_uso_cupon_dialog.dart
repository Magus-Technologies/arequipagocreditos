import 'package:arequipagocreditos/data/models/cupon_model.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;

class ConfirmacionUsoCuponDialog extends StatelessWidget {
  final CuponModel cupon;
  final VoidCallback onConfirm;

  const ConfirmacionUsoCuponDialog({
    super.key,
    required this.cupon,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono del cupón
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.local_offer,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Título
            const Text(
              'Confirmar Uso de Cupón',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Información del cupón
            _buildCuponInfo(),
            
            // Condiciones
            if (cupon.condiciones != null) ...[
              const SizedBox(height: 12),
              _buildCondiciones(),
            ],
            
            const SizedBox(height: 24),
            
            // Botones de acción
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCuponInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del cupón
          Text(
            cupon.titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          
          // Código
          if (cupon.codigo != null)
            _buildInfoRow(
              Icons.qr_code,
              'Código: ${cupon.codigo}',
              Colors.grey.shade600,
            ),
          const SizedBox(height: 8),
          
          // Valor del descuento
          _buildInfoRow(
            Icons.discount,
            'Valor: ${cupon.valorFormateado}',
            Colors.green.shade600,
          ),
          
          // Usos restantes
          if (cupon.limiteUsosConductor != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.refresh,
              'Usos restantes: ${cupon.usosRestantes}',
              Colors.blue.shade600,
            ),
          ],
          
          // Fecha de vencimiento
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.schedule,
            'Válido hasta: ${app_date_utils.DateUtils.formatDate(cupon.fechaFin)}',
            Colors.orange.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: text.contains('Valor:') ? 16 : 14,
              fontWeight: text.contains('Valor:') ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCondiciones() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cupon.condiciones!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Usar Cupón',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
