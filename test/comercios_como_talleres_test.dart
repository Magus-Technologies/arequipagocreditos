import 'dart:convert';

import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/datasources/comercio_remote_datasource.dart';
import 'package:arequipagocreditos/data/models/comercio_model.dart';
import 'package:arequipagocreditos/data/models/promo_taller_banner_model.dart';
import 'package:arequipagocreditos/domain/entities/comercio_entity.dart';
import 'package:arequipagocreditos/domain/entities/conductor_entity.dart';
import 'package:arequipagocreditos/domain/repositories/comercio_repository.dart';
import 'package:arequipagocreditos/domain/usecases/get_comercios_usecase.dart';
import 'package:arequipagocreditos/presentation/components/calificar_sheet.dart';
import 'package:arequipagocreditos/presentation/components/comercio_card.dart';
import 'package:arequipagocreditos/presentation/pages/comercio_detalle_page.dart';
import 'package:arequipagocreditos/presentation/pages/comercios_go_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/domain/entities/beneficio_servicio_entity.dart';
import 'package:arequipagocreditos/presentation/providers/comercios_provider.dart';
import 'package:arequipagocreditos/presentation/providers/financiamiento_servicio_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TK-0382: Comercios GO con lo mismo que Talleres en el app: lista agrupada por ciudad, filtro por tipo de vehículo, la audiencia del
// conductor (el servidor solo manda los comercios con servicios para él) y las calificaciones con estrellas.

Map<String, dynamic> _comercioJson({
  int id = 1,
  String nombre = 'BODEGITA DOÑA PETITA',
  double? promedio,
  int? total,
}) {
  return {
    'id': id,
    'razon_social': 'VASQUEZ SOLIS EDIMAR EDUARDO',
    'nombre_comercial': nombre,
    'categoria': {'id': 1, 'nombre': 'Minimarkets y Bodegas'},
    'direccion': 'Av. La Cultura K-15, Arequipa',
    'servicios_count': 2,
    if (promedio != null) 'promedio_calificacion': promedio,
    if (total != null) 'total_calificaciones': total,
  };
}

ComercioModel _comercio({int id = 1, String nombre = 'Bodega', double? promedio, int? total}) =>
    ComercioModel.fromJson(_comercioJson(id: id, nombre: nombre, promedio: promedio, total: total));

ComercioGrupoEntity _grupo(String nombre, List<ComercioModel> comercios) =>
    ComercioGrupoEntity(nombre: nombre, total: comercios.length, comercios: comercios);

/// Repositorio falso: guarda lo que el provider le pide para comprobar qué viaja al servidor.
class _RepoFalso implements ComercioRepository {
  List<ComercioGrupoEntity> grupos = [];
  bool falla = false;
  Map<String, dynamic>? respuestaCalificar = {'promedio_calificacion': 4.5, 'total_calificaciones': 2};

  final List<Map<String, dynamic>> pedidos = [];
  final List<Map<String, dynamic>> calificaciones = [];

  @override
  Future<Either<Failure, List<ComercioGrupoEntity>>> getComerciosAgrupados({
    int? categoriaId,
    String? departamento,
    String? audiencia,
    String? tipoVehicular,
  }) async {
    pedidos.add({
      'categoriaId': categoriaId,
      'departamento': departamento,
      'audiencia': audiencia,
      'tipoVehicular': tipoVehicular,
    });
    if (falla) return Either.left(const ServerFailure('boom'));
    return Either.right(grupos);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> calificarComercio({
    required int comercioId,
    required int clienteConductorId,
    required int puntuacion,
    String? comentario,
  }) async {
    calificaciones.add({
      'comercioId': comercioId,
      'clienteConductorId': clienteConductorId,
      'puntuacion': puntuacion,
      'comentario': comentario,
    });
    final respuesta = respuestaCalificar;
    if (respuesta == null) return Either.left(const ServerFailure('no se pudo'));
    return Either.right(respuesta);
  }

  @override
  Future<Either<Failure, List<ComercioEntity>>> getComercios({int? categoriaId, String? departamento}) async =>
      Either.right(grupos.expand((g) => g.comercios).toList());

  @override
  Future<Either<Failure, List<ComercioCategoriaEntity>>> getCategorias() async => Either.right(const []);

  @override
  Future<Either<Failure, List<PromoTallerBannerModel>>> getPromocionesBanners({String? departamento}) async =>
      Either.right(const []);
}

ComerciosProvider _provider(_RepoFalso repo) => ComerciosProvider(
      getComerciosUseCase: GetComerciosUseCase(repo),
      getComerciosAgrupadosUseCase: GetComerciosAgrupadosUseCase(repo),
      calificarComercioUseCase: CalificarComercioUseCase(repo),
      getComercioCategoriasUseCase: GetComercioCategoriasUseCase(repo),
      getPromocionesBannersUseCase: GetComercioPromocionesBannersUseCase(repo),
    );

ConductorEntity _conductor({int tipo = 1, int id = 77, String? departamento = 'Arequipa'}) => ConductorEntity(
      idConductor: id,
      nombres: 'Juan Perez',
      nroDocumento: '12345678',
      telefono: '999888777',
      direccion: 'Calle 1',
      departamento: departamento,
      correo: 'juan@example.com',
      flag: 1,
      tipo: tipo,
      fotoPerfilCambiada: false,
    );

/// Solo el usuario actual: es lo único que leen las pantallas de comercios.
class _AuthFalso extends ChangeNotifier implements AuthProvider {
  _AuthFalso(this._usuario);

