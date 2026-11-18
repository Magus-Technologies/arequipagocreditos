import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Una opción de [AppSelect]: [value] es lo que se guarda y [label] lo que ve la persona.
class SelectOption {
  const SelectOption(this.value, this.label);

  final String value;
  final String label;
}

/// Selector único del app. Cerrado se ve como un campo de texto del formulario (mismo fondo, radio, ícono y altura); al tocarlo abre
/// una hoja inferior con la lista de opciones. Reemplaza al `DropdownButtonFormField`, cuya lista de Material salía pegada al borde,
/// con esquinas rectas, con el resaltado lila del tema y tapando el campo de abajo.
///
/// También cubre los estados que antes se repetían en cada pantalla: cargando, error con reintento, texto de espera
/// («Selecciona primero…») y aviso naranja cuando no hay nada que elegir.
class AppSelect extends StatefulWidget {
  const AppSelect({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
    this.loading = false,
    this.error,
    this.onRetry,
    this.placeholder,
    this.placeholderEsAviso = false,
    this.avisoKey,
    this.fieldKey,
  });

  /// Hasta esta cantidad de opciones la lista cabe a la vista y no hace falta buscador.
  static const int maxOpcionesSinBuscador = 7;

  /// Tope de la hoja respecto al alto de la pantalla.
  static const double alturaMaximaHoja = 0.7;

  /// Alto de cada fila de la hoja. Es el mínimo: con letra grande la fila crece en vez de recortar el texto.
  static const double alturaFila = 52;

  final String label;
  final IconData icon;

  /// Valor elegido. Si no está entre [options] el campo se muestra vacío (nunca se rompe por un valor huérfano).
  final String? value;
  final List<SelectOption> options;

  /// Se llama al elegir una opción DISTINTA de la actual. Cerrar la hoja sin elegir, o tocar la que ya estaba elegida, no lo llama.
  final ValueChanged<String> onChanged;

  /// Muestra el campo apagado con «Cargando...» y un spinner.
  final bool loading;

  /// Si no es null, muestra el recuadro rojo «Error al cargar {label}. Toca para reintentar».
  final String? error;
  final VoidCallback? onRetry;

  /// Si no es null, el campo se muestra apagado con este texto (p. ej. «Selecciona primero el departamento»).
  final String? placeholder;

  /// El [placeholder] es un aviso que bloquea el avance (no solo «primero elige lo anterior»): se pinta como alerta naranja.
  final bool placeholderEsAviso;

  /// Key del recuadro de aviso, para que las pruebas lo ubiquen.
  final Key? avisoKey;

  /// Key del campo en su estado normal.
  final Key? fieldKey;

  @override
  State<AppSelect> createState() => _AppSelectState();
}

const TextStyle _estiloValor = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black);

class _AppSelectState extends State<AppSelect> {
  /// Mientras la hoja está abierta el campo se pinta enfocado (borde amarillo), igual que el desplegable que reemplaza.
  bool _hojaAbierta = false;

  SelectOption? get _seleccionada {
    for (final o in widget.options) {
      if (o.value == widget.value) return o;
    }
    return null;
  }

