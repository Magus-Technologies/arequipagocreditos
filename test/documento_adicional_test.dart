import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/core/utils/adenda_pendiente_gate.dart';
import 'package:arequipagocreditos/core/utils/either.dart';
import 'package:arequipagocreditos/data/models/documento_firmado_model.dart';
import 'package:arequipagocreditos/domain/entities/documento_firmado_entity.dart';
import 'package:arequipagocreditos/domain/repositories/beneficios_comercial_repository.dart';
import 'package:arequipagocreditos/domain/usecases/create_financiamiento_usecase.dart';
import 'package:arequipagocreditos/domain/usecases/get_beneficios_servicios_usecase.dart';
import 'package:arequipagocreditos/domain/usecases/get_documentos_firmados_usecase.dart';
import 'package:arequipagocreditos/domain/usecases/signature_usecases.dart';
import 'package:arequipagocreditos/presentation/pages/documentos_firmados_page.dart';
import 'package:arequipagocreditos/presentation/pages/signature/firma_documento_page.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/financiamiento_servicio_provider.dart';
import 'package:arequipagocreditos/presentation/providers/signature_provider.dart';
import 'package:arequipagocreditos/core/errors/failures.dart';

/// TK-0353: la empresa anexa un PDF a un financiamiento y el conductor lo firma desde «Mis documentos» (o desde la ventana
/// que sale al abrir el app). Es una firma aparte de la del contrato: se manda con su propio tipo (`documento-adicional`) y su
/// propio id (`documento_id`), nunca con los del financiamiento.
Map<String, dynamic> _adicional({
  int id = 12,
  bool firmado = false,
  String nombre = 'Autorización de descuento',
  String? descripcion = 'Se firma una sola vez',
  String? url = 'https://credigo.test/documento-adicional/abc',
}) =>
    {
      'id': firmado ? 77 : null,
      'tipo': 'documento_adicional',
      'tipo_documento': 'documento_adicional',
      'tipo_firma': 'documento-adicional',
      'documento_id': id,
      'nombre_documento': nombre,
      'descripcion': descripcion,
      'financiamiento_id': 1324,
      'grupo_financiamiento': 'Credi Yango',
      'nombre_firmante': 'Juan Pérez',
      'documento_firmante': '45678912',
      'cargo': 'CONDUCTOR',
      'firmado': firmado,
      'firma_url': firmado ? 'https://credigo.test/storage/firma.png' : null,
      'contrato_url': url,
      'firmado_at': firmado ? '2026-10-09 18:42:10' : null,
      'origen': 'app',
    };

Map<String, dynamic> _adenda({bool firmado = false}) => {
      'id': null,
      'tipo': 'adenda',
      'tipo_documento': 'adenda_yango',
      'tipo_firma': 'adenda-yango',
      'adenda_id': 5,
      'nombre_documento': 'Adenda Flota AREQUIPA GO – YANGO',
      'financiamiento_id': 1324,
      'nombre_firmante': 'Juan Pérez',
      'documento_firmante': '45678912',
      'cargo': 'CONDUCTOR',
      'firmado': firmado,
      'contrato_url': 'https://credigo.test/financiamiento/1324/adenda/pdf',
      'origen': 'app',
    };

Map<String, dynamic> _contratoPendiente() => {
      'id': null,
      'tipo': 'financiamiento',
      'tipo_documento': 'contrato',
      'nombre_documento': 'Contrato de Financiamiento',
      'financiamiento_id': 1324,
      'nombre_firmante': 'Juan Pérez',
      'documento_firmante': '45678912',
      'cargo': 'CONDUCTOR',
      'firmado': false,
      'contrato_url': 'https://credigo.test/financiamiento/1324/contrato/pdf',
      'origen': 'app',
    };

Map<String, dynamic> _listado({
  List<Map<String, dynamic>> documentos = const [],
  List<Map<String, dynamic>>? adendas,
  List<Map<String, dynamic>>? adicionales,
  Map<String, dynamic> resumen = const {},
}) =>
    {
      'resumen': {
        'conductor': {'id': 1, 'nombre': 'Juan Pérez', 'nro_documento': '45678912'},
        'total_documentos': documentos.length,
        'afiliaciones': 0,
        'contratos': 0,
        ...resumen,
      },
      'documentos': documentos,
      if (adendas != null) 'adendas': adendas,
      if (adicionales != null) 'documentos_adicionales': adicionales,
    };

class _SinUsar extends Fake implements GetBeneficiosServiciosUseCase {}

class _SinUsar2 extends Fake implements CreateFinanciamientoUseCase {}

class _SinUsar3 extends Fake implements BeneficiosComercialRepository {}

