import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/domain/entities/financiamiento_entity.dart';
import 'package:arequipagocreditos/presentation/pages/financiamiento_detalle_page.dart';
import 'package:arequipagocreditos/presentation/providers/financiamiento_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExpandableFinanciamientos extends StatefulWidget {
  final ConductorModel conductor;

  const ExpandableFinanciamientos({super.key, required this.conductor});

  @override
  State<ExpandableFinanciamientos> createState() =>
      _ExpandableFinanciamientosState();
}

class _ExpandableFinanciamientosState
    extends State<ExpandableFinanciamientos> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinanciamientos();
    });
  }

  Future<void> _loadFinanciamientos() async {
    final provider =
        Provider.of<FinanciamientoProvider>(context, listen: false);
    await provider.loadFinanciamientos(
      idConductor: widget.conductor.idConductor,
      tipo: widget.conductor.tipo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanciamientoProvider>(
      builder: (context, provider, _) {
        final financiamientos = provider.financiamientos;
        final total = financiamientos.length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.08 * 255).toInt()),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: _isExpanded
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          )
                        : BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mis Financiamientos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              provider.isLoading
                                  ? 'Cargando...'
                                  : total == 0
                                      ? 'Sin créditos activos'
                                      : '$total crédito${total > 1 ? 's' : ''} activo${total > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      // Badge contador (siempre visible)
                      if (!provider.isLoading && total > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withAlpha((0.25 * 255).toInt()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$total',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      // Icono expand/collapse
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            Icons.expand_more,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Lista expandible ─────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                child: _isExpanded
                    ? _buildList(provider, financiamientos, total)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(
    FinanciamientoProvider provider,
    List<FinanciamientoEntity> financiamientos,
    int total,
  ) {
    // Loading
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error
    if (provider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Error al cargar financiamientos',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadFinanciamientos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Vacío
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No tienes financiamientos activos',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Lista de items
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < financiamientos.length; i++) ...[
            _FinanciamientoRow(
              financiamiento: financiamientos[i],
              onRefresh: _loadFinanciamientos,
            ),
            if (i < financiamientos.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade100,
                indent: 16,
                endIndent: 16,
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Fila individual (sin card extra) ──────────────────────────────────────────
class _FinanciamientoRow extends StatelessWidget {
  final FinanciamientoEntity financiamiento;
  final VoidCallback onRefresh;

  const _FinanciamientoRow({
    required this.financiamiento,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isActivo =
        financiamiento.estado.toLowerCase() == 'activo';
    final tienePagoInicial = financiamiento.tieneCuotaInicial &&
        financiamiento.cuotaInicialEstado?.toLowerCase() == 'pendiente';

    return InkWell(
      onTap: () {
        Provider.of<FinanciamientoProvider>(context, listen: false)
            .selectFinanciamiento(financiamiento);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FinanciamientoDetallePage(
              idFinanciamiento: financiamiento.idFinanciamiento,
              moneda: financiamiento.moneda,
              onSigned: onRefresh,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: código + badges
            Row(
              children: [
                // Ícono de financiamiento
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1)
                        .withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Código y grupo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crédito #${financiamiento.idFinanciamiento}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        financiamiento.grupoFinanciamiento,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Badge estado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isActivo ? Colors.green : Colors.grey)
                        .withAlpha((0.12 * 255).toInt()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    financiamiento.estado,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActivo ? Colors.green.shade700 : Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(width: 6),
                Icon(Icons.chevron_right,
                    size: 18, color: Colors.grey.shade400),
              ],
            ),

            // Producto (si existe)
            if (financiamiento.nombreProducto != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 50),
                  Icon(Icons.inventory_2_outlined,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      financiamiento.nombreProducto!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Período y cuotas (compacto en una sola fila)
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 50),
                Icon(Icons.date_range,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  '${financiamiento.fechaInicio} – ${financiamiento.fechaFin}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
                const Spacer(),
                Icon(Icons.payment, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  '${financiamiento.cuotas} cuotas',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),

            // Firmado badge
            if (financiamiento.firmado) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 50),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 11, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Firmado',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Banner pago inicial pendiente
            if (tienePagoInicial) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.orange.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        financiamiento.cuotaInicialMonto != null
                            ? 'Pago inicial pendiente: ${financiamiento.moneda} ${financiamiento.cuotaInicialMonto!.toStringAsFixed(2)}'
                            : 'Tienes un pago inicial pendiente',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
