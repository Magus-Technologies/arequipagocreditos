import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/core/utils/pdf_paginas.dart';
import 'package:arequipagocreditos/data/datasources/signature_remote_datasource.dart';
import 'package:arequipagocreditos/domain/entities/posicion_firma.dart';
import 'package:arequipagocreditos/domain/repositories/signature_repository.dart';
import 'package:arequipagocreditos/domain/usecases/signature_usecases.dart';
import 'package:arequipagocreditos/presentation/pages/signature/colocar_firma_page.dart';
import 'package:arequipagocreditos/presentation/providers/signature_provider.dart';

/// TK-0353: el conductor dibuja su firma y la COLOCA sobre el PDF (arrastra, cambia de página y de tamaño). Lo que confirma
/// viaja al servidor como fracciones de la página en `posicion`, y ahí se estampa en una copia del documento.
const _pagina1x1 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

/// PNG real de [ancho]x[alto] (el lienzo exporta fondo blanco): lo que decodifica el motor de pruebas.
Future<Uint8List> _png(int ancho, int alto) async {
  final grabador = ui.PictureRecorder();
  ui.Canvas(grabador).drawRect(
    ui.Rect.fromLTWH(0, 0, ancho.toDouble(), alto.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  final imagen = await grabador.endRecording().toImage(ancho, alto);
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  return datos!.buffer.asUint8List();
}

class _Paginas implements PdfPaginas {
  _Paginas(this.total, {this.fallaEnPagina});

  @override
  final int total;
  final int? fallaEnPagina;
  final List<int> pedidas = [];
  bool cerrada = false;

  @override
  Future<PaginaPdf> renderizar(int numero) async {
    pedidas.add(numero);
    if (numero == fallaEnPagina) throw StateError('sin memoria');
    // Hoja A4 (595 x 842). El contenido es solo un pixel: se estira.
    return PaginaPdf(bytes: base64Decode(_pagina1x1), ancho: 595, alto: 842);
  }

  @override
  Future<void> cerrar() async => cerrada = true;
}

void main() {
  // Firma apaisada 300x120 (aspecto 2.5), como la que exporta el lienzo; se genera una vez con el motor real.
  Uint8List? firma;

  group('PosicionFirma', () {
    test('se manda al servidor en fracciones de la página, redondeadas', () {
      const p = PosicionFirma(pagina: 2, x: 0.123456789, y: 0.5, ancho: 0.3);

      expect(p.toJson(), {'pagina': 2, 'x': 0.12346, 'y': 0.5, 'ancho': 0.3});
    });

    test('dos posiciones iguales son iguales', () {
      expect(const PosicionFirma(pagina: 1, x: 0.1, y: 0.2, ancho: 0.3), const PosicionFirma(pagina: 1, x: 0.1, y: 0.2, ancho: 0.3));
    });
  });

  group('filtro «blanco → transparente» de la firma', () {
    // Alfa nuevo con la matriz del filtro, sobre un píxel (r, g, b, a) en 0-255.
    double alfa(double r, double g, double b, double a) {
      final m = ColocarFirmaPage.matrizBlancoTransparente;
      return (m[15] * r + m[16] * g + m[17] * b + m[18] * a + m[19]).clamp(0.0, 255.0);
    }

    test('lo transparente sigue transparente: si no, el filtro pinta de negro TODA la pantalla', () {
      expect(alfa(0, 0, 0, 0), 0);
    });

    test('el fondo blanco opaco pasa a transparente y el trazo negro sigue opaco', () {
      expect(alfa(255, 255, 255, 255), closeTo(0, 0.5));
      expect(alfa(0, 0, 0, 255), 255);
    });

    test('un trazo suavizado (gris) queda medio transparente, y el color de salida es siempre negro', () {
      expect(alfa(128, 128, 128, 255), closeTo(127, 1.5));
      final m = ColocarFirmaPage.matrizBlancoTransparente;
      expect(m.sublist(0, 15).every((v) => v == 0), isTrue);
    });
  });

  group('pantalla «Coloca tu firma»', () {
    PosicionFirma? resultado;
    var salioSinConfirmar = false;

    /// Abre la pantalla desde otra (como en la app) para poder leer lo que devuelve.
    Future<void> abrir(WidgetTester tester, PdfPaginas paginas, {int? paginaInicial}) async {
      tester.view.physicalSize = const Size(800, 1700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      resultado = null;
      salioSinConfirmar = false;
      firma ??= (await tester.runAsync(() => _png(300, 120)))!;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final r = await Navigator.of(context).push<PosicionFirma>(MaterialPageRoute(
                    builder: (_) => ColocarFirmaPage(title: 'Anexo', paginas: paginas, firmaPng: firma!, paginaInicial: paginaInicial),
                  ));
                  resultado = r;
                  salioSinConfirmar = r == null;
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    Future<void> confirmar(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('colocar_firma_confirmar')));
      await tester.pumpAndSettle();
    }

    testWidgets('abre en la última página, con la firma abajo a la derecha, y confirma esa posición', (tester) async {
      final paginas = _Paginas(3);
      await abrir(tester, paginas);

      expect(find.text('Página 3 de 3'), findsOneWidget);
      expect(paginas.pedidas, [3]);

      await confirmar(tester);

      final r = resultado!;
      expect(r.pagina, 3);
      expect(r.ancho, ColocarFirmaPage.anchoInicial);
      expect(r.x, closeTo(1 - ColocarFirmaPage.anchoInicial - 0.08, 0.001));
      expect(r.y, closeTo(0.78, 0.001));
    });

    testWidgets('arrastrar la firma la mueve en fracciones de la página (no en píxeles)', (tester) async {
      await abrir(tester, _Paginas(2));
      final hoja = tester.getSize(find.byKey(const Key('colocar_firma_hoja')));

      await tester.drag(find.byKey(const Key('colocar_firma_arrastre')), const Offset(-100, -150));
      await tester.pumpAndSettle();
      await confirmar(tester);

      // El arrastre tiene que mover exactamente lo que se desplazó el dedo, medido sobre la hoja que se ve.
      final r = resultado!;
      expect(r.x, closeTo(1 - ColocarFirmaPage.anchoInicial - 0.08 - 100 / hoja.width, 0.02));
      expect(r.y, closeTo(0.78 - 150 / hoja.height, 0.02));
    });

    testWidgets('no se puede sacar la firma de la hoja', (tester) async {
      await abrir(tester, _Paginas(1));

      await tester.drag(find.byKey(const Key('colocar_firma_arrastre')), const Offset(-2000, -2000));
      await tester.pumpAndSettle();
      await confirmar(tester);
      expect(resultado!.x, 0);
      expect(resultado!.y, 0);

      await abrir(tester, _Paginas(1));
      await tester.drag(find.byKey(const Key('colocar_firma_arrastre')), const Offset(2000, 2000));
      await tester.pumpAndSettle();
      await confirmar(tester);
      // Contra el borde derecho / inferior: la firma completa sigue dentro de la hoja.
      expect(resultado!.x, closeTo(1 - ColocarFirmaPage.anchoInicial, 0.0001));
      expect(resultado!.y, lessThan(1));
      expect(resultado!.y, greaterThan(0.7));
    });

    testWidgets('se puede cambiar de página y la firma se confirma en la que se eligió', (tester) async {
      final paginas = _Paginas(3);
      await abrir(tester, paginas);

      await tester.tap(find.byKey(const Key('colocar_firma_anterior')));
      await tester.pumpAndSettle();
      expect(find.text('Página 2 de 3'), findsOneWidget);
      await tester.tap(find.byKey(const Key('colocar_firma_anterior')));
      await tester.pumpAndSettle();
      expect(find.text('Página 1 de 3'), findsOneWidget);
      expect(paginas.pedidas, [3, 2, 1]);

      // En la primera ya no hay «anterior».
      expect(tester.widget<IconButton>(find.byKey(const Key('colocar_firma_anterior'))).onPressed, isNull);

      // Volver a una ya dibujada no la dibuja otra vez.
      await tester.tap(find.byKey(const Key('colocar_firma_siguiente')));
      await tester.pumpAndSettle();
      expect(paginas.pedidas, [3, 2, 1]);

      await confirmar(tester);
      expect(resultado!.pagina, 2);
    });

    testWidgets('la posición se conserva al cambiar de página', (tester) async {
      await abrir(tester, _Paginas(2));

      await tester.drag(find.byKey(const Key('colocar_firma_arrastre')), const Offset(-120, -60));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('colocar_firma_anterior')));
      await tester.pumpAndSettle();
      await confirmar(tester);

      expect(resultado!.pagina, 1);
      expect(resultado!.x, lessThan(1 - ColocarFirmaPage.anchoInicial - 0.08));
    });

    testWidgets('el control de tamaño cambia el ancho y la firma sigue dentro de la hoja', (tester) async {
      await abrir(tester, _Paginas(1));

      // A la derecha del todo: al agrandarla tiene que correrse hacia adentro.
      await tester.drag(find.byKey(const Key('colocar_firma_arrastre')), const Offset(2000, 0));
      await tester.pumpAndSettle();
      tester.widget<Slider>(find.byKey(const Key('colocar_firma_tamano'))).onChanged!(ColocarFirmaPage.anchoMaximo);
      await tester.pumpAndSettle();
      await confirmar(tester);

      expect(resultado!.ancho, ColocarFirmaPage.anchoMaximo);
      expect(resultado!.x + resultado!.ancho, lessThanOrEqualTo(1.0 + 1e-9));
    });

    testWidgets('salir sin confirmar no devuelve posición (no se firma nada)', (tester) async {
      await abrir(tester, _Paginas(2));

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(salioSinConfirmar, isTrue);
      expect(resultado, isNull);
    });

    testWidgets('con una página inicial indicada abre ahí', (tester) async {
      await abrir(tester, _Paginas(4), paginaInicial: 2);

      expect(find.text('Página 2 de 4'), findsOneWidget);
    });

    testWidgets('si una página no se puede dibujar avisa y deja reintentar, sin permitir confirmar', (tester) async {
      await abrir(tester, _Paginas(2, fallaEnPagina: 2));

      expect(find.text('No se pudo mostrar la página 2 del documento.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byKey(const Key('colocar_firma_confirmar'))).onPressed, isNull);
    });
  });

  group('la posición llega al servidor', () {
    test('el datasource la manda en `posicion`, y sin ella no manda nada extra (contratos y adendas igual que antes)', () async {
      final cuerpos = <Map<String, dynamic>>[];
      final cliente = MockClient((http.Request req) async {
        cuerpos.add(jsonDecode(req.body) as Map<String, dynamic>);
        return http.Response(jsonEncode({'success': true}), 200);
      });
      final datasource = SignatureRemoteDataSourceImpl(client: cliente);

      await datasource.firmar(
        tipo: 'documento-adicional',
        id: 12,
        firmaBase64: 'data:image/png;base64,AAA',
        nroDocumento: '45678912',
        posicion: const PosicionFirma(pagina: 2, x: 0.5, y: 0.8, ancho: 0.3),
      );
      await datasource.firmar(tipo: 'contrato', id: 1324, firmaBase64: 'data:image/png;base64,AAA', nroDocumento: '45678912');

      expect(cuerpos[0]['posicion'], {'pagina': 2, 'x': 0.5, 'y': 0.8, 'ancho': 0.3});
      expect(cuerpos[0]['nro_documento'], '45678912');
      expect(cuerpos[1].containsKey('posicion'), isFalse);
    });

    test('el provider se la pasa al caso de uso', () async {
      final casoDeUso = _FirmarCaptura();
      final provider = SignatureProvider(firmarUseCase: casoDeUso);

      final ok = await provider.firmar(
        tipo: 'documento-adicional',
        id: 12,
        firmaBase64: 'data:image/png;base64,AAA',
        nroDocumento: '45678912',
        posicion: const PosicionFirma(pagina: 1, x: 0.1, y: 0.2, ancho: 0.25),
      );

      expect(ok, isTrue);
      expect(casoDeUso.posicion, const PosicionFirma(pagina: 1, x: 0.1, y: 0.2, ancho: 0.25));
      expect(casoDeUso.tipo, 'documento-adicional');
      expect(casoDeUso.id, 12);
    });
  });
}

class _FirmarCaptura extends FirmarUseCase {
  _FirmarCaptura() : super(_RepoNulo());

  PosicionFirma? posicion;
  String? tipo;
  int? id;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call({
    required String tipo,
    required int id,
    required String firmaBase64,
    required String nroDocumento,
    PosicionFirma? posicion,
  }) async {
    this.tipo = tipo;
    this.id = id;
    this.posicion = posicion;
    return Either.right({'success': true});
  }
}

class _RepoNulo extends Fake implements SignatureRepository {}
