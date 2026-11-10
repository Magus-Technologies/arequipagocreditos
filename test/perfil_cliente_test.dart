import 'package:arequipagocreditos/data/datasources/documentos_pendientes_remote_datasource.dart';
import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/domain/entities/conductor_entity.dart';
import 'package:arequipagocreditos/presentation/components/perfil_seccion_card.dart';
import 'package:arequipagocreditos/presentation/components/personal_info_card.dart';
import 'package:arequipagocreditos/presentation/components/profile_avatar.dart';
import 'package:arequipagocreditos/presentation/components/vehiculo_info_card.dart';
import 'package:arequipagocreditos/presentation/pages/perfil_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

/// Perfil del cliente (10-nov): antes la cabecera (foto, nombre, DNI) quedaba FIJA ocupando media pantalla y solo se deslizaba un recuadro
/// pequeño, todo iba centrado y los datos del vehículo eran una lista larga. Ahora es una sola página que se desliza completa, con la
/// foto y el nombre arriba a la izquierda y las secciones en tarjetas.

class _AuthFalso extends ChangeNotifier implements AuthProvider {
  _AuthFalso(this._usuario);

  final ConductorEntity _usuario;

  @override
  ConductorEntity? get currentUser => _usuario;

  @override
  bool get isLoading => false;

  @override
  Future<bool> refreshUserDataFromRemote() async => true;

