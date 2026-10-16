import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/models/catalogo_models.dart';
import 'package:arequipagocreditos/data/models/izipay_models.dart';
import 'package:arequipagocreditos/domain/repositories/catalogos_repository.dart';
import 'package:arequipagocreditos/presentation/pages/pre_register_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/catalogos_provider.dart';

/// La inscripción de PASAJEROS hoy es gratis, pero tendrá costo por ciudad. El registro del app no cambia mientras sea gratis; cuando
/// el servidor responde que en su ciudad tiene precio, aparece un paso de pago (Caja Arequipa o QR IziPay) antes de enviar la solicitud.
/// Es lo que pidió Yessenia: que los campos de pago salgan solos cuando se decida cobrar, sin otra versión del app.

class _AuthFalso extends ChangeNotifier implements AuthProvider {
  final List<Map<String, dynamic>> envios = [];
  final List<Map<String, File>> archivos = [];
  Map<String, dynamic>? respuesta = {'success': true, 'message': 'Pre-registro recibido. Un asesor revisará tu solicitud pronto.'};

  /// Mensaje de error del servidor cuando [respuesta] es null (el envío fue rechazado).
  String? mensajeDeError;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => mensajeDeError;

  @override
  Future<Map<String, dynamic>?> preRegister(Map<String, dynamic> data, Map<String, File> files) async {
    envios.add(data);
    archivos.add(files);
    return respuesta;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RepoMonto extends Fake implements CatalogosRepository {
  /// [fallasIniciales]: cuántas consultas seguidas fallan antes de responder bien (o todas, con un número grande).
  _RepoMonto(this.respuesta, {int fallasIniciales = 0}) : _fallasPendientes = fallasIniciales;
  final InscripcionPagoInfoModel respuesta;
  int _fallasPendientes;
  final List<Map<String, String?>> consultas = [];

  // Catálogos de ubicación: dos departamentos, cada uno con una provincia y un distrito.
  static const _departamentos = [
    UbigeoItemModel(codigo: '04', nombre: 'AREQUIPA'),
    UbigeoItemModel(codigo: '15', nombre: 'LIMA'),
  ];

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getDepartamentos() async => Either.right(_departamentos);

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getProvincias(String codigoDepartamento) async => Either.right([
        UbigeoItemModel(codigo: '${codigoDepartamento}01', nombre: codigoDepartamento == '04' ? 'AREQUIPA' : 'LIMA'),
      ]);

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getDistritos(String codigoProvincia) async => Either.right([
        UbigeoItemModel(codigo: '${codigoProvincia}01', nombre: codigoProvincia.startsWith('04') ? 'CERCADO' : 'MIRAFLORES'),
      ]);

  @override
  Future<Either<Failure, InscripcionPagoInfoModel>> getInscripcionPagoInfo({String? plataforma, String? departamento, String? tipo}) async {
    consultas.add({'plataforma': plataforma, 'departamento': departamento, 'tipo': tipo});
    if (_fallasPendientes > 0) {
      _fallasPendientes--;
      return Either.left(const ServerFailure('Sin conexión'));
    }
    return Either.right(respuesta);
  }
}

InscripcionPagoInfoModel _info(Map<String, dynamic> json) => InscripcionPagoInfoModel.fromJson({
      'caja_arequipa': {'disponible': true},
      'izipay': {'disponible': false},
      ...json,
    });

void main() {
  group('¿la inscripción del pasajero tiene costo?', () {
    test('gratis (monto 0) no cobra, venga del tipo que venga', () {
      expect(_info({'tipo': 'pasajero', 'monto': 0}).esCobroDePasajero, isFalse);
    });

    test('con precio y confirmado como monto de pasajeros, cobra', () {
      expect(_info({'tipo': 'pasajero', 'monto': 20}).esCobroDePasajero, isTrue);
    });

    test('un servidor anterior (sin «tipo») respondería el monto de un conductor: NO se le cobra al pasajero', () {
      final servidorViejo = _info({'monto': 100});

      expect(servidorViejo.tipo, isNull);
      expect(servidorViejo.esCobroDePasajero, isFalse);
    });

    test('el monto de un conductor tampoco cobra', () {
      expect(_info({'tipo': 'conductor', 'monto': 100}).esCobroDePasajero, isFalse);
    });
  });

  group('registro de pasajero', () {
    late _AuthFalso auth;

    Future<void> abrir(WidgetTester tester, _RepoMonto repo) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      auth = _AuthFalso();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<CatalogosProvider>.value(value: CatalogosProvider(catalogosRepository: repo)),
          ],
          child: const MaterialApp(home: PreRegisterPage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> escribir(WidgetTester tester, String etiqueta, String texto) async {
      await tester.enterText(find.widgetWithText(TextFormField, etiqueta), texto);
    }

    Future<void> siguiente(WidgetTester tester, [String boton = 'SIGUIENTE']) async {
      await tester.tap(find.text(boton));
      await tester.pumpAndSettle();
    }

    /// Abre el selector de [etiqueta] (departamento, provincia o distrito) y elige [opcion].
    Future<void> elegir(WidgetTester tester, String etiqueta, String opcion) async {
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, etiqueta));
      await tester.pumpAndSettle();
      await tester.tap(find.text(opcion).last);
      await tester.pumpAndSettle();
    }

    /// Elige la ubicación completa (cada nivel carga después de elegir el anterior).
    Future<void> elegirUbicacion(WidgetTester tester, {String departamento = 'AREQUIPA'}) async {
      await elegir(tester, 'Departamento', departamento);
      await elegir(tester, 'Provincia', departamento);
      await elegir(tester, 'Distrito', departamento == 'AREQUIPA' ? 'CERCADO' : 'MIRAFLORES');
    }

    /// Llena el paso 1 y deja la pantalla en el paso 2 (contacto y ubicación).
    Future<void> hastaElPaso2(WidgetTester tester) async {
      await escribir(tester, 'Nombres Completos', 'Rosa');
      await escribir(tester, 'Apellido Paterno', 'Quispe');
      await escribir(tester, 'Apellido Materno', 'Mamani');
      await tester.tap(find.text('Fecha de Nacimiento'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await siguiente(tester);
    }

    /// Llena los datos del paso 2 menos la ubicación.
    Future<void> datosDelPaso2(WidgetTester tester) async {
      await escribir(tester, 'Tu Teléfono', '987654321');
      await escribir(tester, 'Correo Electrónico', 'rosa@correo.pe');
      await escribir(tester, 'Ingreso Neto Aproximado', '2500');
      await escribir(tester, 'Dirección exacta', 'Calle Mercaderes 123');
      await escribir(tester, 'Link Google Maps', 'https://maps.app.goo.gl/abc123');
    }

    /// Llena los pasos 1 y 2 y deja la pantalla en el paso 3 (documentos).
    Future<void> hastaElPaso3(WidgetTester tester, {String departamento = 'AREQUIPA'}) async {
      await hastaElPaso2(tester);
      await datosDelPaso2(tester);
      await elegirUbicacion(tester, departamento: departamento);
      await siguiente(tester);
    }

    Future<void> llenarPaso3(WidgetTester tester) async {
      await escribir(tester, 'Nombre completo', 'Ana Quispe');
      await escribir(tester, 'Teléfono', '987000111');
      await escribir(tester, 'Parentesco', 'Hermana');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
    }

    testWidgets('con la inscripción gratis, el registro sigue siendo de 3 pasos y se envía sin pago', (tester) async {
      final repo = _RepoMonto(_info({'tipo': 'pasajero', 'monto': 0}));
      await abrir(tester, repo);
      await hastaElPaso3(tester);
      await llenarPaso3(tester);

      expect(find.text('ENVIAR SOLICITUD'), findsOneWidget);   // el 3.º es el último
      await siguiente(tester, 'ENVIAR SOLICITUD');

      expect(auth.envios, hasLength(1));
      expect(auth.envios.single.containsKey('metodo_pago_inscripcion'), isFalse);
      expect(auth.archivos.single.containsKey('captura_pago'), isFalse);
      expect(find.text('Pago de inscripción'), findsNothing);
      // Pregunta por el costo de un PASAJERO en su ciudad.
      expect(repo.consultas.first['tipo'], 'pasajero');
      expect(repo.consultas.first['departamento'], 'AREQUIPA');
      expect(find.text('¡Excelente!'), findsOneWidget);
    });

    testWidgets('un servidor que todavía no conoce el cobro de pasajeros no hace aparecer ningún pago', (tester) async {
      await abrir(tester, _RepoMonto(_info({'monto': 100}))); // sin «tipo»: respondió el monto de un conductor
      await hastaElPaso3(tester);
      await llenarPaso3(tester);
      await siguiente(tester, 'ENVIAR SOLICITUD');

      expect(auth.envios, hasLength(1));
      expect(auth.envios.single.containsKey('metodo_pago_inscripcion'), isFalse);
    });

    testWidgets('con precio aparece el paso de pago y no deja enviar sin elegir cómo pagar', (tester) async {
      await abrir(tester, _RepoMonto(_info({'tipo': 'pasajero', 'monto': 20})));
      await hastaElPaso3(tester);
      await llenarPaso3(tester);

      expect(find.text('ENVIAR SOLICITUD'), findsNothing);   // ya no es el último: falta el pago
      await siguiente(tester);

      expect(find.text('Pago de inscripción'), findsOneWidget);
      expect(find.text('Monto de tu inscripción'), findsOneWidget);
      expect(find.text('S/ 20.00'), findsOneWidget);

      await siguiente(tester, 'ENVIAR SOLICITUD');
      expect(find.text('Elige cómo vas a pagar tu inscripción'), findsOneWidget);
      expect(auth.envios, isEmpty);
    });

    testWidgets('con Caja Arequipa envía el método y muestra el código de pago de la respuesta', (tester) async {
      await abrir(tester, _RepoMonto(_info({'tipo': 'pasajero', 'monto': 20})));
      await hastaElPaso3(tester);
      await llenarPaso3(tester);
      await siguiente(tester);

      await tester.tap(find.byKey(const Key('pago_metodo_caja')));
      await tester.pumpAndSettle();
      auth.respuesta = {
        'success': true,
        'message': 'Pre-registro recibido. Un asesor revisará tu solicitud pronto.',
        'data': {
          'inscripcion': {
            'metodo': 'caja_arequipa',
            'monto': 20,
            'orden_pago': {'codigo': '48213', 'fecha_expiracion': '2026-10-17T10:00:00-05:00'},
            'captura_izipay': null,
          },
        },
      };
      await siguiente(tester, 'ENVIAR SOLICITUD');

      expect(auth.envios.single['metodo_pago_inscripcion'], 'caja_arequipa');
      expect(auth.archivos.single.containsKey('captura_pago'), isFalse);
      expect(find.byKey(const Key('exito_codigo_caja')), findsOneWidget);
      expect(find.text('48213'), findsOneWidget);
      expect(find.textContaining('Vale 24 horas'), findsOneWidget);
    });

    testWidgets('con IziPay exige la captura del pago antes de enviar', (tester) async {
      await abrir(tester, _RepoMonto(_info({
        'tipo': 'pasajero',
        'monto': 20,
        'izipay': {'disponible': true, 'qr_url': 'https://credigo.test/qr.png'},
      })));
      await hastaElPaso3(tester);
      await llenarPaso3(tester);
      await siguiente(tester);

      await tester.tap(find.byKey(const Key('pago_metodo_izipay')));
      await tester.pumpAndSettle();
      await siguiente(tester, 'ENVIAR SOLICITUD');

      expect(find.text('Adjunta la captura de tu pago por IziPay'), findsOneWidget);
      expect(auth.envios, isEmpty);
    });

    testWidgets('si la consulta del costo falla (sin señal, servidor que aún no la conoce) el registro sigue como siempre: no se bloquea', (tester) async {
      await abrir(tester, _RepoMonto(_info({'monto': 0}), fallasIniciales: 99));
      await hastaElPaso3(tester);
      await llenarPaso3(tester);

      expect(find.text('ENVIAR SOLICITUD'), findsOneWidget);   // sigue siendo de 3 pasos
      await siguiente(tester, 'ENVIAR SOLICITUD');

      expect(auth.envios, hasLength(1));
      expect(auth.envios.single.containsKey('metodo_pago_inscripcion'), isFalse);
      expect(find.textContaining('No pudimos comprobar'), findsNothing);
      expect(find.text('¡Excelente!'), findsOneWidget);
    });

    testWidgets('si la consulta falló pero el servidor responde que la inscripción tiene un costo, lo lleva al paso de pago', (tester) async {
      // La consulta previa falla; cuando el servidor rechaza el envío, la segunda consulta ya responde con el precio.
      final repo = _RepoMonto(_info({'tipo': 'pasajero', 'monto': 20}), fallasIniciales: 1);
      await abrir(tester, repo);
      await hastaElPaso3(tester);
      await llenarPaso3(tester);

      auth
        ..respuesta = null
        ..mensajeDeError = 'La inscripción ahora tiene un costo. Actualiza la aplicación para elegir cómo pagarla y completar tu registro.';
      await siguiente(tester, 'ENVIAR SOLICITUD');

      expect(auth.envios, hasLength(1));                              // se intentó enviar como gratis…
      expect(find.text('Pago de inscripción'), findsOneWidget);       // …y el servidor la mandó al pago
      expect(find.text('S/ 20.00'), findsOneWidget);
      expect(repo.consultas, hasLength(2));
    });

    testWidgets('otro rechazo del servidor (p. ej. documento repetido) se muestra tal cual y no cambia de paso', (tester) async {
      await abrir(tester, _RepoMonto(_info({'tipo': 'pasajero', 'monto': 0})));
      await hastaElPaso3(tester);
      await llenarPaso3(tester);

      auth
        ..respuesta = null
        ..mensajeDeError = 'Este documento ya está registrado';
      await siguiente(tester, 'ENVIAR SOLICITUD');

      expect(find.text('Este documento ya está registrado'), findsOneWidget);
      expect(find.text('Pago de inscripción'), findsNothing);
    });
  });

  // Antes el departamento y la provincia quedaban fijos en «AREQUIPA» para todos y solo se escribía el distrito: un pasajero de
  // Lima se registraba como de Arequipa y, con precios por ciudad, habría pagado como tal.
  group('ubicación del pasajero', () {
    late _AuthFalso auth;

    Future<void> abrir(WidgetTester tester, _RepoMonto repo) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      auth = _AuthFalso();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<CatalogosProvider>.value(value: CatalogosProvider(catalogosRepository: repo)),
          ],
          child: const MaterialApp(home: PreRegisterPage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> escribir(WidgetTester tester, String etiqueta, String texto) async {
      await tester.enterText(find.widgetWithText(TextFormField, etiqueta), texto);
    }

    Future<void> siguiente(WidgetTester tester, [String boton = 'SIGUIENTE']) async {
      await tester.tap(find.text(boton));
      await tester.pumpAndSettle();
    }

    Future<void> elegir(WidgetTester tester, String etiqueta, String opcion) async {
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, etiqueta));
      await tester.pumpAndSettle();
      await tester.tap(find.text(opcion).last);
      await tester.pumpAndSettle();
    }

    Future<void> alPaso2(WidgetTester tester) async {
      await escribir(tester, 'Nombres Completos', 'Rosa');
      await escribir(tester, 'Apellido Paterno', 'Quispe');
      await escribir(tester, 'Apellido Materno', 'Mamani');
      await tester.tap(find.text('Fecha de Nacimiento'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await siguiente(tester);
      await escribir(tester, 'Tu Teléfono', '987654321');
      await escribir(tester, 'Correo Electrónico', 'rosa@correo.pe');
      await escribir(tester, 'Ingreso Neto Aproximado', '2500');
      await escribir(tester, 'Dirección exacta', 'Calle Mercaderes 123');
      await escribir(tester, 'Link Google Maps', 'https://maps.app.goo.gl/abc123');
    }

    testWidgets('el paso 2 pide elegir departamento, provincia y distrito (ya no queda fijo en Arequipa)', (tester) async {
      await abrir(tester, _RepoMonto(_info({'tipo': 'pasajero', 'monto': 0})));
      await alPaso2(tester);

      expect(find.widgetWithText(DropdownButtonFormField<String>, 'Departamento'), findsOneWidget);
      expect(find.text('Selecciona primero el departamento'), findsOneWidget);   // la provincia espera al departamento
      expect(find.text('Selecciona primero la provincia'), findsOneWidget);       // el distrito, a la provincia

      await siguiente(tester);
      expect(find.text('Selecciona tu departamento'), findsOneWidget);            // no avanza sin elegir
      expect(find.text('Adjuntar Documentación'), findsNothing);

      // Los avisos se ponen en cola: se limpia el anterior para ver el siguiente.
      void limpiarAvisos() => ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();

      limpiarAvisos();
      await elegir(tester, 'Departamento', 'LIMA');
      await siguiente(tester);
      expect(find.text('Selecciona tu provincia'), findsOneWidget);

      limpiarAvisos();
      await elegir(tester, 'Provincia', 'LIMA');
      await siguiente(tester);
      expect(find.text('Selecciona tu distrito'), findsOneWidget);

      limpiarAvisos();   // el aviso flotante tapa el botón
      await elegir(tester, 'Distrito', 'MIRAFLORES');
      await siguiente(tester);
      expect(find.text('Adjuntar Documentación'), findsOneWidget);
    });

    testWidgets('el departamento que elige es el que se manda y con el que se consulta el costo (un pasajero de Lima ya no sale de Arequipa)', (tester) async {
      final repo = _RepoMonto(_info({'tipo': 'pasajero', 'monto': 0}));
      await abrir(tester, repo);
      await alPaso2(tester);
      await elegir(tester, 'Departamento', 'LIMA');
      await elegir(tester, 'Provincia', 'LIMA');
      await elegir(tester, 'Distrito', 'MIRAFLORES');
      await siguiente(tester);

      await escribir(tester, 'Nombre completo', 'Ana Quispe');
      await escribir(tester, 'Teléfono', '987000111');
      await escribir(tester, 'Parentesco', 'Hermana');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await siguiente(tester, 'ENVIAR SOLICITUD');

      expect(repo.consultas.first['departamento'], 'LIMA');
      expect(auth.envios.single['departamento'], 'LIMA');
      expect(auth.envios.single['provincia'], 'LIMA');
      expect(auth.envios.single['distrito'], 'MIRAFLORES');
    });

    testWidgets('si vuelve al paso 2 y cambia de departamento, el costo se consulta de nuevo con el departamento nuevo', (tester) async {
      // Arequipa gratis; en Lima, S/ 20.
      final repo = _RepoMonto(_info({'tipo': 'pasajero', 'monto': 0}));
      await abrir(tester, repo);
      await alPaso2(tester);
      await elegir(tester, 'Departamento', 'AREQUIPA');
      await elegir(tester, 'Provincia', 'AREQUIPA');
      await elegir(tester, 'Distrito', 'CERCADO');
      await siguiente(tester);                      // paso 3: consulta por AREQUIPA
      expect(repo.consultas.map((c) => c['departamento']).toList(), ['AREQUIPA']);

      await tester.tap(find.text('ATRÁS'));
      await tester.pumpAndSettle();
      await elegir(tester, 'Departamento', 'LIMA');
      await elegir(tester, 'Provincia', 'LIMA');
      await elegir(tester, 'Distrito', 'MIRAFLORES');
      await siguiente(tester);                      // de nuevo al paso 3: consulta por LIMA

      expect(repo.consultas.map((c) => c['departamento']).toList(), ['AREQUIPA', 'LIMA']);
    });
  });
}
