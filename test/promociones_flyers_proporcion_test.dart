import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:arequipagocreditos/presentation/components/servicios_taller_promociones_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TK-0414 (Gian): los flyers de Promociones pueden ser de cualquier tamaño y el app tiene que acomodarlos sin bordes. El recuadro del
// diálogo tomaba siempre 16:9: una imagen cuadrada o vertical salía con bandas a los lados. Ahora toma la forma de la imagen, con un
// tope de alto para que una muy vertical no se salga de la pantalla.

/// Una imagen real (PNG en memoria) de `ancho` x `alto` píxeles.
Future<MemoryImage> _imagen(int ancho, int alto) async {
  final grabador = ui.PictureRecorder();
  final lienzo = Canvas(grabador);
  lienzo.drawRect(
    Rect.fromLTWH(0, 0, ancho.toDouble(), alto.toDouble()),
    Paint()..color = Colors.orange,
  );
  final imagen = await grabador.endRecording().toImage(ancho, alto);
  final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
  return MemoryImage(Uint8List.view(bytes!.buffer));
}

void main() {
  group('proporción del recuadro', () {
    test('sin medir todavía usa la de siempre, 16:9', () {
      expect(ServiciosTallerPromocionesDialog.proporcionAjustada(null), 16 / 9);
      expect(ServiciosTallerPromocionesDialog.proporcionAjustada(0), 16 / 9);
      expect(ServiciosTallerPromocionesDialog.proporcionAjustada(double.nan), 16 / 9);
    });

    test('un flyer normal conserva su forma: horizontal, cuadrado o vertical', () {
      expect(ServiciosTallerPromocionesDialog.proporcionAjustada(16 / 9), 16 / 9);
      expect(ServiciosTallerPromocionesDialog.proporcionAjustada(1.0), 1.0);
      expect(ServiciosTallerPromocionesDialog.proporcionAjustada(0.75), 0.75);
    });

    test('un flyer extremo se limita para no dejar un recuadro absurdo', () {
      expect(ServiciosTallerPromocionesDialog.proporcionAjustada(0.2), 0.5);
      expect(ServiciosTallerPromocionesDialog.proporcionAjustada(5.0), 2.4);
    });
  });

  group('alto del recuadro', () {
    double alto(double proporcion, {double ancho = 460, double maximo = 600}) =>
        ServiciosTallerPromocionesDialog.altoDelRecuadro(
          ancho: ancho,
          proporcion: proporcion,
          altoMaximo: maximo,
        );

    test('16:9 es el alto de siempre', () {
      expect(alto(16 / 9), closeTo(460 * 9 / 16, 0.001));
    });

    test('un flyer cuadrado ocupa un cuadrado, sin bordes', () {
      expect(alto(1.0), 460);
    });

    test('uno vertical es más alto, pero no pasa del tope de la pantalla', () {
      expect(alto(0.75, maximo: 700), closeTo(613.33, 0.01));
      expect(alto(0.75), 600);
      expect(alto(0.5625), 600);
    });

    test('uno muy alargado queda bajo, no cero', () {
      expect(alto(10), closeTo(460 / 2.4, 0.001));
    });

    test('en una pantalla angosta el recuadro se ajusta a su ancho', () {
      expect(alto(1.0, ancho: 300), 300);
    });
  });

  group('MedidorProporcionImagen', () {
    testWidgets('avisa la proporción real de la imagen y muestra su contenido', (tester) async {
      final medidas = <double>[];
      final imagen = (await tester.runAsync(() => _imagen(40, 20)))!;

      await tester.pumpWidget(MaterialApp(
        home: MedidorProporcionImagen(
          imagen: imagen,
          onProporcion: medidas.add,
          child: const Text('flyer'),
        ),
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      expect(find.text('flyer'), findsOneWidget);
      expect(medidas, isNotEmpty);
      expect(medidas.last, 2.0);
    });

    testWidgets('una imagen vertical avisa una proporción menor que 1', (tester) async {
      final medidas = <double>[];
      final imagen = (await tester.runAsync(() => _imagen(30, 60)))!;

      await tester.pumpWidget(MaterialApp(
        home: MedidorProporcionImagen(
          imagen: imagen,
          onProporcion: medidas.add,
          child: const SizedBox(),
        ),
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      expect(medidas.last, 0.5);
    });
  });
}
