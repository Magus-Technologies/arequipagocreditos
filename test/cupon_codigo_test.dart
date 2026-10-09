import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/data/models/cupon_model.dart';
import 'package:arequipagocreditos/data/models/uso_cupon_model.dart';
import 'package:arequipagocreditos/presentation/widgets/confirmacion_uso_cupon_dialog.dart';
import 'package:arequipagocreditos/presentation/widgets/cupon_card.dart';
import 'package:arequipagocreditos/presentation/widgets/cupon_usado_dialog.dart';

/// TK-0359 — Cupones: resumen «Confirmar uso», «¡Cupón usado!» con el código de 24 h, «Ver código» y «Código vencido».
String _iso(DateTime fecha) => fecha.toUtc().toIso8601String();

Map<String, dynamic> _usoJson({Duration vence = const Duration(hours: 23), String codigo = '583921'}) => {
      'cupon_id': 24,
      'numero': '000024',
      'establecimiento': 'Restaurante XYZ',
      'tipo_descuento': 'monto_fijo',
      'valor_descuento': '10.00',
      'monto_descuento': 10,
      'precio_normal': '15.00',
      'monto_pagar': 5,
      'codigo': codigo,
      'generado_at': _iso(DateTime.now().subtract(const Duration(hours: 1))),
      'vence_at': _iso(DateTime.now().add(vence)),
      'usos_restantes': 0,
      'horas_vigencia': 24,
    };

Map<String, dynamic> _cuponJson({
  String tipo = 'monto_fijo',
  num valor = 10,
  Object? precioNormal = 15,
  Object? montoDescuento = 10,
  Object? montoPagar = 5,
  String estadoUso = 'disponible',
  Map<String, dynamic>? usoVigente,
  bool puedeUsar = true,
  int usosRealizados = 0,
}) =>
    {
      'id': 24,
      'titulo': 'DON TORIBIO CARNES Y VINOS',
      'categoria': 'restaurantes',
      'descripcion': 'Descuentos exclusivos',
      'tipo_descuento': tipo,
      'valor': valor,
      'fecha_fin': _iso(DateTime.now().add(const Duration(days: 60))),
      'activo': true,
      'limite_usos_conductor': 1,
      'usos_realizados': usosRealizados,
      'puede_usar': puedeUsar,
      'estado': 'activo',
      'numero': '000024',
      'establecimiento': 'Restaurante XYZ',
      'precio_normal': precioNormal,
      'monto_descuento_estimado': montoDescuento,
      'monto_pagar_estimado': montoPagar,
      'estado_uso': estadoUso,
      'uso_vigente': usoVigente,
      'condiciones': 'Válido según términos y condiciones.',
    };

