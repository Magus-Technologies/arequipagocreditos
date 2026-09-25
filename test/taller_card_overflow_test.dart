import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/data/models/taller_model.dart';
import 'package:arequipagocreditos/presentation/components/taller_card.dart';

/// La fila de "N servicios · Mapa · Chat" se pasaba 12 px en pantallas
/// angostas: en debug salían las franjas amarillas y en release el botón de
/// WhatsApp quedaba recortado sin aviso.
///
/// El test renderiza la tarjeta en anchos reales de teléfono; si algo se
/// desborda, flutter_test lo reporta como error y el test falla.
void main() {
  TallerModel tallerDePrueba({int serviciosCount = 4}) {
    return TallerModel.fromJson({
      'id': 1,
      'razon_social': 'AREQUIPA GO S.A.C.',
      'nombre_comercial': 'ArequipaGO',
      'direccion': 'Av. La Cultura K-15, Arequipa',
      'telefono': '+51 993 570 000',
      'servicios_count': serviciosCount,
      'activo': true,
      'google_maps_url': 'https://maps.google.com/?q=arequipago',
      'whatsapp_url': 'https://wa.me/51993570000',
      'ubicaciones': const [],
    });
  }

  Future<void> renderizar(WidgetTester tester, Size tamano, TallerModel taller) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TallerCard(taller: taller, onTap: () {}),
          ),
        ),
      ),
    );
  }

  testWidgets('la tarjeta de taller no se desborda en pantallas angostas', (tester) async {
    // 320 es el ancho más chico que se ve en la práctica (iPhone SE 1ª gen).
    for (final ancho in [320.0, 360.0, 411.0]) {
      await renderizar(tester, Size(ancho, 800), tallerDePrueba());
      expect(tester.takeException(), isNull, reason: 'Se desbordó a $ancho px de ancho');
    }
  });

  testWidgets('tampoco se desborda con muchos servicios', (tester) async {
    await renderizar(tester, const Size(320, 800), tallerDePrueba(serviciosCount: 128));
    expect(tester.takeException(), isNull);
  });
}