  Future<void> _abrirHoja() async {
    // El selector no toma el foco: si un campo de texto lo tenía (p. ej. el correo), lo conservaría y, al cerrarse la hoja, Flutter se
    // lo devolvería y reabriría el teclado. Se suelta ANTES de abrir (así tampoco se «recuerda» para devolverlo después).
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _hojaAbierta = true);
    final elegido = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _HojaOpciones(
        titulo: widget.label,
        opciones: widget.options,
        valorActual: _seleccionada?.value,
      ),
    );
    if (!mounted) return;
    setState(() => _hojaAbierta = false);
    // Tocar la opción que ya estaba elegida solo cierra la hoja: avisar «cambió» borraría lo que depende de ella (al volver a tocar
    // el departamento se perderían la provincia y el distrito ya elegidos).
    if (elegido != null && elegido != _seleccionada?.value) widget.onChanged(elegido);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return _buildCargando();
    if (widget.error != null) return _buildError();
    final placeholder = widget.placeholder;
    if (placeholder != null) {
      return widget.placeholderEsAviso ? _buildAviso(placeholder) : _buildEspera(placeholder);
    }
    return _buildCampo();
  }

  Widget _buildCampo() {
    final seleccionada = _seleccionada;
    final habilitado = widget.options.isNotEmpty;
    final radio = BorderRadius.circular(15);
    // El mismo estilo base que usa un TextField, para que el texto ocupe la misma línea y el campo mida igual que sus vecinos.
    final tema = Theme.of(context);
    final estilo = (tema.useMaterial3 ? tema.textTheme.bodyLarge : tema.textTheme.titleMedium)!.merge(_estiloValor);

    return Semantics(
      button: true,
      enabled: habilitado,
      label: widget.label,
      value: seleccionada?.label ?? 'Sin seleccionar',
      onTap: habilitado ? _abrirHoja : null,
      // El texto de adentro ya está dicho en label/value: se evita que el lector lo repita.
      excludeSemantics: true,
      child: Stack(
        children: [
          // Se usa el mismo InputDecorator que los campos de texto para que la altura y la etiqueta flotante coincidan al píxel.
          InputDecorator(
            isEmpty: seleccionada == null,
            isFocused: _hojaAbierta,
            baseStyle: estilo,
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: const TextStyle(color: Colors.black45),
              prefixIcon: Icon(widget.icon, color: Colors.black87, size: 22),
              suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: habilitado ? Colors.black45 : Colors.black26),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide(color: AppTheme.primary, width: 2)),
            ),
            child: Text(
              // Con el campo vacío igual se deja un texto para que la línea ocupe su alto y no se achique frente a los vecinos.
              seleccionada?.label ?? ' ',
              style: estilo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // El toque va ENCIMA del campo: el relleno gris del InputDecorator taparía la onda si el InkWell estuviera debajo.
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: widget.fieldKey,
                borderRadius: radio,
                onTap: habilitado ? _abrirHoja : null,
                splashColor: AppTheme.primary.withValues(alpha: 0.2),
                highlightColor: AppTheme.primary.withValues(alpha: 0.1),
                focusColor: AppTheme.primary.withValues(alpha: 0.12),
                hoverColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargando() {
    return Semantics(
      label: '${widget.label}, cargando',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            Icon(widget.icon, color: Colors.black87, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Cargando...', style: TextStyle(fontSize: 15, color: Colors.black45)),
            ),
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return InkWell(
      onTap: widget.onRetry,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.refresh, color: Colors.red.shade400, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error al cargar ${widget.label}. Toca para reintentar',
                style: TextStyle(fontSize: 13, color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAviso(String texto) {
    return Container(
      key: widget.avisoKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 13, color: Colors.orange.shade900)),
          ),
        ],
      ),
    );
  }

  Widget _buildEspera(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(widget.icon, color: Colors.black26, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: const TextStyle(fontSize: 14, color: Colors.black38)),
          ),
        ],
      ),
    );
  }
}

/// Letras con tilde (y la ñ) a su letra base, para que «Junín» se encuentre escribiendo «junin». Sustituye a normalizar en NFD
/// sin sumar una dependencia: además se descartan las marcas combinantes por si el texto ya viene descompuesto.
const Map<String, String> _sinTilde = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n',
};

String _normalizar(String texto) {
  final salida = StringBuffer();
  for (final rune in texto.toLowerCase().runes) {
    // U+0300 a U+036F: marcas combinantes (la tilde suelta de una letra descompuesta).
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final letra = String.fromCharCode(rune);
    salida.write(_sinTilde[letra] ?? letra);
  }
  return salida.toString();
}

/// Contenido de la hoja inferior: manija, título, buscador (solo con muchas opciones) y la lista.
class _HojaOpciones extends StatefulWidget {
  const _HojaOpciones({required this.titulo, required this.opciones, required this.valorActual});

  final String titulo;
  final List<SelectOption> opciones;
  final String? valorActual;

  @override
  State<_HojaOpciones> createState() => _HojaOpcionesState();
}

class _HojaOpcionesState extends State<_HojaOpciones> {
  late final TextEditingController _buscador = TextEditingController();
  late final ScrollController _scroll;

  bool get _conBuscador => widget.opciones.length > AppSelect.maxOpcionesSinBuscador;

  @override
  void initState() {
    super.initState();
    // La hoja abre con la opción elegida a la vista (con 25 departamentos, Tacna no puede quedar escondida abajo).
    final indice = widget.opciones.indexWhere((o) => o.value == widget.valorActual);
    final inicio = indice <= 0 ? 0.0 : (indice - 1) * AppSelect.alturaFila;
    _scroll = ScrollController(initialScrollOffset: inicio);
  }

