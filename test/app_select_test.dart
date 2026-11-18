import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arequipagocreditos/presentation/components/app_select.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';

/// Selector único del app: campo cerrado + hoja inferior con las opciones (y buscador cuando son muchas). Reemplaza a los tres
/// desplegables de Material cuya lista salía pegada al borde, con esquinas rectas y resaltado lila.

const _tres = [SelectOption('a', 'Alfa'), SelectOption('b', 'Beta'), SelectOption('c', 'Gamma')];

/// Nueve regiones (más de 7: lleva buscador) con tildes y una ñ para probar la búsqueda.
const _regiones = [
  SelectOption('ancash', 'Áncash'),
  SelectOption('apurimac', 'Apurímac'),
  SelectOption('arequipa', 'Arequipa'),
  SelectOption('canete', 'Cañete'),
  SelectOption('ica', 'Ica'),
  SelectOption('junin', 'Junín'),
  SelectOption('lima', 'Lima'),
  SelectOption('piura', 'Piura'),
  SelectOption('puno', 'Puno'),
];

List<SelectOption> _muchas(int n) => List.generate(n, (i) => SelectOption('v$i', 'Opción $i'));

/// Guarda el valor elegido como lo haría una página: al elegir, el campo pasa a mostrarlo.
class _Arnes extends StatefulWidget {
  const _Arnes({required this.options, this.valorInicial, this.etiqueta = 'Departamento', this.fieldKey});

  final List<SelectOption> options;
  final String? valorInicial;
  final String etiqueta;
  final Key? fieldKey;

  @override
  State<_Arnes> createState() => _ArnesState();
}

class _ArnesState extends State<_Arnes> {
  late String? valor = widget.valorInicial;
  final List<String> cambios = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AppSelect(
            fieldKey: widget.fieldKey,
            label: widget.etiqueta,
            icon: Icons.public_outlined,
            value: valor,
            options: widget.options,
            onChanged: (v) => setState(() {
              cambios.add(v);
              valor = v;
            }),
          ),
        ),
      ),
    );
  }
}

Future<_ArnesState> _montar(
  WidgetTester tester, {
  List<SelectOption> options = _tres,
  String? valor,
  String etiqueta = 'Departamento',
  Key? fieldKey,
  Size pantalla = const Size(800, 1000),
}) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_Arnes(options: options, valorInicial: valor, etiqueta: etiqueta, fieldKey: fieldKey));
  return tester.state<_ArnesState>(find.byType(_Arnes));
}

/// Monta un [AppSelect] suelto (para los estados que no pasan por el arnés).
Future<void> _montarSuelto(WidgetTester tester, AppSelect select) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: select))));
}

Finder get _hoja => find.byKey(const Key('select_hoja'));
Finder get _buscador => find.byKey(const Key('select_buscador'));
Finder _fila(String value) => find.byKey(Key('select_opcion_$value'));

Future<void> _abrir(WidgetTester tester, [String etiqueta = 'Departamento']) async {
  await tester.tap(find.widgetWithText(AppSelect, etiqueta));
  await tester.pumpAndSettle();
}

Future<void> _escribirBusqueda(WidgetTester tester, String texto) async {
  await tester.enterText(_buscador, texto);
  await tester.pumpAndSettle();
}

