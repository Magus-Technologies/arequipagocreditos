import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../core/utils/evento_formato.dart';
import '../../data/models/evento_invitado.dart';
import '../../data/models/evento_models.dart';
import '../../domain/repositories/evento_repository.dart';

/// Resultado de una acción del usuario (comprar, subir captura, cancelar): o salió bien con su dato, o trae el mensaje que se le
/// muestra tal cual (el del servidor cuando es un error de negocio, como «Ya tienes 4 de 4 tickets»).
class EventoResultado<T> {
  final T? data;
  final String? mensaje;

  /// Solo en un error: no se sabe si el servidor llegó a registrar la acción (se perdió la respuesta). La pantalla ofrece ir a
  /// «Mis tickets» a comprobarlo antes de reintentar, para no duplicar la compra.
  final bool incierto;

  const EventoResultado.ok([this.data])
      : mensaje = null,
        incierto = false;
  const EventoResultado.error(String this.mensaje, {this.incierto = false}) : data = null;

  bool get ok => mensaje == null;
}

typedef _Persona = ({int id, String documento});

/// Estado del módulo «Eventos»: el evento activo (para el aviso al entrar y el chip de eventos del inicio) y las compras de tickets
/// de la persona. El servidor es quien decide el tope por persona; acá solo se evita mandar lo que ya se sabe que va a fallar.
///
/// Todo lo que guarda es de UNA persona (la última identificada). Si la sesión cambia o se cierra ([limpiar],
/// [vincularSesion]) se descarta todo y las respuestas que todavía venían en camino para la persona anterior se ignoran.
///
/// TK-0450: además de la persona REGISTRADA (con sesión) existe el INVITADO: quien no tiene cuenta, o no puede entrar con ella, y
/// compra un evento PÚBLICO con su nombre, documento y teléfono. Los dos «modos» comparten las mismas pantallas y el mismo estado
/// (evento, compras, cupo): las acciones (comprar, subir captura, bajar el ticket) van al servidor de una u otra forma según el modo.
/// El modo de la persona registrada no cambia en nada.
class EventoProvider extends ChangeNotifier {
  final EventoRepository repository;
  final DateTime Function() _ahora;
  final EventoInvitadoAlmacen _almacen;

  /// `ahora` y `almacenInvitado` solo se cambian en pruebas.
  EventoProvider({required this.repository, DateTime Function()? ahora, EventoInvitadoAlmacen? almacenInvitado})
      : _ahora = ahora ?? DateTime.now,
        _almacen = almacenInvitado ?? const EventoInvitadoAlmacenLocal();

  static const String _sinCuenta = 'No pudimos identificar tu cuenta. Vuelve a iniciar sesión.';
  static const String _sinDatos = 'Completa tus datos para continuar.';
  static const String _ocupado = 'Ya estamos procesando tu solicitud. Espera un momento.';
  static const String _inesperado = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  static const String _sesionCambio = 'Tu sesión cambió. Inténtalo de nuevo.';
  static const String _compraIncierta =
      'No pudimos confirmar si tu compra se registró. Revisa «Mis tickets» antes de intentar de nuevo.';
  static const String _soloClientes =
      'Este evento es solo para clientes de Arequipa Go. Inicia sesión con tu cuenta para comprar.';
  static const String _invitadoNoCancela =
      'Esta compra no se puede cancelar desde el app. Comunícate con Arequipa Go si necesitas anularla.';

  /// Una compra de un evento ya pasado deja de dar acceso fijo desde el inicio pasado este plazo (el evento es de un solo día).
  static const Duration plazoAccesoTrasEvento = Duration(days: 1);

  _Persona? _persona;
  EventoModel? _evento;
  List<EventoCompraModel> _compras = const [];
  bool _cargandoActivo = false;
  bool _cargandoCompras = false;
  bool _enviando = false;
  String? _errorCompras;
  Future<void>? _activoEnCurso;

