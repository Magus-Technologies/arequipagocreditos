import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/datasources/catalogos_remote_datasource.dart';
import 'package:arequipagocreditos/data/models/catalogo_models.dart';
import 'package:arequipagocreditos/data/models/verificacion_registro_model.dart';
import 'package:arequipagocreditos/data/repositories/catalogos_repository_impl.dart';
import 'package:arequipagocreditos/domain/repositories/catalogos_repository.dart';
import 'package:arequipagocreditos/presentation/components/app_select.dart';
import 'package:arequipagocreditos/presentation/pages/conductor_register_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/catalogos_provider.dart';

/// Registro de conductor: la PLATAFORMA va primero (paso 1) porque define en qué ciudades se puede registrar la persona, y antes de
/// pasar de los datos personales (paso 2) y del contacto (paso 3) se pregunta al servidor si ya existe un registro con esos datos.

/// Ciudades de una plataforma restringida: solo Arequipa (con dos provincias).
const _soloArequipa = UbicacionPlataformaModel(
  restringido: true,
  departamentos: [
    DepartamentoUbicacionModel(
      codigo: '04',
      nombre: 'AREQUIPA',
      provincias: [
        UbigeoItemModel(codigo: '0401', nombre: 'AREQUIPA'),
        UbigeoItemModel(codigo: '0402', nombre: 'CAMANA'),
      ],
    ),
  ],
);
const _sinRestriccion = UbicacionPlataformaModel(restringido: false);
const _restringidaSinCiudades = UbicacionPlataformaModel(restringido: true);

const _libre = VerificacionRegistroModel(registrado: false);