void main() {
  group('abrir y elegir', () {
    testWidgets('al abrir la hoja se suelta el foco de un campo de texto vecino y no vuelve al cerrarla (no reabre el teclado)', (tester) async {
      final foco = FocusNode();
      addTearDown(foco.dispose);
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: foco),
                AppSelect(label: 'Departamento', icon: Icons.public_outlined, value: null, options: _tres, onChanged: (_) {}),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(foco.hasFocus, isTrue, reason: 'el campo de texto empieza con el foco (teclado abierto)');

      await _abrir(tester);
      expect(foco.hasFocus, isFalse, reason: 'al abrir la hoja el campo de texto suelta el foco');

      await tester.tap(_fila('b'));
      await tester.pumpAndSettle();
      expect(_hoja, findsNothing);
      expect(foco.hasFocus, isFalse, reason: 'al cerrar la hoja el foco no vuelve al campo de texto');
    });

    testWidgets('tocar la opción que ya estaba elegida cierra la hoja y NO avisa un cambio', (tester) async {
      final estado = await _montar(tester, valor: 'b');

      await _abrir(tester);
      await tester.tap(_fila('b'));
      await tester.pumpAndSettle();

      expect(_hoja, findsNothing);
      expect(estado.cambios, isEmpty);
      expect(estado.valor, 'b');

      // Elegir otra distinta sí avisa, y después volver a tocarla ya no.
      await _abrir(tester);
      await tester.tap(_fila('c'));
      await tester.pumpAndSettle();
      await _abrir(tester);
      await tester.tap(_fila('c'));
      await tester.pumpAndSettle();

      expect(estado.cambios, ['c']);
    });

    testWidgets('tocar el campo abre la hoja con el título y todas las opciones; elegir una cierra y avisa', (tester) async {
      final estado = await _montar(tester);
      expect(_hoja, findsNothing);

      await _abrir(tester);

      expect(_hoja, findsOneWidget);
      // El título de la hoja es la etiqueta del campo (queda también la del campo de atrás).
      expect(find.descendant(of: _hoja, matching: find.text('Departamento')), findsOneWidget);
      for (final o in _tres) {
        expect(_fila(o.value), findsOneWidget);
      }

      await tester.tap(_fila('b'));
      await tester.pumpAndSettle();

      expect(_hoja, findsNothing, reason: 'elegir cierra la hoja');
      expect(estado.cambios, ['b']);
      expect(find.descendant(of: find.byType(AppSelect), matching: find.text('Beta')), findsOneWidget, reason: 'el campo muestra lo elegido');
    });

    testWidgets('cerrar la hoja sin elegir no llama onChanged ni cambia el valor', (tester) async {
      final estado = await _montar(tester, valor: 'a');
      await _abrir(tester);
      expect(_hoja, findsOneWidget);

      // Se toca la zona oscura de arriba, fuera de la hoja.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(_hoja, findsNothing);
      expect(estado.cambios, isEmpty);
      expect(estado.valor, 'a');
      expect(find.descendant(of: find.byType(AppSelect), matching: find.text('Alfa')), findsOneWidget);
    });

    testWidgets('el campo abre también al tocar su fieldKey', (tester) async {
      await _montar(tester, fieldKey: const Key('mi_campo'));

      await tester.tap(find.byKey(const Key('mi_campo')));
      await tester.pumpAndSettle();

      expect(_hoja, findsOneWidget);
    });

    testWidgets('un valor que no está entre las opciones se muestra vacío', (tester) async {
      await _montar(tester, valor: 'no_existe');

      final decorador = tester.widget<InputDecorator>(find.descendant(of: find.byType(AppSelect), matching: find.byType(InputDecorator)));
      expect(decorador.isEmpty, isTrue, reason: 'sin valor válido la etiqueta queda como hint, no flotando');
      for (final o in _tres) {
        expect(find.descendant(of: find.byType(AppSelect), matching: find.text(o.label)), findsNothing);
      }

      // Y al abrir ninguna fila aparece como elegida.
      await _abrir(tester);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('con un valor válido la etiqueta flota y el campo muestra el texto de la opción', (tester) async {
      await _montar(tester, valor: 'c');

      final decorador = tester.widget<InputDecorator>(find.descendant(of: find.byType(AppSelect), matching: find.byType(InputDecorator)));
      expect(decorador.isEmpty, isFalse);
      expect(find.descendant(of: find.byType(AppSelect), matching: find.text('Gamma')), findsOneWidget);
      expect(find.descendant(of: find.byType(AppSelect), matching: find.text('Departamento')), findsOneWidget);
    });

    testWidgets('sin opciones el campo no abre la hoja', (tester) async {
      await _montar(tester, options: const []);

      await tester.tap(find.byType(AppSelect));
      await tester.pumpAndSettle();

      expect(_hoja, findsNothing);
    });
  });

  group('aspecto de la hoja', () {
    testWidgets('la opción elegida va en negrita, con check oscuro y fondo suave del color de marca', (tester) async {
      await _montar(tester, valor: 'b');
      await _abrir(tester);

      expect(find.descendant(of: _fila('b'), matching: find.byIcon(Icons.check_rounded)), findsOneWidget);
      expect(find.descendant(of: _fila('a'), matching: find.byIcon(Icons.check_rounded)), findsNothing);

      final check = tester.widget<Icon>(find.descendant(of: _fila('b'), matching: find.byIcon(Icons.check_rounded)));
      expect(check.color, isNot(AppTheme.primary), reason: 'el amarillo de marca no se lee sobre blanco');
      expect(check.color!.computeLuminance(), lessThan(0.2));

      final elegida = tester.widget<Text>(find.descendant(of: _fila('b'), matching: find.text('Beta')));
      final otra = tester.widget<Text>(find.descendant(of: _fila('a'), matching: find.text('Alfa')));
      expect(elegida.style!.fontWeight, FontWeight.w700);
      expect(otra.style!.fontWeight, isNot(FontWeight.w700));

      Color? fondo(String value) =>
          tester.widget<Material>(find.ancestor(of: _fila(value), matching: find.byType(Material)).first).color;
      expect(fondo('b'), AppTheme.primary.withValues(alpha: 0.12));
      expect(fondo('a'), Colors.transparent);
    });

    testWidgets('hoja blanca con esquinas superiores de radio 24, manija arriba y filas de al menos 48 px', (tester) async {
      await _montar(tester);
      await _abrir(tester);

      final hoja = tester.widget<Material>(find.ancestor(of: _hoja, matching: find.byType(Material)).first);
      expect(hoja.color, Colors.white);
      expect(hoja.surfaceTintColor == null || hoja.surfaceTintColor == Colors.transparent, isTrue, reason: 'sin el tinte lila de Material 3');
      expect(hoja.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))));

      for (final o in _tres) {
        expect(tester.getSize(_fila(o.value)).height, greaterThanOrEqualTo(48));
      }
      expect(tester.getSize(_fila('a')).height, closeTo(AppSelect.alturaFila, 1));
    });

    testWidgets('la hoja mide como mucho el 70 % de la pantalla y queda pegada abajo', (tester) async {
      await _montar(tester, options: _muchas(40));
      await _abrir(tester);
      expect(tester.getSize(_hoja).height, closeTo(1000 * AppSelect.alturaMaximaHoja, 1));
      expect(tester.getRect(_hoja).bottom, closeTo(1000, 1), reason: 'pegada abajo, no al medio');
    });

    testWidgets('con pocas opciones la hoja es más baja que el tope', (tester) async {
      await _montar(tester);
      await _abrir(tester);
      expect(tester.getSize(_hoja).height, lessThan(1000 * AppSelect.alturaMaximaHoja));
    });

    testWidgets('la hoja abre con la opción elegida a la vista aunque esté al final de una lista larga', (tester) async {
      await _montar(tester, options: _muchas(40), valor: 'v39');
      await _abrir(tester);

      final fila = _fila('v39');
      expect(fila, findsOneWidget);
      expect(tester.getRect(fila).bottom, lessThanOrEqualTo(tester.getRect(_hoja).bottom + 0.5));
      expect(tester.getRect(fila).top, greaterThanOrEqualTo(tester.getRect(_hoja).top));
    });
  });

  group('buscador', () {
    testWidgets('con 7 opciones no hay buscador', (tester) async {
      await _montar(tester, options: _muchas(AppSelect.maxOpcionesSinBuscador));
      await _abrir(tester);

      expect(_hoja, findsOneWidget);
      expect(_buscador, findsNothing);
    });

    testWidgets('con 8 opciones sí hay buscador', (tester) async {
      await _montar(tester, options: _muchas(AppSelect.maxOpcionesSinBuscador + 1));
      await _abrir(tester);

      expect(_buscador, findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('filtra ignorando mayúsculas y tildes (en ambos sentidos)', (tester) async {
      await _montar(tester, options: _regiones);
      await _abrir(tester);

      // Sin tilde y en minúsculas encuentra «Áncash».
      await _escribirBusqueda(tester, 'ancash');
      expect(_fila('ancash'), findsOneWidget);
      expect(_fila('lima'), findsNothing);

      // Con mayúsculas y sin tilde encuentra «Junín».
      await _escribirBusqueda(tester, 'JUNIN');
      expect(_fila('junin'), findsOneWidget);
      expect(_fila('ancash'), findsNothing);

      // Con tilde también (el usuario escribe «ú» y el texto original tiene «u»).
      await _escribirBusqueda(tester, 'Púno');
      expect(_fila('puno'), findsOneWidget);
      expect(_fila('piura'), findsNothing);

      // La ñ equivale a la n.
      await _escribirBusqueda(tester, 'canete');
      expect(_fila('canete'), findsOneWidget);
      await _escribirBusqueda(tester, 'CAÑETE');
      expect(_fila('canete'), findsOneWidget);

      // Texto ya descompuesto (u + tilde suelta), como llega de algunos teclados.
      await _escribirBusqueda(tester, 'Junín');
      expect(_fila('junin'), findsOneWidget);
    });

    testWidgets('busca por contenido, no solo por el principio, y deja varias coincidencias', (tester) async {
      await _montar(tester, options: _regiones);
      await _abrir(tester);

      await _escribirBusqueda(tester, 'ur');

      // «Apurímac» y «Piura» contienen «ur»; ninguna otra.
      expect(_fila('apurimac'), findsOneWidget);
      expect(_fila('piura'), findsOneWidget);
      expect(_fila('lima'), findsNothing);
      expect(_fila('ica'), findsNothing);
    });

    testWidgets('sin coincidencias dice «Sin resultados» y limpiar devuelve la lista completa', (tester) async {
      await _montar(tester, options: _regiones);
      await _abrir(tester);

      await _escribirBusqueda(tester, 'zzz');
      expect(find.text('Sin resultados'), findsOneWidget);
      expect(_fila('lima'), findsNothing);

      await tester.tap(find.byKey(const Key('select_buscador_limpiar')));
      await tester.pumpAndSettle();

      expect(find.text('Sin resultados'), findsNothing);
      expect(_fila('lima'), findsOneWidget);
      expect(_fila('ancash'), findsOneWidget);
      expect(find.byKey(const Key('select_buscador_limpiar')), findsNothing, reason: 'el botón solo aparece con texto escrito');
    });

    testWidgets('se puede elegir una opción ya filtrada', (tester) async {
      final estado = await _montar(tester, options: _regiones);
      await _abrir(tester);

      await _escribirBusqueda(tester, 'arequi');
      await tester.tap(_fila('arequipa'));
      await tester.pumpAndSettle();

      expect(estado.cambios, ['arequipa']);
      expect(_hoja, findsNothing);
    });

    testWidgets('con el teclado abierto la hoja queda por encima de él', (tester) async {
      // El teclado ocupa los 300 px de abajo; _montar deja la vista como estaba al terminar la prueba.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await _montar(tester, options: _regiones);
      await _abrir(tester);

      expect(_hoja, findsOneWidget);
      expect(tester.getRect(_hoja).bottom, lessThanOrEqualTo(1000 - 300 + 0.5));
      expect(tester.getRect(_hoja).top, greaterThanOrEqualTo(0));
      expect(_buscador, findsOneWidget);
    });
  });

  group('misma altura que los campos de texto', () {
    testWidgets('cerrado mide lo mismo que un TextFormField del formulario, con valor y sin valor', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      InputDecoration decoracion(String etiqueta) => InputDecoration(
            labelText: etiqueta,
            labelStyle: const TextStyle(color: Colors.black45),
            prefixIcon: const Icon(Icons.public_outlined, color: Colors.black87, size: 22),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('texto'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: decoracion('Dirección'),
                  ),
                  const SizedBox(height: 20),
                  AppSelect(key: const Key('vacio'), label: 'Departamento', icon: Icons.public_outlined, value: null, options: _tres, onChanged: (_) {}),
                  const SizedBox(height: 20),
                  AppSelect(key: const Key('lleno'), label: 'Provincia', icon: Icons.public_outlined, value: 'a', options: _tres, onChanged: (_) {}),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alturaTexto = tester.getSize(find.byKey(const Key('texto'))).height;
      expect(tester.getSize(find.byKey(const Key('vacio'))).height, alturaTexto);
      expect(tester.getSize(find.byKey(const Key('lleno'))).height, alturaTexto);
      expect(tester.getSize(find.byKey(const Key('vacio'))).width, tester.getSize(find.byKey(const Key('texto'))).width);
    });
  });

  group('estados', () {
    testWidgets('cargando: campo apagado con «Cargando...» y spinner, sin abrir hoja', (tester) async {
      await _montarSuelto(
        tester,
        AppSelect(label: 'Provincia', icon: Icons.location_city_outlined, value: null, options: _tres, loading: true, onChanged: (_) {}),
      );

      expect(find.text('Cargando...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Cargando...'));
      await tester.pump();
      expect(_hoja, findsNothing);
    });

    testWidgets('error: recuadro rojo con el nombre del campo; tocarlo llama onRetry', (tester) async {
      var reintentos = 0;
      await _montarSuelto(
        tester,
        AppSelect(
          label: 'Departamento',
          icon: Icons.public_outlined,
          value: null,
          options: const [],
          error: 'Sin conexión',
          onRetry: () => reintentos++,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Error al cargar Departamento. Toca para reintentar'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.text('Error al cargar Departamento. Toca para reintentar'));
      await tester.pumpAndSettle();

      expect(reintentos, 1);
      expect(_hoja, findsNothing);
    });

    testWidgets('mientras carga manda «Cargando...» aunque haya un error anterior', (tester) async {
      await _montarSuelto(
        tester,
        AppSelect(label: 'Distrito', icon: Icons.map_outlined, value: null, options: _tres, loading: true, error: 'x', onChanged: (_) {}),
      );

      // Igual que antes de la migración: mientras carga manda el «Cargando...».
      expect(find.text('Cargando...'), findsOneWidget);
      expect(find.textContaining('Error al cargar'), findsNothing);
    });

    testWidgets('placeholder: campo apagado en gris con el texto, sin abrir hoja ni aviso naranja', (tester) async {
      await _montarSuelto(
        tester,
        AppSelect(
          label: 'Provincia',
          icon: Icons.location_city_outlined,
          value: null,
          options: _tres,
          placeholder: 'Selecciona primero el departamento',
          avisoKey: const Key('ubicacion_sin_ciudades'),
          onChanged: (_) {},
        ),
      );

      expect(find.text('Selecciona primero el departamento'), findsOneWidget);
      expect(find.byKey(const Key('ubicacion_sin_ciudades')), findsNothing, reason: 'el aviso solo sale con placeholderEsAviso');
      expect(find.byIcon(Icons.info_outline), findsNothing);

      await tester.tap(find.text('Selecciona primero el departamento'));
      await tester.pumpAndSettle();
      expect(_hoja, findsNothing);
    });

    testWidgets('aviso: recuadro naranja con ícono de info y la key para las pruebas', (tester) async {
      await _montarSuelto(
        tester,
        AppSelect(
          label: 'Departamento',
          icon: Icons.public_outlined,
          value: null,
          options: const [],
          placeholder: 'Tu plataforma aún no está habilitada en ninguna ciudad.',
          placeholderEsAviso: true,
          avisoKey: const Key('ubicacion_sin_ciudades'),
          onChanged: (_) {},
        ),
      );

      expect(find.byKey(const Key('ubicacion_sin_ciudades')), findsOneWidget);
      expect(find.text('Tu plataforma aún no está habilitada en ninguna ciudad.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('aviso sin avisoKey no inventa ninguna key', (tester) async {
      await _montarSuelto(
        tester,
        AppSelect(
          label: 'Departamento',
          icon: Icons.public_outlined,
          value: null,
          options: const [],
          placeholder: 'Nada que elegir',
          placeholderEsAviso: true,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Nada que elegir'), findsOneWidget);
      expect(find.byKey(const Key('ubicacion_sin_ciudades')), findsNothing);
    });
  });

  group('accesibilidad', () {
    testWidgets('el campo se anuncia con su etiqueta y el valor actual (o «Sin seleccionar»)', (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, valor: 'b');

      var nodo = tester.getSemantics(find.byType(AppSelect));
      expect(nodo.label, 'Departamento');
      expect(nodo.value, 'Beta');
      expect(nodo.flagsCollection.isButton, isTrue);

      await _montarSuelto(tester, AppSelect(label: 'Departamento', icon: Icons.public_outlined, value: null, options: _tres, onChanged: (_) {}));
      nodo = tester.getSemantics(find.byType(AppSelect));
      expect(nodo.label, 'Departamento');
      expect(nodo.value, 'Sin seleccionar');

      semantica.dispose();
    });

    testWidgets('la fila elegida se marca como seleccionada para el lector de pantalla', (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, valor: 'b');
      await _abrir(tester);

      expect(tester.getSemantics(_fila('b')).flagsCollection.isSelected, Tristate.isTrue);
      expect(tester.getSemantics(_fila('a')).flagsCollection.isSelected, Tristate.isFalse);

      semantica.dispose();
    });
  });
}
