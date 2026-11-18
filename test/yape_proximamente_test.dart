import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/models/izipay_models.dart';
import 'package:arequipagocreditos/domain/repositories/catalogos_repository.dart';
import 'package:arequipagocreditos/presentation/components/pago_inscripcion_registro.dart';
import 'package:arequipagocreditos/presentation/components/yape_widgets.dart';
import 'package:arequipagocreditos/presentation/providers/catalogos_provider.dart';

/// Yape en el registro de conductor: «Próximamente» para todos, y habilitado solo para quien el servidor diga (modo de prueba del
/// Director: una lista de documentos). El app solo dibuja lo que el servidor responde y NUNCA habilita Yape por su cuenta.

/// `data` de `GET /app/inscripcion/monto` con el bloque `yape` que se indique.
InscripcionPagoInfoModel _info(Map<String, dynamic>? yape, {double monto = 50}) => InscripcionPagoInfoModel.fromJson({
      'tipo': 'conductor',
      'monto': monto,
      'caja_arequipa': {'disponible': true},
      'izipay': {'disponible': false},
      if (yape != null) 'yape': yape,
    });

const _proximamente = {'disponible': false, 'proximamente': true, 'monto': 50, 'recargo': 1.39, 'total': 51.39};

/// Repositorio con solo lo que usa esta prueba: el monto y la pregunta «¿esta persona puede usar Yape?».
class _Repo extends Fake implements CatalogosRepository {
  _Repo(this.info, {this.acceso, this.fallaAcceso = false, this.lanzaAcceso = false});

  final InscripcionPagoInfoModel info;
  final bool? acceso;
  final bool fallaAcceso;
  final bool lanzaAcceso;
  final List<String> preguntas = [];

  @override
  Future<Either<Failure, InscripcionPagoInfoModel>> getInscripcionPagoInfo({String? plataforma, String? departamento, String? tipo}) async =>
      Either.right(info);

  @override
  Future<Either<Failure, bool>> getYapeAcceso({required String nroDocumento}) async {
    preguntas.add(nroDocumento);
    if (lanzaAcceso) throw StateError('se cayó');
    if (fallaAcceso) return Either.left(const ServerFailure('Sin conexión'));
    return Either.right(acceso ?? false);
  }
}

