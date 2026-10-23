import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/models/nivel_taller_model.dart';
import 'package:arequipagocreditos/domain/entities/conductor_entity.dart';
import 'package:arequipagocreditos/domain/entities/nivel_taller_entity.dart';
import 'package:arequipagocreditos/domain/repositories/nivel_taller_repository.dart';
import 'package:arequipagocreditos/domain/usecases/get_nivel_taller_usecase.dart';
import 'package:arequipagocreditos/presentation/components/nivel_insignia.dart';
import 'package:arequipagocreditos/presentation/pages/mi_nivel_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/nivel_taller_provider.dart';

// TK-0390: los niveles los administra el Director desde el panel (Pollito como nivel base, y los que él cree con su nombre e
// imagen). «Mi nivel» no trae nada escrito en el código: nombre e imagen llegan del servidor, así un cambio en el panel se ve en el app
// al abrir la pantalla, sin publicar otra versión. Un servidor anterior (sin nombre ni imagen) sigue viéndose como siempre.

Map<String, dynamic> _json({
  required int finalizados,
  String? actual,
  String? actualNombre,
  String? siguiente,
  String? siguienteNombre,
  int? faltantes,
  List<Map<String, dynamic>>? niveles,
  bool conNombres = true,
}) {
  Map<String, dynamic> nivel(String codigo, String nombre, int requeridos, {String? imagen, bool base = false, Object? porcentajes}) => {
        'nivel': codigo,
        if (conNombres) 'nombre': nombre,
        if (conNombres) 'imagen_url': imagen,
        if (conNombres) 'es_base': base,
        'financiamientos_requeridos': requeridos,
        'porcentajes': porcentajes ?? {'taller': 30.0, 'celular': 40.0},
      };

  return {
    'cliente_conductor_id': 601,
    'financiamientos_finalizados': finalizados,
    'nivel_actual': actual,
    if (conNombres) 'nivel_actual_nombre': actualNombre,
    'porcentaje_inicial_actual': {'taller': null, 'celular': null},
    'siguiente_nivel': siguiente,
    if (conNombres) 'siguiente_nivel_nombre': siguienteNombre,
    'financiamientos_faltantes': faltantes,
    'niveles': niveles ??
        [
          nivel('pollito', 'Pollito', 0, base: true, porcentajes: []), // el servidor manda [] cuando el nivel no tiene % propio
          nivel('bronce', 'Bronce', 3),
          nivel('plata', 'Plata', 6, porcentajes: {'taller': 20.0, 'celular': 30.0}),
          nivel('oro', 'Oro', 9, porcentajes: {'taller': 10.0, 'celular': 20.0}),
        ],
  };
}

class _Usuario extends Fake implements ConductorEntity {
  @override
  int get idConductor => 601;
}

class _Auth extends Fake implements AuthProvider {
  @override
  ConductorEntity? get currentUser => _Usuario();
}

class _Repo implements NivelTallerRepository {
  _Repo(this.nivel);
  final NivelTallerEntity nivel;

  @override
  Future<Either<Failure, NivelTallerEntity>> getMiNivel({required int clienteConductorId}) async => Either.right(nivel);
}