class _AuthFalso extends ChangeNotifier implements AuthProvider {
  @override
  bool get isLoading => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repo extends Fake implements CatalogosRepository {
  _Repo({Map<String, UbicacionPlataformaModel>? ubicaciones, this.alVerificar, this.alConsultarUbicaciones}) : ubicaciones = ubicaciones ?? {};

  /// Qué contesta el servidor por plataforma; las que no están fallan (como una consulta sin red).
  final Map<String, UbicacionPlataformaModel> ubicaciones;
  final Future<Either<Failure, VerificacionRegistroModel>> Function(Map<String, String?> consulta)? alVerificar;
  final Future<Either<Failure, UbicacionPlataformaModel>> Function(String plataforma)? alConsultarUbicaciones;

  final List<Map<String, String?>> verificaciones = [];
  final List<String> consultasUbicaciones = [];
  final List<String> consultasProvincias = [];

  static const _departamentos = [
    UbigeoItemModel(codigo: '04', nombre: 'AREQUIPA'),
    UbigeoItemModel(codigo: '15', nombre: 'LIMA'),
  ];

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getDepartamentos() async => Either.right(_departamentos);

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getProvincias(String codigoDepartamento) async {
    consultasProvincias.add(codigoDepartamento);
    return Either.right([
      UbigeoItemModel(codigo: '${codigoDepartamento}01', nombre: codigoDepartamento == '04' ? 'AREQUIPA' : 'LIMA CIUDAD'),
    ]);
  }

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getDistritos(String codigoProvincia) async => Either.right([
        UbigeoItemModel(codigo: '${codigoProvincia}01', nombre: codigoProvincia.startsWith('04') ? 'CERCADO' : 'MIRAFLORES'),
      ]);

  @override
  Future<Either<Failure, List<PlataformaItemModel>>> getPlataformas() async => Either.right(const [
        PlataformaItemModel(id: 1, plataforma: 'django', nombrePlataforma: 'Django'),
        PlataformaItemModel(id: 2, plataforma: 'atu', nombrePlataforma: 'Atu'),
        PlataformaItemModel(id: 3, plataforma: 'setare', nombrePlataforma: 'Setare'),
      ]);

  @override
  Future<Either<Failure, UbicacionPlataformaModel>> getUbicacionesPlataforma(String plataforma) async {
    consultasUbicaciones.add(plataforma);
    if (alConsultarUbicaciones != null) return alConsultarUbicaciones!(plataforma);
    final u = ubicaciones[plataforma];
    return u == null ? Either.left(const ServerFailure('Sin conexión')) : Either.right(u);
  }

  @override
  Future<Either<Failure, VerificacionRegistroModel>> verificarRegistroConductor({String? nroDocumento, String? nroLicencia, String? correo}) async {
    final consulta = {'nro_documento': nroDocumento, 'nro_licencia': nroLicencia, 'correo': correo};
    verificaciones.add(consulta);
    if (alVerificar != null) return alVerificar!(consulta);
    return Either.right(_libre);
  }
}

void main() {
  group('ubicaciones de la plataforma (modelo)', () {
    test('se leen los departamentos y provincias que manda el servidor', () {
      final u = UbicacionPlataformaModel.fromJson({
        'restringido': true,
        'departamentos': [
          {
            'codigo': '04',
            'nombre': 'AREQUIPA',
            'provincias': [
              {'codigo': '0401', 'nombre': 'AREQUIPA'},
              {'codigo': '0402', 'nombre': 'CAMANA'},
            ],
          },
          {'codigo': '15', 'nombre': 'LIMA', 'provincias': [{'codigo': '1501', 'nombre': 'LIMA'}]},
        ],
      });

      expect(u.restringido, isTrue);
      expect(u.departamentosItems.map((d) => d.codigo), ['04', '15']);
      expect(u.provinciasDe('04').map((p) => p.nombre), ['AREQUIPA', 'CAMANA']);
      expect(u.provinciasDe('99'), isEmpty);
    });

    test('valida si un departamento o una provincia están habilitados', () {
      expect(_soloArequipa.permiteDepartamento('04'), isTrue);
      expect(_soloArequipa.permiteDepartamento('15'), isFalse);
      expect(_soloArequipa.permiteDepartamento(null), isFalse);
      expect(_soloArequipa.permiteProvincia('04', '0402'), isTrue);
      // La provincia existe, pero en otro departamento: no vale.
      expect(_soloArequipa.permiteProvincia('15', '0402'), isFalse);
      expect(_soloArequipa.permiteProvincia('04', '0499'), isFalse);
      expect(_soloArequipa.permiteProvincia('04', null), isFalse);
    });

    test('sin «restringido» o con datos raros no restringe y no revienta', () {
      expect(UbicacionPlataformaModel.fromJson({}).restringido, isFalse);
      expect(UbicacionPlataformaModel.fromJson({'restringido': false, 'departamentos': 'x'}).departamentos, isEmpty);
      final raro = UbicacionPlataformaModel.fromJson({
        'restringido': 1,
        'departamentos': [
          'basura',
          {'codigo': '04', 'nombre': 'AREQUIPA', 'provincias': 'nada'},
        ],
      });
      expect(raro.restringido, isTrue);
      expect(raro.departamentos.single.provincias, isEmpty);
    });
  });

  group('verificación de registro (modelo)', () {
    test('se lee la respuesta del servidor', () {
      final v = VerificacionRegistroModel.fromJson({
        'registrado': true,
        'campo': 'documento',
        'eliminado': false,
        'message': 'Ya existe un registro con este documento.',
      });

      expect(v.registrado, isTrue);
      expect(v.campo, 'documento');
      expect(v.eliminado, isFalse);
      expect(v.titulo, 'Ya estás registrado');
      expect(v.mensajeParaMostrar, 'Ya existe un registro con este documento.');
    });

    test('un registro dado de baja tiene otro título', () {
      final v = VerificacionRegistroModel.fromJson({'registrado': true, 'campo': 'licencia', 'eliminado': true, 'message': 'Tu registro fue dado de baja.'});

      expect(v.titulo, 'Registro dado de baja');
    });

    test('libre: sin campo ni mensaje; sin mensaje del servidor hay uno genérico', () {
      final libre = VerificacionRegistroModel.fromJson({'registrado': false, 'campo': null, 'eliminado': false, 'message': null});
      expect(libre.registrado, isFalse);
      expect(libre.campo, isNull);
      expect(libre.message, isNull);

      final sinTexto = VerificacionRegistroModel.fromJson({'registrado': true, 'campo': 'correo', 'message': ' '});
      expect(sinTexto.mensajeParaMostrar, contains('este correo'));
    });
  });

  group('CatalogosProvider: ciudades por plataforma', () {
    test('restringida: los departamentos y las provincias salen de la lista de la plataforma, sin llamar al catálogo global', () async {
      final repo = _Repo(ubicaciones: {'atu': _soloArequipa});
      final catalogos = CatalogosProvider(catalogosRepository: repo);
      await catalogos.loadDepartamentos();

      expect(catalogos.departamentosRegistro, isEmpty, reason: 'sin saber dónde está habilitada la plataforma no se ofrece ninguna ciudad');

      await catalogos.loadUbicacionesPlataforma('atu');
      expect(catalogos.ubicacionRestringida, isTrue);
      expect(catalogos.departamentosRegistro.map((d) => d.nombre), ['AREQUIPA']);

      await catalogos.loadProvinciasDelRegistro('04');
      expect(catalogos.provincias.map((p) => p.nombre), ['AREQUIPA', 'CAMANA']);
      expect(repo.consultasProvincias, isEmpty);
    });

    test('sin restricción las provincias se piden al catálogo de siempre', () async {
      final repo = _Repo(ubicaciones: {'django': _sinRestriccion});
      final catalogos = CatalogosProvider(catalogosRepository: repo);
      await catalogos.loadDepartamentos();
      await catalogos.loadUbicacionesPlataforma('django');

      expect(catalogos.ubicacionRestringida, isFalse);
      expect(catalogos.departamentosRegistro.map((d) => d.codigo), ['04', '15']);

      await catalogos.loadProvinciasDelRegistro('15');
      expect(repo.consultasProvincias, ['15']);
      expect(catalogos.provincias.single.nombre, 'LIMA CIUDAD');
    });

    test('si la consulta falla NO se ofrece el catálogo completo (falla cerrado) y un reintento exitoso lo habilita', () async {
      final repo = _Repo();
      final catalogos = CatalogosProvider(catalogosRepository: repo);
      await catalogos.loadDepartamentos();
      await catalogos.loadUbicacionesPlataforma('atu');

      expect(catalogos.ubicacionesPlataformaError, CatalogosProvider.ubicacionesPlataformaErrorMensaje);
      expect(catalogos.ubicacionesPlataformaCargada, isFalse);
      expect(catalogos.departamentosRegistro, isEmpty, reason: 'sin saber dónde está habilitada no se ofrece ninguna ciudad');
      expect(catalogos.departamentosRegistroError, CatalogosProvider.ubicacionesPlataformaErrorMensaje);
      expect(catalogos.ubicacionesPlataformaListas('atu'), isFalse, reason: 'falló: conviene reintentar');

      repo.ubicaciones['atu'] = _soloArequipa;
      await catalogos.loadUbicacionesPlataforma('atu');

      expect(catalogos.ubicacionesPlataformaError, isNull);
      expect(catalogos.ubicacionRestringida, isTrue);
      expect(catalogos.departamentosRegistro.map((d) => d.nombre), ['AREQUIPA']);
      expect(catalogos.ubicacionesPlataformaListas('atu'), isTrue);
    });

    test('una excepción inesperada de la consulta también falla cerrado, sin lanzar', () async {
      final catalogos = CatalogosProvider(
        catalogosRepository: _Repo(alConsultarUbicaciones: (_) async => throw StateError('JSON raro')),
      );
      await catalogos.loadDepartamentos();

      await catalogos.loadUbicacionesPlataforma('atu');

      expect(catalogos.ubicacionesPlataformaError, isNotNull);
      expect(catalogos.departamentosRegistro, isEmpty);
    });

    test('200 con restringido:false es «sin restricción»: catálogo completo y sin error', () async {
      final catalogos = CatalogosProvider(catalogosRepository: _Repo(ubicaciones: {'django': _sinRestriccion}));
      await catalogos.loadDepartamentos();

      await catalogos.loadUbicacionesPlataforma('django');

      expect(catalogos.ubicacionesPlataformaError, isNull);
      expect(catalogos.ubicacionRestringida, isFalse);
      expect(catalogos.departamentosRegistro, hasLength(2));
    });

    test('si se elige otra plataforma antes de que conteste la primera, esa respuesta no pisa a la nueva', () async {
      final lenta = Completer<Either<Failure, UbicacionPlataformaModel>>();
      final repo = _Repo(
        alConsultarUbicaciones: (plataforma) => plataforma == 'atu' ? lenta.future : Future.value(Either.right(_sinRestriccion)),
      );
      final catalogos = CatalogosProvider(catalogosRepository: repo);

      final primera = catalogos.loadUbicacionesPlataforma('atu');
      await catalogos.loadUbicacionesPlataforma('django');
      lenta.complete(Either.right(_soloArequipa));
      await primera;

      expect(catalogos.ubicacionRestringida, isFalse);
      expect(catalogos.ubicacionesPlataformaListas('django'), isTrue);
      expect(catalogos.ubicacionesPlataformaListas('atu'), isFalse);
    });

    test('limpiar olvida la restricción de un registro anterior', () async {
      final catalogos = CatalogosProvider(catalogosRepository: _Repo(ubicaciones: {'atu': _soloArequipa}));
      await catalogos.loadUbicacionesPlataforma('atu');
      expect(catalogos.ubicacionRestringida, isTrue);

      catalogos.limpiarUbicacionesPlataforma();

      expect(catalogos.ubicacionRestringida, isFalse);
      expect(catalogos.ubicacionesPlataformaListas('atu'), isFalse);
    });
  });

  group('ciudades de la plataforma: servidor real (datasource + repositorio + provider)', () {
    http.Response json200(Object data) => http.Response(json.encode({'success': true, 'data': data}), 200, headers: {'content-type': 'application/json'});

    /// Provider armado con las capas reales y un servidor falso que contesta lo que se le indique.
    CatalogosProvider conServidor(http.Response Function(http.Request) responder, {List<http.Request>? vistas}) {
      final client = MockClient((request) async {
        vistas?.add(request);
        return responder(request);
      });
      return CatalogosProvider(
        catalogosRepository: CatalogosRepositoryImpl(remoteDataSource: CatalogosRemoteDataSourceImpl(client: client)),
      );
    }

    test('pide GET /app/plataformas/{plataforma}/ubicaciones y lee la respuesta restringida', () async {
      final vistas = <http.Request>[];
      final catalogos = conServidor(
        (_) => json200({
          'restringido': true,
          'departamentos': [
            {'codigo': '04', 'nombre': 'AREQUIPA', 'provincias': [{'codigo': '0401', 'nombre': 'AREQUIPA'}]},
          ],
        }),
        vistas: vistas,
      );

      await catalogos.loadUbicacionesPlataforma('tuk_tuk');

      expect(vistas.single.method, 'GET');
      expect(vistas.single.url.path, endsWith('/app/plataformas/tuk_tuk/ubicaciones'));
      expect(catalogos.ubicacionRestringida, isTrue);
      expect(catalogos.ubicacionesPlataformaError, isNull);
      expect(catalogos.departamentosRegistro.map((d) => d.nombre), ['AREQUIPA']);
    });

    test('200 con restringido:false es «sin restricción» legítimo', () async {
      final catalogos = conServidor((_) => json200({'restringido': false, 'departamentos': []}));

      await catalogos.loadUbicacionesPlataforma('django');

      expect(catalogos.ubicacionesPlataformaError, isNull);
      expect(catalogos.ubicacionesPlataformaCargada, isTrue);
      expect(catalogos.ubicacionRestringida, isFalse);
    });

    test('404 (el servidor aún no tiene el endpoint) cuenta como sin restricción: no bloquea los registros', () async {
      final catalogos = conServidor((_) => http.Response('{"message":"Not Found"}', 404));
      await catalogos.loadDepartamentos();

      await catalogos.loadUbicacionesPlataforma('django');

      expect(catalogos.ubicacionesPlataformaError, isNull);
      expect(catalogos.ubicacionesPlataformaCargada, isTrue);
      expect(catalogos.ubicacionRestringida, isFalse);
      expect(catalogos.ubicacionesPlataformaListas('django'), isTrue);
    });

    for (final caso in <String, http.Response Function(http.Request)>{
      '500': (_) => http.Response('{"message":"Server Error"}', 500),
      '503 sin cuerpo': (_) => http.Response('', 503),
      '200 con una página HTML (no es JSON)': (_) => http.Response('<html>Mantenimiento</html>', 200),
      '200 con success:false': (_) => http.Response(json.encode({'success': false, 'message': 'x'}), 200),
      '200 sin data': (_) => http.Response(json.encode({'success': true}), 200),
      'sin conexión': (_) => throw http.ClientException('Failed host lookup'),
    }.entries) {
      test('${caso.key}: falla cerrado (sin ciudades y con error), no se confunde con un 404', () async {
        final catalogos = conServidor(caso.value);
        await catalogos.loadDepartamentos();

        await catalogos.loadUbicacionesPlataforma('django');

        expect(catalogos.ubicacionesPlataformaError, CatalogosProvider.ubicacionesPlataformaErrorMensaje);
        expect(catalogos.ubicacionesPlataformaCargada, isFalse);
        expect(catalogos.departamentosRegistro, isEmpty);
      });
    }

    test('verificar-registro: manda un POST JSON solo con los datos que vienen y lee la respuesta', () async {
      final vistas = <http.Request>[];
      final catalogos = conServidor(
        (_) => json200({'registrado': true, 'campo': 'documento', 'eliminado': false, 'message': 'Ya estás registrado.'}),
        vistas: vistas,
      );

      final v = await catalogos.verificarRegistroConductor(nroDocumento: '12345678', nroLicencia: '', correo: null);

      expect(vistas.single.method, 'POST');
      expect(vistas.single.url.path, endsWith('/app/conductores/verificar-registro'));
      expect(vistas.single.headers['Content-Type'], contains('application/json'));
      expect(json.decode(vistas.single.body), {'nro_documento': '12345678'});
      expect(v!.registrado, isTrue);
      expect(v.campo, 'documento');
    });

    for (final caso in <String, http.Response Function(http.Request)>{
      '500': (_) => http.Response('boom', 500),
      '200 con JSON raro': (_) => http.Response('no es json', 200),
      '200 con data que no es un objeto': (_) => json200('texto'),
      'sin conexión': (_) => throw http.ClientException('sin red'),
    }.entries) {
      test('verificar-registro, ${caso.key}: devuelve null (no bloquea) y no lanza', () async {
        final catalogos = conServidor(caso.value);

        expect(await catalogos.verificarRegistroConductor(nroDocumento: '12345678'), isNull);
      });
    }
  });

  group('CatalogosProvider: verificar registro', () {
    test('devuelve lo que contesta el servidor', () async {
      final catalogos = CatalogosProvider(
        catalogosRepository: _Repo(alVerificar: (_) async => Either.right(const VerificacionRegistroModel(registrado: true, campo: 'documento', message: 'Ya existe.'))),
      );

      final v = await catalogos.verificarRegistroConductor(nroDocumento: '12345678');

      expect(v!.registrado, isTrue);
      expect(v.campo, 'documento');
    });

    test('si falla (red, 5xx) devuelve null en vez de lanzar: no se bloquea a la persona', () async {
      final sinRed = CatalogosProvider(catalogosRepository: _Repo(alVerificar: (_) async => Either.left(const ServerFailure('Error HTTP 500'))));
      expect(await sinRed.verificarRegistroConductor(nroDocumento: '12345678'), isNull);

      final explota = CatalogosProvider(catalogosRepository: _Repo(alVerificar: (_) async => throw StateError('JSON raro')));
      expect(await explota.verificarRegistroConductor(correo: 'a@b.pe'), isNull);
    });
  });

  group('pantalla de registro de conductor', () {
    Future<void> abrir(WidgetTester tester, _Repo repo) async {
      tester.view.physicalSize = const Size(900, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: _AuthFalso()),
            ChangeNotifierProvider<CatalogosProvider>.value(value: CatalogosProvider(catalogosRepository: repo)),
          ],
          child: const MaterialApp(home: ConductorRegisterPage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tocarBoton(WidgetTester tester, String texto) async {
      await tester.tap(find.text(texto));
      await tester.pumpAndSettle();
    }

    Future<void> siguiente(WidgetTester tester) => tocarBoton(tester, 'SIGUIENTE');

    Future<void> escribir(WidgetTester tester, String etiqueta, String texto) async {
      await tester.enterText(find.widgetWithText(TextFormField, etiqueta), texto);
    }

    /// El selector de [etiqueta] (el campo cerrado de la página, no la hoja que abre).
    Finder selector(String etiqueta) => find.widgetWithText(AppSelect, etiqueta);

    /// Una opción dentro de la hoja abierta (el campo de atrás puede mostrar el mismo texto si ya estaba elegida).
    Finder opcionEnHoja(String texto) => find.descendant(of: find.byKey(const Key('select_hoja')), matching: find.text(texto));

    Future<void> abrirSelector(WidgetTester tester, String etiqueta) async {
      await tester.tap(selector(etiqueta));
      await tester.pumpAndSettle();
    }

    Future<void> elegir(WidgetTester tester, String etiqueta, String opcion) async {
      await abrirSelector(tester, etiqueta);
      await tester.tap(opcionEnHoja(opcion));
      await tester.pumpAndSettle();
    }

    /// Paso 1: elige la plataforma (la tarjeta muestra el nombre en mayúsculas).
    Future<void> elegirPlataforma(WidgetTester tester, String nombre) async {
      await tester.tap(find.text(nombre));
      await tester.pumpAndSettle();
    }

    Future<void> llenarDatosPersonales(WidgetTester tester, {String dni = '12345678', String licencia = 'Q12345678'}) async {
      await escribir(tester, 'DNI / Nro Documento', dni);
      await escribir(tester, 'Nombres Completos', 'Rosa');
      await escribir(tester, 'Apellido Paterno', 'Quispe');
      await tester.tap(find.text('Fecha de Nacimiento'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await escribir(tester, 'Número de Licencia', licencia);
      await elegir(tester, 'Categoría de Licencia', 'A-I');
    }

    Future<void> llenarContacto(WidgetTester tester) async {
      await escribir(tester, 'Tu Teléfono', '987654321');
      await escribir(tester, 'Dirección exacta', 'Calle Mercaderes 123');
      await escribir(tester, 'Link Google Maps', 'https://maps.app.goo.gl/abc123');
    }

    /// Plataforma + datos personales -> deja la pantalla en el paso 3.
    Future<void> hastaElPaso3(WidgetTester tester, {String plataforma = 'DJANGO'}) async {
      await elegirPlataforma(tester, plataforma);
      await siguiente(tester);
      await llenarDatosPersonales(tester);
      await siguiente(tester);
    }

    group('foco del teclado', () {
      testWidgets('elegir la fecha de nacimiento no devuelve el foco (ni el teclado) al campo de texto que lo tenía antes', (tester) async {
        await abrir(tester, _Repo(ubicaciones: {'django': _sinRestriccion}));
        await elegirPlataforma(tester, 'DJANGO');
        await siguiente(tester);

        bool hayCampoConFoco() => find.byType(EditableText).evaluate().any((e) => (e.widget as EditableText).focusNode.hasFocus);

        await tester.tap(find.widgetWithText(TextFormField, 'Apellido Materno (Opcional)'));
        await tester.pump();
        expect(hayCampoConFoco(), isTrue, reason: 'el apellido materno empieza con el foco (teclado abierto)');

        await tester.tap(find.text('Fecha de Nacimiento'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(hayCampoConFoco(), isFalse, reason: 'al abrir el calendario se suelta el foco');

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(hayCampoConFoco(), isFalse, reason: 'al elegir la fecha el foco no vuelve al apellido materno');
      });
    });

    group('orden de los pasos', () {
      testWidgets('empieza por la plataforma; los datos personales van en el paso 2 y el contacto en el 3', (tester) async {
        await abrir(tester, _Repo(ubicaciones: {'django': _sinRestriccion}));

        expect(find.text('Plataforma en la que trabajas'), findsOneWidget);
        expect(find.text('DJANGO'), findsOneWidget);
        expect(find.text('CANCELAR'), findsOneWidget, reason: 'el paso 1 sale del registro');
        expect(find.widgetWithText(TextFormField, 'DNI / Nro Documento'), findsNothing);

        await elegirPlataforma(tester, 'DJANGO');
        await siguiente(tester);

        expect(find.text('Información Personal'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'DNI / Nro Documento'), findsOneWidget);
        expect(find.text('ATRÁS'), findsOneWidget);

        await llenarDatosPersonales(tester);
        await siguiente(tester);

        expect(find.text('Contacto y Ubicación'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Tu Teléfono'), findsOneWidget);
      });

      testWidgets('no se avanza del paso 1 sin elegir plataforma', (tester) async {
        await abrir(tester, _Repo());

        await siguiente(tester);

        expect(find.text('Selecciona la plataforma con la que trabajas'), findsOneWidget);
        expect(find.text('Plataforma en la que trabajas'), findsOneWidget);
      });

      testWidgets('ATRÁS vuelve al paso anterior y conserva lo escrito', (tester) async {
        await abrir(tester, _Repo(ubicaciones: {'django': _sinRestriccion}));
        await elegirPlataforma(tester, 'DJANGO');
        await siguiente(tester);
        await escribir(tester, 'DNI / Nro Documento', '12345678');

        await tocarBoton(tester, 'ATRÁS');
        expect(find.text('Plataforma en la que trabajas'), findsOneWidget);

        await siguiente(tester);
        expect(find.widgetWithText(TextFormField, 'DNI / Nro Documento'), findsOneWidget);
        expect(find.text('12345678'), findsOneWidget);
      });
    });

    group('¿ya está registrado?', () {
      testWidgets('al pasar de los datos personales se consulta el documento y la licencia', (tester) async {
        final repo = _Repo(ubicaciones: {'django': _sinRestriccion});
        await abrir(tester, repo);

        await hastaElPaso3(tester);

        expect(repo.verificaciones, [
          {'nro_documento': '12345678', 'nro_licencia': 'Q12345678', 'correo': null},
        ]);
        expect(find.text('Contacto y Ubicación'), findsOneWidget);
      });

      testWidgets('si ya está registrado se muestra un diálogo con el mensaje del servidor y NO se avanza', (tester) async {
        final repo = _Repo(
          ubicaciones: {'django': _sinRestriccion},
          alVerificar: (_) async => Either.right(const VerificacionRegistroModel(
            registrado: true,
            campo: 'documento',
            message: 'Ya tienes un registro con este documento. Inicia sesión.',
          )),
        );
        await abrir(tester, repo);

        await hastaElPaso3(tester);

        expect(find.byKey(const Key('registro_ya_registrado_dialogo')), findsOneWidget);
        expect(find.text('Ya estás registrado'), findsOneWidget);
        expect(find.text('Ya tienes un registro con este documento. Inicia sesión.'), findsOneWidget);
        expect(find.text('Información Personal'), findsOneWidget, reason: 'sigue en el paso 2');

        // Es bloqueante: tocar fuera no lo cierra.
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('registro_ya_registrado_dialogo')), findsOneWidget);

        await tester.tap(find.byKey(const Key('registro_ya_registrado_entendido')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('registro_ya_registrado_dialogo')), findsNothing);
        expect(find.text('Información Personal'), findsOneWidget);
      });

      testWidgets('un registro dado de baja se avisa con otro título', (tester) async {
        final repo = _Repo(
          ubicaciones: {'django': _sinRestriccion},
          alVerificar: (_) async => Either.right(const VerificacionRegistroModel(
            registrado: true,
            campo: 'licencia',
            eliminado: true,
            message: 'Tu registro fue dado de baja. Comunícate con nosotros.',
          )),
        );
        await abrir(tester, repo);

        await hastaElPaso3(tester);

        expect(find.text('Registro dado de baja'), findsOneWidget);
        expect(find.text('Tu registro fue dado de baja. Comunícate con nosotros.'), findsOneWidget);
        expect(find.text('Ya estás registrado'), findsNothing);
      });

      testWidgets('si la consulta falla NO se bloquea: la persona avanza (el servidor igual rechaza duplicados al enviar)', (tester) async {
        final repo = _Repo(
          ubicaciones: {'django': _sinRestriccion},
          alVerificar: (_) async => Either.left(const ServerFailure('Error HTTP 500')),
        );
        await abrir(tester, repo);

        await hastaElPaso3(tester);

        expect(repo.verificaciones, hasLength(1));
        expect(find.byKey(const Key('registro_ya_registrado_dialogo')), findsNothing);
        expect(find.text('Contacto y Ubicación'), findsOneWidget);
      });

      testWidgets('no repite la consulta de lo que no cambió; si cambia el DNI vuelve a consultar solo ese dato', (tester) async {
        final repo = _Repo(ubicaciones: {'django': _sinRestriccion});
        await abrir(tester, repo);
        await hastaElPaso3(tester);
        expect(repo.verificaciones, hasLength(1));

        await tocarBoton(tester, 'ATRÁS');
        await siguiente(tester);
        expect(repo.verificaciones, hasLength(1), reason: 'documento y licencia ya estaban verificados');
        expect(find.text('Contacto y Ubicación'), findsOneWidget);

        await tocarBoton(tester, 'ATRÁS');
        await escribir(tester, 'DNI / Nro Documento', '87654321');
        await siguiente(tester);
        expect(repo.verificaciones, hasLength(2));
        expect(repo.verificaciones.last, {'nro_documento': '87654321', 'nro_licencia': null, 'correo': null});
      });

      testWidgets('un dato que ya estaba registrado se vuelve a consultar (no se da por bueno)', (tester) async {
        var registrado = true;
        final repo = _Repo(
          ubicaciones: {'django': _sinRestriccion},
          alVerificar: (_) async => Either.right(registrado
              ? const VerificacionRegistroModel(registrado: true, campo: 'documento', message: 'Ya existe.')
              : _libre),
        );
        await abrir(tester, repo);
        await hastaElPaso3(tester);
        await tester.tap(find.byKey(const Key('registro_ya_registrado_entendido')));
        await tester.pumpAndSettle();

        registrado = false;
        await siguiente(tester);

        expect(repo.verificaciones, hasLength(2));
        expect(find.text('Contacto y Ubicación'), findsOneWidget);
      });

      testWidgets('el correo se consulta al pasar del paso 3, solo si no está vacío', (tester) async {
        final repo = _Repo(ubicaciones: {'django': _sinRestriccion});
        await abrir(tester, repo);
        await hastaElPaso3(tester);
        await llenarContacto(tester);
        await elegir(tester, 'Departamento', 'AREQUIPA');
        await elegir(tester, 'Provincia', 'AREQUIPA');
        await elegir(tester, 'Distrito', 'CERCADO');

        // Sin correo no hay nada que preguntar.
        await siguiente(tester);
        expect(repo.verificaciones, hasLength(1), reason: 'solo la del paso 2');
        expect(find.text('Vehículo (Opcional)'), findsOneWidget);

        await tocarBoton(tester, 'ATRÁS');
        await escribir(tester, 'Correo Electrónico (Opcional)', 'rosa@correo.pe');
        await siguiente(tester);

        expect(repo.verificaciones, hasLength(2));
        expect(repo.verificaciones.last, {'nro_documento': null, 'nro_licencia': null, 'correo': 'rosa@correo.pe'});
        expect(find.text('Vehículo (Opcional)'), findsOneWidget);
      });

      testWidgets('un correo ya registrado detiene el paso 3 con el diálogo', (tester) async {
        final repo = _Repo(
          ubicaciones: {'django': _sinRestriccion},
          alVerificar: (consulta) async => consulta['correo'] != null
              ? Either.right(const VerificacionRegistroModel(registrado: true, campo: 'correo', message: 'Ese correo ya está en uso.'))
              : Either.right(_libre),
        );
        await abrir(tester, repo);
        await hastaElPaso3(tester);
        await llenarContacto(tester);
        await escribir(tester, 'Correo Electrónico (Opcional)', 'rosa@correo.pe');
        await elegir(tester, 'Departamento', 'AREQUIPA');
        await elegir(tester, 'Provincia', 'AREQUIPA');
        await elegir(tester, 'Distrito', 'CERCADO');

        await siguiente(tester);

        expect(find.text('Ese correo ya está en uso.'), findsOneWidget);
        expect(find.text('Contacto y Ubicación'), findsOneWidget);
      });

      testWidgets('mientras consulta el botón queda bloqueado: un solo toque, una sola consulta', (tester) async {
        final respuesta = Completer<Either<Failure, VerificacionRegistroModel>>();
        final repo = _Repo(ubicaciones: {'django': _sinRestriccion}, alVerificar: (_) => respuesta.future);
        await abrir(tester, repo);
        await elegirPlataforma(tester, 'DJANGO');
        await siguiente(tester);
        await llenarDatosPersonales(tester);

        await tester.tap(find.text('SIGUIENTE'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
        expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'ATRÁS')).onPressed, isNull);

        await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
        await tester.pump();
        expect(repo.verificaciones, hasLength(1));

        respuesta.complete(Either.right(_libre));
        await tester.pumpAndSettle();

        expect(find.text('Contacto y Ubicación'), findsOneWidget);
        expect(find.text('SIGUIENTE'), findsOneWidget);
      });

      testWidgets('las validaciones locales van primero: sin datos completos no se consulta', (tester) async {
        final repo = _Repo(ubicaciones: {'django': _sinRestriccion});
        await abrir(tester, repo);
        await elegirPlataforma(tester, 'DJANGO');
        await siguiente(tester);

        await siguiente(tester);

        expect(find.text('Ingresa tu DNI o número de documento'), findsOneWidget);
        expect(repo.verificaciones, isEmpty);
      });
    });

    group('ubicación según la plataforma', () {
      testWidgets('al elegir la plataforma se consultan sus ciudades, y al entrar al paso 3 ya están listas', (tester) async {
        final repo = _Repo(ubicaciones: {'atu': _soloArequipa});
        await abrir(tester, repo);

        await elegirPlataforma(tester, 'ATU');
        expect(repo.consultasUbicaciones, ['atu']);

        await siguiente(tester);
        await llenarDatosPersonales(tester);
        await siguiente(tester);

        expect(repo.consultasUbicaciones, ['atu'], reason: 'no se vuelve a pedir si ya salió bien');
      });

      testWidgets('plataforma restringida: solo se ofrecen sus departamentos y sus provincias', (tester) async {
        final repo = _Repo(ubicaciones: {'atu': _soloArequipa});
        await abrir(tester, repo);
        await hastaElPaso3(tester, plataforma: 'ATU');

        await abrirSelector(tester, 'Departamento');
        expect(opcionEnHoja('AREQUIPA'), findsOneWidget);
        expect(find.text('LIMA'), findsNothing, reason: 'Lima no está habilitada para esta plataforma');
        await tester.tap(opcionEnHoja('AREQUIPA'));
        await tester.pumpAndSettle();

        await abrirSelector(tester, 'Provincia');
        expect(find.text('CAMANA'), findsOneWidget);
        await tester.tap(opcionEnHoja('CAMANA'));
        await tester.pumpAndSettle();

        expect(repo.consultasProvincias, isEmpty, reason: 'las provincias salen de la lista de la plataforma');

        // Los distritos siguen viniendo del catálogo de siempre.
        await abrirSelector(tester, 'Distrito');
        expect(find.text('CERCADO'), findsOneWidget);
      });

      testWidgets('plataforma sin restricción: catálogo completo de departamentos y provincias', (tester) async {
        final repo = _Repo(ubicaciones: {'django': _sinRestriccion});
        await abrir(tester, repo);
        await hastaElPaso3(tester);

        await abrirSelector(tester, 'Departamento');
        expect(find.text('LIMA'), findsOneWidget);
        await tester.tap(opcionEnHoja('LIMA'));
        await tester.pumpAndSettle();

        expect(repo.consultasProvincias, ['15']);
      });

      testWidgets('si la consulta de ciudades falla NO hay catálogo completo: avisa, ofrece Reintentar y SIGUIENTE no avanza', (tester) async {
        final repo = _Repo(); // toda consulta de ciudades falla
        await abrir(tester, repo);

        await elegirPlataforma(tester, 'DJANGO');
        expect(repo.consultasUbicaciones, ['django']);

        await siguiente(tester);
        await llenarDatosPersonales(tester);
        await siguiente(tester);
        expect(repo.consultasUbicaciones, ['django', 'django'], reason: 'al entrar al paso 3 se reintenta');

        // En lugar de los selectores de ciudad hay un aviso con «Reintentar».
        expect(find.text('Contacto y Ubicación'), findsOneWidget);
        expect(find.byKey(const Key('ubicacion_error_consulta')), findsOneWidget);
        expect(find.text(CatalogosProvider.ubicacionesPlataformaErrorMensaje), findsOneWidget);
        expect(find.byKey(const Key('ubicacion_reintentar')), findsOneWidget);
        expect(selector('Departamento'), findsNothing);
        expect(find.text('LIMA'), findsNothing);

        // SIGUIENTE no avanza, dice por qué y además vuelve a consultar.
        await llenarContacto(tester);
        await siguiente(tester);
        expect(find.text('Contacto y Ubicación'), findsOneWidget);
        expect(find.text(CatalogosProvider.ubicacionesPlataformaErrorMensaje), findsNWidgets(2), reason: 'el aviso del selector y el SnackBar');
        expect(repo.consultasUbicaciones, hasLength(3), reason: 'SIGUIENTE relanza la consulta');
      });

      testWidgets('un reintento exitoso desbloquea el paso 3 con las ciudades de la plataforma', (tester) async {
        final repo = _Repo();
        await abrir(tester, repo);
        await hastaElPaso3(tester, plataforma: 'ATU');
        await llenarContacto(tester);
        expect(find.byKey(const Key('ubicacion_error_consulta')), findsOneWidget);

        repo.ubicaciones['atu'] = _soloArequipa;
        await tester.tap(find.byKey(const Key('ubicacion_reintentar')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ubicacion_error_consulta')), findsNothing);
        await abrirSelector(tester, 'Departamento');
        expect(find.text('LIMA'), findsNothing, reason: 'solo las ciudades de la plataforma');
        await tester.tap(opcionEnHoja('AREQUIPA'));
        await tester.pumpAndSettle();
        await elegir(tester, 'Provincia', 'CAMANA');
        await elegir(tester, 'Distrito', 'CERCADO');

        await siguiente(tester);
        expect(find.text('Vehículo (Opcional)'), findsOneWidget);
      });

      testWidgets('tras un fallo, SIGUIENTE vuelve a consultar y, si ya sale bien, deja elegir la ciudad', (tester) async {
        final repo = _Repo();
        await abrir(tester, repo);
        await hastaElPaso3(tester);
        await llenarContacto(tester);

        repo.ubicaciones['django'] = _sinRestriccion;
        await siguiente(tester); // sigue bloqueado por el fallo, pero relanza la consulta (que ahora sale bien)

        expect(find.byKey(const Key('ubicacion_error_consulta')), findsNothing);
        expect(selector('Departamento'), findsOneWidget);
        expect(find.text('Contacto y Ubicación'), findsOneWidget);
      });


      testWidgets('restringida pero sin ciudades: avisa con claridad y no deja avanzar', (tester) async {
        final repo = _Repo(ubicaciones: {'setare': _restringidaSinCiudades});
        await abrir(tester, repo);
        await hastaElPaso3(tester, plataforma: 'SETARE');

        expect(find.byKey(const Key('ubicacion_sin_ciudades')), findsOneWidget);
        expect(find.textContaining('aún no está habilitada en ninguna ciudad'), findsWidgets);

        await llenarContacto(tester);
        await siguiente(tester);

        expect(find.text('Contacto y Ubicación'), findsOneWidget);
        expect(find.textContaining('Vuelve al paso 1 y elige otra plataforma'), findsWidgets);
      });

      testWidgets('cambiar a una plataforma que no admite la ubicación elegida la descarta', (tester) async {
        final repo = _Repo(ubicaciones: {'django': _sinRestriccion, 'atu': _soloArequipa});
        await abrir(tester, repo);
        await hastaElPaso3(tester);
        await llenarContacto(tester);
        await elegir(tester, 'Departamento', 'LIMA');
        await elegir(tester, 'Provincia', 'LIMA CIUDAD');
        await elegir(tester, 'Distrito', 'MIRAFLORES');
        expect(find.text('MIRAFLORES'), findsOneWidget);

        // Vuelve al paso 1 y cambia a una plataforma restringida a Arequipa.
        await tocarBoton(tester, 'ATRÁS');
        await tocarBoton(tester, 'ATRÁS');
        await elegirPlataforma(tester, 'ATU');
        await siguiente(tester);
        await siguiente(tester);

        expect(find.text('Contacto y Ubicación'), findsOneWidget);
        expect(find.text('LIMA'), findsNothing);
        expect(find.text('MIRAFLORES'), findsNothing);

        await siguiente(tester);
        expect(find.text('Selecciona tu departamento'), findsOneWidget, reason: 'no se manda una ubicación inválida');
      });

      testWidgets('cambiar de plataforma conserva la ubicación si sigue siendo válida', (tester) async {
        final repo = _Repo(ubicaciones: {'atu': _soloArequipa, 'setare': _soloArequipa});
        await abrir(tester, repo);
        await hastaElPaso3(tester, plataforma: 'ATU');
        await llenarContacto(tester);
        await elegir(tester, 'Departamento', 'AREQUIPA');
        await elegir(tester, 'Provincia', 'CAMANA');
        await elegir(tester, 'Distrito', 'CERCADO');

        await tocarBoton(tester, 'ATRÁS');
        await tocarBoton(tester, 'ATRÁS');
        await elegirPlataforma(tester, 'SETARE');
        await siguiente(tester);
        await siguiente(tester);

        expect(find.text('CAMANA'), findsOneWidget);
        expect(find.text('CERCADO'), findsOneWidget);
      });

      testWidgets('pasar de una lista restringida a una sin restricción también descarta la ubicación', (tester) async {
        final repo = _Repo(ubicaciones: {'atu': _soloArequipa, 'django': _sinRestriccion});
        await abrir(tester, repo);
        await hastaElPaso3(tester, plataforma: 'ATU');
        await llenarContacto(tester);
        await elegir(tester, 'Departamento', 'AREQUIPA');
        await elegir(tester, 'Provincia', 'AREQUIPA');
        await elegir(tester, 'Distrito', 'CERCADO');

        await tocarBoton(tester, 'ATRÁS');
        await tocarBoton(tester, 'ATRÁS');
        await elegirPlataforma(tester, 'DJANGO');
        await siguiente(tester);
        await siguiente(tester);

        expect(find.text('CERCADO'), findsNothing);
        await siguiente(tester);
        expect(find.text('Selecciona tu departamento'), findsOneWidget);
      });
    });
  });
}
