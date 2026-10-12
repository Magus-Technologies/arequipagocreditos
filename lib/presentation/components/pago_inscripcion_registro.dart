import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/izipay_models.dart';
import '../widgets/image_full_screen_view.dart';

/// Paso de PAGO del registro de conductor: va después de los documentos y antes de enviar la solicitud.
///
/// El conductor ve cuánto paga y elige cómo:
///  - Caja Arequipa: al enviar la solicitud recibe su código (vale 24 horas) y paga en un agente o agencia.
///  - QR IziPay: paga con el QR y adjunta la captura de su pago; el equipo la valida junto con la solicitud.
/// La aprobación del registro sigue siendo del asesor aunque el pago ya esté hecho.
class PagoInscripcionRegistro extends StatelessWidget {
  static const String metodoCaja = 'caja_arequipa';
  static const String metodoIzipay = 'izipay';

  const PagoInscripcionRegistro({
    super.key,
    required this.info,
    required this.cargando,
    required this.error,
    required this.metodo,
    required this.captura,
    required this.operacionController,
    required this.onMetodo,
    required this.onElegirCaptura,
    required this.onReintentar,
  });

  final InscripcionPagoInfoModel? info;
  final bool cargando;
  final String? error;
  final String? metodo;
  final File? captura;
  final TextEditingController operacionController;
  final ValueChanged<String> onMetodo;
  final VoidCallback onElegirCaptura;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Colors.black87),
              SizedBox(height: 14),
              Text('Calculando tu monto de inscripción…', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    if (info == null) {
      return _nota(
        key: const Key('pago_error'),
        icono: Icons.wifi_off_rounded,
        color: Colors.red,
        texto: error ?? 'No pudimos calcular tu monto de inscripción.',
        accion: TextButton(
          onPressed: onReintentar,
          child: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    final i = info!;

    if (i.monto <= 0) {
      return _nota(
        key: const Key('pago_sin_costo'),
        icono: Icons.check_circle_outline,
        color: Colors.green,
        texto: 'Tu inscripción no tiene costo. Envía tu solicitud para que la revisemos.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const Key('pago_monto'),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Monto de tu inscripción',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'S/ ${i.monto.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text('Elige cómo pagar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black)),
        const SizedBox(height: 12),
        if (i.cajaDisponible)
          _metodoCard(
            key: const Key('pago_metodo_caja'),
            valor: metodoCaja,
            titulo: 'Caja Arequipa',
            subtitulo: 'Al enviar tu solicitud recibes tu código de pago y pagas en un agente o agencia.',
            icono: Icons.storefront_outlined,
          ),
        if (i.izipayDisponible) ...[
          const SizedBox(height: 12),
          _metodoCard(
            key: const Key('pago_metodo_izipay'),
            valor: metodoIzipay,
            titulo: 'QR IziPay',
            subtitulo: 'Paga con el QR y adjunta la captura de tu pago.',
            icono: Icons.qr_code_2_rounded,
          ),
        ],
        const SizedBox(height: 18),
        if (metodo == metodoCaja)
          _nota(
            key: const Key('pago_nota_caja'),
            icono: Icons.schedule_rounded,
            color: Colors.blue,
            texto: 'Tu código de pago vale 24 horas desde que envías la solicitud. Tu solicitud se revisa mientras tanto.',
          ),
        if (metodo == metodoIzipay) _izipay(context, i),
      ],
    );
  }

  Widget _izipay(BuildContext context, InscripcionPagoInfoModel i) {
    final qr = i.qrUrl;
    return Column(
      key: const Key('pago_izipay'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (qr != null && qr.isNotEmpty)
          Center(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageFullScreenView(imageUrl: qr, heroTag: 'registro_izipay_qr', title: 'QR IziPay'),
                ),
              ),
              child: Hero(
                tag: 'registro_izipay_qr',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    qr,
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: const Icon(Icons.qr_code_2, size: 64, color: Colors.black26),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        const Center(
          child: Text('Toca el QR para ampliarlo', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ),
        const SizedBox(height: 14),
        _nota(
          icono: Icons.info_outline,
          color: Colors.blue,
          texto: 'Escanea el QR con tu app, paga el monto exacto (S/ ${i.monto.toStringAsFixed(2)}) y sube la captura del comprobante.',
        ),
        const SizedBox(height: 14),
        InkWell(
          key: const Key('pago_captura'),
          onTap: onElegirCaptura,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: captura != null ? Colors.green.shade50 : Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: captura != null ? Colors.green.shade300 : Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  captura != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                  color: captura != null ? Colors.green.shade700 : Colors.black87,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    captura != null ? 'Captura adjuntada. Toca para cambiarla' : 'Adjuntar captura del pago',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: captura != null ? Colors.green.shade800 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const Key('pago_operacion'),
          controller: operacionController,
          maxLength: 100,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Número de operación (opcional)',
            labelStyle: const TextStyle(color: Colors.black45),
            prefixIcon: const Icon(Icons.tag, color: Colors.black87, size: 22),
            counterText: '',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _metodoCard({
    required Key key,
    required String valor,
    required String titulo,
    required String subtitulo,
    required IconData icono,
  }) {
    final bool elegido = metodo == valor;
    return InkWell(
      key: key,
      onTap: () => onMetodo(valor),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elegido ? Colors.black.withValues(alpha: 0.04) : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: elegido ? Colors.black : Colors.grey[200]!, width: elegido ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icono, color: elegido ? Colors.black : Colors.black45),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitulo, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
            ),
            Icon(elegido ? Icons.check_circle : Icons.radio_button_unchecked, color: elegido ? Colors.black : Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _nota({
    Key? key,
    required IconData icono,
    required MaterialColor color,
    required String texto,
    Widget? accion,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: color.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto, style: TextStyle(fontSize: 13, color: color.shade800)),
                if (accion != null) accion,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
