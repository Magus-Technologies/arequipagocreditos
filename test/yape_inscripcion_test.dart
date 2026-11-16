import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/models/conductor_estado_model.dart';
import 'package:arequipagocreditos/data/models/izipay_models.dart';
import 'package:arequipagocreditos/data/models/yape_models.dart';
import 'package:arequipagocreditos/domain/repositories/catalogos_repository.dart';
import 'package:arequipagocreditos/presentation/components/pago_inscripcion_registro.dart';
import 'package:arequipagocreditos/presentation/pages/conductor_estado_page.dart';
import 'package:arequipagocreditos/presentation/pages/conductor_register_success_page.dart';
import 'package:arequipagocreditos/presentation/pages/conductor_yape_page.dart';
import 'package:arequipagocreditos/presentation/providers/catalogos_provider.dart';

/// Pagar la inscripción con Yape: el SERVIDOR dice en qué paso va el pago y el app solo dibuja esa pantalla. Estas pruebas
/// comprueban que cada paso se vea bien, que el app nunca dé por pagado nada por su cuenta y que no haya cobros dobles.

/// Estado que contesta el servidor (`data` de `POST /app/yape/inscripcion/{id}/estado`).
YapeInscripcionEstadoModel _yape(
  String paso, {
  bool disponible = true,
  double monto = 50,
  double recargo = 1.39,
  double total = 51.39,
  Map<String, dynamic>? afiliacion,
  Map<String, dynamic>? cobro,
  String? mensaje,
}) =>
    YapeInscripcionEstadoModel.fromJson({
      'disponible': disponible,
      'paso': paso,
      'monto': monto,
      'recargo': recargo,
      'total': total,
      'afiliacion': afiliacion,
      'cobro': cobro,
      'mensaje': mensaje,
    });

Map<String, dynamic> _afiliacionPendiente({int minutos = 14}) => {
      'estado': 'pending',
      'celular': '***4321',
      'link': 'yape://afiliar/abc',
      'expira_at': DateTime.now().add(Duration(minutes: minutos)).toIso8601String(),
    };

const Map<String, dynamic> _afiliacionConfirmada = {'estado': 'confirmed', 'celular': '***4321', 'link': null, 'expira_at': null};

/// Repositorio que contesta lo que el servidor contestaría. Los estados se entregan en orden (el último se repite) y se cuentan
/// las llamadas para comprobar que no se cobra de más.
class _RepoYape extends Fake implements CatalogosRepository {
  _RepoYape({List<YapeInscripcionEstadoModel>? estados, this.alAfiliar, this.alCobrar, this.conductor})
      : _estados = List.of(estados ?? [_yape('afiliar')]);

  final List<YapeInscripcionEstadoModel> _estados;
  final Future<Either<Failure, YapeInscripcionEstadoModel>> Function(String celular)? alAfiliar;
  final Future<Either<Failure, YapeInscripcionEstadoModel>> Function()? alCobrar;
  final ConductorEstadoModel? conductor;

  int consultas = 0;
  final List<String> celulares = [];
  int cobros = 0;

  YapeInscripcionEstadoModel get _actual => _estados.length > 1 ? _estados.first : _estados.single;

  void _avanzar() {
    if (_estados.length > 1) _estados.removeAt(0);
  }

  /// Lo que pasa en el servidor: el siguiente estado pasa a ser el vigente.
  void servidorAvanzaA(YapeInscripcionEstadoModel estado) {
    _estados
      ..clear()
      ..add(estado);
  }

  @override
  Future<Either<Failure, ConductorEstadoModel>> getConductorEstado(int conductorId) async => Either.right(conductor!);

  @override
  Future<Either<Failure, YapeInscripcionEstadoModel>> getYapeInscripcionEstado({required int clienteId, required String nroDocumento}) async {
    consultas++;
    final estado = _actual;
    _avanzar();
    return Either.right(estado);
  }

