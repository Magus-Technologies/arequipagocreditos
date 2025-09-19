import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/beneficio_entity.dart';
import '../../theme/app_theme.dart';

class BeneficioDetailsModal extends StatelessWidget {
  final BeneficioComercialEntity beneficio;

  const BeneficioDetailsModal({
    super.key,
    required this.beneficio,
  });

  static Future<void> show(BuildContext context, BeneficioComercialEntity beneficio) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BeneficioDetailsModal(beneficio: beneficio),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle del modal
                _buildHandle(),
                const SizedBox(height: 20),
                
                // Título
                _buildTitle(),
                const SizedBox(height: 16),
                
                // Imagen
                if (beneficio.imagen != null && beneficio.imagen!.isNotEmpty)
                  _buildImage(),
                const SizedBox(height: 20),
                
                // Descripción
                _buildDescription(),
                const SizedBox(height: 20),
                
                // Detalles financieros
                _buildFinancialDetails(),
                const SizedBox(height: 20),
                
                // Botón de acción
                _buildActionButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      beneficio.nombre,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          '${ApiConstants.imagenesBaseUrl}/${beneficio.imagen!}',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 48,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          beneficio.descripcion,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildFinancialDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalles del Financiamiento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Cuota Inicial:', 'S/ ${beneficio.cuotaInicial.toStringAsFixed(2)}'),
        _buildDetailRow('Cantidad de Cuotas:', '${beneficio.cantidadCuotas}'),
        _buildDetailRow('Cuota Mensual:', 'S/ ${beneficio.cuotaMensual.toStringAsFixed(2)}'),
        _buildDetailRow('Total del Plan:', 'S/ ${((beneficio.cuotaMensual * beneficio.cantidadCuotas) + beneficio.cuotaInicial).toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.btnColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: beneficio.disponible ? () {
          Navigator.pop(context);
          // Aquí puedes agregar la lógica para solicitar el beneficio
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Solicitar ${beneficio.nombre}'),
              backgroundColor: Colors.green,
            ),
          );
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: beneficio.disponible ? AppTheme.btnColor : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          beneficio.disponible ? 'Solicitar Beneficio' : 'No Disponible',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}