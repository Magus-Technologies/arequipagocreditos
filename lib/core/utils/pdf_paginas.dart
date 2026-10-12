import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';

/// TK-0353: una página de un PDF ya dibujada como imagen (PNG), para poder poner la firma encima.
class PaginaPdf {
  final Uint8List bytes;
  final int ancho;
  final int alto;

  const PaginaPdf({required this.bytes, required this.ancho, required this.alto});

  /// Ancho / alto de la hoja.
  double get aspecto => ancho / alto;
}

/// Las páginas de un PDF abierto. Es una interfaz para que la pantalla de colocar la firma no dependa del plugin nativo
/// (en las pruebas se reemplaza por una versión que devuelve imágenes ya hechas).
abstract class PdfPaginas {
  int get total;

  /// Dibuja la página [numero] (desde 1).
  Future<PaginaPdf> renderizar(int numero);

  Future<void> cerrar();
}

/// Cómo se abre un PDF desde un archivo local.
typedef AbridorDePdf = Future<PdfPaginas> Function(String rutaArchivo);

/// Implementación real con `pdfx` (PDFium nativo).
class PdfPaginasPdfx implements PdfPaginas {
  PdfPaginasPdfx._(this._documento);

  final PdfDocument _documento;

  /// Ancho en píxeles con el que se dibuja cada página: lo bastante nítido para ubicar la línea de firma sin gastar memoria.
  static const double anchoDeRenderizado = 1100;

  static Future<PdfPaginas> abrir(String rutaArchivo) async => PdfPaginasPdfx._(await PdfDocument.openFile(rutaArchivo));

  @override
  int get total => _documento.pagesCount;

  @override
  Future<PaginaPdf> renderizar(int numero) async {
    final pagina = await _documento.getPage(numero);
    try {
      final escala = anchoDeRenderizado / pagina.width;
      final ancho = pagina.width * escala;
      final alto = pagina.height * escala;
      final imagen = await pagina.render(
        width: ancho,
        height: alto,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      if (imagen == null) {
        throw StateError('No se pudo dibujar la página $numero');
      }
      return PaginaPdf(
        bytes: imagen.bytes,
        ancho: imagen.width ?? ancho.round(),
        alto: imagen.height ?? alto.round(),
      );
    } finally {
      await pagina.close();
    }
  }

  @override
  Future<void> cerrar() => _documento.close();
}