  @override
  Future<Either<Failure, YapeInscripcionEstadoModel>> afiliarYapeInscripcion({
    required int clienteId,
    required String nroDocumento,
    required String celular,
  }) async {
    celulares.add(celular);
    if (alAfiliar != null) return alAfiliar!(celular);
    return Either.right(_yape('aprobar_en_yape', afiliacion: _afiliacionPendiente()));
  }

  @override
  Future<Either<Failure, YapeInscripcionEstadoModel>> cobrarYapeInscripcion({required int clienteId, required String nroDocumento}) async {
    cobros++;
    if (alCobrar != null) return alCobrar!();
    return Either.right(_yape('procesando', afiliacion: _afiliacionConfirmada, cobro: {'estado': 'enviado', 'monto': 51.39}));
  }
}

void main() {
  group('modelos', () {
    test('el estado del pago se lee tal como lo manda el servidor', () {
      final e = YapeInscripcionEstadoModel.fromJson({
        'disponible': true,
        'paso': 'aprobar_en_yape',
        'monto': 50,
        'recargo': '1.39',
        'total': 51.39,
        'afiliacion': {'estado': 'pending', 'celular': '***4321', 'link': 'yape://x', 'expira_at': '2026-11-16T10:15:00-05:00'},
        'cobro': {'estado': 'denegado', 'monto': 51.39, 'mensaje': 'No tienes saldo suficiente en tu Yape. Recarga y vuelve a intentar.'},
        'mensaje': 'Abre Yape y aprueba la afiliación.',
      });

      expect(e.paso, 'aprobar_en_yape');
      expect(e.monto, 50.0);
      expect(e.recargo, 1.39);
      expect(e.total, 51.39);
      expect(e.tieneRecargo, isTrue);
      expect(e.afiliacion!.celular, '***4321');
      expect(e.afiliacion!.link, 'yape://x');
      expect(e.afiliacion!.expiraAt, isNotNull);
      expect(e.cobro!.estado, 'denegado');
      expect(e.cobro!.mensaje, contains('saldo suficiente'));
      expect(e.esperando, isTrue);
      expect(e.pagada, isFalse);
      expect(e.puedePagarse, isTrue);
    });

    test('esperando solo en aprobar en Yape y procesando; pagada y no disponible no se pueden pagar', () {
      expect(_yape('procesando').esperando, isTrue);
      expect(_yape('afiliar').esperando, isFalse);
      expect(_yape('cobrar').esperando, isFalse);
      expect(_yape('pagada').pagada, isTrue);
      expect(_yape('pagada').puedePagarse, isFalse);
      expect(_yape('no_disponible').puedePagarse, isFalse);
      expect(_yape('afiliar', disponible: false).puedePagarse, isFalse);
    });

    test('sin recargo no hay línea de costo por usar Yape y el total es la inscripción', () {
      final e = YapeInscripcionEstadoModel.fromJson({'disponible': true, 'paso': 'afiliar', 'monto': 50});

      expect(e.tieneRecargo, isFalse);
      expect(e.total, 50.0);
    });

    test('un paso que el app no conoce se trata como no disponible', () {
      expect(YapeInscripcionEstadoModel.fromJson({'monto': 50}).paso, YapeInscripcionEstadoModel.pasoNoDisponible);
    });

    test('Yape en el monto de la inscripción: con recargo y total', () {
      final info = InscripcionPagoInfoModel.fromJson({
        'monto': 50,
        'caja_arequipa': {'disponible': true},
        'izipay': {'disponible': false},
        'yape': {'disponible': true, 'monto': 50, 'recargo': 1.39, 'total': 51.39},
      });

      expect(info.yapeDisponible, isTrue);
      expect(info.yapeRecargo, 1.39);
      expect(info.yapeTotal, 51.39);
    });

    test('un servidor que no manda Yape, o lo tiene apagado, no lo ofrece', () {
      final sin = InscripcionPagoInfoModel.fromJson({'monto': 100, 'caja_arequipa': {'disponible': true}});
      final apagado = InscripcionPagoInfoModel.fromJson({'monto': 100, 'yape': {'disponible': false}});

      expect(sin.yapeDisponible, isFalse);
      expect(apagado.yapeDisponible, isFalse);
      expect(apagado.yapeRecargo, 0);
      expect(apagado.yapeTotal, 100.0);
    });
  });

  group('elegir Yape en el paso de pago del registro', () {
    const conYape = InscripcionPagoInfoModel(monto: 50, yapeDisponible: true, yapeRecargo: 1.39, yapeTotal: 51.39);
    const conYapeSinRecargo = InscripcionPagoInfoModel(monto: 50, yapeDisponible: true);

    Widget paso({InscripcionPagoInfoModel info = conYape, String? metodo, ValueChanged<String>? onMetodo}) => MaterialApp(
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

    testWidgets('Yape aparece junto a Caja Arequipa cuando el servidor lo ofrece', (tester) async {
      await tester.pumpWidget(paso());

      expect(find.byKey(const Key('pago_metodo_caja')), findsOneWidget);
      expect(find.byKey(const Key('pago_metodo_yape')), findsOneWidget);
    });

    testWidgets('sin Yape en el servidor no se ofrece (el app nuevo con un servidor que no lo tiene)', (tester) async {
      await tester.pumpWidget(paso(info: const InscripcionPagoInfoModel(monto: 50)));

      expect(find.byKey(const Key('pago_metodo_yape')), findsNothing);
    });

    testWidgets('elegirlo avisa el método «yape»', (tester) async {
      final elegidos = <String>[];
      await tester.pumpWidget(paso(onMetodo: elegidos.add));

      await tester.tap(find.byKey(const Key('pago_metodo_yape')));

      expect(elegidos, [PagoInscripcionRegistro.metodoYape]);
      expect(PagoInscripcionRegistro.metodoYape, 'yape');
    });

    testWidgets('muestra el costo por usar Yape como línea aparte, antes de continuar', (tester) async {
      await tester.pumpWidget(paso(metodo: PagoInscripcionRegistro.metodoYape));

      expect(find.byKey(const Key('pago_nota_yape')), findsOneWidget);
      expect(find.textContaining('Pagarás S/ 51.39 en total: S/ 50.00 + S/ 1.39 de costo por pagar con Yape.'), findsOneWidget);
    });

    testWidgets('si Arequipa Go asume el costo, solo dice lo que se paga', (tester) async {
      await tester.pumpWidget(paso(info: conYapeSinRecargo, metodo: PagoInscripcionRegistro.metodoYape));

      expect(find.textContaining('Pagarás S/ 50.00 con tu Yape.'), findsOneWidget);
      expect(find.textContaining('costo por pagar'), findsNothing);
    });

    testWidgets('con Yape no se pide captura ni aparece el código de Caja', (tester) async {
      await tester.pumpWidget(paso(metodo: PagoInscripcionRegistro.metodoYape));

      expect(find.byKey(const Key('pago_captura')), findsNothing);
      expect(find.byKey(const Key('pago_nota_caja')), findsNothing);
    });
  });

  group('pantalla de pago con Yape', () {
    final finalizados = <bool>[];

    setUp(finalizados.clear);

    Future<void> abrir(
      WidgetTester tester,
      _RepoYape repo, {
      Duration intervalo = const Duration(milliseconds: 100),
    }) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider<CatalogosProvider>.value(
          value: CatalogosProvider(catalogosRepository: repo),
          child: MaterialApp(
            home: ConductorYapePage(
              conductorId: 7,
              nroDocumento: '00445566',
              telefonoInicial: '987 654 321',
              intervalo: intervalo,
              alFinalizar: (_, pagada) => finalizados.add(pagada),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    /// Deja pasar el tiempo para que corra la consulta periódica y lleguen sus respuestas.
    Future<void> pasar(WidgetTester tester, [Duration tiempo = const Duration(milliseconds: 150)]) async {
      await tester.pump(tiempo);
      await tester.pump();
    }

    testWidgets('paso afiliar: monto con el costo de Yape, celular del registro y el botón dice cuánto se cobra', (tester) async {
      await abrir(tester, _RepoYape());

      expect(find.byKey(const Key('yape_paso_afiliar')), findsOneWidget);
      expect(find.text('Hoy se cobrará'), findsOneWidget);
      expect(find.text('S/ 51.39'), findsOneWidget);
      expect(find.text('Inscripción a Arequipa Go (S/ 50.00 + S/ 1.39)'), findsOneWidget);
      expect(find.text('Afiliar y pagar S/ 51.39'), findsOneWidget);
      expect(find.text('Se abrirá Yape para que apruebes. Tienes 15 minutos.'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('yape_celular'))).controller!.text, '987654321');
    });

    testWidgets('sin costo por usar Yape el detalle no habla de recargo', (tester) async {
      await abrir(tester, _RepoYape(estados: [_yape('afiliar', recargo: 0, total: 50)]));

      expect(find.text('Inscripción a Arequipa Go'), findsOneWidget);
      expect(find.text('Afiliar y pagar S/ 50.00'), findsOneWidget);
    });

    testWidgets('no afilia sin aceptar la autorización', (tester) async {
      final repo = _RepoYape();
      await abrir(tester, repo);

      await tester.tap(find.byKey(const Key('yape_btn_afiliar')));
      await tester.pump();

      expect(find.text('Debes aceptar la autorización para afiliar tu Yape.'), findsOneWidget);
      expect(repo.celulares, isEmpty);
    });

    testWidgets('no afilia con un celular que no es de 9 dígitos', (tester) async {
      final repo = _RepoYape();
      await abrir(tester, repo);

      await tester.enterText(find.byKey(const Key('yape_celular')), '12345');
      await tester.tap(find.byKey(const Key('yape_acepta')));
      await tester.tap(find.byKey(const Key('yape_btn_afiliar')));
      await tester.pump();

      expect(find.textContaining('9 dígitos'), findsOneWidget);
      expect(repo.celulares, isEmpty);
    });

    testWidgets('un celular pegado con espacios o guiones queda completo y solo con dígitos', (tester) async {
      final repo = _RepoYape();
      await abrir(tester, repo);

      await tester.enterText(find.byKey(const Key('yape_celular')), '987 654-321');
      expect(tester.widget<TextField>(find.byKey(const Key('yape_celular'))).controller!.text, '987654321');

      await tester.tap(find.byKey(const Key('yape_acepta')));
      await tester.tap(find.byKey(const Key('yape_btn_afiliar')));
      await tester.pump();
      await tester.pump();

      expect(repo.celulares, ['987654321']);
    });

    testWidgets('la autorización completa se puede leer antes de aceptar', (tester) async {
      await abrir(tester, _RepoYape());

      await tester.tap(find.byKey(const Key('yape_ver_autorizacion')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('yape_autorizacion')), findsOneWidget);
      expect(find.textContaining('AREQUIPA GO S.A.C., mediante GMoney S.A.'), findsOneWidget);
      expect(find.textContaining('Versión 1.0'), findsOneWidget);
    });

    testWidgets('acepta, afilia con el celular y pasa a «Vamos a abrir Yape»', (tester) async {
      final repo = _RepoYape();
      await abrir(tester, repo);

      await tester.tap(find.byKey(const Key('yape_acepta')));
      await tester.tap(find.byKey(const Key('yape_btn_afiliar')));
      await tester.pump();
      await tester.pump();

      expect(repo.celulares, ['987654321']);
      expect(find.byKey(const Key('yape_paso_aprobar')), findsOneWidget);
      expect(find.text('Vamos a abrir Yape para que apruebes'), findsOneWidget);
      expect(find.text('Revisa que el comercio sea AREQUIPA GO.'), findsOneWidget);
      expect(find.text('Esperando tu aprobación en Yape…'), findsOneWidget);
      expect(find.byKey(const Key('yape_cuenta_regresiva')), findsOneWidget);
    });

    testWidgets('si el servidor no puede afiliar, muestra su mensaje y vuelve a consultar el estado', (tester) async {
      final repo = _RepoYape(alAfiliar: (_) async => Either.left(const ValidationFailure('El celular no es válido.')));
      await abrir(tester, repo);

      await tester.tap(find.byKey(const Key('yape_acepta')));
      await tester.tap(find.byKey(const Key('yape_btn_afiliar')));
      await tester.pump();
      await tester.pump();

      expect(find.text('El celular no es válido.'), findsOneWidget);
      expect(find.byKey(const Key('yape_paso_afiliar')), findsOneWidget);
      expect(repo.consultas, greaterThanOrEqualTo(2));
    });

    testWidgets('una afiliación rechazada o vencida se explica y se puede intentar de nuevo', (tester) async {
      await abrir(
        tester,
        _RepoYape(estados: [_yape('afiliar', afiliacion: {'estado': 'rejected', 'celular': '***4321'}, mensaje: 'Rechazaste la afiliación en Yape. Puedes volver a intentarlo.')]),
      );

      expect(find.text('Rechazaste la afiliación en Yape. Puedes volver a intentarlo.'), findsOneWidget);
      expect(find.byKey(const Key('yape_btn_afiliar')), findsOneWidget);
    });

    testWidgets('«Abrir Yape» abre el enlace que dio el servidor', (tester) async {
      final abiertos = <Uri>[];
      final anterior = ConductorYapePage.abridor;
      ConductorYapePage.abridor = (uri) async {
        abiertos.add(uri);
        return true;
      };
      addTearDown(() => ConductorYapePage.abridor = anterior);

      await abrir(tester, _RepoYape(estados: [_yape('aprobar_en_yape', afiliacion: _afiliacionPendiente())]));
      await tester.tap(find.byKey(const Key('yape_btn_abrir')));
      await tester.pump();

      expect(abiertos.map((u) => u.toString()), ['yape://afiliar/abc']);
      expect(find.byKey(const Key('yape_no_instalado')), findsNothing);
    });

    testWidgets('sin Yape instalado avisa y deja otra salida', (tester) async {
      final anterior = ConductorYapePage.abridor;
      ConductorYapePage.abridor = (uri) async => false;
      addTearDown(() => ConductorYapePage.abridor = anterior);

      await abrir(tester, _RepoYape(estados: [_yape('aprobar_en_yape', afiliacion: _afiliacionPendiente())]));
      await tester.tap(find.byKey(const Key('yape_btn_abrir')));
      await tester.pump();

      expect(find.byKey(const Key('yape_no_instalado')), findsOneWidget);
      expect(find.byKey(const Key('yape_btn_despues')), findsOneWidget);
    });

    testWidgets('«Ya aprobé, revisar» consulta el estado en el acto', (tester) async {
      final repo = _RepoYape(estados: [_yape('aprobar_en_yape', afiliacion: _afiliacionPendiente())]);
      await abrir(tester, repo);
      final antes = repo.consultas;

      await tester.tap(find.byKey(const Key('yape_btn_revisar')));
      await tester.pump();

      expect(repo.consultas, antes + 1);
    });

    testWidgets('mientras espera a Yape consulta cada pocos segundos y, al aprobar, cobra sola SOLO si venía de «Afiliar y pagar»', (tester) async {
      final repo = _RepoYape();
      await abrir(tester, repo);

      await tester.tap(find.byKey(const Key('yape_acepta')));
      await tester.tap(find.byKey(const Key('yape_btn_afiliar')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('yape_paso_aprobar')), findsOneWidget);
      expect(repo.cobros, 0);

      // En el servidor la persona aprobó en Yape: la siguiente consulta ya trae la afiliación confirmada.
      repo.servidorAvanzaA(_yape('cobrar', afiliacion: _afiliacionConfirmada));
      await pasar(tester);
      await tester.pump();

      expect(repo.cobros, 1, reason: 'el cobro del monto que ya vio sale solo');
      expect(find.byKey(const Key('yape_paso_procesando')), findsOneWidget);
      expect(find.text('Cobrando… S/ 51.39'), findsOneWidget);

      // El servidor confirma el pago: ahora sí el app muestra el éxito (nunca lo da por hecho antes).
      repo.servidorAvanzaA(_yape('pagada', afiliacion: _afiliacionConfirmada, cobro: {'estado': 'exitoso', 'monto': 51.39}));
      await pasar(tester);

      expect(find.byKey(const Key('yape_paso_pagada')), findsOneWidget);
      expect(find.text('¡Pago exitoso!'), findsOneWidget);
      expect(find.text('Yape ***4321'), findsOneWidget);
      expect(find.text('S/ 51.39'), findsOneWidget);
      expect(repo.cobros, 1);
    });

    testWidgets('al volver con la afiliación ya aprobada (sin pasar por «Afiliar y pagar») NO cobra sola: pide confirmar', (tester) async {
      final repo = _RepoYape(estados: [_yape('cobrar', afiliacion: _afiliacionConfirmada)]);
      await abrir(tester, repo);
      await pasar(tester, const Duration(seconds: 1));

      expect(find.byKey(const Key('yape_paso_cobrar')), findsOneWidget);
      expect(find.text('¡Tu Yape quedó afiliado!'), findsOneWidget);
      expect(find.text('Celular ***4321 · Yape'), findsOneWidget);
      expect(find.text('Se cobrará'), findsOneWidget);
      expect(find.text('Confirmar y pagar'), findsOneWidget);
      expect(repo.cobros, 0);
    });

    testWidgets('«Confirmar y pagar» cobra una sola vez aunque se toque dos veces', (tester) async {
      final respuesta = Completer<Either<Failure, YapeInscripcionEstadoModel>>();
      final repo = _RepoYape(estados: [_yape('cobrar', afiliacion: _afiliacionConfirmada)], alCobrar: () => respuesta.future);
      await abrir(tester, repo);

      await tester.tap(find.byKey(const Key('yape_btn_cobrar')));
      await tester.pump();
      // Con el cobro en camino se ve «Cobrando…» y ya no hay botón que tocar otra vez.
      expect(find.byKey(const Key('yape_paso_procesando')), findsOneWidget);
      expect(find.byKey(const Key('yape_btn_cobrar')), findsNothing);

      respuesta.complete(Either.right(_yape('procesando', afiliacion: _afiliacionConfirmada, cobro: {'estado': 'enviado', 'monto': 51.39})));
      await tester.pump();
      await tester.pump();

      expect(repo.cobros, 1);
    });

    testWidgets('un cobro rechazado muestra el motivo y permite reintentar', (tester) async {
      await abrir(
        tester,
        _RepoYape(estados: [
          _yape(
            'cobrar',
            afiliacion: _afiliacionConfirmada,
            cobro: {'estado': 'denegado', 'monto': 51.39, 'mensaje': 'No tienes saldo suficiente en tu Yape. Recarga y vuelve a intentar.'},
            mensaje: 'No tienes saldo suficiente en tu Yape. Recarga y vuelve a intentar.',
          ),
        ]),
      );

      expect(find.text('No pudimos cobrar tu inscripción'), findsOneWidget);
      expect(find.text('No tienes saldo suficiente en tu Yape. Recarga y vuelve a intentar.'), findsOneWidget);
      expect(find.text('Reintentar con Yape'), findsOneWidget);
    });

    testWidgets('un cobro en curso se ve como «procesando» y se puede salir sin perder el pago', (tester) async {
      await abrir(
        tester,
        _RepoYape(estados: [_yape('procesando', afiliacion: _afiliacionConfirmada, cobro: {'estado': 'enviado', 'monto': 51.39}, mensaje: 'Esperando la confirmación de Yape.')]),
      );

      expect(find.byKey(const Key('yape_paso_procesando')), findsOneWidget);
      expect(find.textContaining('No cierres esta pantalla'), findsOneWidget);
      expect(find.text('Esperando la confirmación de Yape.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('yape_btn_salir')));
      expect(finalizados, [false]);
    });

    testWidgets('ya pagada: comprobante y «Continuar» avisa que quedó pagada', (tester) async {
      await abrir(
        tester,
        _RepoYape(estados: [_yape('pagada', afiliacion: _afiliacionConfirmada, cobro: {'estado': 'exitoso', 'monto': 51.39})]),
      );

      expect(find.text('Concepto'), findsOneWidget);
      expect(find.text('Inscripción'), findsOneWidget);
      expect(find.text('Tu inscripción quedó pagada. Seguimos revisando tu solicitud.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('yape_btn_continuar')));
      expect(finalizados, [true]);
    });

    testWidgets('si Yape no está disponible lo dice con el texto del servidor y deja volver', (tester) async {
      await abrir(
        tester,
        _RepoYape(estados: [_yape('no_disponible', mensaje: 'Tu inscripción es en cuotas: por ahora págala con Caja Arequipa o IziPay.')]),
      );

      expect(find.byKey(const Key('yape_paso_no_disponible')), findsOneWidget);
      expect(find.text('Tu inscripción es en cuotas: por ahora págala con Caja Arequipa o IziPay.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('yape_btn_volver')));
      expect(finalizados, [false]);
    });

    testWidgets('«Pagar después» y la flecha de atrás salen sin dar el pago por hecho', (tester) async {
      await abrir(tester, _RepoYape());

      await tester.tap(find.byKey(const Key('yape_btn_despues')));
      await tester.tap(find.byKey(const Key('yape_atras')));

      expect(finalizados, [false, false]);
    });

    testWidgets('si no se puede consultar el estado ofrece reintentar', (tester) async {
      final repo = _RepoSinConexion();
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider<CatalogosProvider>.value(
          value: CatalogosProvider(catalogosRepository: repo),
          child: const MaterialApp(home: ConductorYapePage(conductorId: 7, nroDocumento: '00445566')),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('yape_error')), findsOneWidget);
      expect(find.text('Sin conexión'), findsOneWidget);

      await tester.tap(find.byKey(const Key('yape_btn_reintentar')));
      await tester.pump();
      await tester.pump();

      expect(repo.consultas, 2);
    });
  });

  group('«Se envió tu solicitud» con Yape', () {
    Future<void> pintar(WidgetTester tester, {bool pagado = false}) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: ConductorRegisterSuccessPage(
            conductorId: 7,
            yapePagado: pagado,
            inscripcion: const {'metodo': 'yape', 'monto': 50, 'orden_pago': null, 'captura_izipay': null},
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('si todavía no pagó avisa que lo retoma desde «Ver el resultado»', (tester) async {
      await pintar(tester);

      expect(find.byKey(const Key('exito_yape_pendiente')), findsOneWidget);
      expect(find.textContaining('Ver el resultado'), findsWidgets);
      expect(find.byKey(const Key('exito_codigo_caja')), findsNothing);
    });

    testWidgets('si ya pagó lo dice', (tester) async {
      await pintar(tester, pagado: true);

      expect(find.byKey(const Key('exito_yape_pagado')), findsOneWidget);
      expect(find.text('Tu inscripción quedó pagada con Yape.'), findsOneWidget);
    });
  });

  group('«Estado de tu solicitud» y Yape', () {
    Map<String, dynamic> base(String estado, {Map<String, dynamic>? extra}) => {
          'id': 7,
          'nro_documento': '00445566',
          'estado_aprobacion': estado,
          'inscripcion_pagada': false,
          'pago_inscripcion': {'tipo_pago': 'contado', 'monto_total': 50, 'estado': 'activo', 'cuotas': []},
          ...?extra,
        };

    Future<_RepoYape> abrir(WidgetTester tester, Map<String, dynamic> json, {List<YapeInscripcionEstadoModel>? yape}) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _RepoYape(estados: yape ?? [_yape('afiliar')], conductor: ConductorEstadoModel.fromJson(json));
      await tester.pumpWidget(
        ChangeNotifierProvider<CatalogosProvider>.value(
          value: CatalogosProvider(catalogosRepository: repo),
          child: const MaterialApp(home: ConductorEstadoPage(conductorId: 7)),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('en revisión y sin pagar: muestra el pago pendiente con un botón para pagar con Yape', (tester) async {
      await abrir(tester, base('pendiente'));

      expect(find.text('Pago con Yape:'), findsOneWidget);
      expect(find.text('Pendiente · S/ 51.39'), findsOneWidget);
      expect(find.byKey(const Key('estado_btn_pagar_yape')), findsOneWidget);
    });

    testWidgets('tocar «Pagar con Yape» abre la pantalla de pago con el id y el documento de la solicitud', (tester) async {
      await abrir(tester, base('pendiente'));

      await tester.tap(find.byKey(const Key('estado_btn_pagar_yape')));
      await tester.pumpAndSettle();

      final pagina = tester.widget<ConductorYapePage>(find.byType(ConductorYapePage));
      expect(pagina.conductorId, 7);
      expect(pagina.nroDocumento, '00445566');
    });

    testWidgets('con el cobro en curso el botón dice «Ver mi pago»', (tester) async {
      await abrir(tester, base('pendiente'), yape: [_yape('procesando', afiliacion: _afiliacionConfirmada, cobro: {'estado': 'enviado', 'monto': 51.39})]);

      expect(find.text('Procesando · S/ 51.39'), findsOneWidget);
      expect(find.text('Ver mi pago'), findsOneWidget);
    });

    testWidgets('aprobada y sin pagar: Yape aparece junto a los otros métodos con su total', (tester) async {
      await abrir(tester, base('aprobado'));

      expect(find.text('Selecciona tu método de pago'), findsOneWidget);
      expect(find.byKey(const Key('estado_metodo_yape')), findsOneWidget);
      expect(find.textContaining('Paga S/ 51.39: S/ 50.00 + S/ 1.39 de costo por usar Yape.'), findsOneWidget);
    });

    testWidgets('con el servidor sin Yape no aparece ni la fila ni la tarjeta', (tester) async {
      await abrir(tester, base('pendiente'), yape: [_yape('afiliar', disponible: false)]);
      expect(find.byKey(const Key('estado_btn_pagar_yape')), findsNothing);

      await abrir(tester, base('aprobado'), yape: [_yape('no_disponible')]);
      expect(find.byKey(const Key('estado_metodo_yape')), findsNothing);
    });

    testWidgets('quien ya empezó con un código de Caja no recibe una segunda oferta ni se le consulta a Yape', (tester) async {
      final repo = await abrir(
        tester,
        base('pendiente', extra: {
          'orden_pago': {'codigo': '48213', 'estado': 'pendiente', 'monto_total': 50},
        }),
      );

      expect(find.byKey(const Key('estado_btn_pagar_yape')), findsNothing);
      expect(find.text('48213'), findsOneWidget);
      expect(repo.consultas, 0);
    });

    testWidgets('ya pagada no se consulta ni se ofrece Yape', (tester) async {
      final repo = await abrir(tester, base('aprobado', extra: {'inscripcion_pagada': true}));

      expect(find.byKey(const Key('estado_metodo_yape')), findsNothing);
      expect(repo.consultas, 0);
    });

    testWidgets('si la consulta de Yape falla, el resto de la pantalla funciona igual', (tester) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider<CatalogosProvider>.value(
          value: CatalogosProvider(catalogosRepository: _RepoSinConexion(conductor: ConductorEstadoModel.fromJson(base('pendiente')))),
          child: const MaterialApp(home: ConductorEstadoPage(conductorId: 7)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tu solicitud está\nen revisión'), findsOneWidget);
      expect(find.byKey(const Key('estado_btn_pagar_yape')), findsNothing);
    });
  });
}

/// Repositorio al que no le llega nada de Yape (sin señal): para comprobar que nada se rompe.
class _RepoSinConexion extends Fake implements CatalogosRepository {
  _RepoSinConexion({this.conductor});

  final ConductorEstadoModel? conductor;
  int consultas = 0;

  @override
  Future<Either<Failure, ConductorEstadoModel>> getConductorEstado(int conductorId) async => Either.right(conductor!);

  @override
  Future<Either<Failure, YapeInscripcionEstadoModel>> getYapeInscripcionEstado({required int clienteId, required String nroDocumento}) async {
    consultas++;
    return Either.left(const ServerFailure('Sin conexión'));
  }
}
