import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/yape_models.dart';
import '../../theme/app_theme.dart';
import '../components/yape_widgets.dart';
import '../providers/catalogos_provider.dart';

/// Pagar la inscripción con Yape: afiliar el Yape → aprobar en la app de Yape → cobro → comprobante.
///
/// El SERVIDOR decide en qué paso va el pago (`YapeInscripcionEstadoModel.paso`) y trae los montos y mensajes listos: esta pantalla solo
/// dibuja el paso que corresponde y nunca da por pagado nada por su cuenta. Mientras espera a Yape consulta cada pocos segundos y al
/// volver de la app de Yape; si la persona sale, el avance no se pierde (el servidor lo guarda) y se retoma desde «Estado de tu solicitud».
class ConductorYapePage extends StatefulWidget {
  const ConductorYapePage({
    super.key,
    required this.conductorId,
    required this.nroDocumento,
    this.telefonoInicial,
    this.alFinalizar,
    this.intervalo = const Duration(seconds: 4),
  });

  final int conductorId;

  /// Con el id identifica a la persona ante el servidor (viaja en el cuerpo, no en la URL).
  final String nroDocumento;

  /// Para no hacer escribir otra vez el celular: el que dio al registrarse (puede no ser su Yape; la persona lo confirma).
  final String? telefonoInicial;

  /// Qué hacer al terminar o salir: `pagada` dice si la inscripción quedó pagada. Sin esto, se cierra la pantalla devolviendo ese valor.
  final void Function(BuildContext context, bool pagada)? alFinalizar;

  /// Cada cuánto consulta el estado mientras espera la respuesta de Yape.
  final Duration intervalo;

  /// Cómo se abre el enlace de Yape. Se puede reemplazar en las pruebas.
  static Future<bool> Function(Uri) abridor = (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  State<ConductorYapePage> createState() => _ConductorYapePageState();
}

class _ConductorYapePageState extends State<ConductorYapePage> with WidgetsBindingObserver {
  static const Color _navy = Color(0xFF16233C);

  YapeInscripcionEstadoModel? _estado;
  bool _cargando = true;
  String? _errorCarga;

  /// Cuántas acciones (afiliar, cobrar) están en camino al servidor. Es un contador y no un bool porque el cobro sale solo apenas
  /// termina de afiliar: si lo pisara el `finally` de afiliar, el botón de pagar se reactivaría con el cobro en vuelo.
  int _trabajos = 0;
  bool get _trabajando => _trabajos > 0;

  /// Texto de la última acción que el servidor no pudo hacer (celular inválido, cobro en curso…).
  String? _aviso;

  /// La persona tocó «Afiliar y pagar» en esta pantalla: al aprobar en Yape el cobro sale solo (ya aceptó pagar ese monto).
  bool _vinoDeAfiliar = false;
  bool _cobroAutomaticoIntentado = false;
  bool _noAbrioYape = false;
  bool _consultando = false;

  bool _acepta = false;
  final _celularController = TextEditingController();

  Timer? _sondeo;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _celularController.text = _soloDigitos(widget.telefonoInicial ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sondeo?.cancel();
    _reloj?.cancel();
    _celularController.dispose();
    super.dispose();
  }

  /// Al volver de la app de Yape se consulta ya, sin esperar al siguiente intervalo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !_cargando) _cargar();
  }

  static String _soloDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

  String _texto(Object error) => error.toString().replaceFirst('Exception: ', '');

  Future<void> _cargar() async {
    if (_consultando) return;
    _consultando = true;
    try {
      final estado = await context.read<CatalogosProvider>().fetchYapeInscripcionEstado(
            clienteId: widget.conductorId,
            nroDocumento: widget.nroDocumento,
          );
      if (!mounted) return;
      _aplicar(estado);
    } catch (e) {
      if (!mounted) return;
      // Una consulta que falla mientras ya se tiene el estado no tira la pantalla: se reintenta en el siguiente intervalo.
      setState(() {
        _cargando = false;
        if (_estado == null) _errorCarga = _texto(e);
      });
    } finally {
      _consultando = false;
    }
  }