  @override
  Future<void> refreshUserDataSilently() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ConductorEntity _flota() => const ConductorEntity(
      idConductor: 82,
      nombres: 'JUAN AGUSTO SANJINES HUALPA',
      nroDocumento: '43373493',
      telefono: '959123456',
      direccion: 'Urb. Miguel Grau Mz. D Lt. 12, Cerro Colorado, Arequipa',
      correo: 'juan@example.com',
      flag: 1,
      tipo: 1,
      fotoPerfilCambiada: false,
      fechaNacimiento: '1988-03-14',
      placa: 'VEG-110',
      soat: '2030-01-15',
      revisionTecnica: '2020-02-10',
      seguroVehicular: '2030-06-01',
      color: 'GRIS',
      anio: 2019,
      marca: 'TOYOTA',
      modelo: 'YARIS',
    );

ConductorModel _modelo({Map<String, dynamic> extra = const {}}) => ConductorModel.fromJson({
      'conductor': {
        'id_conductor': 82,
        'nro_documento': '43373493',
        'nombres': 'JUAN AGUSTO',
        'tipo': 1,
        'foto_perfil_cambiada': 0,
        ...extra,
      },
    });

Future<void> _pintarPerfil(WidgetTester tester, {Size tam = const Size(390, 700)}) async {
  tester.view.physicalSize = tam * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: _AuthFalso(_flota()),
        // «Mis documentos» consulta al servidor: aquí contesta una lista vacía (la tarjeta tiene sus propias pruebas).
        child: PerfilPage(
          documentosServicio: DocumentosPendientesRemoteDataSource(
            client: MockClient((_) async => http.Response('{"success":true,"data":[]}', 200, headers: {'content-type': 'application/json'})),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('estado de un documento del vehículo', () {
    final hoy = DateTime(2026, 11, 10);

    test('vencido el día siguiente a su fecha; vence hoy todavía cuenta como por vencer', () {
      expect(estadoVencimiento('2026-11-09', hoy: hoy), EstadoVencimiento.vencido);
      expect(estadoVencimiento('2026-11-10', hoy: hoy), EstadoVencimiento.porVencer);
    });

    test('por vencer hasta 30 días; después, vigente', () {
      expect(estadoVencimiento('2026-12-10', hoy: hoy), EstadoVencimiento.porVencer); // 30 días
      expect(estadoVencimiento('2026-12-11', hoy: hoy), EstadoVencimiento.vigente); // 31 días
    });

    test('una fecha que no se entiende, o vacía, no muestra ningún aviso', () {
      expect(estadoVencimiento(null, hoy: hoy), isNull);
      expect(estadoVencimiento('', hoy: hoy), isNull);
      expect(estadoVencimiento('pronto', hoy: hoy), isNull);
    });

    test('las fechas se muestran como día/mes/año; lo que no es fecha se deja tal cual y vacío dice «No disponible»', () {
      expect(fechaLegible('2026-11-25'), '25/11/2026');
      expect(fechaLegible('2026-11-25T00:00:00.000000Z'), '25/11/2026');
      expect(fechaLegible('Pendiente'), 'Pendiente');
      expect(fechaLegible(null), 'No disponible');
      expect(fechaLegible('  '), 'No disponible');
    });
  });

  group('pantalla del perfil', () {
    testWidgets('toda la pantalla se desliza: la foto y el nombre suben junto con el resto (ya no quedan fijos)', (tester) async {
      await _pintarPerfil(tester);

      // skipOffstage: false → se sigue encontrando la foto aunque ya haya salido por arriba.
      final foto = find.byType(ProfileAvatar, skipOffstage: false);
      final antes = tester.getTopLeft(foto).dy;
      expect(find.text('JUAN AGUSTO SANJINES HUALPA'), findsOneWidget);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
      await tester.pump(const Duration(milliseconds: 500));

      final despues = tester.getTopLeft(foto).dy;
      expect(despues, lessThan(antes - 100), reason: 'la cabecera debe moverse al deslizar');
    });

    testWidgets('hay un solo desplazamiento (no un recuadro pequeño dentro de una cabecera fija)', (tester) async {
      await _pintarPerfil(tester);

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('el nombre y el DNI quedan a la izquierda, junto a la foto, y no centrados debajo', (tester) async {
      await _pintarPerfil(tester);

      final foto = tester.getRect(find.byType(ProfileAvatar));
      final nombre = tester.getRect(find.text('JUAN AGUSTO SANJINES HUALPA'));

      expect(nombre.left, greaterThan(foto.right), reason: 'el nombre va a la derecha de la foto');
      expect(nombre.top, lessThan(foto.bottom), reason: 'y a su altura, no debajo');
    });

    testWidgets('las secciones salen en orden de arriba hacia abajo: información personal y luego el vehículo', (tester) async {
      await _pintarPerfil(tester, tam: const Size(390, 1600));

      final personal = tester.getTopLeft(find.text('Información personal')).dy;
      final vehiculo = tester.getTopLeft(find.text('Datos del vehículo')).dy;
      final cerrar = tester.getTopLeft(find.text('Cerrar Sesión')).dy;

      expect(personal, lessThan(vehiculo));
      expect(vehiculo, lessThan(cerrar));
      // Con la pantalla muy alta el contenido sigue arriba: no se reparte ni se centra en vertical.
      expect(personal, lessThan(500));
    });
  });

  group('tarjetas del perfil', () {
    testWidgets('información personal: fecha legible y «No disponible» en lo que falta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PersonalInfoCard(conductor: _modelo(extra: {'fecha_nacimiento': '1988-03-14', 'telefono': '959123456'})),
            ),
          ),
        ),
      );

      expect(find.text('14/03/1988'), findsOneWidget);
      expect(find.text('959123456'), findsOneWidget);
      // Sin correo ni dirección.
      expect(find.text('No disponible'), findsWidgets);
    });

    testWidgets('vehículo: cada documento muestra su vencimiento y si está vencido, por vencer o vigente', (tester) async {
      final ahora = DateTime.now();
      String iso(DateTime f) => '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VehiculoInfoCard(
                conductor: _modelo(extra: {
                  'placa': 'VEG-110',
                  'soat': iso(ahora.subtract(const Duration(days: 5))),
                  'revision_tecnica': iso(ahora.add(const Duration(days: 10))),
                  'seguro_vehicular': iso(ahora.add(const Duration(days: 200))),
                }),
              ),
            ),
          ),
        ),
      );

      expect(find.text('VEG-110'), findsOneWidget);
      expect(find.text('Vencido'), findsOneWidget);
      expect(find.text('Por vencer'), findsOneWidget);
      expect(find.text('Vigente'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
    });
  });
}
