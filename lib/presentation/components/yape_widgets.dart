import 'package:flutter/material.dart';

/// Piezas compartidas del pago con Yape (selector del registro, pantalla de pago y estado de la solicitud).

/// Violeta de Yape.
const Color colorYape = Color(0xFF742284);

/// Ícono oficial de Yape (`images/yape_logo.png`, 256 px, con las esquinas redondeadas ya transparentes). Si el archivo no se pudiera
/// cargar se dibuja la insignia violeta con la «Y» de antes, para que el pago nunca quede sin su marca.
class YapeLogo extends StatelessWidget {
  const YapeLogo({super.key, this.tamano = 28});

  static const String asset = 'images/yape_logo.png';

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: tamano,
      height: tamano,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Yape',
      errorBuilder: (context, error, stackTrace) => Container(
        width: tamano,
        height: tamano,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colorYape, borderRadius: BorderRadius.circular(tamano * 0.3)),
        child: Text(
          'Y',
          style: TextStyle(color: Colors.white, fontSize: tamano * 0.58, fontWeight: FontWeight.w800, height: 1),
        ),
      ),
    );
  }
}

/// Tarjeta de Yape apagada con la etiqueta «Próximamente»: se ve para que sepan que viene, pero no se puede tocar ni elegir.
/// La usan el registro de conductor y el «Cálculo de Pago» de los servicios.
class YapeProximamenteCard extends StatelessWidget {
  const YapeProximamenteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Yape, próximamente. Todavía no disponible.',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: 0.6,
          child: Container(
            key: const Key('pago_metodo_yape_proximamente'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                // Misma caja que los logos de Caja Arequipa e IziPay del paso de pago: así los títulos quedan alineados.
                const SizedBox(width: 56, height: 28, child: Align(alignment: Alignment.centerLeft, child: YapeLogo(tamano: 28))),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yape', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Pronto podrás pagar desde tu celular, sin ir a ninguna agencia.', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  key: const Key('pago_yape_etiqueta_proximamente'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: colorYape.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Próximamente', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorYape)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ¿Se avisa que Yape viene pronto en el «Cálculo de Pago» de un servicio? Solo en soles (Yape no cobra dólares) y si el servicio no
/// trae ya un «Yape» propio entre sus métodos (el manual, con número de operación), para no mostrar dos. La compra de servicios todavía
/// NO se cobra con Yape de GMoney, así que esto no depende del interruptor del Director: es solo un aviso, nunca habilita nada.
bool mostrarYapeProximamenteEnServicio({required String simbolo, required List<String> metodos}) {
  final enSoles = simbolo.replaceAll('.', '').trim().toUpperCase() == 'S/';
  final tieneYape = metodos.any((m) => m.toUpperCase().contains('YAPE'));
  return enSoles && !tieneYape;
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
