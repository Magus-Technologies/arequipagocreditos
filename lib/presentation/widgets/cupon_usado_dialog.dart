import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/uso_cupon_entity.dart';

/// «¡Cupón Usado!» (TK-0359): el código único de 24 horas que se muestra en el establecimiento.
///
/// Se abre al confirmar el uso y también desde «Ver código» en la tarjeta mientras el código siga vigente. Si el servidor es
/// anterior al código (sin `codigo`), solo avisa que el cupón se usó.
class CuponUsadoDialog extends StatefulWidget {
  final UsoCuponEntity uso;

  /// true cuando se abre de nuevo desde la tarjeta (el cupón ya se había usado antes).
  final bool reabierto;

  const CuponUsadoDialog({super.key, required this.uso, this.reabierto = false});

  @override
  State<CuponUsadoDialog> createState() => _CuponUsadoDialogState();
}

class _CuponUsadoDialogState extends State<CuponUsadoDialog> {
  bool _copiado = false;

  UsoCuponEntity get uso => widget.uso;

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: uso.codigo));
    if (!mounted) return;
    setState(() => _copiado = true);
  }

  @override
  Widget build(BuildContext context) {
    final vigente = uso.vigente;
    final verde = Colors.green.shade600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: verde, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.reabierto ? 'Tu código del cupón' : '¡Cupón Usado!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              uso.tieneCodigo
                  ? (widget.reabierto ? 'Muéstralo en ${uso.establecimiento}' : 'Cupón usado exitosamente')
                  : 'Cupón usado exitosamente',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (uso.tieneCodigo) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 20, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Text('Código del cupón:', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: _copiar,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(
                          uso.codigo,
                          key: const Key('cupon_codigo'),
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 4, color: Colors.black87),
                        ),
                      ),
                    ),
                    Text(
                      _copiado ? 'Código copiado' : 'Toca el código para copiarlo',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 18, color: vigente ? Colors.orange.shade800 : Colors.red.shade700),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            vigente
                                ? (widget.reabierto
                                    ? 'Vence en ${uso.restanteTexto}'
                                    : 'Válido por ${uso.horasVigencia} horas')
                                : 'Código vencido',
                            key: const Key('cupon_vigencia'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: vigente ? Colors.orange.shade800 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
