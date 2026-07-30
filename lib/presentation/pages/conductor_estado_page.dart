import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/conductor_estado_model.dart';
import '../../theme/app_theme.dart';
import '../providers/catalogos_provider.dart';
import 'conductor_izipay_page.dart';
import 'conductor_orden_pago_page.dart';

class ConductorEstadoPage extends StatefulWidget {
  final int? conductorId;

  const ConductorEstadoPage({super.key, this.conductorId});

  @override
  State<ConductorEstadoPage> createState() => _ConductorEstadoPageState();
}

class _ConductorEstadoPageState extends State<ConductorEstadoPage> {
  bool _loading = true;
  String? _error;
  ConductorEstadoModel? _estado;
  bool _generandoOrden = false;

  static const List<_MetodoPagoInscripcion> _metodosPagoInscripcion = [
    _MetodoPagoInscripcion(
      id: 'caja_arequipa',
      titulo: 'Caja Arequipa',
      subtitulo: 'Genera tu código de pago y realiza el depósito en cualquier agencia o agente Caja Arequipa.',
      logoAsset: 'images/logo_caja_arequipa.svg',
      esSvg: true,
      disponible: true,
    ),
    _MetodoPagoInscripcion(
      id: 'izipay_qr',
      titulo: 'QR Izi Pay',
      subtitulo: 'Paga de forma rápida y segura escaneando el código QR con IziPay.',
      logoAsset: 'images/logo_izipay.svg',
      esSvg: true,
      disponible: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final catalogos = context.read<CatalogosProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });

    int? id = widget.conductorId;
    if (id == null) {
      final prefs = await SharedPreferences.getInstance();
      id = prefs.getInt(AppConstants.conductorPreRegistroIdKey);
    }

