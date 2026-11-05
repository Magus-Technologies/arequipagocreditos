import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/utils/evento_formato.dart';
import '../../data/models/evento_models.dart';
import '../../theme/app_theme.dart';
import 'evento_widgets.dart';

/// El ticket de una compra de «Eventos», con forma de entrada y COMPACTO: arriba la franja amarilla (evento, fecha, lugar y el estado),
/// una línea de corte con muescas y abajo el talón: a la izquierda tickets, monto y código; a la derecha el QR de entrada.
///
/// - Confirmada: el QR de ENTRADA (contiene el código de la compra, el mismo que ve el personal en la web).
/// - Pendiente: el mismo ticket pero el cuadro del QR dice que se activa al confirmar el pago.
///
/// Las llaves `evento_codigo`, `evento_copiar_codigo` y `evento_monto` son las de la pantalla de pago.
class EventoTicketCard extends StatelessWidget {
  final EventoCompraModel compra;

  /// Lugar del evento, si se conoce (la compra no lo trae: se toma del evento activo cuando es el mismo).
  final String? lugar;
  final VoidCallback? onCopiarCodigo;

  /// Si es true, el estado de la compra («Confirmado», «En revisión»…) se ve dentro del ticket, arriba a la derecha (ahorra una tarjeta).
  final bool conEstado;

  const EventoTicketCard({super.key, required this.compra, this.lugar, this.onCopiarCodigo, this.conEstado = false});

  static const double _radioEsquina = 20;
  static const double _radioMuesca = 11;
  static const double _ladoQr = 124;

  bool get _confirmado => compra.estadoCompra == EstadoCompra.confirmado;

  /// QR grande para que lo lea el lector en la entrada (pantalla completa de la persona, sobre fondo blanco).
  static Future<void> ampliarQr(BuildContext context, String codigo) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final lado = math.min(MediaQuery.of(dialogContext).size.width - 96, 320.0);
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  key: const Key('evento_ticket_qr_grande'),
                  data: codigo,
                  size: lado,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
                const SizedBox(height: 8),
                Text(codigo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(height: 4),
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cerrar')),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('evento_ticket'),
      mainAxisSize: MainAxisSize.min,
      children: [
        PhysicalShape(
          clipper: const _ClipSuperior(radioEsquina: _radioEsquina, radioMuesca: _radioMuesca),
          color: AppTheme.primary,
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          shadowColor: Colors.black38,
          child: _franjaEvento(),
        ),
        PhysicalShape(
          clipper: const _ClipInferior(radioEsquina: _radioEsquina, radioMuesca: _radioMuesca),
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          shadowColor: Colors.black38,
          child: _talon(context),
        ),
      ],
    );
  }

  Widget _franjaEvento() {
    final fecha = EventoFormato.fechaHora(compra.fechaHoraEvento);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE867), AppTheme.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Si la etiqueta y el estado no caben juntos en un celular angosto, la etiqueta se achica en vez de desbordar.
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.confirmation_number_rounded, size: 12, color: AppTheme.primary),
                                SizedBox(width: 5),
                                Text(
                                  'TICKET DE ENTRADA',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.9, color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (conEstado) ...[
                      const SizedBox(width: 8),
                      EventoEstadoChip(compra: compra),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  compra.eventoNombre,
                  key: const Key('evento_ticket_nombre'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.15, color: Colors.black),
                ),
                if (fecha.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _lineaConIcono(Icons.calendar_month_rounded, fecha),
                ],
                if (lugar != null) ...[
                  const SizedBox(height: 3),
                  _lineaConIcono(Icons.place_rounded, lugar!),
                ],
              ],
            ),
          ),
          const _LineaDeCorte(),
        ],
      ),
    );
  }

  Widget _lineaConIcono(IconData icono, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 15, color: Colors.black87),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.2, color: Colors.black87)),
        ),
      ],
    );
  }

  Widget _dato(String etiqueta, String valor, {bool grande = false, Key? key}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        Text(
          valor,
          key: key,
          style: TextStyle(fontSize: grande ? 19 : 14, fontWeight: FontWeight.w900, color: Colors.black),
        ),
      ],
    );
  }

  Widget _talon(BuildContext context) {
    final pendiente = compra.estadoCompra == EstadoCompra.pendiente;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dato('Tickets', '${compra.cantidad} × ${EventoFormato.monto(compra.precioUnitario)}'),
                    const SizedBox(height: 8),
                    _dato(
                      pendiente ? 'Monto a pagar' : 'Monto',
                      EventoFormato.monto(compra.montoTotal),
                      grande: true,
                      key: const Key('evento_monto'),
                    ),
                    const SizedBox(height: 8),
                    _codigo(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _cuadroQr(context),
            ],
          ),
          const SizedBox(height: 10),
          _nota(),
        ],
      ),
    );
  }

  Widget _codigo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Código de compra', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        Row(
          children: [
            Flexible(
              child: Text(
                compra.codigo,
                key: const Key('evento_codigo'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.black),
              ),
            ),
            IconButton(
              key: const Key('evento_copiar_codigo'),
              tooltip: 'Copiar código',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              onPressed: compra.codigo.isEmpty ? null : onCopiarCodigo,
              icon: const Icon(Icons.copy_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  /// El cuadro de la derecha: el QR de entrada (confirmada) o el aviso de que aún no está activo.
  Widget _cuadroQr(BuildContext context) {
    final hayQr = _confirmado && compra.codigo.isNotEmpty;

    if (hayQr) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            key: const Key('evento_ticket_qr'),
            onTap: () => ampliarQr(context, compra.codigo),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: compra.codigo,
                semanticsLabel: 'QR de entrada ${compra.codigo}',
                size: _ladoQr,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text('Toca para ampliar', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      );
    }

    return Container(
      key: const Key('evento_ticket_qr_bloqueado'),
      width: _ladoQr + 18,
      height: _ladoQr + 18,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 30, color: Colors.grey.shade500),
          const SizedBox(height: 6),
          Text(
            'QR de entrada',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  /// Qué hacer con el ticket según su estado.
  Widget _nota() {
    final IconData icono;
    final String texto;
    final Color color;
    switch (compra.estadoCompra) {
      case EstadoCompra.confirmado:
        icono = Icons.verified_rounded;
        texto = 'Presenta este QR o tu código en la entrada.';
        color = Colors.green.shade700;
        break;
      case EstadoCompra.pendiente:
        icono = Icons.lock_outline_rounded;
        texto = 'Tu QR de entrada se activa al confirmar tu pago.';
        color = Colors.grey.shade700;
        break;
      default:
        icono = Icons.info_outline_rounded;
        texto = 'Este ticket no es válido para el ingreso.';
        color = Colors.grey.shade700;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            key: const Key('evento_ticket_nota'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color, height: 1.25),
          ),
        ),
      ],
    );
  }
}

