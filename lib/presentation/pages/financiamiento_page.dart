import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/providers/financiamiento_provider.dart';
import 'package:arequipagocreditos/presentation/pages/financiamiento_detalle_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FinanciamientoPage extends StatefulWidget {
  final int idConductor;
  final int tipo;

  const FinanciamientoPage({
    super.key,
    required this.idConductor,
    required this.tipo,
  });

  @override
  State<FinanciamientoPage> createState() => _FinanciamientoPageState();
}

class _FinanciamientoPageState extends State<FinanciamientoPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinanciamientos();
    });
  }

  Future<void> _loadFinanciamientos() async {
    final financiamientoProvider = Provider.of<FinanciamientoProvider>(context, listen: false);
    await financiamientoProvider.loadFinanciamientos(idConductor: widget.idConductor, tipo: widget.tipo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<FinanciamientoProvider>(
              builder: (context, financiamientoProvider, child) {
                if (financiamientoProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (financiamientoProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar financiamientos',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${financiamientoProvider.errorMessage}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFinanciamientos,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                } else if (financiamientoProvider.financiamientos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay financiamientos',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No tienes financiamientos disponibles en este momento.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFinanciamientos,
                          child: const Text('Actualizar'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadFinanciamientos,
                  child: ListView.builder(
                    itemCount: financiamientoProvider.financiamientos.length,
                    itemBuilder: (context, index) {
                      final financiamiento = financiamientoProvider.financiamientos[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Código: ${financiamiento.idFinanciamiento}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha((0.1 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    financiamiento.estado,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (financiamiento.firmado) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withAlpha((0.1 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.check_circle, size: 12, color: Colors.blue),
                                        SizedBox(width: 4),
                                        Text(
                                          'Firmado',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.group, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Grupo: ${financiamiento.grupoFinanciamiento}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (financiamiento.nombreProducto != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined,
                                      size: 18, color: Colors.purple),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Producto: ${financiamiento.nombreProducto}',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            // Banner pago inicial pendiente (Caja Arequipa)
                            if (financiamiento.tieneCuotaInicial &&
                                financiamiento.cuotaInicialEstado?.toLowerCase() == 'pendiente') ...[
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FinanciamientoDetallePage(
                                        idFinanciamiento: financiamiento.idFinanciamiento,
                                        moneda: financiamiento.moneda,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.orange.shade300,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          financiamiento.cuotaInicialMonto != null
                                              ? 'Pago inicial pendiente: ${financiamiento.moneda} ${financiamiento.cuotaInicialMonto!.toStringAsFixed(2)}'
                                              : 'Tienes un pago inicial pendiente',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade800,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.orange.shade600,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.date_range, size: 18, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Período: ${financiamiento.fechaInicio} - ${financiamiento.fechaFin}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.payment, size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'Cuotas: ${financiamiento.cuotas}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Provider.of<FinanciamientoProvider>(context, listen: false)
                                        .selectFinanciamiento(financiamiento);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FinanciamientoDetallePage(
                                          idFinanciamiento: financiamiento.idFinanciamiento,
                                          moneda: financiamiento.moneda,
                                          onSigned: () => _loadFinanciamientos(),
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Ver detalles',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