  @override
  void dispose() {
    _buscador.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<SelectOption> get _filtradas {
    final consulta = _normalizar(_buscador.text.trim());
    if (consulta.isEmpty) return widget.opciones;
    return widget.opciones.where((o) => _normalizar(o.label).contains(consulta)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final tema = Theme.of(context);
    final filtradas = _filtradas;

    return Theme(
      // El tema global trae el lila de Material 3: dentro de la hoja el cursor, la selección y las ondas siguen la paleta del app.
      data: tema.copyWith(
        colorScheme: tema.colorScheme.copyWith(primary: Colors.black, surfaceTint: Colors.transparent),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionHandleColor: Colors.black,
          selectionColor: AppTheme.primary.withValues(alpha: 0.35),
        ),
      ),
      // Con el teclado abierto (buscador) la hoja sube por encima de él.
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final altoMaximo = math.min(media.size.height * AppSelect.alturaMaximaHoja, restricciones.maxHeight);
            return ConstrainedBox(
              key: const Key('select_hoja'),
              constraints: BoxConstraints(maxHeight: altoMaximo),
              child: Column(
                // Con buscador la hoja mantiene su alto mientras se filtra (si no, saltaría con cada letra).
                mainAxisSize: _conBuscador ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  _buildManija(),
                  _buildTitulo(),
                  if (_conBuscador) _buildBuscador(),
                  const Divider(height: 1, thickness: 1, color: Colors.black12),
                  Flexible(
                    fit: _conBuscador ? FlexFit.tight : FlexFit.loose,
                    child: filtradas.isEmpty ? _buildSinResultados() : _buildLista(filtradas, media.padding.bottom),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildManija() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildTitulo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          header: true,
          child: Text(
            widget.titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildBuscador() {
    final radio = BorderRadius.circular(15);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        key: const Key('select_buscador'),
        controller: _buscador,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        style: _estiloValor,
        decoration: InputDecoration(
          hintText: 'Buscar',
          hintStyle: const TextStyle(color: Colors.black45),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.black87, size: 22),
          suffixIcon: _buscador.text.isEmpty
              ? null
              : IconButton(
                  key: const Key('select_buscador_limpiar'),
                  tooltip: 'Limpiar búsqueda',
                  icon: const Icon(Icons.close_rounded, color: Colors.black54, size: 20),
                  onPressed: () {
                    _buscador.clear();
                    setState(() {});
                  },
                ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide(color: AppTheme.primary, width: 2)),
        ),
      ),
    );
  }

  Widget _buildSinResultados() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Align(
        alignment: Alignment.topCenter,
        child: Text('Sin resultados', style: TextStyle(fontSize: 14, color: Colors.black45)),
      ),
    );
  }

  Widget _buildLista(List<SelectOption> opciones, double margenInferior) {
    return ListView.builder(
      controller: _scroll,
      shrinkWrap: true,
      padding: EdgeInsets.only(bottom: margenInferior),
      itemCount: opciones.length,
      itemBuilder: (context, i) {
        final opcion = opciones[i];
        return _FilaOpcion(
          opcion: opcion,
          seleccionada: opcion.value == widget.valorActual,
          ultima: i == opciones.length - 1,
        );
      },
    );
  }
}

class _FilaOpcion extends StatelessWidget {
  const _FilaOpcion({required this.opcion, required this.seleccionada, required this.ultima});

  final SelectOption opcion;
  final bool seleccionada;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: seleccionada,
      button: true,
      child: Material(
        // El fondo suave de la opción elegida va en el Material para que la onda del toque se pinte encima.
        color: seleccionada ? AppTheme.primary.withValues(alpha: 0.12) : Colors.transparent,
        child: InkWell(
          key: Key('select_opcion_${opcion.value}'),
          onTap: () => Navigator.of(context).pop(opcion.value),
          splashColor: AppTheme.primary.withValues(alpha: 0.2),
          highlightColor: AppTheme.primary.withValues(alpha: 0.1),
          focusColor: AppTheme.primary.withValues(alpha: 0.12),
          hoverColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSelect.alturaFila),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: ultima ? null : const Border(bottom: BorderSide(color: Colors.black12, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    opcion.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: seleccionada ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                // El color primario del app es amarillo y sobre blanco no se lee: el check va oscuro.
                if (seleccionada) const Icon(Icons.check_rounded, color: Colors.black87, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
