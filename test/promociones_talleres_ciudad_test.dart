import 'dart:convert';

import 'package:arequipagocreditos/data/datasources/beneficios_comercial_remote_datasource.dart';
import 'package:arequipagocreditos/data/datasources/comercio_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// TK-0393 (y TK-0382, que lo extiende a Comercios GO): los flyers de Servicios de Talleres y de Comercios GO se muestran solo en las ciudades que elige quien los sube. El servidor sabe la ciudad del
// conductor únicamente si el app se la manda (la ruta es pública), así que el app pide los flyers con `departamento` (el de su perfil).

Future<Uri> _pedir({String? departamento}) async {
  late Uri pedida;
  final client = MockClient((request) async {
    pedida = request.url;
    return http.Response(
      json.encode({'success': true, 'data': []}),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
  await BeneficiosComercialRemoteDataSourceImpl(client: client).getPromocionesTalleresBanners(departamento: departamento);
  return pedida;
}

void main() {
  test('pide los flyers con la ciudad del conductor', () async {
    final url = await _pedir(departamento: 'Lima');

    expect(url.path, endsWith('/app/promociones/servicios/banners'));
    expect(url.queryParameters, {'departamento': 'Lima'});
  });

  test('una ciudad con espacios o acentos viaja bien codificada', () async {
    final url = await _pedir(departamento: ' La Libertad ');

    expect(url.queryParameters, {'departamento': 'La Libertad'});
    expect(url.toString(), contains('departamento=La+Libertad'));
  });

  test('sin ciudad conocida no manda nada y el servidor responde solo con los flyers de todas las ciudades', () async {
    expect((await _pedir()).queryParameters, isEmpty);
    expect((await _pedir(departamento: '')).queryParameters, isEmpty);
    expect((await _pedir(departamento: '   ')).queryParameters, isEmpty);
  });

  group('Comercios GO', () {
    Future<Uri> pedirComercios({String? departamento}) async {
      late Uri pedida;
      final client = MockClient((request) async {
        pedida = request.url;
        return http.Response(
          json.encode({'success': true, 'data': []}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      await ComercioRemoteDataSourceImpl(client: client).getPromocionesBanners(departamento: departamento);
      return pedida;
    }

    test('pide los flyers de comercios con la ciudad del conductor', () async {
      final url = await pedirComercios(departamento: 'Arequipa');

      expect(url.path, endsWith('/app/promociones/comercios/banners'));
      expect(url.queryParameters, {'departamento': 'Arequipa'});
    });

    test('sin ciudad conocida no manda nada', () async {
      expect((await pedirComercios()).queryParameters, isEmpty);
      expect((await pedirComercios(departamento: '  ')).queryParameters, isEmpty);
    });
  });
}