    if (id == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No encontramos tu solicitud en este dispositivo.';
        });
      }
      return;
    }

    try {
      final estado = await catalogos.fetchConductorEstado(id);
      if (mounted) {
        setState(() {
          _estado = estado;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No se pudo consultar el estado. Revisa tu conexión e inténtalo de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandYellow,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
                  ),
                  const Expanded(
                    child: Text(
                      'Estado de tu solicitud',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            SvgPicture.asset('images/credigo_logo.svg', height: 48),
            const SizedBox(height: 4),
            const Text(
              'así fácil, así de rápido, así de go',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: Colors.black,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(30, 8, 30, 24),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }
    if (_error != null) {
      return _buildCard(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    switch (_estado!.estadoAprobacion) {
      case 'aprobado':
        return _buildAprobado(_estado!);
      case 'rechazado':
        return _buildRechazado(_estado!);
      default:
        return _buildPendiente();
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildEstadoBadge(String texto, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: foreground),
      ),
    );
  }

  /// Aro blanco con borde de color y el ícono del estado adentro.
  ///
  /// Es el mismo tratamiento que usa la pantalla de "solicitud enviada": la
  /// persona viene de ahí, así que reconoce la figura y solo cambia el color.
  Widget _buildIconoEstado(IconData icono, Color color) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 5),
      ),
      child: Center(child: Icon(icono, size: 60, color: color)),
    );
  }

  /// Fila de la tarjeta de estado: ícono en círculo amarillo + contenido.
  Widget _buildFilaInfo({required Widget icono, required Widget contenido}) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.28),
            shape: BoxShape.circle,
          ),
          child: Center(child: icono),
        ),
        const SizedBox(width: 14),
        Expanded(child: contenido),
      ],
    );
  }

  Widget _buildPendiente() {
    const ambar = Color(0xFFF59E0B);

    return Column(
      children: [
        const SizedBox(height: 8),
        _buildIconoEstado(Icons.hourglass_top_rounded, ambar),
        const SizedBox(height: 22),
        const Text(
          'Tu solicitud está\nen revisión',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Un asesor está validando tu información.\nTe avisaremos apenas tengamos el resultado.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _buildFilaInfo(
                  icono: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 21, color: Colors.grey.shade800),
                      const Positioned(
                        right: 1,
                        bottom: 1,
                        child: CircleAvatar(
                          radius: 6.5,
                          backgroundColor: ambar,
                          child: Icon(Icons.schedule_rounded,
                              size: 9, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  contenido: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado de tu solicitud',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 13, color: Color(0xFFB45309)),
                            const SizedBox(width: 5),
                            Text(
                              'En revisión',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _buildFilaInfo(
                  icono: Icon(Icons.schedule_rounded,
                      size: 21, color: Colors.grey.shade800),
                  contenido: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiempo estimado de revisión:',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '30 minutos a 2 horas.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16233C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            label: const Text(
              'Actualizar estado',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'También puedes deslizar hacia abajo para actualizar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildRechazado(ConductorEstadoModel estado) {
    final motivo = estado.motivoRechazo;
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildIconoEstado(Icons.close_rounded, const Color(0xFFDC2626)),
        const SizedBox(height: 22),
        const Text(
          'Tu solicitud\nfue rechazada',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 22),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (motivo != null && motivo.isNotEmpty) ...[
                const Text(
                  'Motivo:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  motivo,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const Divider(height: 24),
              ],
              Row(
                children: [
                  const Icon(Icons.support_agent, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Si tienes dudas, comunícate con nuestra oficina para más información.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAprobado(ConductorEstadoModel estado) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildIconoEstado(Icons.check_rounded, const Color(0xFF22C55E)),
        const SizedBox(height: 22),
        const Text(
          '¡Tu solicitud\nfue aprobada!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ya puedes realizar el pago de inscripción\npara activar tu cuenta.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Selecciona tu método de pago',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Elige la opción que prefieras para completar tu inscripción.',
            style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
          ),
        ),
        const SizedBox(height: 16),
        for (final metodo in _metodosPagoInscripcion) ...[
          _buildMetodoPagoCard(metodo, estado),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 16, color: Colors.black54),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Pago 100% seguro — Tu información y pago están protegidos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Bloque de monto del diálogo de confirmación.
  ///
  /// En financiado se muestra lo que paga AHORA (la primera cuota impaga) y no
  /// el total: es la cifra que va a entregar en ventanilla.
  Widget _buildMontoConfirmacion(ConductorEstadoModel estado) {
    final pago = estado.pagoInscripcion;
    if (pago == null) return const SizedBox.shrink();

    final bool esFinanciado = pago.tipoPago == 'financiado';
    CuotaInscripcionModel? proxima;
    if (esFinanciado) {
      for (final c in pago.cuotas) {
        final e = c.estado.toLowerCase();
        if (e != 'pagado' && e != 'pagada') {
          proxima = c;
          break;
        }
      }
    }

    final double monto = proxima?.monto ?? pago.montoTotal;
    final String etiqueta = proxima != null
        ? 'Monto de la cuota ${proxima.numero}'
        : 'Monto a pagar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 2),
          Text(
            'S/ ${monto.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (esFinanciado) ...[
            const SizedBox(height: 4),
            Text(
              'Plan de ${pago.cuotas.length} cuotas · Total S/ ${pago.montoTotal.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  /// Avisa el monto y la vigencia antes de emitir el código.
  Future<bool> _confirmarGeneracion(ConductorEstadoModel estado) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.28),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.confirmation_number_outlined,
                  size: 22, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Generar tu código de pago',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Con este código pagas tu inscripción en cualquier agencia, '
              'agente, cajero o banca móvil de Caja Arequipa.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 14),
            _buildMontoConfirmacion(estado),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 20, color: Colors.orange.shade800),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'El código vence en 24 horas. Genéralo cuando ya vayas a pagar.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text(
              'Ahora no',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16233C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Generar código',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return resultado ?? false;
  }

  /// Pide el código de Caja Arequipa y recién ahí abre la orden.
  ///
  /// El código se emite en este momento —no al aprobar— porque vence a las 24h:
  /// el reloj tiene que arrancar cuando la persona decide ir a pagar. Si ya
  /// tenía uno vigente, el backend devuelve ese mismo.
  Future<void> _abrirCajaArequipa(ConductorEstadoModel estado) async {
    final catalogos = context.read<CatalogosProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final id = estado.id;

    // Con código ya emitido no hace falta volver a pedirlo.
    if (estado.ordenPago != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ConductorOrdenPagoPage(estado: estado),
        ),
      );
      return;
    }

    // El código dura 24h y después hay que esperar 72h para pedir otro, así que
    // no se emite por un tap exploratorio: la persona confirma que va a pagar.
    final confirmado = await _confirmarGeneracion(estado);
    if (!confirmado || !mounted) return;

    setState(() => _generandoOrden = true);

    try {
      final actualizado = await catalogos.generarOrdenCajaArequipa(id);
      if (!mounted) return;

      setState(() {
        _estado = actualizado;
        _generandoOrden = false;
      });

      navigator.push(
        MaterialPageRoute(
          builder: (context) => ConductorOrdenPagoPage(estado: actualizado),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _generandoOrden = false);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildMetodoPagoCard(_MetodoPagoInscripcion metodo, ConductorEstadoModel estado) {
    final bool esperando = _generandoOrden && metodo.id == 'caja_arequipa';

    final Widget card = InkWell(
      onTap: _generandoOrden
          ? null
          : () {
        if (!metodo.disponible) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este método estará disponible próximamente'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        if (metodo.id == 'izipay_qr') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConductorIzipayPage(estado: estado),
            ),
          );
          return;
        }

        _abrirCajaArequipa(estado);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 28,
              child: metodo.esSvg
                  ? SvgPicture.asset(metodo.logoAsset, fit: BoxFit.contain)
                  : Image.asset(metodo.logoAsset, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        metodo.titulo,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      if (!metodo.disponible) ...[
                        const SizedBox(width: 8),
                        _buildEstadoBadge('Próximamente', Colors.grey.shade200, Colors.grey.shade700),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metodo.subtitulo,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            esperando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black45,
                    ),
                  )
                : const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );

    return metodo.disponible ? card : Opacity(opacity: 0.55, child: card);
  }

}

class _MetodoPagoInscripcion {
  final String id;
  final String titulo;
  final String subtitulo;
  final String logoAsset;
  final bool esSvg;
  final bool disponible;

  const _MetodoPagoInscripcion({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.logoAsset,
    required this.esSvg,
    required this.disponible,
  });
}
