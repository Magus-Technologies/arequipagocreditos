import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/utils/pdf_paginas.dart';
import '../../../domain/entities/posicion_firma.dart';
import '../../../theme/app_theme.dart';

/// TK-0353: el conductor ya dibujó su firma; aquí la COLOCA sobre el documento: ve la página, arrastra la firma hasta la línea
/// donde corresponde, cambia de página si hace falta y ajusta el tamaño. Al confirmar devuelve la [PosicionFirma] (en fracciones
/// de la página); el servidor estampa la firma ahí en una copia del PDF. Si sale sin confirmar devuelve null y no se firma nada.
class ColocarFirmaPage extends StatefulWidget {
  final String title;
  final PdfPaginas paginas;

  /// La firma tal como la exporta el lienzo: PNG negro sobre fondo blanco opaco.
  final Uint8List firmaPng;

  /// Página con la que se abre; por defecto la última (donde casi siempre va la firma).
  final int? paginaInicial;

  const ColocarFirmaPage({
    super.key,
    required this.title,
    required this.paginas,
    required this.firmaPng,
    this.paginaInicial,
  });

  /// Ancho de la firma sobre el ancho de la página: lo que permite elegir el control de tamaño.
  static const double anchoMinimo = 0.12;
  static const double anchoMaximo = 0.60;
  static const double anchoInicial = 0.30;

  /// Mismo efecto que el servidor al estamparla: lo blanco se vuelve transparente y el trazo conserva su opacidad según lo
  /// oscuro que sea. Así la firma no tapa la línea ni el texto del documento.
  ///
  /// Alfa nuevo = alfa − luminosidad. OJO: no puede ser «255 − luminosidad»: un filtro de color también se aplica a los píxeles
  /// transparentes (0,0,0,0) y los volvería negros opacos, pintando de negro toda la pantalla. Con «alfa − luminosidad» lo
  /// transparente sigue transparente, lo blanco opaco pasa a transparente y lo negro opaco sigue opaco.
  static const List<double> matrizBlancoTransparente = <double>[
    0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    -0.299, -0.587, -0.114, 1, 0,
  ];

  static const ColorFilter blancoTransparente = ColorFilter.matrix(matrizBlancoTransparente);

  @override
  State<ColocarFirmaPage> createState() => _ColocarFirmaPageState();
}

class _ColocarFirmaPageState extends State<ColocarFirmaPage> {
  late int _pagina;
  late final double _firmaAspecto;
  final Map<int, PaginaPdf> _paginas = {};

