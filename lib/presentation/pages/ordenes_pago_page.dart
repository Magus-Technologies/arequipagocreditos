import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/orden_pago_entity.dart';
import '../../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/ordenes_pago_provider.dart';
import 'pdf_viewer_page.dart';

/// "Mis órdenes de pago" — los códigos con los que la persona paga en Caja
/// Arequipa.
///
/// Los códigos temporales vencen a las 24h y los permanentes no vencen nunca.
/// La vista no muestra nada de vigencia cuando el código es permanente.
class OrdenesPagoPage extends StatefulWidget {
  const OrdenesPagoPage({super.key});

  @override
  State<OrdenesPagoPage> createState() => _OrdenesPagoPageState();
}

class _OrdenesPagoPageState extends State<OrdenesPagoPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());

    // Los contadores se recalculan contra `fecha_expiracion`, que es absoluta,
    // así que basta con repintar cada minuto mientras la pantalla esté abierta.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int? get _clienteId =>
      context.read<AuthProvider>().currentUser?.idConductor;

  Future<void> _cargar({bool? incluirHistorial}) async {
    final id = _clienteId;
    if (id == null) return;
    await context
        .read<OrdenesPagoProvider>()
        .cargar(clienteId: id, incluirHistorial: incluirHistorial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: AppTheme.brandYellow,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Mis órdenes de pago',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<OrdenesPagoProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.ordenes.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.hasError && provider.ordenes.isEmpty) {
              return _buildError(provider.errorMessage);
            }

            return RefreshIndicator(
              onRefresh: () => _cargar(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (provider.porVencer > 0) _buildAvisoPorVencer(provider),
                  if (provider.activas.isEmpty && !provider.incluirHistorial)
                    _buildVacio()
                  else
                    ...provider.activas.map(_buildOrdenCard),
                  const SizedBox(height: 8),
                  _buildDondePagar(),
                  const SizedBox(height: 16),
                  _buildToggleHistorial(provider),
                  if (provider.incluirHistorial) ...[
                    const SizedBox(height: 12),
                    if (provider.historial.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No hay órdenes anteriores.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    else
                      ...provider.historial.map(_buildOrdenCard),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ====================== Tarjeta de una orden ======================

  /// Ícono que identifica de un vistazo qué se está pagando.
  IconData _iconoTipo(int tipoPagoId) {
    switch (tipoPagoId) {
      case 2:
        return Icons.how_to_reg_rounded;
      case 3:
        return Icons.shopping_bag_outlined;
      case 4:
        return Icons.directions_car_filled_outlined;
      case 5:
        return Icons.warning_amber_rounded;
      case 6:
        return Icons.gavel_rounded;
      case 7:
        return Icons.savings_outlined;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Widget _buildOrdenCard(OrdenPagoEntity orden) {
    final expirada = orden.expirada();
    final porVencer = orden.porVencer();
    final inactiva = !orden.pagable;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: porVencer && !expirada
              ? Colors.orange.shade300
              : Colors.grey.shade200,
          width: porVencer && !expirada ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Encabezado: qué se paga, cuánto, y en qué estado está.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: inactiva
                        ? Colors.grey.shade100
                        : AppTheme.primary.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconoTipo(orden.tipoPagoId),
                    size: 21,
                    color: inactiva ? Colors.grey.shade500 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orden.concepto,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color:
                              inactiva ? Colors.grey.shade600 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${orden.moneda} ${orden.monto.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                          color: inactiva ? Colors.grey.shade500 : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildEstadoBadge(orden),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCodigo(orden, inactiva),
          ),
          if (expirada && !orden.estaPagada)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 17, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este código venció. Comunícate con CREDIGO para obtener uno nuevo.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Pie: vigencia a la izquierda, voucher a la derecha.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
            child: Row(
              children: [
                Expanded(child: _buildVigencia(orden)),
                if (orden.voucherUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _abrirVoucher(orden),
                    icon: const Icon(Icons.description_outlined, size: 17),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF16233C),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    label: const Text(
                      'Voucher',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// El código es el dato principal de la pantalla: grande y fácil de copiar.
  Widget _buildCodigo(OrdenPagoEntity orden, bool inactiva) {
    return InkWell(
      onTap: inactiva ? null : () => _copiar(orden.codigo),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: inactiva
              ? Colors.grey.shade100
              : AppTheme.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: inactiva
                ? Colors.grey.shade300
                : AppTheme.primary.withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CÓDIGO DE PAGO',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: inactiva
                          ? Colors.grey.shade500
                          : Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    orden.codigo,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      height: 1.15,
                      color: inactiva ? Colors.grey.shade500 : Colors.black,
                      decoration: inactiva ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
            if (!inactiva)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.copy_rounded,
                    size: 17, color: Colors.black87),
              ),
          ],
        ),
      ),
    );
  }

  /// Vigencia del código. Los permanentes no muestran contador: se usan durante
  /// todo el contrato y un "vence" sería mentira.
  Widget _buildVigencia(OrdenPagoEntity orden) {
    if (orden.esPermanente) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.all_inclusive_rounded,
                size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 5),
            Text(
              'Código permanente',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final restante = orden.restante();
    if (restante == null || restante == Duration.zero) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Código vencido',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
      );
    }

    final urgente = restante.inHours < 6;
    final fg = urgente ? Colors.orange.shade900 : Colors.grey.shade700;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: urgente ? Colors.orange.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(
              'Vence en ${_formatearRestante(restante)}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: urgente ? FontWeight.bold : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(OrdenPagoEntity orden) {
    final Color bg;
    final Color fg;
    final String texto;

    if (orden.estaPagada) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      texto = 'Pagado';
    } else if (orden.expirada() || orden.estado == 'vencida') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      texto = 'Vencido';
    } else if (orden.estaAnulada) {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
      texto = 'Anulado';
    } else if (!orden.pagable) {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
      texto = 'En revisión';
    } else {
      bg = AppTheme.primary.withValues(alpha: 0.3);
      fg = Colors.brown.shade800;
      texto = 'Por pagar';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  // ====================== Secciones auxiliares ======================

  Widget _buildAvisoPorVencer(OrdenesPagoProvider provider) {
    final n = provider.porVencer;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 20, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              n == 1
                  ? 'Tienes 1 código a punto de vencer'
                  : 'Tienes $n códigos a punto de vencer',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDondePagar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              const Text(
                '¿Dónde pago?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Usa tu código en agencias de Caja Arequipa, cajeros, banca móvil o web, '
            'y agentes corresponsales. Indica que el pago es para CREDIGO.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleHistorial(OrdenesPagoProvider provider) {
    return Center(
      child: TextButton.icon(
        onPressed: provider.isLoading
            ? null
            : () => _cargar(incluirHistorial: !provider.incluirHistorial),
        icon: Icon(
          provider.incluirHistorial
              ? Icons.expand_less
              : Icons.history,
          size: 18,
        ),
        style: TextButton.styleFrom(foregroundColor: Colors.black87),
        label: Text(
          provider.incluirHistorial ? 'Ocultar historial' : 'Ver historial',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No tienes órdenes de pago',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando tengas un pago pendiente, acá verás el código para pagarlo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              mensaje.isEmpty
                  ? 'No pudimos cargar tus órdenes de pago.'
                  : mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _cargar(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== Acciones ======================

  void _copiar(String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado al portapapeles'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _abrirVoucher(OrdenPagoEntity orden) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          title: orden.concepto,
          pdfUrl: orden.voucherUrl,
        ),
      ),
    );
  }

  String _formatearRestante(Duration d) {
    if (d.inHours >= 1) {
      final horas = d.inHours;
      final minutos = d.inMinutes % 60;
      return minutos > 0 ? '${horas}h ${minutos}min' : '${horas}h';
    }
    return '${d.inMinutes} min';
  }
}
