import 'package:arequipagocreditos/data/models/cuota_financiamiento_model.dart';
import 'package:arequipagocreditos/presentation/components/cuota_card.dart';
import 'package:arequipagocreditos/presentation/providers/financiamiento_provider.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:provider/provider.dart';

class FinanciamientoDetallePage extends StatefulWidget {
  final int idFinanciamiento;
  final String moneda;

  const FinanciamientoDetallePage({
    super.key,
    required this.idFinanciamiento,
    required this.moneda,
  });

  @override
  State<FinanciamientoDetallePage> createState() =>
      _FinanciamientoDetallePageState();
}

class _FinanciamientoDetallePageState extends State<FinanciamientoDetallePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCuotas();
    });
  }

  Future<void> _fetchCuotas() async {
    final financiamientoProvider =
        Provider.of<FinanciamientoProvider>(context, listen: false);
    await Future.wait([
      financiamientoProvider.loadCuotasFinanciamiento(widget.idFinanciamiento),
      financiamientoProvider.loadFinanciamientoById(widget.idFinanciamiento),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
          bottom: false,
          child: Column(
            children: [
              // Header moderno
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // AppBar personalizado
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withAlpha((0.3 * 255).toInt()),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Detalle de Cuotas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Consumer<FinanciamientoProvider>(
                          builder: (context, financiamientoProvider, child) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.3 * 255).toInt()),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withAlpha((0.3 * 255).toInt()),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: financiamientoProvider.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                onPressed: financiamientoProvider.isLoading ? null : _fetchCuotas,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Info del financiamiento
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.3 * 255).toInt()),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.4 * 255).toInt()),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Consumer<FinanciamientoProvider>(
                        builder: (context, financiamientoProvider, child) {
                          final current = financiamientoProvider.currentFinanciamiento;
                          return Column(
                            children: [
                              if (current?.nombreProducto != null) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Producto:',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha((0.2 * 255).toInt()),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            current!.nombreProducto!,
                                            textAlign: TextAlign.end,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'ID Financiamiento:',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '#${widget.idFinanciamiento}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Moneda:',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.moneda,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Cuotas:',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${financiamientoProvider.cuotas.length} cuotas',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido principal
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Consumer<FinanciamientoProvider>(
                        builder: (context, financiamientoProvider, child) {
                          return _buildContent(financiamientoProvider);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(FinanciamientoProvider financiamientoProvider) {
    if (financiamientoProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Cargando cuotas...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (financiamientoProvider.errorMessage != null) {
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
              'Error al cargar cuotas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              financiamientoProvider.errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCuotas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (financiamientoProvider.cuotas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay cuotas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'No se encontraron cuotas para este financiamiento.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCuotas,
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCuotas,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: financiamientoProvider.cuotas.length,
        itemBuilder: (context, index) {
          final cuotaEntity = financiamientoProvider.cuotas[index];
          // Convertir entidad a modelo para el componente
          final cuotaModel = CuotaFinanciamientoModel(
            id: cuotaEntity.id,
            idFinanciamiento: cuotaEntity.idFinanciamiento,
            numeroCuota: cuotaEntity.numeroCuota,
            monto: cuotaEntity.monto,
            fechaVencimiento: cuotaEntity.fechaVencimiento,
            estado: cuotaEntity.estado,
            fechaPago: cuotaEntity.fechaPago,
            idPago: cuotaEntity.idPago,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CuotaCard(
              cuota: cuotaModel,
              moneda: widget.moneda,
            ),
          );
        },
      ),
    );
  }
}