  /// Sube cada vez que cambia la persona o se limpia: una respuesta que vuelve de un `await` con otro número es de otra sesión.
  int _generacion = 0;
  VoidCallback? _desvincular;

  // Invitado (sin cuenta)
  EventoInvitado? _invitado;
  bool _modoInvitado = false;
  Future<void>? _restauracion;

  EventoModel? get evento => _evento;
  List<EventoCompraModel> get compras => _compras;
  bool get cargandoActivo => _cargandoActivo;
  bool get cargandoCompras => _cargandoCompras;

  /// Hay una compra, una captura o una cancelación en camino: los botones se bloquean para no mandar dos veces.
  bool get enviando => _enviando;

  /// Mensaje del último intento fallido de cargar «Mis tickets» (null si salió bien).
  String? get errorCompras => _errorCompras;

  /// Los datos del invitado (null si todavía no los dio o los borró). Es de quien usa el app SIN sesión.
  EventoInvitado? get invitado => _invitado;

  /// ¿Las compras y el evento que se ven son de un invitado (sin cuenta)?
  bool get modoInvitado => _modoInvitado;

  // ---------------------------------------------------------------------------------------------------------------------
  // Entrada fija del inicio

  /// Compras que todavía importan: pendientes o confirmadas, de un evento que no terminó hace más de [plazoAccesoTrasEvento].
  /// Con el evento ya empezado el servidor deja de mandarlo como «activo», y aun así quien pagó tiene que poder llegar a su
  /// código (o terminar de subir su captura).
  List<EventoCompraModel> get comprasVigentes {
    final limite = _ahora().subtract(plazoAccesoTrasEvento);
    return _compras
        .where((c) => c.ocupaCupo && (c.fechaHoraEvento == null || c.fechaHoraEvento!.isAfter(limite)))
        .toList();
  }

  /// ¿Se muestra el chip de eventos del inicio? Con evento activo, o sin él si la persona tiene una compra vigente.
  bool get hayAccesoFijo => _evento != null || comprasVigentes.isNotEmpty;

  /// Sin evento activo, el chip sale solo por una compra: dice «Mis tickets» y no ofrece comprar.
  bool get accesoSoloPorCompra => _evento == null && comprasVigentes.isNotEmpty;

  /// Nombre del evento del acceso (el activo, o el de la compra vigente más reciente).
  String? get nombreAccesoFijo => _evento?.nombre ?? (comprasVigentes.isEmpty ? null : comprasVigentes.first.eventoNombre);

  // ---------------------------------------------------------------------------------------------------------------------
  // Cupo por persona

  /// Cuántos tickets más puede comprar. Lo dice el servidor en `mis_tickets`; sin ese dato se calcula con sus compras
  /// (pendiente + confirmado ocupan cupo; rechazado y anulado lo liberan).
  int get ticketsDisponibles {
    final e = _evento;
    if (e == null) return 0;
    final mis = e.misTickets;
    if (mis != null) return math.max(0, mis.disponibles);
    return math.max(0, e.maxTicketsPorPersona - _ticketsEnUso(e));
  }

  bool get puedeComprar => _evento != null && ticketsDisponibles > 0;

  String get mensajeTope {
    final max = _evento?.maxTicketsPorPersona ?? 0;
    return 'Ya tienes el máximo de ${EventoFormato.tickets(max)} por persona';
  }

  String get textoCupo {
    final max = _evento?.maxTicketsPorPersona ?? 0;
    return 'Máximo $max por persona · te quedan $ticketsDisponibles';
  }

  int _ticketsEnUso(EventoModel e) {
    return _compras.where((c) => c.eventoId == e.id && c.ocupaCupo).fold<int>(0, (suma, c) => suma + c.cantidad);
  }