  void _aplicar(YapeInscripcionEstadoModel estado) {
    setState(() {
      _estado = estado;
      _cargando = false;
      _errorCarga = null;
    });
    _programarEspera();

    // Aprobó en Yape y venía de «Afiliar y pagar»: el cobro del monto que ya vio sale solo.
    if (_vinoDeAfiliar && estado.paso == YapeInscripcionEstadoModel.pasoCobrar && estado.cobro == null && !_cobroAutomaticoIntentado) {
      _cobroAutomaticoIntentado = true;
      _cobrar();
    }
  }

  /// Consulta periódica y cuenta regresiva solo mientras se espera a Yape.
  void _programarEspera() {
    final esperando = _estado?.esperando ?? false;
    if (esperando) {
      _sondeo ??= Timer.periodic(widget.intervalo, (_) => _cargar());
    } else {
      _sondeo?.cancel();
      _sondeo = null;
    }

    if (_estado?.paso == YapeInscripcionEstadoModel.pasoAprobarEnYape) {
      _reloj ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _reloj?.cancel();
      _reloj = null;
    }
  }

  Future<void> _afiliar() async {
    final celular = _soloDigitos(_celularController.text);
    if (!RegExp(r'^9\d{8}$').hasMatch(celular)) {
      _avisarError('Ingresa el celular de tu Yape: 9 dígitos que empiezan con 9.');
      return;
    }
    if (!_acepta) {
      _avisarError('Debes aceptar la autorización para afiliar tu Yape.');
      return;
    }

    setState(() {
      _trabajos++;
      _aviso = null;
      _noAbrioYape = false;
    });
    try {
      final estado = await context.read<CatalogosProvider>().afiliarYapeInscripcion(
            clienteId: widget.conductorId,
            nroDocumento: widget.nroDocumento,
            celular: celular,
          );
      if (!mounted) return;
      _vinoDeAfiliar = true;
      _cobroAutomaticoIntentado = false;
      _aplicar(estado);
    } catch (e) {
      if (!mounted) return;
      setState(() => _aviso = _texto(e));
      await _cargar();
    } finally {
      if (mounted) setState(() => _trabajos--);
    }
  }

  Future<void> _cobrar() async {
    setState(() {
      _trabajos++;
      _aviso = null;
    });
    try {
      final estado = await context.read<CatalogosProvider>().cobrarYapeInscripcion(
            clienteId: widget.conductorId,
            nroDocumento: widget.nroDocumento,
          );
      if (!mounted) return;
      _aplicar(estado);
    } catch (e) {
      if (!mounted) return;
      setState(() => _aviso = _texto(e));
      await _cargar();
    } finally {
      if (mounted) setState(() => _trabajos--);
    }
  }

  Future<void> _abrirYape() async {
    final enlace = _estado?.afiliacion?.link;
    final uri = enlace == null ? null : Uri.tryParse(enlace);
    if (uri == null) {
      setState(() => _aviso = 'No recibimos el enlace de Yape. Toca «Ya aprobé, revisar» o vuelve a intentarlo en un momento.');
      return;
    }

    var abierto = false;
    try {
      abierto = await ConductorYapePage.abridor(uri);
    } catch (_) {
      abierto = false;
    }
    if (mounted) setState(() => _noAbrioYape = !abierto);
  }