  final ConductorEntity? _usuario;

  @override
  ConductorEntity? get currentUser => _usuario;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


/// Provider de servicios falso: el detalle solo le pide los servicios del comercio y la audiencia del conductor.
class _ServiciosFalso extends ChangeNotifier implements FinanciamientoServicioProvider {
  final List<String?> audiencias = [];
  final List<Map<String, int?>> cargas = [];

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  List<BeneficioServicioEntity> get beneficios => const [];

  @override
  void setAudiencia(int tipoUsuario) => audiencias.add('tipo-$tipoUsuario');

  @override
  Future<void> loadBeneficiosServicios({int? tallerId, int? comercioId, int? clienteConductorId}) async {
    cargas.add({'tallerId': tallerId, 'comercioId': comercioId, 'clienteConductorId': clienteConductorId});
  }

  @override
  void setBeneficioSearchQuery(String query) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('modelo', () {
    test('lee el promedio y el total de calificaciones', () {
      final comercio = _comercio(promedio: 4.5, total: 12);

      expect(comercio.promedioCalificacion, 4.5);
      expect(comercio.totalCalificaciones, 12);
      expect(comercio.tieneCalificaciones, isTrue);
    });

    test('el promedio puede llegar como texto y sin calificaciones queda en cero', () {
      final comoTexto = ComercioModel.fromJson({..._comercioJson(), 'promedio_calificacion': '3.5', 'total_calificaciones': '4'});
      expect(comoTexto.promedioCalificacion, 3.5);
      expect(comoTexto.totalCalificaciones, 4);

      final sinDatos = _comercio();
      expect(sinDatos.promedioCalificacion, 0.0);
      expect(sinDatos.totalCalificaciones, 0);
      expect(sinDatos.tieneCalificaciones, isFalse);
    });

    test('un grupo trae su ciudad y sus comercios', () {
      final grupo = ComercioGrupoModel.fromJson({
        'nombre': 'Cayma',
        'total': 2,
        'comercios': [_comercioJson(id: 1), _comercioJson(id: 2)],
      });

      expect(grupo.nombre, 'Cayma');
      expect(grupo.total, 2);
      expect(grupo.comercios.map((c) => c.id), [1, 2]);
    });
  });