class _SinUsar4 extends Fake implements FirmarUseCase {}

class _Documentos extends Fake implements GetDocumentosFirmadosUseCase {
  _Documentos(this.listado);
  final ListadoDocumentosEntity listado;

  @override
  Future<Either<Failure, ListadoDocumentosEntity>> call(int conductorId) async => Either.right(listado);
}

class _Auth extends Fake implements AuthProvider {
  @override
  get currentUser => null;
}

void main() {
  // AuthProvider es un ChangeNotifier y aquí se da con `Provider.value` (la pantalla solo lo lee): provider lo advierte.
  setUpAll(() => Provider.debugCheckInvalidValueType = null);

  group('lista «Mis documentos» del servidor', () {
    test('los documentos adicionales vienen en su propia lista y se leen con su tipo de firma e id', () {
      final listado = ListadoDocumentosModel.fromJson(_listado(
        adicionales: [_adicional()],
      ));

      expect(listado.documentos, hasLength(1));
      final doc = listado.documentos.single;
      expect(doc.tipo, 'documento_adicional');
      expect(doc.tipoFirma, 'documento-adicional');
      // El servidor lo manda como `documento_id`; el app lo usa igual que el `adenda_id`.
      expect(doc.adendaId, 12);
      expect(doc.descripcion, 'Se firma una sola vez');
      expect(doc.nombreDocumento, 'Autorización de descuento');
      expect(doc.firmado, isFalse);
      expect(doc.esFirmaSeparada, isTrue);
      expect(doc.esDocumentoAdicional, isTrue);
    });

    test('se mezclan con contratos y adendas, los pendientes primero', () {
      final listado = ListadoDocumentosModel.fromJson(_listado(
        documentos: [_contratoPendiente()],
        adendas: [_adenda(firmado: true)],
        adicionales: [_adicional(firmado: true, nombre: 'Firmado'), _adicional(id: 13, nombre: 'Pendiente')],
      ));

      expect(listado.documentos, hasLength(4));
      expect(listado.documentos.take(2).every((d) => !d.firmado), isTrue);
      expect(listado.documentos.skip(2).every((d) => d.firmado), isTrue);
    });

    test('el resumen los cuenta y el total los suma (el del servidor no los incluye)', () {
      final listado = ListadoDocumentosModel.fromJson(_listado(
        adicionales: [_adicional(), _adicional(id: 13, firmado: true)],
        resumen: {'documentos_adicionales': 1, 'documentos_adicionales_pendientes': 1},
      ));

      expect(listado.resumen.documentosAdicionales, 1);
      expect(listado.resumen.documentosAdicionalesPendientes, 1);
      expect(listado.resumen.totalDocumentos, 2);
    });

    test('un servidor anterior, sin la lista nueva, sigue funcionando', () {
      final listado = ListadoDocumentosModel.fromJson(_listado(
        documentos: [_contratoPendiente()],
        adendas: [_adenda()],
      ));

      expect(listado.documentos, hasLength(2));
      expect(listado.resumen.documentosAdicionales, 0);
      expect(listado.resumen.documentosAdicionalesPendientes, 0);
      // Las adendas conservan su id: `adenda_id` sigue mandando.
      expect(listado.documentos.firstWhere((d) => d.tipo == 'adenda').adendaId, 5);
    });
  });

  group('ventana flotante al abrir el app', () {
    List<DocumentoFirmadoEntity> lista(List<Map<String, dynamic>> adicionales, {List<Map<String, dynamic>>? adendas}) =>
        ListadoDocumentosModel.fromJson(_listado(adicionales: adicionales, adendas: adendas)).documentos;

    test('incluye el documento adicional pendiente, no el ya firmado', () {
      final pendientes = AdendaPendienteGate.findPendientes(
        lista([_adicional(), _adicional(id: 13, firmado: true)]),
      );

      expect(pendientes, hasLength(1));
      expect(pendientes.single.adendaId, 12);
    });

    test('sin PDF que mostrar no se ofrece firmar', () {
      expect(AdendaPendienteGate.findPendientes(lista([_adicional(url: null)])), isEmpty);
      expect(AdendaPendienteGate.findPendientes(lista([_adicional(url: '')])), isEmpty);
    });

    test('sigue incluyendo las adendas pendientes y no toca los contratos (su ventana es otra)', () {
      final todos = ListadoDocumentosModel.fromJson(_listado(
        documentos: [_contratoPendiente()],
        adendas: [_adenda()],
        adicionales: [_adicional()],
      )).documentos;

      final pendientes = AdendaPendienteGate.findPendientes(todos);
      expect(pendientes.map((d) => d.tipo).toSet(), {'adenda', 'documento_adicional'});
    });

    test('los textos distinguen documento, adenda y mezcla', () {
      final docs = lista([_adicional()]);
      expect(AdendaPendienteGate.titulo(docs), 'Documento pendiente');
      expect(AdendaPendienteGate.mensaje(docs), contains('un documento pendiente por firmar'));
      expect(AdendaPendienteGate.mensaje(docs), contains('Autorización de descuento'));
      expect(AdendaPendienteGate.indicacion(docs), startsWith('Revísalo y fírmalo'));

      final adendas = lista([], adendas: [_adenda()]);
      expect(AdendaPendienteGate.titulo(adendas), 'Adenda pendiente');
      expect(AdendaPendienteGate.mensaje(adendas), contains('una adenda pendiente por firmar'));
      expect(AdendaPendienteGate.indicacion(adendas), startsWith('Revísala y fírmala'));

      final mezcla = lista([_adicional()], adendas: [_adenda()]);
      expect(AdendaPendienteGate.titulo(mezcla), 'Documentos pendientes');
      expect(AdendaPendienteGate.mensaje(mezcla), 'Tienes 2 documentos y adendas pendientes por firmar.');

      final varios = lista([_adicional(), _adicional(id: 13)]);
      expect(AdendaPendienteGate.mensaje(varios), 'Tienes 2 documentos pendientes por firmar.');
    });
  });

  group('pantalla «Mis documentos»', () {
    Future<FinanciamientoServicioProvider> abrir(WidgetTester tester, Map<String, dynamic> json) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final provider = FinanciamientoServicioProvider(
        getBeneficiosServiciosUseCase: _SinUsar(),
        createFinanciamientoUseCase: _SinUsar2(),
        getDocumentosFirmadosUseCase: _Documentos(ListadoDocumentosModel.fromJson(json)),
        beneficiosRepository: _SinUsar3(),
      );
      await provider.loadDocumentosFirmados(1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FinanciamientoServicioProvider>.value(value: provider),
            Provider<AuthProvider>.value(value: _Auth()),
            ChangeNotifierProvider<SignatureProvider>(create: (_) => SignatureProvider(firmarUseCase: _SinUsar4())),
          ],
          child: const MaterialApp(home: DocumentosFirmadosPage()),
        ),
      );
      await tester.pump();
      return provider;
    }

    testWidgets('el documento adicional pendiente se ve con su nombre y «Pendiente de firma»', (tester) async {
      await abrir(tester, _listado(adicionales: [_adicional()]));

      expect(find.text('Autorización de descuento'), findsOneWidget);
      expect(find.text('Pendiente de firma'), findsOneWidget);
    });

    testWidgets('al expandirlo muestra el grupo y lo que escribió la empresa, y ofrece firmar', (tester) async {
      await abrir(tester, _listado(adicionales: [_adicional()]));

      await tester.tap(find.text('Autorización de descuento'));
      await tester.pumpAndSettle();

      expect(find.text('Credi Yango'), findsOneWidget);
      expect(find.text('Se firma una sola vez'), findsOneWidget);
      expect(find.text('Firmar'), findsOneWidget);
    });

    testWidgets('«Firmar» abre la firma con el tipo y el id DEL DOCUMENTO, no los del contrato', (tester) async {
      await abrir(tester, _listado(adicionales: [_adicional(id: 12)]));

      await tester.tap(find.text('Autorización de descuento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Firmar'));
      // La pantalla de firma baja el PDF (en los tests toda petición devuelve 400): no se espera a que termine de animarse.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));

      final firma = tester.widget<FirmaDocumentoPage>(find.byType(FirmaDocumentoPage, skipOffstage: false));
      expect(firma.tipo, 'documento-adicional');
      // Un documento adicional se firma colocando la firma sobre el PDF; el contrato y las adendas, como siempre.
      expect(firma.colocarEnPdf, isTrue);
      // El financiamiento es el 1324: firmar con ese id firmaría el contrato por error.
      expect(firma.id, 12);
      expect(firma.title, 'Autorización de descuento');
      expect(firma.pdfUrl, 'https://credigo.test/documento-adicional/abc');
    });

    testWidgets('uno ya firmado ofrece ver la firma, no volver a firmar', (tester) async {
      await abrir(tester, _listado(adicionales: [_adicional(firmado: true)]));

      expect(find.textContaining('Firmado el:'), findsOneWidget);
      await tester.tap(find.text('Autorización de descuento'));
      await tester.pumpAndSettle();

      expect(find.text('Ver Firma'), findsOneWidget);
      expect(find.text('Firmar'), findsNothing);
    });
  });
}
