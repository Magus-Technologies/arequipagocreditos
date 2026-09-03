import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/domain/entities/financiamiento_entity.dart';
import 'package:arequipagocreditos/presentation/pages/financiamiento_detalle_page.dart';
import 'package:arequipagocreditos/presentation/providers/financiamiento_provider.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pantalla completa con todos los financiamientos del cliente/conductor.
/// Antes vivía como una tarjeta expandible dentro del dashboard; ahora es
/// su propia pantalla, accesible desde el módulo "Mis Financiamientos".
class MisFinanciamientosPage extends StatefulWidget {
  final ConductorModel conductor;

  const MisFinanciamientosPage({super.key, required this.conductor});

  @override
  State<MisFinanciamientosPage> createState() => _MisFinanciamientosPageState();
}

class _MisFinanciamientosPageState extends State<MisFinanciamientosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinanciamientos();
    });
  }

  Future<void> _loadFinanciamientos() async {
    final provider = Provider.of<FinanciamientoProvider>(context, listen: false);
    await provider.loadFinanciamientos(
      idConductor: widget.conductor.idConductor,
      tipo: widget.conductor.tipo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary,
              AppTheme.primary.withAlpha((0.8 * 255).toInt()),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Consumer<FinanciamientoProvider>(
                    builder: (context, provider, _) {
                      return RefreshIndicator(
                        onRefresh: _loadFinanciamientos,
                        color: AppTheme.primary,
                        child: _buildContent(provider),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.3 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Text(
              'Mis Financiamientos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent(FinanciamientoProvider provider) {
    final financiamientos = provider.financiamientos;
    final total = financiamientos.length;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 64),
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text('Error al cargar financiamientos', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _loadFinanciamientos,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    if (total == 0) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 64),
        children: const [
          Icon(Icons.account_balance_wallet_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No tienes financiamientos activos',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: financiamientos.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade100,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) => _FinanciamientoRow(
        financiamiento: financiamientos[index],
        onRefresh: _loadFinanciamientos,
      ),
    );
  }
}

// ── Fila individual, mismo diseño que tenía la tarjeta expandible ──────────
class _FinanciamientoRow extends StatelessWidget {
  final FinanciamientoEntity financiamiento;
  final VoidCallback onRefresh;

  const _FinanciamientoRow({
    required this.financiamiento,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isActivo = financiamiento.estado.toLowerCase() == 'activo';
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isActivo ? Colors.green : Colors.grey).withAlpha((0.12 * 255).toInt()),
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
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ],
            ),
            if (financiamiento.nombreProducto != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 50),
                  Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      financiamiento.nombreProducto!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 50),
                Icon(Icons.date_range, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  '${financiamiento.fechaInicio} – ${financiamiento.fechaFin}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const Spacer(),
                Icon(Icons.payment, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  '${financiamiento.cuotas} cuotas',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            if (financiamiento.firmado) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 50),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 11, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Firmado',
                          style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (tienePagoInicial) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        financiamiento.cuotaInicialMonto != null
                            ? 'Pago inicial pendiente: ${financiamiento.moneda} ${financiamiento.cuotaInicialMonto!.toStringAsFixed(2)}'
                            : 'Tienes un pago inicial pendiente',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
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
