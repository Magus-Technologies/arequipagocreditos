import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/conductor_estado_model.dart';
import '../../theme/app_theme.dart';

class ConductorOrdenPagoPage extends StatelessWidget {
  final ConductorEstadoModel estado;

  const ConductorOrdenPagoPage({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
                  ),
                  const Expanded(
                    child: Text(
                      'Orden de pago',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            SvgPicture.asset('images/credigo_logo.svg', height: 48),
            const SizedBox(height: 4),
            const Text(
              'así fácil, así de rápido, así de go',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(30, 8, 30, 24),
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final orden = estado.ordenPago;
    final pago = estado.pagoInscripcion;
    final bool esFinanciado = pago?.tipoPago == 'financiado' && (pago?.cuotas.isNotEmpty ?? false);

    if (orden == null) {
      return _buildCard(
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 20, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tu orden de pago aún no está disponible. Comunícate con nuestra oficina para completar tu inscripción.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CÓDIGO DE PAGO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: orden.codigo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Código copiado al portapapeles'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          orden.codigo,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const Icon(Icons.copy, size: 20, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Monto a pagar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    'S/ ${orden.montoTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                'Realiza el depósito en cualquier agencia o agente Caja Arequipa con este código.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        if (esFinanciado) ...[
          const SizedBox(height: 16),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cronograma de cuotas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...pago!.cuotas.map((cuota) => _buildCuotaRow(cuota)),
              ],
            ),
          ),
        ],
        if (pago?.tipoPago == 'contado' && pago?.capturaIzipay != null) ...[
          const SizedBox(height: 16),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Captura IziPay',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    _buildCapturaBadge(pago!.capturaIzipay!),
                  ],
                ),
                if (pago.capturaIzipay!.estado == 'rechazado' &&
                    (pago.capturaIzipay!.motivoRechazo?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Motivo: ${pago.capturaIzipay!.motivoRechazo}',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 16, color: Colors.black54),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Pago 100% seguro — Tu información y pago están protegidos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildCuotaRow(CuotaInscripcionModel cuota) {
    final Color bg;
    final Color fg;
    final String estadoLower = cuota.estado.toLowerCase();
    if (estadoLower == 'pagado' || estadoLower == 'pagada') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (estadoLower == 'vencido' || estadoLower == 'vencida') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    } else {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuota ${cuota.numero} — S/ ${cuota.monto.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (cuota.fechaVencimiento != null)
                      Text(
                        'Vence: ${cuota.fechaVencimiento}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cuota.estado,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
                ),
              ),
            ],
          ),
          if (cuota.capturaIzipay != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.qr_code_2, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'IziPay:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 6),
                _buildCapturaBadge(cuota.capturaIzipay!),
              ],
            ),
            if (cuota.capturaIzipay!.estado == 'rechazado' &&
                (cuota.capturaIzipay!.motivoRechazo?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Motivo: ${cuota.capturaIzipay!.motivoRechazo}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCapturaBadge(CapturaIzipayModel captura) {
    final Color bg;
    final Color fg;
    final String texto;
    switch (captura.estado) {
      case 'aprobado':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        texto = 'Aprobada';
        break;
      case 'rechazado':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        texto = 'Rechazada';
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        texto = 'En validación';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
