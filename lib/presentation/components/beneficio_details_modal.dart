import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/contrato_pendiente_gate.dart';
import '../../domain/entities/beneficio_entity.dart';
import '../../domain/entities/beneficio_servicio_entity.dart';
import '../../theme/app_theme.dart';
import '../pages/calculo_financiamiento_page.dart';
import '../providers/auth_provider.dart';
import '../providers/financiamiento_servicio_provider.dart';
import '../widgets/image_full_screen_view.dart';

class BeneficioDetailsModal extends StatefulWidget {
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
  State<BeneficioDetailsModal> createState() => _BeneficioDetailsModalState();
}

class _BeneficioDetailsModalState extends State<BeneficioDetailsModal> {
  BeneficioServicioEntity? _detalle;
  VarianteEntity? _varianteElegida;
  bool _cargandoDetalle = true;
  bool _procesando = false;

  BeneficioComercialEntity get beneficio => widget.beneficio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDetalle());
  }

  Future<void> _cargarDetalle() async {
    final provider = context.read<FinanciamientoServicioProvider>();
    final conductorId = context.read<AuthProvider>().currentUser?.idConductor;

    final detalle = await provider.loadBeneficioDetalle(
      beneficioId: beneficio.id,
      clienteConductorId: conductorId,
    );

    if (!mounted) return;
    setState(() {
      _detalle = detalle;
      _cargandoDetalle = false;
      final variantes = detalle?.variantesDisponibles ?? const <VarianteEntity>[];
      if (variantes.length == 1) _varianteElegida = variantes.first;
    });
  }

  /// El beneficio se puede solicitar dentro de la app solo si tiene el
  /// financiamiento configurado. Si no, se mantiene el canal de WhatsApp.
  bool get _solicitudEnAppDisponible {
    final detalle = _detalle;
    if (detalle == null) return false;
    if (detalle.grupoFinanciamientoId == null) return false;
    return detalle.detalleFinanciamiento != null;
  }

  List<VarianteEntity> get _variantes =>
      _detalle?.variantesDisponibles ?? const <VarianteEntity>[];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHandle(),
                const SizedBox(height: 20),
                _buildTitle(),
                const SizedBox(height: 16),
                if (beneficio.imagen != null && beneficio.imagen!.isNotEmpty)
                  _buildImage(context),
                const SizedBox(height: 20),
                _buildDescription(),
                const SizedBox(height: 20),
                if (_variantes.isNotEmpty) ...[
                  _buildVarianteSelector(),
                  const SizedBox(height: 20),
                ],
                _buildFinancialDetails(),
                const SizedBox(height: 20),
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
                  fit: BoxFit.contain,
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
        builder: (context) => ImageFullScreenView(
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

  Widget _buildVarianteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Elige tu opción',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecciona el plan que quieres solicitar.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        ..._variantes.map(_buildVarianteCard),
      ],
    );
  }

  Widget _buildVarianteCard(VarianteEntity variante) {
    final bool selected = _varianteElegida?.varianteId == variante.varianteId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _varianteElegida = variante),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withAlpha((0.12 * 255).toInt()) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.black : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variante.nombre,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${variante.cantidadCuotas} cuotas de ${variante.monedaSimbolo} ${variante.montoCuota.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    Text(
                      'Total: ${variante.monedaSimbolo} ${variante.montoTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.btnColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? Colors.black : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialDetails() {
    final v = _varianteElegida;
    final String moneda = v?.monedaSimbolo ?? beneficio.moneda;

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
          '$moneda ${(v?.cuotaInicial ?? beneficio.cuotaInicial).toStringAsFixed(2)}',
        ),
        _buildDetailRow(
          'Cantidad de Cuotas:',
          '${v?.cantidadCuotas ?? beneficio.cantidadCuotas}',
        ),
        _buildDetailRow(
          'Cuota ${beneficio.frecuenciaPago}:',
          '$moneda ${(v?.montoCuota ?? beneficio.cuotaMensual).toStringAsFixed(2)}',
        ),
        if (v != null && v.montoInscripcion > 0)
          _buildDetailRow(
            'Pago de Inscripción:',
            '${v.monedaInicialSimbolo} ${v.montoInscripcion.toStringAsFixed(2)}',
          )
        else if (v == null && beneficio.pagoInscripcion != null)
          _buildDetailRow(
            'Pago de Inscripción:',
            '$moneda ${beneficio.pagoInscripcion!.toStringAsFixed(2)}',
          ),
        _buildDetailRow(
          'Total del Plan:',
          '$moneda ${(v?.montoTotal ?? _calculateTotal()).toStringAsFixed(2)}',
        ),
      ],
    );
  }

  double _calculateTotal() {
    final total =
        (beneficio.cuotaMensual * beneficio.cantidadCuotas) + beneficio.cuotaInicial;
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
    if (_cargandoDetalle) {
      return const SizedBox(
        width: double.infinity,
        height: 52,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (!_solicitudEnAppDisponible) return _buildWhatsappButton(context);

    final bool faltaVariante = _variantes.isNotEmpty && _varianteElegida == null;
    final bool habilitado = beneficio.disponible && !faltaVariante && !_procesando;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (faltaVariante)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Selecciona una opción para continuar.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: habilitado ? () => _solicitarBeneficio(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: habilitado ? AppTheme.btnColor : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _procesando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.shopping_cart_outlined, size: 20),
            label: Text(
              beneficio.disponible ? 'Solicitar Beneficio' : 'No Disponible',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _solicitarBeneficio(BuildContext context) async {
    final detalle = _detalle;
    if (detalle == null) return;

    final alertas = detalle.clienteAlertas;
    if (alertas != null && !alertas.puedeSolicitar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alertas.motivoPrincipal ?? 'No puedes adquirir este beneficio en este momento.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _procesando = true);
    final puedeContinuar = await ContratoPendienteGate.ensureSinContratoPendiente(context);
    if (!mounted) return;
    setState(() => _procesando = false);
    if (!puedeContinuar || !context.mounted) return;

    context.read<FinanciamientoServicioProvider>().selectBeneficioComercial(
          detalle,
          variante: _varianteElegida,
        );

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalculoFinanciamientoPage()),
    );
  }

  Widget _buildWhatsappButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: beneficio.disponible
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
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
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
          backgroundColor: beneficio.disponible ? AppTheme.btnColor : Colors.grey,
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
