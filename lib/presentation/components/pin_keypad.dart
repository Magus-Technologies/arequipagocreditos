import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Indicador de progreso del PIN: [length] círculos, [filled] rellenos.
class PinDots extends StatelessWidget {
  final int length;
  final int filled;
  final bool error;

  const PinDots({super.key, required this.length, required this.filled, this.error = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: error ? Colors.red : (isFilled ? Colors.black87 : Colors.grey.shade300),
          ),
        );
      }),
    );
  }
}

/// Teclado numérico 0-9 + borrar, estilo apps de acceso rápido (Yape/BCP).
class PinKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool enabled;

  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.enabled = true,
  });

  Widget _key({String? digit, Widget? icon, VoidCallback? onTap}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.4,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              // Ripple con el amarillo de marca (el theme de la app usa un
              // swatch rojo heredado, que no corresponde al branding).
              splashColor: AppTheme.primary.withAlpha((0.35 * 255).toInt()),
              highlightColor: AppTheme.primary.withAlpha((0.18 * 255).toInt()),
              onTap: (enabled && onTap != null) ? onTap : null,
              child: Center(
                child: icon ??
                    Text(
                      digit ?? '',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          _key(digit: '1', onTap: () => onDigit('1')),
          _key(digit: '2', onTap: () => onDigit('2')),
          _key(digit: '3', onTap: () => onDigit('3')),
        ]),
        Row(children: [
          _key(digit: '4', onTap: () => onDigit('4')),
          _key(digit: '5', onTap: () => onDigit('5')),
          _key(digit: '6', onTap: () => onDigit('6')),
        ]),
        Row(children: [
          _key(digit: '7', onTap: () => onDigit('7')),
          _key(digit: '8', onTap: () => onDigit('8')),
          _key(digit: '9', onTap: () => onDigit('9')),
        ]),
        Row(children: [
          _key(),
          _key(digit: '0', onTap: () => onDigit('0')),
          _key(icon: const Icon(Icons.backspace_outlined, size: 22, color: Colors.black54), onTap: onDelete),
        ]),
      ],
    );
  }
}