  double _x = 0;
  double _y = 0;
  double _ancho = ColocarFirmaPage.anchoInicial;
  bool _posicionada = false;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final total = widget.paginas.total;
    _pagina = (widget.paginaInicial ?? total).clamp(1, math.max(total, 1));
    _firmaAspecto = _aspectoDelPng(widget.firmaPng);
    _cargar(_pagina);
  }

  /// Ancho / alto leídos de la cabecera del PNG (IHDR); sin ella, una firma típica (apaisada).
  static double _aspectoDelPng(Uint8List png) {
    if (png.length < 24) return 2.5;
    final datos = ByteData.sublistView(png);
    final ancho = datos.getUint32(16);
    final alto = datos.getUint32(20);
    return (ancho > 0 && alto > 0) ? ancho / alto : 2.5;
  }

  Future<void> _cargar(int numero) async {
    if (_paginas.containsKey(numero)) {
      setState(() {
        _cargando = false;
        _error = null;
        _ajustar(_paginas[numero]!);
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pagina = await widget.paginas.renderizar(numero);
      if (!mounted) return;
      setState(() {
        _paginas[numero] = pagina;
        _cargando = false;
        if (!_posicionada) {
          // Abajo a la derecha: donde suele ir la firma. El conductor la arrastra desde ahí.
          _x = 1 - _ancho - 0.08;
          _y = 0.78;
          _posicionada = true;
        }
        _ajustar(pagina);
      });
    } catch (e) {
      debugPrint('Error dibujando la página $numero: $e');
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo mostrar la página $numero del documento.';
      });
    }
  }

  /// Alto de la firma como fracción del alto de la página (más un pequeño margen para la leyenda que se imprime debajo).
  double _altoFraccion(PaginaPdf pagina) => _ancho * pagina.aspecto / _firmaAspecto + 0.015;

  /// Mantiene la firma dentro de la hoja.
  void _ajustar(PaginaPdf pagina) {
    _x = _x.clamp(0.0, math.max(0.0, 1 - _ancho)).toDouble();
    _y = _y.clamp(0.0, math.max(0.0, 1 - _altoFraccion(pagina))).toDouble();
  }

  void _irA(int numero) {
    if (numero < 1 || numero > widget.paginas.total || numero == _pagina) return;
    setState(() => _pagina = numero);
    _cargar(numero);
  }

  void _confirmar() {
    Navigator.of(context).pop(PosicionFirma(pagina: _pagina, x: _x, y: _y, ancho: _ancho));
  }

  @override
  Widget build(BuildContext context) {
    final pagina = _paginas[_pagina];

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text(
          'Coloca tu firma',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: Column(
            children: [
              _instruccion(),
              _selectorDePagina(),
              Expanded(child: _zonaDePagina(pagina)),
              _controlDeTamano(),
              _botonConfirmar(pagina != null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _instruccion() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha((0.05 * 255).toInt()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withAlpha((0.1 * 255).toInt())),
        ),
        child: Row(
          children: [
            const Icon(Icons.open_with, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Arrastra tu firma hasta la línea donde corresponde. Puedes cambiar de página y de tamaño.',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade800, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorDePagina() {
    final total = widget.paginas.total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const Key('colocar_firma_anterior'),
            tooltip: 'Página anterior',
            onPressed: _pagina > 1 ? () => _irA(_pagina - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            'Página $_pagina de $total',
            key: const Key('colocar_firma_pagina_texto'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            key: const Key('colocar_firma_siguiente'),
            tooltip: 'Página siguiente',
            onPressed: _pagina < total ? () => _irA(_pagina + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _zonaDePagina(PaginaPdf? pagina) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => _cargar(_pagina), child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (pagina == null || _cargando && !_paginas.containsKey(_pagina)) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: LayoutBuilder(
        builder: (context, restricciones) {
          // La hoja entera, con su proporción real, dentro del espacio disponible.
          var ancho = restricciones.maxWidth;
          var alto = ancho / pagina.aspecto;
          if (alto > restricciones.maxHeight) {
            alto = restricciones.maxHeight;
            ancho = alto * pagina.aspecto;
          }
          final firmaAncho = _ancho * ancho;
          final firmaAlto = firmaAncho / _firmaAspecto;

          return Center(
            child: Container(
              key: const Key('colocar_firma_hoja'),
              width: ancho,
              height: alto,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.memory(pagina.bytes, fit: BoxFit.fill, gaplessPlayback: true),
                  ),
                  Positioned(
                    left: _x * ancho,
                    top: _y * alto,
                    width: firmaAncho,
                    height: firmaAlto,
                    child: GestureDetector(
                      key: const Key('colocar_firma_arrastre'),
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (d) => setState(() {
                        _x += d.delta.dx / ancho;
                        _y += d.delta.dy / alto;
                        _ajustar(pagina);
                      }),
                      child: DecoratedBox(
                        decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 1.5)),
                        child: ColorFiltered(
                          colorFilter: ColocarFirmaPage.blancoTransparente,
                          child: Image.memory(widget.firmaPng, fit: BoxFit.fill),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _controlDeTamano() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(Icons.photo_size_select_small, size: 18, color: Colors.black54),
          Expanded(
            child: Slider(
              key: const Key('colocar_firma_tamano'),
              value: _ancho.clamp(ColocarFirmaPage.anchoMinimo, ColocarFirmaPage.anchoMaximo).toDouble(),
              min: ColocarFirmaPage.anchoMinimo,
              max: ColocarFirmaPage.anchoMaximo,
              activeColor: Colors.black,
              onChanged: (v) => setState(() {
                _ancho = v;
                final pagina = _paginas[_pagina];
                if (pagina != null) _ajustar(pagina);
              }),
            ),
          ),
          const Icon(Icons.photo_size_select_large, size: 22, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _botonConfirmar(bool habilitado) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          key: const Key('colocar_firma_confirmar'),
          onPressed: habilitado ? _confirmar : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text(
            'CONFIRMAR FIRMA AQUÍ',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
        ),
      ),
    );
  }
}