  void _avisarError(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _salir() {
    final pagada = _estado?.pagada ?? false;
    final alFinalizar = widget.alFinalizar;
    if (alFinalizar != null) {
      alFinalizar(context, pagada);
    } else {
      Navigator.of(context).pop(pagada);
    }
  }

  // ---------------------------------------------------------------------------------------------------------------- pantalla

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _salir();
      },
      child: Scaffold(
        backgroundColor: AppTheme.brandYellow,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('yape_atras'),
                      onPressed: _salir,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
                    ),
                    const Expanded(
                      child: Text(
                        'Paga con Yape',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _contenido(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    final estado = _estado;
    if (estado == null) {
      return _tarjeta(
        key: const Key('yape_error'),
        hijos: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(_errorCarga ?? 'No pudimos consultar tu pago con Yape.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          _boton(texto: 'Reintentar', onTap: _cargar, clave: const Key('yape_btn_reintentar')),
        ],
      );
    }

    // Cobrando ahora mismo (el cobro sale apenas se aprueba en Yape): se ve igual que «procesando», sin esperar a que el servidor conteste.
    if (_trabajando && estado.paso == YapeInscripcionEstadoModel.pasoCobrar) return _procesando(estado);

    switch (estado.paso) {
      case YapeInscripcionEstadoModel.pasoPagada:
        return _pagada(estado);
      case YapeInscripcionEstadoModel.pasoProcesando:
        return _procesando(estado);
      case YapeInscripcionEstadoModel.pasoCobrar:
        return _cobrarPaso(estado);
      case YapeInscripcionEstadoModel.pasoAprobarEnYape:
        return _aprobar(estado);
      case YapeInscripcionEstadoModel.pasoAfiliar:
        return _afiliarPaso(estado);
      default:
        return _noDisponible(estado);
    }
  }

  // Paso: afiliar ------------------------------------------------------------------------------------------------------------

  Widget _afiliarPaso(YapeInscripcionEstadoModel estado) {
    final detalle = estado.tieneRecargo
        ? 'Inscripción a Arequipa Go (${soles(estado.monto)} + ${soles(estado.recargo)})'
        : 'Inscripción a Arequipa Go';

    return Column(
      key: const Key('yape_paso_afiliar'),
      children: [
        _cabeceraYape('Afilia tu Yape para pagar'),
        const SizedBox(height: 14),
        if (_aviso != null || estado.mensaje != null) ...[
          _nota(_aviso ?? estado.mensaje!, color: Colors.red, clave: const Key('yape_aviso')),
          const SizedBox(height: 12),
        ],
        _tarjeta(
          hijos: [
            TextField(
              key: const Key('yape_celular'),
              controller: _celularController,
              keyboardType: TextInputType.phone,
              // Solo dígitos y 9 como máximo: un número pegado con espacios («987 654 321») queda completo, no cortado.
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Celular con Yape',
                counterText: '',
                prefixIcon: const Padding(padding: EdgeInsets.all(10), child: YapeLogo(tamano: 24)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            _montoCaja(titulo: 'Hoy se cobrará', monto: estado.total, detalle: detalle),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  key: const Key('yape_acepta'),
                  value: _acepta,
                  activeColor: Colors.black,
                  onChanged: (v) => setState(() => _acepta = v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                        children: [
                          const TextSpan(text: 'Autorizo a Arequipa Go a cobrar de mi Yape los pagos que yo confirme. '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              key: const Key('yape_ver_autorizacion'),
                              onTap: () => mostrarAutorizacionYape(context),
                              child: const Text(
                                'Ver autorización completa',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _boton(
              texto: 'Afiliar y pagar ${soles(estado.total)}',
              onTap: _trabajando ? null : _afiliar,
              cargando: _trabajando,
              clave: const Key('yape_btn_afiliar'),
            ),
            const SizedBox(height: 10),
            Text(
              'Se abrirá Yape para que apruebes. Tienes 15 minutos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _pagarDespues(),
      ],
    );
  }

  // Paso: aprobar en Yape ----------------------------------------------------------------------------------------------------

  Widget _aprobar(YapeInscripcionEstadoModel estado) {
    final restante = estado.afiliacion?.expiraAt?.difference(DateTime.now());
    final vencido = restante != null && restante <= Duration.zero;

    return Column(
      key: const Key('yape_paso_aprobar'),
      children: [
        _cabeceraYape('Vamos a abrir Yape para que apruebes'),
        const SizedBox(height: 14),
        if (_aviso != null) ...[
          _nota(_aviso!, color: Colors.red, clave: const Key('yape_aviso')),
          const SizedBox(height: 12),
        ],
        _tarjeta(
          hijos: [
            _pasoNumerado(1, 'Se abre la app de Yape.'),
            _pasoNumerado(2, 'Revisa que el comercio sea AREQUIPA GO.'),
            _pasoNumerado(3, 'Aprueba con tu clave o huella.'),
            _pasoNumerado(4, 'Vuelve a esta app: te esperamos aquí.'),
            const SizedBox(height: 14),
            _boton(texto: 'Abrir Yape', onTap: _abrirYape, icono: Icons.open_in_new_rounded, clave: const Key('yape_btn_abrir')),
            if (_noAbrioYape) ...[
              const SizedBox(height: 12),
              _nota(
                'No encontramos Yape en este celular. Instala la app de Yape e inténtalo de nuevo, o paga de otra forma.',
                color: Colors.orange,
                clave: const Key('yape_no_instalado'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _tarjeta(
          hijos: [
            if (restante != null)
              Text(
                vencido ? '00:00' : _mmss(restante),
                key: const Key('yape_cuenta_regresiva'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            const SizedBox(height: 4),
            const Text('Esperando tu aprobación en Yape…', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              vencido
                  ? 'Se acabó el tiempo para aprobar. Toca «Ya aprobé, revisar»: si venció, podrás generar una nueva.'
                  : 'Apruébala dentro de los próximos 15 minutos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            _chip('Afiliación: pendiente'),
            const SizedBox(height: 14),
            _boton(texto: 'Ya aprobé, revisar', onTap: _cargar, primario: false, clave: const Key('yape_btn_revisar')),
          ],
        ),
        const SizedBox(height: 8),
        _pagarDespues(),
      ],
    );
  }

  // Paso: cobrar -------------------------------------------------------------------------------------------------------------

  Widget _cobrarPaso(YapeInscripcionEstadoModel estado) {
    final fallo = estado.cobro != null ? estado.cobro!.mensaje ?? estado.mensaje : null;
    final reintento = estado.cobro != null;

    return Column(
      key: const Key('yape_paso_cobrar'),
      children: [
        _cabeceraYape(reintento ? 'No pudimos cobrar tu inscripción' : '¡Tu Yape quedó afiliado!'),
        const SizedBox(height: 14),
        if (_aviso != null || fallo != null) ...[
          _nota(_aviso ?? fallo!, color: Colors.red, clave: const Key('yape_aviso')),
          const SizedBox(height: 12),
        ],
        _tarjeta(
          hijos: [
            if (estado.afiliacion?.celular != null)
              Text('Celular ${estado.afiliacion!.celular} · Yape', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            _filaMonto('Inscripción', estado.monto),
            if (estado.tieneRecargo) _filaMonto('Costo por usar Yape', estado.recargo),
            const Divider(height: 22),
            _filaMonto('Se cobrará', estado.total, fuerte: true),
            const SizedBox(height: 6),
            Text(
              'Se cobrará de tu Yape${estado.afiliacion?.celular != null ? ' ${estado.afiliacion!.celular}' : ''}. Verás el cobro en tu app de Yape.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            _boton(
              texto: reintento ? 'Reintentar con Yape' : 'Confirmar y pagar',
              onTap: _trabajando ? null : _cobrar,
              cargando: _trabajando,
              clave: const Key('yape_btn_cobrar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _pagarDespues(),
      ],
    );
  }

  // Paso: procesando ---------------------------------------------------------------------------------------------------------

  Widget _procesando(YapeInscripcionEstadoModel estado) {
    return Column(
      key: const Key('yape_paso_procesando'),
      children: [
        _cabeceraYape('Cobrando… ${soles(estado.total)}'),
        const SizedBox(height: 14),
        _tarjeta(
          hijos: [
            const SizedBox(height: 4),
            const Center(child: CircularProgressIndicator(color: Colors.black)),
            const SizedBox(height: 16),
            const Text(
              'Estamos cobrando tu inscripción. Verás el movimiento en tu app de Yape. No cierres esta pantalla.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600),
            ),
            if (estado.mensaje != null) ...[
              const SizedBox(height: 8),
              Text(estado.mensaje!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 8),
            Text(
              'Si tarda más de 2 minutos, puedes salir: el pago se registrará solo cuando Yape responda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('yape_btn_salir'),
          onPressed: _salir,
          child: const Text('Salir y seguir después', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // Paso: pagada -------------------------------------------------------------------------------------------------------------

  Widget _pagada(YapeInscripcionEstadoModel estado) {
    final cobro = estado.cobro;
    final celular = estado.afiliacion?.celular;

    return Column(
      key: const Key('yape_paso_pagada'),
      children: [
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF22C55E), width: 5),
          ),
          child: const Icon(Icons.check_rounded, size: 56, color: Color(0xFF22C55E)),
        ),
        const SizedBox(height: 18),
        const Text('¡Pago exitoso!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        _tarjeta(
          hijos: [
            _filaTexto('Concepto', 'Inscripción'),
            _filaTexto('Medio', celular != null ? 'Yape $celular' : 'Yape'),
            const Divider(height: 22),
            _filaMonto('Total pagado', cobro?.monto ?? estado.total, fuerte: true),
            const SizedBox(height: 10),
            const Text(
              'Tu inscripción quedó pagada. Seguimos revisando tu solicitud.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _boton(texto: 'Continuar', onTap: _salir, clave: const Key('yape_btn_continuar')),
      ],
    );
  }

  // Paso: no disponible ------------------------------------------------------------------------------------------------------

  Widget _noDisponible(YapeInscripcionEstadoModel estado) {
    return _tarjeta(
      key: const Key('yape_paso_no_disponible'),
      hijos: [
        const YapeLogo(tamano: 44),
        const SizedBox(height: 12),
        const Text('Pagar con Yape no está disponible', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          estado.mensaje ?? 'Por el momento no se puede pagar con Yape. Puedes pagar con otro método cuando tu solicitud sea aprobada.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 16),
        _boton(texto: 'Volver', onTap: _salir, clave: const Key('yape_btn_volver')),
      ],
    );
  }

  // Piezas -------------------------------------------------------------------------------------------------------------------

  Widget _cabeceraYape(String titulo) {
    return Row(
      children: [
        const YapeLogo(tamano: 36),
        const SizedBox(width: 12),
        Expanded(child: Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black))),
      ],
    );
  }

  Widget _tarjeta({Key? key, required List<Widget> hijos}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: hijos),
    );
  }

  Widget _montoCaja({required String titulo, required double monto, required String detalle}) {
    return Container(
      key: const Key('yape_monto'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(detalle, style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(soles(monto), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _filaMonto(String etiqueta, double monto, {bool fuerte = false}) {
    final estilo = TextStyle(fontSize: fuerte ? 16 : 14, fontWeight: fuerte ? FontWeight.bold : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(etiqueta, style: estilo), Text(soles(monto), style: estilo)],
      ),
    );
  }

  Widget _filaTexto(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _pasoNumerado(int numero, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: colorYape,
            child: Text('$numero', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _chip(String texto) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(20)),
        child: Text(texto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
      ),
    );
  }

  Widget _nota(String texto, {required MaterialColor color, Key? clave}) {
    return Container(
      key: clave,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Text(texto, style: TextStyle(fontSize: 13, color: color.shade800)),
    );
  }

  Widget _boton({required String texto, required VoidCallback? onTap, Key? clave, IconData? icono, bool primario = true, bool cargando = false}) {
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final contenido = cargando
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icono != null) ...[Icon(icono, size: 20), const SizedBox(width: 8)],
              Flexible(child: Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: primario
          ? ElevatedButton(
              key: clave,
              onPressed: onTap,
              style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white, elevation: 0, shape: forma),
              child: contenido,
            )
          : OutlinedButton(
              key: clave,
              onPressed: onTap,
              style: OutlinedButton.styleFrom(foregroundColor: _navy, side: const BorderSide(color: _navy, width: 1.6), shape: forma),
              child: contenido,
            ),
    );
  }

  Widget _pagarDespues() {
    return TextButton(
      key: const Key('yape_btn_despues'),
      onPressed: _salir,
      child: const Text('Pagar después', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }

  String _mmss(Duration d) {
    final minutos = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }
}
