import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/promo_taller_banner_model.dart';
import '../constants/api_constants.dart';

/// Memoria de los flyers de promociones de cada pantalla (Servicios de Taller, Comercios GO).
///
/// El cuadro flotante tiene que abrirse al instante al entrar. Antes se encadenaba todo cada vez: pedir la lista al servidor, abrir el
/// cuadro y recién ahí bajar la imagen (2 MB), sin guardar nada en el celular. Ahora:
///  - la lista de flyers se guarda en memoria y en el celular: al entrar se usa la guardada y se refresca por detrás para la próxima;
///  - las imágenes se bajan al disco apenas se conoce la lista (al abrir el app), en el mismo caché que usa CachedNetworkImage.
class PromocionesFlyersCache {
  PromocionesFlyersCache._();

  static const String talleres = 'talleres';
  static const String comercios = 'comercios';

  static final Map<String, List<PromoTallerBannerModel>> _memoria = {};
  static final Map<String, Future<List<PromoTallerBannerModel>>> _enVuelo = {};

  /// Cómo se baja una imagen al disco. Se puede cambiar en las pruebas para no tocar la red ni el almacenamiento.
  @visibleForTesting
  static Future<void> Function(String url) descargarImagen = _descargarImagenAlDisco;

  static Future<void> _descargarImagenAlDisco(String url) async {
    await DefaultCacheManager().getSingleFile(url);
  }

  static String _clave(String seccion) => 'promociones_flyers_$seccion';

  /// Los flyers listos para mostrar YA. Si hay una lista guardada (memoria o celular) se devuelve al instante y se refresca por
  /// detrás; si es la primera vez, espera al servidor. Nunca lanza: sin flyers o sin conexión devuelve vacío.
  static Future<List<PromoTallerBannerModel>> paraMostrar(
    String seccion,
    Future<List<PromoTallerBannerModel>> Function() pedir,
  ) async {
    final guardados = await _leer(seccion);
    if (guardados != null) {
      unawaited(actualizar(seccion, pedir));
      return guardados;
    }
    return actualizar(seccion, pedir);
  }

  /// Pide la lista al servidor (una sola petición a la vez por pantalla, aunque la pidan varios), la guarda y baja las imágenes al
  /// disco. Si el servidor responde que no hay flyers (interruptor apagado) se guarda vacío, para dejar de mostrar los anteriores.
  /// Si falla (sin conexión, error), conserva lo guardado.
  static Future<List<PromoTallerBannerModel>> actualizar(
    String seccion,
    Future<List<PromoTallerBannerModel>> Function() pedir,
  ) {
    // Bloque y no flecha: Map.remove devuelve el propio Future, y whenComplete esperaría a que ese Future termine… que es él mismo.
    return _enVuelo[seccion] ??= _actualizar(seccion, pedir).whenComplete(() {
      _enVuelo.remove(seccion);
    });
  }

  static Future<List<PromoTallerBannerModel>> _actualizar(
    String seccion,
    Future<List<PromoTallerBannerModel>> Function() pedir,
  ) async {
    try {
      final banners = await pedir();
      await _guardar(seccion, banners);
      unawaited(_calentarImagenes(banners));
      return banners;
    } catch (_) {
      return await _leer(seccion) ?? <PromoTallerBannerModel>[];
    }
  }

  static Future<List<PromoTallerBannerModel>?> _leer(String seccion) async {
    final enMemoria = _memoria[seccion];
    if (enMemoria != null) return enMemoria;

    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_clave(seccion));
      if (texto == null) return null;

      final lista = (json.decode(texto) as List)
          .map((banner) => PromoTallerBannerModel.fromJson(Map<String, dynamic>.from(banner as Map)))
          .toList();
      return _memoria[seccion] = lista;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _guardar(String seccion, List<PromoTallerBannerModel> banners) async {
    _memoria[seccion] = banners;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clave(seccion), json.encode(banners.map((banner) => banner.toJson()).toList()));
    } catch (_) {
      // Sin disco igual funciona con la memoria de esta sesión.
    }
  }

  /// Baja las imágenes de a una (la primera es la que se ve primero) para no competir con el resto de la pantalla. Una imagen que falla
  /// no impide bajar las demás.
  static Future<void> _calentarImagenes(List<PromoTallerBannerModel> banners) async {
    for (final banner in banners) {
      final url = ApiConstants.normalizeUrl(banner.rutaImagen);
      if (url.isEmpty) continue;
      try {
        await descargarImagen(url);
      } catch (_) {}
    }
  }

  /// Para que cada prueba empiece sin lo que dejó la anterior.
  @visibleForTesting
  static void olvidarMemoria() {
    _memoria.clear();
    _enVuelo.clear();
  }
}
