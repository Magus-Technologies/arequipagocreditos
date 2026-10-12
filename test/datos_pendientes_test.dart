import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/presentation/components/datos_pendientes_banner.dart';

/// TK-0357: el servidor manda `datos_pendientes` (foto de perfil, DNI, SOAT) y el app lo avisa en un banner rojo.
/// Con algo pendiente el cliente no puede generar financiamientos; sin nada pendiente no se dibuja nada.
Map<String, dynamic> _conductorJson({Object? pendientes}) => {
      'success': true,
      'flag': 0,
      'conductor': {
        'id_conductor': 82,
        'nro_documento': '43373493',
        'nombres': 'JUAN AGUSTO',
        'tipo': 1,
        'foto_perfil_cambiada': 0,
        if (pendientes != null) 'datos_pendientes': pendientes,
      },
    };

const _pendientes = [
  {'codigo': 'foto_perfil', 'mensaje': 'Falta la foto de perfil', 'descripcion': 'Debe subir una foto de perfil.'},
  {'codigo': 'soat_vencido', 'mensaje': 'SOAT vencido (29/01/2026)', 'descripcion': 'El SOAT del vehículo está vencido. Debe actualizarlo.'},
];

Future<void> _pintar(WidgetTester tester, Widget banner) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: banner))));

void main() {
  group('datos_pendientes del perfil', () {
    test('se leen del JSON del servidor, con su mensaje', () {
      final c = ConductorModel.fromJson(_conductorJson(pendientes: _pendientes));

      expect(c.datosPendientes, hasLength(2));
      expect(c.datosPendientes.first['mensaje'], 'Falta la foto de perfil');
      expect(c.datosPendientes.last['codigo'], 'soat_vencido');
    });

    test('un perfil sin el campo o con la lista vacía está al día', () {
      expect(ConductorModel.fromJson(_conductorJson()).datosPendientes, isEmpty);
      expect(ConductorModel.fromJson(_conductorJson(pendientes: const [])).datosPendientes, isEmpty);
    });

    test('se conservan al guardar la sesión y al pasar a entidad', () {
      final c = ConductorModel.fromJson(_conductorJson(pendientes: _pendientes));

      expect(c.toJson()['datos_pendientes'], hasLength(2));
      expect(c.toEntity().datosPendientes, hasLength(2));
      expect(ConductorModel.fromJson({'conductor': c.toJson()}).datosPendientes, hasLength(2));
    });
  });

  group('banner de datos por actualizar', () {
    testWidgets('lista cada dato pendiente y avisa que no puede financiar', (tester) async {
      await _pintar(tester, const DatosPendientesBanner(pendientes: _pendientes));

      expect(find.text('Tienes datos por actualizar'), findsOneWidget);
      expect(find.textContaining('No podrás solicitar un financiamiento'), findsOneWidget);
      expect(find.text('Falta la foto de perfil'), findsOneWidget);
      expect(find.text('SOAT vencido (29/01/2026)'), findsOneWidget);
      // Sin callback no ofrece el botón.
      expect(find.text('Actualizar ahora'), findsNothing);
    });

    testWidgets('con callback ofrece «Actualizar ahora»', (tester) async {
      var toques = 0;
      await _pintar(tester, DatosPendientesBanner(pendientes: _pendientes, onActualizar: () => toques++));

      await tester.tap(find.text('Actualizar ahora'));

      expect(toques, 1);
    });

    testWidgets('al día no dibuja nada', (tester) async {
      await _pintar(tester, const DatosPendientesBanner(pendientes: []));

      expect(find.byKey(const Key('datos_pendientes_banner')), findsNothing);
      expect(find.text('Tienes datos por actualizar'), findsNothing);
    });
  });
}
