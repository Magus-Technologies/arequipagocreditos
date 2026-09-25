import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/data/models/comercio_model.dart';
import 'package:arequipagocreditos/presentation/components/comercio_card.dart';

/// Mismo control que en la tarjeta de taller: la fila de rubro + servicios +
/// botones no debe desbordarse en teléfonos angostos.
void main() {
  ComercioModel comercioDePrueba({String rubro = 'Minimarkets y Bodegas', int servicios = 3}) {
    return ComercioModel.fromJson({
      'id': 1,
      'razon_social': 'VASQUEZ SOLIS EDIMAR EDUARDO',
      'nombre_comercial': 'BODEGITA DOÑA PETITA',
      'categoria': {'id': 1, 'nombre': rubro},
      'direccion': 'Av. La Cultura K-15, Arequipa',
      'telefono': '+51 993 570 000',
      'servicios_count': servicios,
      'google_maps_url': 'https://maps.google.com/?q=x',
      'whatsapp_url': 'https://wa.me/51993570000',
    });
  }

  Future<void> renderizar(WidgetTester tester, double ancho, ComercioModel comercio) async {
    tester.view.physicalSize = Size(ancho, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ComercioCard(comercio: comercio)),
        ),
      ),
    );
  }

  testWidgets('la tarjeta de comercio no se desborda en pantallas angostas', (tester) async {
    for (final ancho in [320.0, 360.0, 411.0]) {
      await renderizar(tester, ancho, comercioDePrueba());
      expect(tester.takeException(), isNull, reason: 'Se desbordó a $ancho px de ancho');
    }
  });

  testWidgets('tampoco se desborda con un rubro largo', (tester) async {
    await renderizar(
      tester,
      320,
      comercioDePrueba(rubro: 'Restaurantes, cafeterías y comida rápida', servicios: 128),
    );
    expect(tester.takeException(), isNull);
  });
}