  group('llamadas al servidor', () {
    MockClient cliente(void Function(http.Request) alPedir, Map<String, dynamic> cuerpo, {int status = 200}) {
      return MockClient((request) async {
        alPedir(request);
        return http.Response(json.encode(cuerpo), status, headers: {'content-type': 'application/json; charset=utf-8'});
      });
    }

    test('pide los comercios agrupados con la audiencia y el tipo de vehículo', () async {
      late Uri pedida;
      final fuente = ComercioRemoteDataSourceImpl(
        client: cliente((r) => pedida = r.url, {
          'success': true,
          'data': {
            'total': 1,
            'grupos': [
              {'nombre': 'Cayma', 'total': 1, 'comercios': [_comercioJson()]},
            ],
          },
        }),
      );

      final grupos = await fuente.getComerciosAgrupados(
        categoriaId: 3,
        departamento: ' Arequipa ',
        audiencia: 'conductores',
        tipoVehicular: 'moto',
      );

      expect(pedida.path, endsWith('/app/comercios-list'));
      expect(pedida.queryParameters, {
        'agrupar': 'true',
        'categoria_id': '3',
        'departamento': 'Arequipa',
        'audiencia': 'conductores',
        'tipo_vehicular': 'moto',
      });
      expect(grupos.single.nombre, 'Cayma');
      expect(grupos.single.comercios.single.nombreComercial, 'BODEGITA DOÑA PETITA');
    });

    test('sin filtros solo pide agrupar', () async {
      late Uri pedida;
      final fuente = ComercioRemoteDataSourceImpl(
        client: cliente((r) => pedida = r.url, {
          'success': true,
          'data': {'total': 0, 'grupos': []},
        }),
      );

      expect(await fuente.getComerciosAgrupados(departamento: '  ', audiencia: '', tipoVehicular: ''), isEmpty);
      expect(pedida.queryParameters, {'agrupar': 'true'});
    });

    test('un error del servidor se lanza con su mensaje', () async {
      final fuente = ComercioRemoteDataSourceImpl(
        client: cliente((_) {}, {'success': false, 'message': 'Sin permiso'}, status: 403),
      );

      expect(fuente.getComerciosAgrupados(), throwsA(predicate((e) => e.toString().contains('Sin permiso'))));
    });

    test('califica un comercio con el conductor, las estrellas y el comentario', () async {
      late http.Request pedida;
      final fuente = ComercioRemoteDataSourceImpl(
        client: cliente((r) => pedida = r, {
          'success': true,
          'data': {'promedio_calificacion': 4.5, 'total_calificaciones': 2},
        }),
      );

      final resultado = await fuente.calificarComercio(
        comercioId: 9,
        clienteConductorId: 77,
        puntuacion: 5,
        comentario: 'Muy buena atención',
      );

      expect(pedida.method, 'POST');
      expect(pedida.url.path, endsWith('/app/comercios-list/9/calificar'));
      expect(json.decode(pedida.body), {
        'cliente_conductor_id': 77,
        'puntuacion': 5,
        'comentario': 'Muy buena atención',
      });
      expect(resultado['promedio_calificacion'], 4.5);
      expect(resultado['total_calificaciones'], 2);
    });

    test('sin comentario no manda el campo', () async {
      late http.Request pedida;
      final fuente = ComercioRemoteDataSourceImpl(
        client: cliente((r) => pedida = r, {
          'success': true,
          'data': {'promedio_calificacion': 4, 'total_calificaciones': 1},
        }),
      );

      await fuente.calificarComercio(comercioId: 9, clienteConductorId: 77, puntuacion: 4);

      expect(json.decode(pedida.body), {'cliente_conductor_id': 77, 'puntuacion': 4});
    });

    test('si el servidor rechaza la calificación lanza el motivo', () async {
      final fuente = ComercioRemoteDataSourceImpl(
        client: cliente((_) {}, {'success': false, 'message': 'Comercio no encontrado'}, status: 404),
      );

      expect(
        fuente.calificarComercio(comercioId: 9, clienteConductorId: 77, puntuacion: 4),
        throwsA(predicate((e) => e.toString().contains('Comercio no encontrado'))),
      );
    });
  });

  group('provider', () {
    test('pide los comercios con la audiencia del conductor y la ciudad', () async {
      final repo = _RepoFalso()..grupos = [_grupo('Cayma', [_comercio(id: 1), _comercio(id: 2)])];
      final provider = _provider(repo)..setAudiencia(4);

      await provider.cargarComercios(departamento: 'Arequipa');

      expect(repo.pedidos.single['audiencia'], 'pasajeros_go');
      expect(repo.pedidos.single['departamento'], 'Arequipa');
      expect(provider.grupos.single.nombre, 'Cayma');
      expect(provider.comercios.map((c) => c.id), [1, 2]);
    });

    test('el tipo de vehículo vuelve a pedir el listado con la misma ciudad', () async {
      final repo = _RepoFalso();
      final provider = _provider(repo)..setAudiencia(1);
      await provider.cargarComercios(departamento: 'Lima');

      await provider.setTipoVehicularFiltro('moto');
      expect(repo.pedidos.last['tipoVehicular'], 'moto');
      expect(repo.pedidos.last['departamento'], 'Lima');
      expect(provider.tipoVehicularFiltro, 'moto');

      await provider.setTipoVehicularFiltro('');
      expect(repo.pedidos.last['tipoVehicular'], isNull);
      expect(provider.tipoVehicularFiltro, isNull);
    });

    test('el buscador deja solo las ciudades con coincidencias y recalcula el total', () async {
      final repo = _RepoFalso()
        ..grupos = [
          _grupo('Cayma', [_comercio(id: 1, nombre: 'Bodega Luna'), _comercio(id: 2, nombre: 'Ferretería Sol')]),
          _grupo('Yanahuara', [_comercio(id: 3, nombre: 'Panadería Sol')]),
          _grupo('Cercado', [_comercio(id: 4, nombre: 'Librería Mar')]),
        ];
      final provider = _provider(repo);
      await provider.cargarComercios();

      expect(provider.filteredGrupos, hasLength(3));

      provider.setSearchQuery('sol');
      final grupos = provider.filteredGrupos;
      expect(grupos.map((g) => g.nombre), ['Cayma', 'Yanahuara']);
      expect(grupos.map((g) => g.total), [1, 1]);
      expect(provider.filteredComercios.map((c) => c.id), [2, 3]);
    });

    test('un error del servidor deja el mensaje y no borra el listado anterior', () async {
      final repo = _RepoFalso()..grupos = [_grupo('Cayma', [_comercio()])];
      final provider = _provider(repo);
      await provider.cargarComercios();

      repo.falla = true;
      await provider.cargarComercios();

      expect(provider.error, isNotNull);
      expect(provider.comercios, hasLength(1));
    });

    test('califica y devuelve el promedio nuevo; si falla devuelve null', () async {
      final repo = _RepoFalso();
      final provider = _provider(repo);

      final ok = await provider.calificarComercio(comercioId: 5, clienteConductorId: 77, puntuacion: 4, comentario: 'bien');
      expect(ok?['promedio_calificacion'], 4.5);
      expect(repo.calificaciones.single, {
        'comercioId': 5,
        'clienteConductorId': 77,
        'puntuacion': 4,
        'comentario': 'bien',
      });

      repo.respuestaCalificar = null;
      expect(await provider.calificarComercio(comercioId: 5, clienteConductorId: 77, puntuacion: 4), isNull);
    });
  });

