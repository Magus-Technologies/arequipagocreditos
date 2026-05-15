import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/beneficio_entity.dart';
import '../../theme/app_theme.dart';
import '../widgets/image_full_screen_view.dart';

class BeneficioDetailsModal extends StatelessWidget {
  final BeneficioComercialEntity beneficio;

  const BeneficioDetailsModal({super.key, required this.beneficio});

  static Future<void> show(
    BuildContext context,
    BeneficioComercialEntity beneficio,
  ) {
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
                  _buildImage(context),
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
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildImage(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageFullScreen(context),
      child: Hero(
        tag: 'beneficio_image_${beneficio.id}',
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).toInt()),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(
                  '${ApiConstants.imagenesBaseUrl}/${beneficio.imagen!}',
                  width: double.infinity,
                  height: double.infinity,
                  fit:
                      BoxFit
                          .contain, // Cambiado para mostrar la imagen completa
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
                // Indicador de que se puede hacer tap
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.5 * 255).toInt()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageFullScreen(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder:
            (context) => ImageFullScreenView(
              imageUrl: '${ApiConstants.imagenesBaseUrl}/${beneficio.imagen!}',
              heroTag: 'beneficio_image_${beneficio.id}',
              title: beneficio.nombre,
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(beneficio.descripcion, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildFinancialDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalles del Financiamiento',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Cuota Inicial:',
          '${beneficio.moneda} ${beneficio.cuotaInicial.toStringAsFixed(2)}',
        ),
        _buildDetailRow('Cantidad de Cuotas:', '${beneficio.cantidadCuotas}'),
        _buildDetailRow(
          'Cuota ${beneficio.frecuenciaPago}:',
          '${beneficio.moneda} ${beneficio.cuotaMensual.toStringAsFixed(2)}',
        ),
        if (beneficio.pagoInscripcion != null)
          _buildDetailRow(
            'Pago de Inscripción:',
            '${beneficio.moneda} ${beneficio.pagoInscripcion!.toStringAsFixed(2)}',
          ),
        _buildDetailRow(
          'Total del Plan:',
          '${beneficio.moneda} ${_calculateTotal().toStringAsFixed(2)}',
        ),
      ],
    );
  }

  double _calculateTotal() {
    final total =
        (beneficio.cuotaMensual * beneficio.cantidadCuotas) +
        beneficio.cuotaInicial;
    return beneficio.pagoInscripcion != null
        ? total + beneficio.pagoInscripcion!
        : total;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
      child: ElevatedButton.icon(
        onPressed:
            beneficio.disponible
                ? () async {
                  final total = _calculateTotal().toStringAsFixed(2);
                  final mensaje =
                      'Hola, estoy interesado en el beneficio *${beneficio.nombre}*.\n'
                      'Cuota inicial: ${beneficio.moneda} ${beneficio.cuotaInicial.toStringAsFixed(2)}\n'
                      'Cuotas: ${beneficio.cantidadCuotas} x ${beneficio.moneda} ${beneficio.cuotaMensual.toStringAsFixed(2)}\n'
                      'Total: ${beneficio.moneda} $total\n'
                      'Me gustaría obtener más información.';
                  final url = Uri.parse(
                    'https://wa.me/51982934377?text=${Uri.encodeComponent(mensaje)}',
                  );
                  Navigator.pop(context);
                  if (!await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  )) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo abrir WhatsApp'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              beneficio.disponible ? AppTheme.btnColor : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: beneficio.disponible ? const Icon(Icons.message, size: 20) : null,
        label: Text(
          beneficio.disponible ? 'Solicitar Beneficio' : 'No Disponible',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