/// Línea punteada del corte, pegada al borde de abajo de la franja (donde están las muescas).
class _LineaDeCorte extends StatelessWidget {
  const _LineaDeCorte();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 2,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: EventoTicketCard._radioMuesca + 10),
        child: CustomPaint(painter: _PuntosPainter()),
      ),
    );
  }
}

class _PuntosPainter extends CustomPainter {
  const _PuntosPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const raya = 6.0;
    const hueco = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(math.min(x + raya, size.width), size.height / 2), pincel);
      x += raya + hueco;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Parte de arriba: esquinas redondeadas arriba y media muesca en cada lado del borde de abajo.
class _ClipSuperior extends CustomClipper<Path> {
  final double radioEsquina;
  final double radioMuesca;

  const _ClipSuperior({required this.radioEsquina, required this.radioMuesca});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = radioEsquina;
    final n = radioMuesca;
    return Path()
      ..moveTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, h - n)
      ..arcToPoint(Offset(w - n, h), radius: Radius.circular(n), clockwise: false)
      ..lineTo(n, h)
      ..arcToPoint(Offset(0, h - n), radius: Radius.circular(n), clockwise: false)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Parte de abajo (el talón): media muesca en cada lado del borde de arriba y esquinas redondeadas abajo.
class _ClipInferior extends CustomClipper<Path> {
  final double radioEsquina;
  final double radioMuesca;

  const _ClipInferior({required this.radioEsquina, required this.radioMuesca});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = radioEsquina;
    final n = radioMuesca;
    return Path()
      ..moveTo(0, n)
      ..arcToPoint(Offset(n, 0), radius: Radius.circular(n), clockwise: false)
      ..lineTo(w - n, 0)
      ..arcToPoint(Offset(w, n), radius: Radius.circular(n), clockwise: false)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
