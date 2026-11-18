import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/data/models/izipay_models.dart';
import 'package:arequipagocreditos/presentation/components/pago_inscripcion_registro.dart';
import 'package:arequipagocreditos/presentation/components/yape_widgets.dart';

/// Paso de pago del registro: cada método lleva SU logo (Caja Arequipa, IziPay y Yape), como en la pantalla de estado de la solicitud,
/// y no íconos genéricos. Los títulos quedan alineados porque todos los logos van en una caja del mismo ancho.
InscripcionPagoInfoModel _info({bool yape = true}) => InscripcionPagoInfoModel.fromJson({
      'tipo': 'conductor',
      'monto': 50,
      'caja_arequipa': {'disponible': true},
      'izipay': {'disponible': true, 'qr_url': 'https://credigo.test/qr.png'},
      if (yape) 'yape': {'disponible': true, 'proximamente': false, 'monto': 50, 'recargo': 0, 'total': 50},
    });

Widget _paso(InscripcionPagoInfoModel info) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PagoInscripcionRegistro(
            info: info,
            cargando: false,
            error: null,
            metodo: null,
            captura: null,
            operacionController: TextEditingController(),
            onMetodo: (_) {},
            onElegirCaptura: () {},
            onReintentar: () {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('Caja Arequipa e IziPay se ven con su logo, no con un ícono genérico', (tester) async {
    await tester.pumpWidget(_paso(_info(yape: false)));
    await tester.pump();

    final caja = find.descendant(of: find.byKey(const Key('pago_metodo_caja')), matching: find.byType(SvgPicture));
    final izipay = find.descendant(of: find.byKey(const Key('pago_metodo_izipay')), matching: find.byType(SvgPicture));
    expect(caja, findsOneWidget);
    expect(izipay, findsOneWidget);
    expect((tester.widget<SvgPicture>(caja).bytesLoader as SvgAssetLoader).assetName, 'images/logo_caja_arequipa.svg');
    expect((tester.widget<SvgPicture>(izipay).bytesLoader as SvgAssetLoader).assetName, 'images/logo_izipay.svg');

    expect(find.byIcon(Icons.storefront_outlined), findsNothing);
    expect(find.byIcon(Icons.qr_code_2_rounded), findsNothing);
  });

  testWidgets('los tres métodos (Caja, IziPay y Yape) ponen su título en la misma columna', (tester) async {
    await tester.pumpWidget(_paso(_info()));
    await tester.pump();

    expect(find.byType(YapeLogo), findsOneWidget);
    final xCaja = tester.getTopLeft(find.text('Caja Arequipa')).dx;
    expect(tester.getTopLeft(find.text('QR IziPay')).dx, xCaja);
    expect(tester.getTopLeft(find.text('Yape')).dx, xCaja);
  });

  testWidgets('con Yape en «Próximamente» su tarjeta también alinea el título con los demás', (tester) async {
    final proximamente = InscripcionPagoInfoModel.fromJson({
      'tipo': 'conductor',
      'monto': 50,
      'caja_arequipa': {'disponible': true},
      'izipay': {'disponible': true, 'qr_url': 'https://credigo.test/qr.png'},
      'yape': {'disponible': false, 'proximamente': true, 'monto': 50, 'recargo': 0, 'total': 50},
    });
    await tester.pumpWidget(_paso(proximamente));
    await tester.pump();

    final xCaja = tester.getTopLeft(find.text('Caja Arequipa')).dx;
    expect(tester.getTopLeft(find.text('Yape')).dx, xCaja);
    expect(find.text('Próximamente'), findsOneWidget);
  });
}