/// Abre el diálogo desde un botón, como en la pantalla real (así `Navigator.pop` tiene a dónde volver).
Future<void> _abrir(WidgetTester tester, WidgetBuilder dialogo) async {
  // Pantalla de celular alta: el resumen con precios es más alto que los 600 px de la pantalla de prueba por defecto.
  tester.view.physicalSize = const Size(420, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showDialog<void>(context: context, builder: dialogo),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('modelos', () {
    test('el uso trae el código, el vencimiento a 24 h y lo que paga en el establecimiento', () {
      final uso = UsoCuponModel.fromJson(_usoJson());

      expect(uso.codigo, '583921');
      expect(uso.numero, '000024');
      expect(uso.establecimiento, 'Restaurante XYZ');
      expect(uso.montoPagar, 5.0);
      expect(uso.precioNormal, 15.0);
      expect(uso.vigente, isTrue);
      expect(uso.descuentoTexto, 'S/10.00');
      expect(uso.restanteTexto, matches(r'^22 h|^23 h'));
      expect(uso.horasVigencia, 24);
    });

    test('un porcentaje sin monto en soles se muestra como porcentaje', () {
      final uso = UsoCuponModel.fromJson({..._usoJson(), 'tipo_descuento': 'porcentaje', 'valor_descuento': 10, 'monto_descuento': 0});

      expect(uso.descuentoTexto, '10% OFF');
    });

    test('un código ya vencido deja de estar vigente', () {
      final uso = UsoCuponModel.fromJson(_usoJson(vence: const Duration(hours: -1)));

      expect(uso.vigente, isFalse);
      expect(uso.restanteTexto, 'menos de 1 min');
    });

    test('una respuesta de un servidor anterior (sin código) no rompe nada', () {
      final uso = UsoCuponModel.fromJson({'id': 5, 'cupon_id': 24, 'monto_descuento': '0.00'});

      expect(uso.tieneCodigo, isFalse);
      expect(uso.numero, '000024');
    });

    test('el cupón lee su estado de uso y el código vigente; con código vigente ya no se puede volver a usar', () {
      final cupon = CuponModel.fromJson(_cuponJson(
        estadoUso: 'usado',
        puedeUsar: false,
        usosRealizados: 1,
        usoVigente: _usoJson(),
      ));

      expect(cupon.numeroFormateado, '000024');
      expect(cupon.nombreEstablecimiento, 'Restaurante XYZ');
      expect(cupon.tieneCodigoVigente, isTrue);
      expect(cupon.puedeUsarse, isFalse);
      expect(cupon.montoPagarEstimado, 5.0);
    });

    test('un cupón disponible se puede usar; si el servidor dice que no puede, no', () {
      expect(CuponModel.fromJson(_cuponJson()).puedeUsarse, isTrue);
      expect(CuponModel.fromJson(_cuponJson(puedeUsar: false)).puedeUsarse, isFalse);
    });

    test('sin establecimiento se usa el título y sin número el id con ceros', () {
      final json = _cuponJson()..remove('numero')..['establecimiento'] = null;
      final cupon = CuponModel.fromJson(json);

      expect(cupon.nombreEstablecimiento, 'DON TORIBIO CARNES Y VINOS');
      expect(cupon.numeroFormateado, '000024');
    });
  });

  group('Confirmar uso de cupón', () {
    testWidgets('muestra el resumen del diseño: N.°, establecimiento, descuento, precio normal, lo que pagas y que el código se genera al confirmar', (tester) async {
      await _abrir(tester, (_) => ConfirmacionUsoCuponDialog(cupon: CuponModel.fromJson(_cuponJson()), onConfirm: () {}));

      expect(find.text('Confirmar Uso de Cupón'), findsOneWidget);
      expect(find.text('¿Deseas utilizar este cupón?'), findsOneWidget);
      expect(find.text('Cupón N.° 000024'), findsOneWidget);
      expect(find.text('Restaurante XYZ'), findsOneWidget);
      expect(find.byKey(const Key('cupon_descuento')), findsOneWidget);
      expect(find.text('S/10.00'), findsOneWidget);
      expect(find.text('S/15.00'), findsOneWidget);
      expect(find.text('S/5.00'), findsOneWidget);
      expect(find.text('Código: se generará al confirmar'), findsOneWidget);
      expect(find.text('Usos restantes: 1'), findsOneWidget);
      expect(find.text('Válido por 24 horas'), findsOneWidget);
      expect(find.text('CONFIRMAR USO'), findsOneWidget);
    });

    testWidgets('un porcentaje sin precio normal muestra solo el porcentaje, sin «Pagas en establecimiento»', (tester) async {
      final cupon = CuponModel.fromJson(_cuponJson(tipo: 'porcentaje', valor: 10, precioNormal: null, montoDescuento: null, montoPagar: null));
      await _abrir(tester, (_) => ConfirmacionUsoCuponDialog(cupon: cupon, onConfirm: () {}));

      expect(find.text('10% OFF'), findsOneWidget);
      expect(find.byKey(const Key('cupon_monto_pagar')), findsNothing);
      expect(find.byKey(const Key('cupon_precio_normal')), findsNothing);
    });

    testWidgets('confirmar dos veces seguidas solo envía el uso una vez', (tester) async {
      var confirmaciones = 0;
      await _abrir(tester, (_) => ConfirmacionUsoCuponDialog(cupon: CuponModel.fromJson(_cuponJson()), onConfirm: () => confirmaciones++));

      final boton = find.byKey(const Key('confirmar_uso_cupon'));
      await tester.tap(boton);
      await tester.tap(boton, warnIfMissed: false); // segundo toque durante la animación de cierre
      await tester.pumpAndSettle();

      expect(confirmaciones, 1);
      expect(find.text('Confirmar Uso de Cupón'), findsNothing);
    });

    testWidgets('cancelar no envía nada', (tester) async {
      var confirmaciones = 0;
      await _abrir(tester, (_) => ConfirmacionUsoCuponDialog(cupon: CuponModel.fromJson(_cuponJson()), onConfirm: () => confirmaciones++));

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(confirmaciones, 0);
    });
  });

  group('¡Cupón usado!', () {
    testWidgets('al confirmar muestra el código y que vale 24 horas', (tester) async {
      await _abrir(tester, (_) => CuponUsadoDialog(uso: UsoCuponModel.fromJson(_usoJson())));

      expect(find.text('¡Cupón Usado!'), findsOneWidget);
      expect(find.text('Cupón usado exitosamente'), findsOneWidget);
      expect(find.byKey(const Key('cupon_codigo')), findsOneWidget);
      expect(find.text('583921'), findsOneWidget);
      expect(find.text('Válido por 24 horas'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);
    });

    testWidgets('al volver a verlo muestra cuánto le queda al código', (tester) async {
      await _abrir(tester, (_) => CuponUsadoDialog(uso: UsoCuponModel.fromJson(_usoJson()), reabierto: true));

      expect(find.text('Tu código del cupón'), findsOneWidget);
      expect(find.textContaining('Vence en'), findsOneWidget);
      expect(find.text('583921'), findsOneWidget);
    });

    testWidgets('un código vencido lo dice', (tester) async {
      await _abrir(tester, (_) => CuponUsadoDialog(uso: UsoCuponModel.fromJson(_usoJson(vence: const Duration(hours: -2))), reabierto: true));

      expect(find.text('Código vencido'), findsOneWidget);
    });

    testWidgets('«Entendido» lo cierra', (tester) async {
      await _abrir(tester, (_) => CuponUsadoDialog(uso: UsoCuponModel.fromJson(_usoJson())));

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(find.text('¡Cupón Usado!'), findsNothing);
    });
  });

  group('tarjeta del cupón', () {
    Future<void> pintar(WidgetTester tester, CuponModel cupon, {VoidCallback? onVerCodigo, VoidCallback? onUsar}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CuponCard(cupon: cupon, onUsar: onUsar ?? () {}, onVerCodigo: onVerCodigo),
          ),
        ),
      ));
    }

    testWidgets('disponible: ofrece «Usar Cupón»', (tester) async {
      await pintar(tester, CuponModel.fromJson(_cuponJson()));

      expect(find.text('Usar Cupón'), findsOneWidget);
      expect(find.text('Ver código'), findsNothing);
    });

    testWidgets('usado con código vigente: pasa a «Usado» y ofrece «Ver código»', (tester) async {
      var vistos = 0;
      final cupon = CuponModel.fromJson(_cuponJson(estadoUso: 'usado', puedeUsar: false, usosRealizados: 1, usoVigente: _usoJson()));
      await pintar(tester, cupon, onVerCodigo: () => vistos++);

      expect(find.text('Usar Cupón'), findsNothing);
      expect(find.textContaining('Usado · código vigente'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ver_codigo_cupon')));
      expect(vistos, 1);
    });

    testWidgets('pasadas las 24 h: «Código vencido», sin botones, y no se puede volver a generar', (tester) async {
      final cupon = CuponModel.fromJson(_cuponJson(estadoUso: 'codigo_vencido', puedeUsar: false, usosRealizados: 1));
      await pintar(tester, cupon);

      expect(find.text('Código vencido'), findsOneWidget);
      expect(find.text('Usar Cupón'), findsNothing);
      expect(find.text('Ver código'), findsNothing);
    });
  });
}
