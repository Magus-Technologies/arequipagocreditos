import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/conductor_estado_model.dart';
import '../../theme/app_theme.dart';
import '../providers/catalogos_provider.dart';
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
      logoAsset: 'images/logo_izipay.webp',
      esSvg: false,
      disponible: false,
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
      backgroundColor: AppTheme.primary,
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

  Widget _buildPendiente() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.hourglass_top, color: Colors.orange.shade800, size: 48),
        ),
        const SizedBox(height: 24),
        const Text(
          'Tu solicitud sigue en revisión',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 24),
        _buildCard(
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Estado de tu solicitud',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  _buildEstadoBadge('En revisión', Colors.orange.shade50, Colors.orange.shade800),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tiempo estimado de revisión: 30 minutos a 2 horas',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Desliza hacia abajo para actualizar el estado.',
          style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
        ),
        TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh, size: 18, color: Colors.black87),
          label: const Text(
            'Actualizar',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildRechazado(ConductorEstadoModel estado) {
    final motivo = estado.motivoRechazo;
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.close, color: Colors.red.shade700, size: 48),
        ),
        const SizedBox(height: 24),
        const Text(
          'Tu solicitud fue rechazada',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 24),
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
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 56),
        ),
        const SizedBox(height: 24),
        const Text(
          '¡Tu solicitud fue aprobada!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ya puedes realizar el pago de inscripción para activar tu cuenta.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black87),
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

  Widget _buildMetodoPagoCard(_MetodoPagoInscripcion metodo, ConductorEstadoModel estado) {
    final Widget card = InkWell(
      onTap: () {
        if (!metodo.disponible) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este método estará disponible próximamente'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConductorOrdenPagoPage(estado: estado),
          ),
        );
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
            const Icon(Icons.chevron_right, color: Colors.black45),
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
