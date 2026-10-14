import 'dart:async';

import 'package:arequipagocreditos/core/utils/promociones_flyers_cache.dart';
import 'package:arequipagocreditos/data/models/promo_taller_banner_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// El cuadro de promociones tardaba en salir porque cada vez se pedía la lista, se abría el cuadro y recién ahí se bajaba la imagen
// (2 MB, sin guardar nada). PromocionesFlyersCache guarda la lista y baja las imágenes por adelantado.

PromoTallerBannerModel _banner(int id, {String? ruta}) => PromoTallerBannerModel(
      id: id,
      nombreBanner: 'flyer $id',
      rutaImagen: ruta ?? 'https://arequipago-ventas.pe/storage/cupones_banners/$id.webp',
    );

List<int> _ids(List<PromoTallerBannerModel> banners) => banners.map((b) => b.id).toList();

/// Deja que corran las tareas pendientes (guardado en disco, descargas por adelantado).
Future<void> _esperar() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> descargadas;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PromocionesFlyersCache.olvidarMemoria();
    descargadas = [];
    PromocionesFlyersCache.descargarImagen = (url) async => descargadas.add(url);
  });

  test('la primera vez, sin nada guardado, espera al servidor y deja la lista guardada', () async {
    final lista = await PromocionesFlyersCache.paraMostrar(
      PromocionesFlyersCache.talleres,
      () async => [_banner(1), _banner(2)],
    );
    expect(_ids(lista), [1, 2]);

    // Como en un arranque nuevo: sin memoria, solo lo que quedó en el celular.
    PromocionesFlyersCache.olvidarMemoria();
    final guardada = await PromocionesFlyersCache.paraMostrar(
      PromocionesFlyersCache.talleres,
      () async => throw Exception('sin conexión'),
    );
    expect(_ids(guardada), [1, 2]);
    expect(guardada.first.rutaImagen, 'https://arequipago-ventas.pe/storage/cupones_banners/1.webp');
  });

  test('con una lista guardada la devuelve al instante, sin esperar al servidor, y la refresca por detrás', () async {
    await PromocionesFlyersCache.actualizar(PromocionesFlyersCache.talleres, () async => [_banner(1)]);
    PromocionesFlyersCache.olvidarMemoria();

    final servidor = Completer<List<PromoTallerBannerModel>>();
    final lista = await PromocionesFlyersCache.paraMostrar(PromocionesFlyersCache.talleres, () => servidor.future);
    expect(_ids(lista), [1], reason: 'no debe quedarse esperando la respuesta del servidor');

    servidor.complete([_banner(2), _banner(3)]);
    await _esperar();

    final siguiente = await PromocionesFlyersCache.paraMostrar(
      PromocionesFlyersCache.talleres,
      () async => throw Exception('sin conexión'),
    );
    expect(_ids(siguiente), [2, 3], reason: 'la próxima vez ya sale la lista refrescada');
  });

  test('varios pedidos a la vez hacen una sola petición al servidor', () async {
    var peticiones = 0;
    final servidor = Completer<List<PromoTallerBannerModel>>();
    Future<List<PromoTallerBannerModel>> pedir() {
      peticiones++;
      return servidor.future;
    }

    final a = PromocionesFlyersCache.actualizar(PromocionesFlyersCache.talleres, pedir);
    final b = PromocionesFlyersCache.actualizar(PromocionesFlyersCache.talleres, pedir);
    final c = PromocionesFlyersCache.paraMostrar(PromocionesFlyersCache.talleres, pedir);
    servidor.complete([_banner(1)]);

    expect(_ids(await a), [1]);
    expect(_ids(await b), [1]);
    expect(_ids(await c), [1]);
    expect(peticiones, 1);
  });

  test('si el servidor falla conserva lo guardado; sin nada guardado devuelve vacío', () async {
    expect(
      await PromocionesFlyersCache.paraMostrar(PromocionesFlyersCache.talleres, () async => throw Exception('sin conexión')),
      isEmpty,
    );

    await PromocionesFlyersCache.actualizar(PromocionesFlyersCache.talleres, () async => [_banner(7)]);
    final tras = await PromocionesFlyersCache.actualizar(PromocionesFlyersCache.talleres, () async => throw Exception('500'));
    expect(_ids(tras), [7]);
  });

  test('si el servidor responde que no hay flyers (interruptor apagado) se guarda vacío y dejan de mostrarse', () async {
    await PromocionesFlyersCache.actualizar(PromocionesFlyersCache.comercios, () async => [_banner(1)]);
    await PromocionesFlyersCache.actualizar(PromocionesFlyersCache.comercios, () async => <PromoTallerBannerModel>[]);

    PromocionesFlyersCache.olvidarMemoria();
    final lista = await PromocionesFlyersCache.paraMostrar(
      PromocionesFlyersCache.comercios,
      () async => throw Exception('sin conexión'),
    );
    expect(lista, isEmpty);
  });

  test('Talleres y Comercios guardan cada uno su lista', () async {
    await PromocionesFlyersCache.actualizar(PromocionesFlyersCache.talleres, () async => [_banner(1)]);
    await PromocionesFlyersCache.actualizar(PromocionesFlyersCache.comercios, () async => [_banner(2)]);

    PromocionesFlyersCache.olvidarMemoria();
    Future<List<PromoTallerBannerModel>> sinRed() async => throw Exception('sin conexión');
    expect(_ids(await PromocionesFlyersCache.paraMostrar(PromocionesFlyersCache.talleres, sinRed)), [1]);
    expect(_ids(await PromocionesFlyersCache.paraMostrar(PromocionesFlyersCache.comercios, sinRed)), [2]);
  });

  test('baja las imágenes de a una y en orden; una que falla no impide bajar las demás', () async {
    PromocionesFlyersCache.descargarImagen = (url) async {
      descargadas.add(url);
      if (url.contains('rota')) throw Exception('404');
    };

    await PromocionesFlyersCache.actualizar(
      PromocionesFlyersCache.talleres,
      () async => [
        _banner(1),
        _banner(2, ruta: 'https://arequipago-ventas.pe/storage/cupones_banners/rota.webp'),
        _banner(3),
        _banner(4, ruta: ''),
      ],
    );
    await _esperar();

    expect(descargadas, [
      'https://arequipago-ventas.pe/storage/cupones_banners/1.webp',
      'https://arequipago-ventas.pe/storage/cupones_banners/rota.webp',
      'https://arequipago-ventas.pe/storage/cupones_banners/3.webp',
    ]);
  });
}