Future<void> _abrirMiNivel(WidgetTester tester, Map<String, dynamic> json) async {
  tester.view.physicalSize = const Size(412, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NivelTallerProvider>(
          create: (_) => NivelTallerProvider(getNivelTallerUseCase: GetNivelTallerUseCase(_Repo(NivelTallerModel.fromJson(json)))),
        ),
        Provider<AuthProvider>.value(value: _Auth()),
      ],
      child: const MaterialApp(home: MiNivelPage()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  // AuthProvider es un ChangeNotifier y aquí se da con `Provider.value` (la pantalla solo lo lee): provider lo advierte.
  setUpAll(() => Provider.debugCheckInvalidValueType = null);

  group('modelo', () {
    test('lee nombre, imagen y nivel base de cada nivel, y el nombre del nivel actual y del siguiente', () {
      final nivel = NivelTallerModel.fromJson(_json(
        finalizados: 1,
        actual: 'pollito',
        actualNombre: 'Pollito',
        siguiente: 'bronce',
        siguienteNombre: 'Bronce',
        faltantes: 2,
        niveles: [
          {'nivel': 'pollito', 'nombre': 'Pollito', 'imagen_url': 'https://x.test/storage/niveles/pollito.webp', 'es_base': true, 'financiamientos_requeridos': 0, 'porcentajes': []},
          {'nivel': 'bronce', 'nombre': 'Bronce', 'imagen_url': null, 'es_base': false, 'financiamientos_requeridos': 3, 'porcentajes': {'taller': 30.0}},
        ],
      ));

      expect(nivel.tieneNivel, isTrue);
      expect(nivel.nombreNivelActual, 'Pollito');
      expect(nivel.nombreSiguienteNivel, 'Bronce');
      expect(nivel.niveles.first.esBase, isTrue);
      expect(nivel.niveles.first.imagenUrl, 'https://x.test/storage/niveles/pollito.webp');
      expect(nivel.niveles.first.porcentajesPorCategoria, isEmpty); // Pollito no cambia la inicial del servicio
      expect(nivel.niveles.last.imagenUrl, isNull);
      expect(nivel.infoNivelActual?.nivel, 'pollito');
    });

    test('un servidor anterior (sin nombre ni imagen) se ve como siempre: el código con mayúscula', () {
      final nivel = NivelTallerModel.fromJson(_json(finalizados: 4, actual: 'bronce', siguiente: 'plata', faltantes: 2, conNombres: false));

      expect(nivel.nombreNivelActual, 'Bronce');
      expect(nivel.nombreSiguienteNivel, 'Plata');
      expect(nivel.niveles.map((n) => n.nombreVisible), ['Pollito', 'Bronce', 'Plata', 'Oro']);
      expect(nivel.niveles.every((n) => n.imagenUrl == null && !n.esBase), isTrue);
    });

    test('sin nivel (ningún nivel configurado) no inventa un nombre', () {
      final nivel = NivelTallerModel.fromJson(_json(finalizados: 0, niveles: []));

      expect(nivel.tieneNivel, isFalse);
      expect(nivel.nombreNivelActual, isNull);
      expect(nivel.nombreSiguienteNivel, isNull);
    });

    test('el progreso hacia el siguiente nivel cuenta desde Pollito (0 finalizados): 2 de 3', () {
      final nivel = NivelTallerModel.fromJson(_json(finalizados: 2, actual: 'pollito', siguiente: 'bronce', faltantes: 1));

      expect(nivel.progresoSiguienteNivel, closeTo(2 / 3, 0.001));
    });
  });

  group('imagen del nivel', () {
    testWidgets('los niveles de siempre usan la imagen que trae el app; uno nuevo sin imagen, una medalla genérica', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Row(children: [
          NivelInsignia(codigo: 'pollito', key: Key('pollito')),
          NivelInsignia(codigo: 'bronce', key: Key('bronce')),
          NivelInsignia(codigo: 'super-estrella', key: Key('nuevo')),
        ]),
      ));

      expect(NivelInsignia.assetPara('pollito'), 'images/nivel_pollito.webp');
      expect(NivelInsignia.assetPara('oro'), 'images/nivel_oro.svg');
      expect(NivelInsignia.assetPara('super-estrella'), isNull);
      expect(find.descendant(of: find.byKey(const Key('pollito')), matching: find.byType(Image)), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('nuevo')), matching: find.byIcon(Icons.workspace_premium_rounded)), findsOneWidget);
    });

    testWidgets('si el nivel tiene imagen subida desde el panel la pide al servidor, y si no carga cae a la del app', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: NivelInsignia(codigo: 'super-estrella', imagenUrl: 'https://no-existe.invalid/niveles/estrella.webp'),
      ));

      final imagen = tester.widget<Image>(find.byType(Image));
      expect(imagen.image, isA<NetworkImage>());
      expect((imagen.image as NetworkImage).url, 'https://no-existe.invalid/niveles/estrella.webp');

      // Sin internet (en la prueba la descarga falla): se ve la medalla genérica en vez de un hueco o una excepción.
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });
  });

  group('pantalla Mi nivel', () {
    testWidgets('un conductor nuevo ve su nivel Pollito, cuánto le falta para Bronce y la tabla con todos los niveles', (tester) async {
      await _abrirMiNivel(tester, _json(finalizados: 1, actual: 'pollito', actualNombre: 'Pollito', siguiente: 'bronce', siguienteNombre: 'Bronce', faltantes: 2));

      expect(find.byKey(const Key('nivel_actual_nombre')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('nivel_actual_nombre'))).data, 'Pollito');
      expect(find.text('1 financiamiento finalizado'), findsOneWidget);
      expect(find.byKey(const Key('nivel_actual_insignia')), findsOneWidget);
      expect(find.textContaining('Te faltan', findRichText: true), findsOneWidget);
      expect(find.textContaining('2 financiamientos finalizados para llegar al nivel Bronce', findRichText: true), findsOneWidget);
      for (final nombre in ['Bronce', 'Plata', 'Oro']) {
        expect(find.text(nombre), findsOneWidget);
      }
      expect(find.text('0 financiamientos finalizados'), findsOneWidget); // fila de Pollito en la tabla
      expect(tester.takeException(), isNull);
    });

    testWidgets('un nivel que creó el Director aparece con su nombre, tal cual lo escribió', (tester) async {
      await _abrirMiNivel(
        tester,
        _json(
          finalizados: 12,
          actual: 'super-estrella',
          actualNombre: 'Súper Estrella',
          niveles: [
            {'nivel': 'oro', 'nombre': 'Oro', 'imagen_url': null, 'es_base': false, 'financiamientos_requeridos': 9, 'porcentajes': {'taller': 10.0, 'celular': 20.0}},
            {'nivel': 'super-estrella', 'nombre': 'Súper Estrella', 'imagen_url': 'https://no-existe.invalid/e.webp', 'es_base': false, 'financiamientos_requeridos': 12, 'porcentajes': []},
          ],
        ),
      );

      expect(tester.widget<Text>(find.byKey(const Key('nivel_actual_nombre'))).data, 'Súper Estrella');
      expect(find.text('Súper Estrella'), findsNWidgets(2)); // tarjeta «Tu nivel» y fila de la tabla
      expect(find.textContaining('Ya alcanzaste el nivel más alto', findRichText: true), findsOneWidget);
    });

    testWidgets('con un servidor anterior sigue viéndose Bronce/Plata/Oro como siempre', (tester) async {
      await _abrirMiNivel(tester, _json(finalizados: 4, actual: 'bronce', siguiente: 'plata', faltantes: 2, conNombres: false));

      expect(tester.widget<Text>(find.byKey(const Key('nivel_actual_nombre'))).data, 'Bronce');
      expect(find.textContaining('al nivel Plata', findRichText: true), findsOneWidget);
    });

    testWidgets('sin ningún nivel configurado no se rompe: «Aún sin nivel»', (tester) async {
      await _abrirMiNivel(tester, _json(finalizados: 0, niveles: []));

      expect(tester.widget<Text>(find.byKey(const Key('nivel_actual_nombre'))).data, 'Aún sin nivel');
      expect(find.byKey(const Key('nivel_actual_insignia')), findsNothing);
    });
  });
}
