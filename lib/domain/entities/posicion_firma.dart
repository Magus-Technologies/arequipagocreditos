/// TK-0353: dónde coloca el conductor su firma sobre el PDF de un documento adicional.
///
/// Todo va en fracciones de la página (de 0 a 1), así no depende del tamaño de pantalla ni de la resolución con que se muestre:
/// [x] e [y] son la esquina superior izquierda de la firma (desde la esquina superior izquierda de la página) y [ancho] es el
/// ancho de la firma sobre el ancho de la página. [pagina] cuenta desde 1.
class PosicionFirma {
  final int pagina;
  final double x;
  final double y;
  final double ancho;

  const PosicionFirma({
    required this.pagina,
    required this.x,
    required this.y,
    required this.ancho,
  });

  /// Lo que se manda al servidor en `posicion` (`POST /app/firmar/documento-adicional/{id}`).
  Map<String, dynamic> toJson() => {
        'pagina': pagina,
        'x': _redondear(x),
        'y': _redondear(y),
        'ancho': _redondear(ancho),
      };

  static double _redondear(double v) => double.parse(v.toStringAsFixed(5));

  @override
  bool operator ==(Object other) =>
      other is PosicionFirma && other.pagina == pagina && other.x == x && other.y == y && other.ancho == ancho;

  @override
  int get hashCode => Object.hash(pagina, x, y, ancho);

  @override
  String toString() => 'PosicionFirma(pagina: $pagina, x: $x, y: $y, ancho: $ancho)';
}