void main() {
  group('lo que dice el servidor de Yape', () {
    test('«Próximamente»: no se puede usar, pero se conserva lo que pagaría por si resulta que esta persona sí puede', () {
      final i = _info(_proximamente);

      expect(i.yapeProximamente, isTrue);
      expect(i.yapeDisponible, isFalse);
      expect(i.yapeRecargo, 1.39);
      expect(i.yapeTotal, 51.39);
    });

    test('habilitado nunca es a la vez «Próximamente», aunque el servidor mande las dos marcas', () {
      final i = _info({'disponible': true, 'proximamente': true, 'monto': 50, 'recargo': 0, 'total': 50});

      expect(i.yapeDisponible, isTrue);
      expect(i.yapeProximamente, isFalse);
    });

    test('un servidor anterior no manda `yape`: no se muestra nada de Yape', () {
      final i = _info(null);

      expect(i.yapeDisponible, isFalse);
      expect(i.yapeProximamente, isFalse);
    });

    test('ni disponible ni próximamente (inscripción gratis o pasajero): tampoco se muestra', () {
      final i = _info({'disponible': false, 'proximamente': false}, monto: 0);

      expect(i.yapeDisponible, isFalse);
      expect(i.yapeProximamente, isFalse);
      expect(i.yapeTotal, 0);
    });

    test('conYapeHabilitado conserva todo lo demás y solo enciende Yape', () {
      final base = InscripcionPagoInfoModel.fromJson({
        'tipo': 'conductor',
        'monto': 50,
        'caja_arequipa': {'disponible': true},
        'izipay': {'disponible': true, 'qr_url': 'https://x/qr.png'},
        'yape': _proximamente,
      });

      final i = base.conYapeHabilitado();

      expect(i.yapeDisponible, isTrue);
      expect(i.yapeProximamente, isFalse);
      expect(i.monto, 50);
      expect(i.tipo, 'conductor');
      expect(i.cajaDisponible, isTrue);
      expect(i.izipayDisponible, isTrue);
      expect(i.qrUrl, 'https://x/qr.png');
      expect(i.yapeRecargo, 1.39);
      expect(i.yapeTotal, 51.39);
    });
  });

  group('modo de prueba: se pregunta con el documento si ESTA persona puede usar Yape', () {
    Future<InscripcionPagoInfoModel> consultar(_Repo repo, {String? documento = '004455667'}) =>
        CatalogosProvider(catalogosRepository: repo).fetchInscripcionPagoInfo(plataforma: 'indriver', departamento: 'AREQUIPA', documento: documento);

    test('si el servidor dice que sí, Yape se habilita para ella', () async {
      final repo = _Repo(_info(_proximamente), acceso: true);

      final i = await consultar(repo);

      expect(i.yapeDisponible, isTrue);
      expect(i.yapeProximamente, isFalse);
      expect(i.yapeTotal, 51.39);
      expect(repo.preguntas, ['004455667']);
    });

    test('si el servidor dice que no, sigue «Próximamente»', () async {
      final i = await consultar(_Repo(_info(_proximamente), acceso: false));

      expect(i.yapeDisponible, isFalse);
      expect(i.yapeProximamente, isTrue);
    });

    test('si la pregunta falla (sin red, error del servidor), Yape NO se habilita: queda «Próximamente»', () async {
      final sinRed = await consultar(_Repo(_info(_proximamente), fallaAcceso: true));
      final cae = await consultar(_Repo(_info(_proximamente), lanzaAcceso: true));

      expect(sinRed.yapeDisponible, isFalse);
      expect(sinRed.yapeProximamente, isTrue);
      expect(cae.yapeDisponible, isFalse);
      expect(cae.yapeProximamente, isTrue);
    });

    test('el documento se manda sin espacios de más, y sin documento no se pregunta nada', () async {
      final conEspacios = _Repo(_info(_proximamente), acceso: true);
      await consultar(conEspacios, documento: '  004455667 ');
      expect(conEspacios.preguntas, ['004455667']);

      for (final vacio in [null, '', '   ']) {
        final repo = _Repo(_info(_proximamente), acceso: true);
        final i = await consultar(repo, documento: vacio);

        expect(repo.preguntas, isEmpty);
        expect(i.yapeDisponible, isFalse);
        expect(i.yapeProximamente, isTrue);
      }
    });

    test('si Yape ya está habilitado para todos, o el servidor no lo conoce, no se pregunta nada', () async {
      final paraTodos = _Repo(_info({'disponible': true, 'proximamente': false, 'monto': 50, 'recargo': 0, 'total': 50}), acceso: false);
      final viejo = _Repo(_info(null), acceso: true);

      expect((await consultar(paraTodos)).yapeDisponible, isTrue);
      expect((await consultar(viejo)).yapeDisponible, isFalse);
      expect(paraTodos.preguntas, isEmpty);
      expect(viejo.preguntas, isEmpty);
    });
  });

  group('la tarjeta de Yape en el paso de pago', () {
    Widget paso(InscripcionPagoInfoModel info, {String? metodo, ValueChanged<String>? onMetodo}) => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PagoInscripcionRegistro(
                info: info,
                cargando: false,
                error: null,
                metodo: metodo,
                captura: null,
                operacionController: TextEditingController(),
                onMetodo: onMetodo ?? (_) {},
                onElegirCaptura: () {},
                onReintentar: () {},
              ),
            ),
          ),
        );

    testWidgets('«Próximamente»: se ve la tarjeta apagada con su etiqueta y no se puede elegir', (tester) async {
      String? elegido;
      await tester.pumpWidget(paso(_info(_proximamente), onMetodo: (m) => elegido = m));

      expect(find.byKey(const Key('pago_metodo_yape_proximamente')), findsOneWidget);
      expect(find.byKey(const Key('pago_yape_etiqueta_proximamente')), findsOneWidget);
      expect(find.text('Próximamente'), findsOneWidget);
      expect(find.byKey(const Key('pago_metodo_yape')), findsNothing);

      await tester.tap(find.byKey(const Key('pago_metodo_yape_proximamente')), warnIfMissed: false);
      await tester.pump();

      expect(elegido, isNull);
      expect(find.byKey(const Key('pago_nota_yape')), findsNothing);   // no hay nada que explicar de un pago que no se puede hacer
    });

    testWidgets('«Próximamente» no estorba a los otros métodos: Caja Arequipa sigue eligiéndose', (tester) async {
      String? elegido;
      await tester.pumpWidget(paso(_info(_proximamente), onMetodo: (m) => elegido = m));

      await tester.tap(find.byKey(const Key('pago_metodo_caja')));
      await tester.pump();

      expect(elegido, PagoInscripcionRegistro.metodoCaja);
    });

    testWidgets('habilitado: tarjeta normal que se puede elegir, sin etiqueta «Próximamente»', (tester) async {
      String? elegido;
      await tester.pumpWidget(paso(_info(_proximamente).conYapeHabilitado(), onMetodo: (m) => elegido = m));

      expect(find.byKey(const Key('pago_metodo_yape')), findsOneWidget);
      expect(find.byKey(const Key('pago_metodo_yape_proximamente')), findsNothing);
      expect(find.text('Próximamente'), findsNothing);

      await tester.tap(find.byKey(const Key('pago_metodo_yape')));
      await tester.pump();

      expect(elegido, PagoInscripcionRegistro.metodoYape);
    });

    testWidgets('sin nada de Yape (servidor anterior) o con inscripción gratis, no sale ninguna tarjeta de Yape', (tester) async {
      await tester.pumpWidget(paso(_info(null)));
      expect(find.byKey(const Key('pago_metodo_yape_proximamente')), findsNothing);
      expect(find.byKey(const Key('pago_metodo_yape')), findsNothing);

      await tester.pumpWidget(paso(_info({'disponible': false, 'proximamente': false}, monto: 0)));
      expect(find.byKey(const Key('pago_sin_costo')), findsOneWidget);
      expect(find.byKey(const Key('pago_metodo_yape_proximamente')), findsNothing);
    });
  });

  group('el logo de Yape', () {
    testWidgets('usa el ícono oficial del proyecto, al tamaño pedido', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: YapeLogo(tamano: 40)))));
      await tester.pump();

      final imagen = tester.widget<Image>(find.byType(Image));
      expect((imagen.image as AssetImage).assetName, 'images/yape_logo.png');
      expect(tester.getSize(find.byType(Image)), const Size(40, 40));
    });

    testWidgets('si el archivo no carga, se dibuja la insignia con la «Y» y el pago no queda sin marca', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultAssetBundle(
            bundle: _BundleSinArchivos(),
            child: const Scaffold(body: Center(child: YapeLogo(tamano: 40))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Y'), findsOneWidget);
    });
  });
}

/// Un paquete de archivos al que no se le encuentra nada (como si el ícono no se hubiera empaquetado).
class _BundleSinArchivos extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Future.error(FlutterError('no existe $key'));
}
