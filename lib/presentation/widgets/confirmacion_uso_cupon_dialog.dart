import 'package:arequipagocreditos/data/models/cupon_model.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// «Confirmar Uso de Cupón» (TK-0359, diseño de la pág. «CUPONES»): resumen del cupón y la pregunta ¿Deseas utilizar este cupón?
///
/// El código NO se muestra todavía: se genera al confirmar y vale 24 horas.
class ConfirmacionUsoCuponDialog extends StatefulWidget {
  final CuponModel cupon;
  final VoidCallback onConfirm;

  const ConfirmacionUsoCuponDialog({
    super.key,
    required this.cupon,
    required this.onConfirm,
  });

  @override
  State<ConfirmacionUsoCuponDialog> createState() => _ConfirmacionUsoCuponDialogState();
}

class _ConfirmacionUsoCuponDialogState extends State<ConfirmacionUsoCuponDialog> {
  // Un segundo toque durante la animación de cierre no debe confirmar dos veces ni cerrar la pantalla de atrás.
  bool _confirmado = false;

  CuponModel get cupon => widget.cupon;

  static const Color _rojoDescuento = Color(0xFFD50000);

  void _confirmar() {
    if (_confirmado) return;
    setState(() => _confirmado = true);
    Navigator.pop(context);
    widget.onConfirm();
  }

  String _soles(double monto) => 'S/${monto.toStringAsFixed(2)}';

  /// «S/10.00» si el servidor pudo calcularlo; si no, el porcentaje del cupón («10% OFF»).
  String get _descuentoTexto {
    final monto = cupon.montoDescuentoEstimado;
    if (monto != null && monto > 0) return _soles(monto);
    return cupon.valorFormateado;
  }

  @override
  Widget build(BuildContext context) {
    final precioNormal = cupon.precioNormal;
    final montoPagar = cupon.montoPagarEstimado;
    final usosRestantes = cupon.limiteUsosConductor == null ? null : cupon.usosRestantes;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha((0.2 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_offer, size: 32, color: Color(0xFFB8860B)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Confirmar Uso de Cupón',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '¿Deseas utilizar este cupón?',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      'Cupón N.° ${cupon.numeroFormateado}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.storefront, size: 20, color: Color(0xFFEA580C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cupon.nombreEstablecimiento,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: _rojoDescuento, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        const Text('Descuento:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          _descuentoTexto,
                          key: const Key('cupon_descuento'),
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  if (precioNormal != null && precioNormal > 0) ...[
                    const SizedBox(height: 8),
                    _fila(
                      icono: Icons.sell_outlined,
                      etiqueta: 'Precio normal:',
                      valor: Text(
                        _soles(precioNormal),
                        key: const Key('cupon_precio_normal'),
                        style: const TextStyle(
                          color: Colors.red,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      fondo: Colors.grey.shade100,
                    ),
                  ],
                  if (montoPagar != null) ...[
                    const SizedBox(height: 6),
                    _fila(
                      icono: Icons.attach_money,
                      colorIcono: Colors.green.shade700,
                      etiqueta: 'Pagas en establecimiento:',
                      valor: Text(
                        _soles(montoPagar),
                        key: const Key('cupon_monto_pagar'),
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      fondo: Colors.green.shade50,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _linea(Icons.qr_code_2, 'Código: se generará al confirmar', Colors.black87),
                  if (usosRestantes != null) ...[
                    const SizedBox(height: 6),
                    _linea(Icons.refresh, 'Usos restantes: $usosRestantes', Colors.blue.shade700),
                  ],
                  const SizedBox(height: 6),
                  _linea(Icons.schedule, 'Válido por 24 horas', Colors.orange.shade800),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cupon.condiciones ?? 'Válido según términos y condiciones.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _confirmado ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('confirmar_uso_cupon'),
                    onPressed: _confirmado ? null : _confirmar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    child: const Text('CONFIRMAR USO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fila({
    required IconData icono,
    required String etiqueta,
    required Widget valor,
    required Color fondo,
    Color? colorIcono,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icono, size: 18, color: colorIcono ?? Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(etiqueta, style: TextStyle(fontSize: 13, color: Colors.grey.shade800))),
          valor,
        ],
      ),
    );
  }

  Widget _linea(IconData icono, String texto, Color color) {
    return Row(
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(texto, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
      ],
    );
  }
}