  group('tarjeta', () {
    Future<void> pintar(WidgetTester tester, double ancho, ComercioModel comercio) async {
      tester.view.physicalSize = Size(ancho, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ComercioCard(comercio: comercio)))));
    }

    testWidgets('muestra las estrellas cuando tiene calificaciones', (tester) async {
      await pintar(tester, 360, _comercio(promedio: 4.5, total: 12));

      expect(find.byKey(const Key('comercio-card-calificacion')), findsOneWidget);
      expect(find.text('4.5 (12)'), findsOneWidget);
    });

    testWidgets('sin calificaciones no muestra nada', (tester) async {
      await pintar(tester, 360, _comercio());

      expect(find.byKey(const Key('comercio-card-calificacion')), findsNothing);
    });

    testWidgets('con las estrellas tampoco se desborda en pantallas angostas', (tester) async {
      for (final ancho in [320.0, 360.0, 411.0]) {
        await pintar(tester, ancho, _comercio(promedio: 4.5, total: 128));
        expect(tester.takeException(), isNull, reason: 'Se desbordó a $ancho px de ancho');
      }
    });
  });

  group('hoja de calificación', () {
    Future<void> abrir(WidgetTester tester, void Function(CalificacionElegida?) alCerrar) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async => alCerrar(await mostrarCalificarSheet(context, titulo: 'Calificar comercio', nombre: 'Bodega Luna')),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('no deja enviar sin estrellas y devuelve lo elegido', (tester) async {
      CalificacionElegida? elegida;
      var cerro = false;
      await abrir(tester, (e) {
        elegida = e;
        cerro = true;
      });

      expect(find.text('Calificar comercio'), findsOneWidget);
      expect(find.text('Bodega Luna'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Enviar calificación')).onPressed, isNull);

      await tester.tap(find.byKey(const Key('calificar-estrella-4')));
      await tester.pump();
      expect(find.text('Bueno'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '  Rápidos  ');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar calificación'));
      await tester.pumpAndSettle();

      expect(cerro, isTrue);
      expect(elegida?.puntuacion, 4);
      expect(elegida?.comentario, 'Rápidos');
    });

    testWidgets('un comentario vacío viaja como null', (tester) async {
      CalificacionElegida? elegida;
      await abrir(tester, (e) => elegida = e);

      await tester.tap(find.byKey(const Key('calificar-estrella-5')));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar calificación'));
      await tester.pumpAndSettle();

      expect(elegida?.puntuacion, 5);
      expect(elegida?.comentario, isNull);
    });
  });

  group('pantallas', () {
    Widget app(_RepoFalso repo, ConductorEntity? usuario, Widget pantalla, {_ServiciosFalso? servicios}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ComerciosProvider>.value(value: _provider(repo)),
          ChangeNotifierProvider<FinanciamientoServicioProvider>.value(value: servicios ?? _ServiciosFalso()),
          ChangeNotifierProvider<AuthProvider>.value(value: _AuthFalso(usuario)),
        ],
        child: MaterialApp(home: pantalla),
      );
    }

    testWidgets('la lista sale agrupada por ciudad con el total de cada una', (tester) async {
      tester.view.physicalSize = const Size(411, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = _RepoFalso()
        ..grupos = [
          _grupo('Cayma', [_comercio(id: 1, nombre: 'Bodega Luna'), _comercio(id: 2, nombre: 'Ferretería Sol')]),
          _grupo('Yanahuara', [_comercio(id: 3, nombre: 'Panadería Mar')]),
        ];

      await tester.pumpWidget(app(repo, _conductor(tipo: 1), const ComerciosGoPage()));
      await tester.pumpAndSettle();

      expect(find.text('Cayma'), findsOneWidget);
      expect(find.text('Yanahuara'), findsOneWidget);
      expect(find.text('Bodega Luna'), findsOneWidget);
      expect(find.text('Panadería Mar'), findsOneWidget);
      expect(find.text('Mostrando 3 comercios'), findsOneWidget);
      // La audiencia del conductor (tipo 1) y su ciudad viajan en el primer pedido.
      expect(repo.pedidos.first['audiencia'], 'conductores');
      expect(repo.pedidos.first['departamento'], 'Arequipa');
    });

    testWidgets('elegir Moto vuelve a pedir los comercios de ese tipo de vehículo', (tester) async {
      tester.view.physicalSize = const Size(411, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = _RepoFalso()..grupos = [_grupo('Cayma', [_comercio(id: 1, nombre: 'Bodega Luna')])];

      await tester.pumpWidget(app(repo, _conductor(), const ComerciosGoPage()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('comercios-vehiculo-todos')), findsOneWidget);

      await tester.tap(find.byKey(const Key('comercios-vehiculo-moto')));
      await tester.pumpAndSettle();

      expect(repo.pedidos.last['tipoVehicular'], 'moto');
      expect(repo.pedidos.last['departamento'], 'Arequipa');
    });

    testWidgets('sin comercios dice que no se encontró ninguno', (tester) async {
      tester.view.physicalSize = const Size(411, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app(_RepoFalso(), _conductor(), const ComerciosGoPage()));
      await tester.pumpAndSettle();

      expect(find.text('No se encontraron comercios'), findsOneWidget);
    });

    testWidgets('el detalle califica el comercio y actualiza las estrellas', (tester) async {
      tester.view.physicalSize = const Size(411, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = _RepoFalso();
      final servicios = _ServiciosFalso();
      final comercio = _comercio(id: 9, nombre: 'Bodega Luna', promedio: 4.0, total: 1);

      await tester.pumpWidget(app(repo, _conductor(tipo: 2), ComercioDetallePage(comercio: comercio), servicios: servicios));
      await tester.pumpAndSettle();

      // Antes de pedir los servicios se fija la audiencia del conductor (ya no queda nula si nunca abrió Servicios de Talleres).
      expect(servicios.audiencias, ['tipo-2']);
      expect(servicios.cargas.single, {'tallerId': null, 'comercioId': 9, 'clienteConductorId': 77});
      expect(find.text('4.0 (1)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('comercio-detalle-calificar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('calificar-estrella-5')));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar calificación'));
      await tester.pumpAndSettle();

      expect(repo.calificaciones.single['comercioId'], 9);
      expect(repo.calificaciones.single['clienteConductorId'], 77);
      expect(repo.calificaciones.single['puntuacion'], 5);
      expect(find.text('4.5 (2)'), findsOneWidget);
      expect(find.text('¡Gracias por tu calificación!'), findsOneWidget);
    });

    testWidgets('si no se puede enviar avisa y deja las estrellas como estaban', (tester) async {
      tester.view.physicalSize = const Size(411, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = _RepoFalso()..respuestaCalificar = null;
      final comercio = _comercio(id: 9, promedio: 4.0, total: 1);

      await tester.pumpWidget(app(repo, _conductor(), ComercioDetallePage(comercio: comercio)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comercio-detalle-calificar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('calificar-estrella-2')));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar calificación'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo enviar la calificación.'), findsOneWidget);
      expect(find.text('4.0 (1)'), findsOneWidget);
    });

    testWidgets('un comercio sin calificaciones lo dice y la fila no se desborda en pantallas angostas', (tester) async {
      addTearDown(tester.view.reset);

      for (final ancho in [320.0, 360.0, 411.0]) {
        tester.view.physicalSize = Size(ancho, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(app(_RepoFalso(), _conductor(), ComercioDetallePage(comercio: _comercio())));
        await tester.pumpAndSettle();

        expect(find.text('Sin calificaciones'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Se desbordó a $ancho px de ancho');
      }
    });
  });
}
