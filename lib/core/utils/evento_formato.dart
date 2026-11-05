/// Textos de fecha y dinero del módulo «Eventos».
///
/// La fecha se arma a mano en español: `DateFormat` con la configuración regional «es» exige inicializar los datos de idioma al
/// arrancar, y el app no lo hace (el resto de pantallas solo usa formatos numéricos).
///
/// La hora del evento se muestra SIEMPRE en hora de Lima (UTC-5; Perú no tiene horario de verano), no en la zona del teléfono:
/// quien abre el app con otra zona configurada (o de viaje) vería otra hora y hasta otro día. Sin sufijo «hora de Lima»: el
/// evento es en Arequipa y el texto ya va cargado.
class EventoFormato {
  static const Duration _offsetLima = Duration(hours: 5);

  static const List<String> _dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
  static const List<String> _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// El mismo instante con los campos (día, hora…) de Lima. El resultado es un `DateTime` en UTC solo como contenedor.
  static DateTime aLima(DateTime instante) => instante.toUtc().subtract(_offsetLima);

  /// «Sábado 14 de noviembre · 2:00 p. m.» (hora de Lima)
  static String fechaHora(DateTime? fecha) {
    if (fecha == null) return '';
    final lima = aLima(fecha);
    final dia = _dias[lima.weekday - 1];
    final diaCapitalizado = '${dia[0].toUpperCase()}${dia.substring(1)}';
    return '$diaCapitalizado ${lima.day} de ${_meses[lima.month - 1]} · ${_hora(lima)}';
  }

  /// Día y mes abreviado para la insignia de una tarjeta: («14», «NOV»), con la fecha de Lima.
  static ({String dia, String mes}) diaYMes(DateTime fecha) {
    final lima = aLima(fecha);
    return (dia: lima.day.toString(), mes: _meses[lima.month - 1].substring(0, 3).toUpperCase());
  }

  /// «2:00 p. m.» (hora de Lima)
  static String hora(DateTime fecha) => _hora(aLima(fecha));

  static String _hora(DateTime lima) {
    final h12 = lima.hour % 12 == 0 ? 12 : lima.hour % 12;
    final minutos = lima.minute.toString().padLeft(2, '0');
    return '$h12:$minutos ${lima.hour < 12 ? 'a. m.' : 'p. m.'}';
  }

  /// «S/ 50.00»
  static String monto(double valor) => 'S/ ${valor.toStringAsFixed(2)}';

  /// «1 ticket» / «3 tickets»
  static String tickets(int cantidad) => cantidad == 1 ? '1 ticket' : '$cantidad tickets';
}
