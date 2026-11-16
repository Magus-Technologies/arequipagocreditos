import 'package:flutter/material.dart';

/// Piezas compartidas del pago con Yape (selector del registro, pantalla de pago y estado de la solicitud).

/// Violeta de Yape. Provisional: se reemplaza por los colores y el logo oficiales cuando Yape los entregue (el flujo UX que se le
/// mandó a validar dice lo mismo), por eso el logo es una insignia sencilla y no una copia de su marca.
const Color colorYape = Color(0xFF742284);

class YapeLogo extends StatelessWidget {
  const YapeLogo({super.key, this.tamano = 28});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colorYape, borderRadius: BorderRadius.circular(tamano * 0.3)),
      child: Text(
        'Y',
        style: TextStyle(color: Colors.white, fontSize: tamano * 0.58, fontWeight: FontWeight.w800, height: 1),
      ),
    );
  }
}

/// Versión del texto de autorización que se muestra. El servidor guarda la suya (`GMONEY_CONSENTIMIENTO_VERSION`) junto con la fecha,
/// la hora y el celular al aceptar: si este texto cambia, hay que subir también esa versión.
const String versionAutorizacionYape = '1.0';

/// Texto que acepta la persona al afiliar su Yape. Propuesta sujeta a revisión legal y a la validación de Yape.
const List<String> textoAutorizacionYape = [
  'Autorizo a AREQUIPA GO S.A.C., mediante GMoney S.A., a cobrar de mi cuenta Yape los pagos que yo solicite en la aplicación '
      '(por ahora, mi inscripción), por el monto exacto que veo antes de confirmar cada pago, en soles.',
  'Puedo desafiliar mi Yape en cualquier momento desde la aplicación de Yape o comunicándome con CREDIGO. '
      'Mis datos se usan solo para realizar estos cobros.',
];

/// Hoja inferior con la autorización completa («Ver autorización completa»).
Future<void> mostrarAutorizacionYape(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          key: const Key('yape_autorizacion'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const YapeLogo(),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Autorización de cobros con Yape', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final parrafo in textoAutorizacionYape) ...[
              Text(parrafo, style: const TextStyle(fontSize: 13.5, height: 1.4)),
              const SizedBox(height: 10),
            ],
            Text(
              'Versión $versionAutorizacionYape · se guarda la fecha, la hora y el celular al aceptar.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16233C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String soles(double valor) => 'S/ ${valor.toStringAsFixed(2)}';