  EventoCompraModel? compraPorId(int id) {
    for (final c in _compras) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ---------------------------------------------------------------------------------------------------------------------
  // Sesión

  /// Olvida todo: evento, compras y persona. Lo que todavía venga en camino se descarta al llegar. Los datos del invitado guardados
  /// en el celular no se tocan (no dependen de la sesión); de la lista de eventos solo se quitan los privados (los vio una persona
  /// con sesión).
  void limpiar() {
    _generacion++;
    _persona = null;
    _modoInvitado = false;
    _evento = null;
    _compras = const [];
    _errorCompras = null;
    _activoEnCurso = null;
    _cargandoActivo = false;
    _cargandoCompras = false;
    _enviando = false;
    _lista = _soloPublicos(_lista);
    notifyListeners();
  }

  /// Se limpia solo cuando la sesión se cierra o entra otra persona: `sesion` avisa de cada cambio y `idPersonaActual` dice quién
  /// está en sesión ahora (null = nadie). Evita que la persona B vea, aunque sea un cuadro, las compras de A.
  void vincularSesion(Listenable sesion, int? Function() idPersonaActual) {
    _desvincular?.call();
    void alCambiar() {
      final identificada = _persona;
      if (identificada != null && idPersonaActual() != identificada.id) limpiar();
    }

    sesion.addListener(alCambiar);
    _desvincular = () => sesion.removeListener(alCambiar);
  }

  @override
  void dispose() {
    _desvincular?.call();
    super.dispose();
  }

  /// Otra persona en el mismo teléfono (cerró sesión y entró otra) no hereda el evento ni las compras de la anterior. Lo mismo si
  /// antes se estaba viendo el evento como invitado: las compras del invitado no son de quien inicia sesión.
  void _identificar(int id, String documento) {
    final anterior = _persona;
    if ((anterior != null && anterior.id != id) || _modoInvitado) {
      _generacion++;
      _evento = null;
      _compras = const [];
      _errorCompras = null;
      _activoEnCurso = null;
      _cargandoActivo = false;
      _cargandoCompras = false;
      _enviando = false;
      _modoInvitado = false;
    }
    _persona = (id: id, documento: documento);
  }

  // ---------------------------------------------------------------------------------------------------------------------
  // Cargas

  /// Trae el evento activo. Si ya hay una carga en camino devuelve esa misma (el inicio la dispara al abrirse y el aviso la
  /// espera). Un error de red NO borra el evento que ya se tenía: la entrada del inicio no parpadea. Solo un servidor que
  /// responde «no hay evento» lo quita.
  Future<void> cargarActivo({required int clienteConductorId, required String nroDocumento}) {
    _identificar(clienteConductorId, nroDocumento);
    final enCurso = _activoEnCurso;
    if (enCurso != null) return enCurso;

    final carga = _cargarActivo();
    _activoEnCurso = carga;
    void liberar() {
      if (identical(_activoEnCurso, carga)) _activoEnCurso = null;
    }

    carga.then<void>((_) => liberar(), onError: (Object _) => liberar());
    return carga;
  }

  Future<void> _cargarActivo() async {
    final generacion = _generacion;
    _cargandoActivo = true;
    notifyListeners();
    await _refrescarActivo();
    if (generacion != _generacion) return;
    _cargandoActivo = false;
    notifyListeners();
  }

  /// Pide el evento y, si el servidor responde, lo guarda (incluso un «no hay evento»). Un fallo deja lo que había. Como invitado
  /// se vuelve a pedir el evento público que se está viendo.
  Future<void> _refrescarActivo() async {
    if (_modoInvitado) {
      final actual = _evento;
      if (actual == null) return;
      final generacion = _generacion;
      final r = await repository.getEventoPublico(actual.id);
      if (generacion != _generacion) return;
      if (r.isRight) _evento = r.right;
      return;
    }

    final persona = _persona;
    if (persona == null) return;
    final generacion = _generacion;
    final r = await repository.getEventoActivo(clienteConductorId: persona.id, nroDocumento: persona.documento);
    if (generacion != _generacion) return;
    if (r.isRight) _evento = r.right;
  }

  // ---------------------------------------------------------------------------------------------------------------------
  // Pantalla «Eventos»: próximos y ya realizados

  EventosListaModel? _lista;
  bool _cargandoLista = false;
  String? _errorLista;
  Future<void>? _listaEnCurso;

  /// Los eventos de la pantalla «Eventos» (null mientras no se haya podido cargar ni una vez). Sin sesión son solo los PÚBLICOS; con
  /// sesión también los privados (solo clientes GO).
  EventosListaModel? get lista => _lista;
  bool get cargandoLista => _cargandoLista;

  /// Mensaje del último intento fallido de cargar la lista (null si salió bien).
  String? get errorLista => _errorLista;

  /// Pide los eventos próximos y los ya realizados. Con la persona de la sesión (`clienteConductorId` + `nroDocumento`) el servidor
  /// incluye también los eventos privados; sin ella, solo los públicos. Un error de red deja la lista que ya había y solo avisa;
  /// nunca lanza. Si ya hay una carga en camino devuelve esa misma.
  Future<void> cargarLista({int? clienteConductorId, String? nroDocumento}) {
    return _listaEnCurso ??= _cargarLista(clienteConductorId, nroDocumento).whenComplete(() => _listaEnCurso = null);
  }

  Future<void> _cargarLista(int? clienteConductorId, String? nroDocumento) async {
    _cargandoLista = true;
    _errorLista = null;
    notifyListeners();
    try {
      final r = await repository.getEventos(clienteConductorId: clienteConductorId, nroDocumento: nroDocumento);
      if (r.isRight) {
        _lista = r.right;
      } else {
        _errorLista = r.left.message;
      }
    } catch (_) {
      _errorLista = _inesperado;
    }
    _cargandoLista = false;
    notifyListeners();
  }

  EventosListaModel? _soloPublicos(EventosListaModel? lista) {
    if (lista == null) return null;
    return EventosListaModel(
      proximos: lista.proximos.where((e) => !e.esPrivado).toList(),
      anteriores: lista.anteriores.where((e) => !e.esPrivado).toList(),
    );
  }

  // ---------------------------------------------------------------------------------------------------------------------
  // Evento para quien todavía no inició sesión

  EventoModel? _eventoPublico;
  Future<void>? _publicoEnCurso;

  /// El evento activo tal como lo ve alguien SIN sesión (pantalla de bienvenida): solo sirve para avisar que hay uno (y abrirlo). Es
  /// siempre un evento PÚBLICO. No lleva persona ni cupo, y por eso vive aparte de [evento]: cerrar o cambiar de sesión no lo toca.
  EventoModel? get eventoPublico => _eventoPublico;

  /// Pide el evento activo sin identificar a nadie (el endpoint es público). Un error de red deja lo que ya había y NUNCA lanza:
  /// la bienvenida no se ensucia por esto. Si ya hay una carga en camino devuelve esa misma.
  Future<void> cargarActivoPublico() {
    return _publicoEnCurso ??= _cargarPublico().whenComplete(() => _publicoEnCurso = null);
  }

  Future<void> _cargarPublico() async {
    try {
      final r = await repository.getEventoActivo();
      if (r.isRight) {
        _eventoPublico = r.right;
        notifyListeners();
      }
    } catch (_) {
      // Sin conexión: la bienvenida sigue igual, sin aviso.
    }
  }

  Future<void> cargarMisCompras({required int clienteConductorId, required String nroDocumento}) async {
    _identificar(clienteConductorId, nroDocumento);
    final generacion = _generacion;
    _cargandoCompras = true;
    _errorCompras = null;
    notifyListeners();

    final r = await repository.getMisCompras(clienteConductorId: clienteConductorId, nroDocumento: nroDocumento);
    if (generacion != _generacion) return;
    if (r.isLeft) {
      _errorCompras = r.left.message;
    } else {
      _compras = r.right;
      _recalcularCupo();
    }
    _cargandoCompras = false;
    notifyListeners();
  }

  /// Vuelve a pedir «mis compras» sin banderas ni mensajes: para dejar la lista tal como está en el servidor después de una
  /// acción que falló y de la que no se sabe cómo quedó.
  Future<void> _recargarComprasEnSilencio() async {
    final generacion = _generacion;
    if (_modoInvitado) {
      final inv = _invitado;
      if (inv == null || !inv.puedeConsultar) return;
      final r = await repository.getMisComprasInvitado(nroDocumento: inv.documento, telefono: inv.telefono);
      if (generacion != _generacion || r.isLeft) return;
      _compras = r.right;
      _recalcularCupo();
      return;
    }

    final persona = _persona;
    if (persona == null) return;
    final r = await repository.getMisCompras(clienteConductorId: persona.id, nroDocumento: persona.documento);
    if (generacion != _generacion || r.isLeft) return;
    _compras = r.right;
    _recalcularCupo();
  }

  // ---------------------------------------------------------------------------------------------------------------------
  // Invitado (sin cuenta): eventos PÚBLICOS

  /// Pasa al modo invitado: lo que hubiera de una persona con sesión (evento, compras) no es del invitado y se descarta.
  void _pasarAModoInvitado() {
    if (_modoInvitado) return;
    _generacion++;
    _persona = null;
    _evento = null;
    _compras = const [];
    _errorCompras = null;
    _activoEnCurso = null;
    _cargandoActivo = false;
    _cargandoCompras = false;
    _enviando = false;
    _modoInvitado = true;
  }

  /// Lee los datos del invitado guardados en el celular (una sola vez; cualquiera puede esperarla). Nunca lanza.
  Future<void> restaurarInvitado() => _restauracion ??= _restaurar();

  Future<void> _restaurar() async {
    try {
      final guardado = await _almacen.leer();
      if (guardado != null && _invitado == null) {
        _invitado = guardado;
        notifyListeners();
      }
    } catch (_) {
      // Sin datos guardados (o ilegibles): la persona los escribe cuando se los pidan.
    }
  }

  /// Guarda (y recuerda en el celular) los datos del invitado. Si son de otra persona, las compras de la anterior se descartan.
  Future<void> identificarInvitado(EventoInvitado datos, {bool guardar = true}) async {
    _pasarAModoInvitado();
    final anterior = _invitado;
    if (anterior != null && (anterior.documento != datos.documento || anterior.telefono != datos.telefono)) {
      _generacion++;
      _compras = const [];
      _errorCompras = null;
      _enviando = false;
    }
    _invitado = datos;
    notifyListeners();

    if (guardar) {
      try {
        await _almacen.guardar(datos);
      } catch (_) {
        // No se pudo recordar en el celular: sigue valiendo para esta compra.
      }
    }
  }

  /// «No soy yo» / «Borrar mis datos»: el celular olvida al invitado y sus compras dejan de verse.
  Future<void> olvidarInvitado() async {
    _generacion++;
    _invitado = null;
    _compras = const [];
    _errorCompras = null;
    _enviando = false;
    _cargandoCompras = false;
    notifyListeners();
    try {
      await _almacen.borrar();
    } catch (_) {
      // Aunque no se pueda borrar del almacenamiento, ya no se usa en esta sesión del app.
    }
  }

  /// Pide el evento público completo (términos, política y QR de pago incluidos) para comprarlo como invitado. Si el servidor responde
  /// que ya no está disponible (o que es privado) lo quita; un error de red deja el que había. Nunca lanza.
  Future<void> cargarEventoPublico(int eventoId) async {
    _pasarAModoInvitado();
    final generacion = _generacion;
    try {
      final r = await repository.getEventoPublico(eventoId);
      if (generacion != _generacion) return;
      if (r.isRight) {
        _evento = r.right;
        _recalcularCupo();
        notifyListeners();
      }
    } catch (_) {
      // Sin conexión: se queda con lo que había.
    }
  }

  /// Las compras del invitado guardado en el celular (no hace nada si no hay datos). Nunca lanza.
  Future<void> cargarMisComprasInvitado() async {
    final inv = _invitado;
    if (inv == null || !inv.puedeConsultar) return;
    _pasarAModoInvitado();
    final generacion = _generacion;
    _cargandoCompras = true;
    _errorCompras = null;
    notifyListeners();

    try {
      final r = await repository.getMisComprasInvitado(nroDocumento: inv.documento, telefono: inv.telefono);
      if (generacion != _generacion) return;
      if (r.isLeft) {
        _errorCompras = r.left.message;
      } else {
        _compras = r.right;
        _recalcularCupo();
      }
    } catch (_) {
      if (generacion == _generacion) _errorCompras = _inesperado;
    }
    if (generacion != _generacion) return;
    _cargandoCompras = false;
    notifyListeners();
  }

  /// «Consulta tus tickets»: quien compró como invitado (y no tiene guardados sus datos en este celular) los busca con su documento
  /// y su celular. Si hay tickets, esos datos quedan guardados y se ven sus compras.
  Future<EventoResultado<int>> consultarTicketsDeInvitado({required String documento, required String telefono}) async {
    final doc = documento.trim().toUpperCase();
    final tel = EventoInvitadoValidador.limpiarTelefono(telefono);
    final errorDocumento = EventoInvitadoValidador.documento(doc);
    if (errorDocumento != null) return EventoResultado.error(errorDocumento);
    final errorTelefono = EventoInvitadoValidador.telefono(tel);
    if (errorTelefono != null) return EventoResultado.error(errorTelefono);
    if (_enviando) return const EventoResultado.error(_ocupado);

    _pasarAModoInvitado();
    return _conEnvioGenerico<int>(() async {
      final generacion = _generacion;
      final r = await repository.getMisComprasInvitado(nroDocumento: doc, telefono: tel);
      if (generacion != _generacion) return const EventoResultado<int>.error(_sesionCambio);
      if (r.isLeft) return EventoResultado<int>.error(r.left.message);
      if (r.right.isEmpty) {
        return const EventoResultado<int>.error('No encontramos tickets con ese documento y celular. Revisa que estén bien escritos.');
      }

      final anterior = _invitado;
      final mismo = anterior != null && anterior.documento == doc && anterior.telefono == tel;
      final datos = mismo ? anterior : EventoInvitado(nombre: '', documento: doc, telefono: tel);
      _invitado = datos;
      _compras = r.right;
      _recalcularCupo();
      try {
        await _almacen.guardar(datos);
      } catch (_) {
        // Se ven los tickets igual; solo no se recordarán la próxima vez.
      }
      return EventoResultado<int>.ok(r.right.length);
    });
  }

  // ---------------------------------------------------------------------------------------------------------------------
  // Acciones

  /// Registra la compra CON la captura del pago (obligatoria: sin ella el servidor no la registra). Con sesión, a nombre de la persona
  /// registrada; como invitado, con los datos que dio (solo eventos públicos).
  Future<EventoResultado<EventoCompraModel>> registrarCompra(int cantidad, File captura) async {
    final e = _evento;
    final p = _persona;
    final inv = _invitado;
    if (e == null) return const EventoResultado.error('No hay un evento activo en este momento.');
    if (_modoInvitado) {
      if (inv == null || !inv.puedeComprar) return const EventoResultado.error(_sinDatos);
      if (e.esPrivado) return const EventoResultado.error(_soloClientes);
    } else if (p == null) {
      return const EventoResultado.error(_sinCuenta);
    }
    if (_enviando) return const EventoResultado.error(_ocupado);
    if (cantidad < 1) return const EventoResultado.error('Elige al menos 1 ticket.');

    final disponibles = ticketsDisponibles;
    if (disponibles <= 0) return EventoResultado.error(mensajeTope);
    if (cantidad > disponibles) {
      return EventoResultado.error('Solo puedes comprar ${EventoFormato.tickets(disponibles)} más.');
    }

    return _conEnvio(() async {
      final generacion = _generacion;
      final r = _modoInvitado
          ? await repository.registrarCompraInvitado(eventoId: e.id, invitado: inv!, cantidad: cantidad, captura: captura)
          : await repository.registrarCompra(
              eventoId: e.id,
              clienteConductorId: p!.id,
              nroDocumento: p.documento,
              cantidad: cantidad,
              captura: captura,
            );
      if (generacion != _generacion) return const EventoResultado<EventoCompraModel>.error(_sesionCambio);

      if (r.isLeft) {
        final failure = r.left;
        if (failure is ValidationFailure) {
          // El servidor dijo que NO (tope excedido, evento vencido): el cupo que el app mostraba estaba desactualizado.
          await _refrescarActivo();
          return EventoResultado<EventoCompraModel>.error(failure.message);
        }
        // Red, tiempo agotado o error del servidor: la compra pudo haberse registrado igual y haberse perdido solo la respuesta.
        // Se deja la lista como está en el servidor y se avisa; reintentar a ciegas crearía otra compra.
        await _recargarComprasEnSilencio();
        await _refrescarActivo();
        return const EventoResultado<EventoCompraModel>.error(_compraIncierta, incierto: true);
      }

      final compra = r.right;
      _compras = [compra, ..._compras.where((c) => c.id != compra.id)];
      if (compra.ocupaCupo && compra.eventoId == e.id) _ajustarCupo(compra.cantidad);
      await _refrescarActivo();
      return EventoResultado.ok(compra);
    });
  }

  /// El PDF del ticket de una compra confirmada (lo arma el servidor). Con el mensaje del servidor si no se pudo.
  Future<EventoResultado<Uint8List>> descargarTicketPdf(int compraId) async {
    final p = _persona;
    final inv = _invitado;
    if (_modoInvitado) {
      if (inv == null || !inv.puedeConsultar) return const EventoResultado.error(_sinDatos);
    } else if (p == null) {
      return const EventoResultado.error(_sinCuenta);
    }

    try {
      final r = _modoInvitado
          ? await repository.descargarTicketPdfInvitado(compraId: compraId, nroDocumento: inv!.documento, telefono: inv.telefono)
          : await repository.descargarTicketPdf(compraId: compraId, clienteConductorId: p!.id, nroDocumento: p.documento);
      return r.isRight ? EventoResultado.ok(r.right) : EventoResultado.error(r.left.message);
    } catch (_) {
      return const EventoResultado.error(_inesperado);
    }
  }

  Future<EventoResultado<EventoCompraModel>> subirCaptura(int compraId, File captura) {
    if (_modoInvitado) {
      final inv = _invitado;
      return _accionSobreCompra(
        identificado: inv != null && inv.puedeConsultar,
        accion: () => repository.subirCapturaInvitado(
          compraId: compraId,
          nroDocumento: inv!.documento,
          telefono: inv.telefono,
          captura: captura,
        ),
      );
    }

    final p = _persona;
    return _accionSobreCompra(
      identificado: p != null,
      accion: () => repository.subirCaptura(
        compraId: compraId,
        clienteConductorId: p!.id,
        nroDocumento: p.documento,
        captura: captura,
      ),
    );
  }

  Future<EventoResultado<EventoCompraModel>> cancelarCompra(int compraId) {
    // Un invitado no cancela: su compra siempre se registra con la captura (el servidor ni lo ofrece).
    if (_modoInvitado) return Future.value(const EventoResultado.error(_invitadoNoCancela));

    final p = _persona;
    return _accionSobreCompra(
      identificado: p != null,
      accion: () => repository.cancelarCompra(
        compraId: compraId,
        clienteConductorId: p!.id,
        nroDocumento: p.documento,
      ),
    );
  }

  Future<EventoResultado<EventoCompraModel>> _accionSobreCompra({
    required bool identificado,
    required Future<Either<Failure, EventoCompraModel>> Function() accion,
  }) async {
    if (!identificado) return EventoResultado.error(_modoInvitado ? _sinDatos : _sinCuenta);
    if (_enviando) return const EventoResultado.error(_ocupado);

    return _conEnvio(() async {
      final generacion = _generacion;
      final r = await accion();
      if (generacion != _generacion) return const EventoResultado<EventoCompraModel>.error(_sesionCambio);

      if (r.isLeft) {
        // Si el servidor dijo que no (el personal ya la confirmó, rechazó o anuló) o no se supo cómo terminó, lo que el app
        // tenía de la compra puede estar viejo (p. ej. el botón de subir captura): se deja como está en el servidor.
        await _recargarComprasEnSilencio();
        await _refrescarActivo();
        return EventoResultado<EventoCompraModel>.error(r.left.message);
      }

      final compra = r.right;
      _reemplazarCompra(compra);
      // Cancelar libera cupo en el servidor: se vuelve a pedir para que «te quedan N» sea el de verdad.
      await _refrescarActivo();
      return EventoResultado.ok(compra);
    });
  }

  /// Marca «enviando» mientras dura la acción y lo suelta SIEMPRE, también si algo inesperado falla: un botón que se queda girando
  /// para siempre es peor que un mensaje de error.
  Future<EventoResultado<EventoCompraModel>> _conEnvio(
    Future<EventoResultado<EventoCompraModel>> Function() cuerpo,
  ) {
    return _conEnvioGenerico<EventoCompraModel>(cuerpo);
  }

  Future<EventoResultado<T>> _conEnvioGenerico<T>(Future<EventoResultado<T>> Function() cuerpo) async {
    final generacion = _generacion;
    _enviando = true;
    notifyListeners();
    try {
      return await cuerpo();
    } catch (_) {
      return const EventoResultado.error(_inesperado);
    } finally {
      // Si la sesión cambió, `limpiar` ya soltó la bandera y puede haber otra acción de otra persona en marcha.
      if (generacion == _generacion) {
        _enviando = false;
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------------------------------------------------------------
  // Mantener la lista y el cupo al día sin esperar al servidor

  void _reemplazarCompra(EventoCompraModel nueva) {
    final indice = _compras.indexWhere((c) => c.id == nueva.id);
    if (indice < 0) {
      _compras = [nueva, ..._compras];
      return;
    }
    final vieja = _compras[indice];
    final e = _evento;
    if (e != null && nueva.eventoId == e.id) {
      final antes = vieja.ocupaCupo ? vieja.cantidad : 0;
      final ahora = nueva.ocupaCupo ? nueva.cantidad : 0;
      _ajustarCupo(ahora - antes);
    }
    _compras = [..._compras]..[indice] = nueva;
  }

  /// `ocupados` > 0 toma cupo; < 0 lo libera. El tope por persona siempre es `max_tickets_por_persona`.
  void _ajustarCupo(int ocupados) {
    final e = _evento;
    final mis = e?.misTickets;
    if (e == null || mis == null || ocupados == 0) return;
    _evento = e.copyWith(misTickets: _cupo(e, math.max(0, mis.comprados + ocupados)));
  }

  /// Con la lista COMPLETA de compras (la que devuelve «mis-compras») el cupo sale de ella: es la regla del servidor.
  void _recalcularCupo() {
    final e = _evento;
    if (e == null) return;
    _evento = e.copyWith(misTickets: _cupo(e, _ticketsEnUso(e)));
  }

  MisTicketsModel _cupo(EventoModel e, int comprados) {
    return MisTicketsModel(
      comprados: comprados,
      disponibles: math.max(0, e.maxTicketsPorPersona - comprados),
    );
  }
}
