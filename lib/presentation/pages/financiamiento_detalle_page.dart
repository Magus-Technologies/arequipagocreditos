import 'package:arequipagocreditos/data/models/cuota_financiamiento_model.dart';
import 'package:arequipagocreditos/presentation/components/cuota_card.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:arequipagocreditos/services/api_service.dart';
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
  List<CuotaFinanciamientoModel> cuotas = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCuotas();
  }

  Future<void> _fetchCuotas() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      List<CuotaFinanciamientoModel> fetchedCuotas = await ApiService.fetchCuotas(
        widget.idFinanciamiento,
      );
      if (mounted) {
        setState(() {
          cuotas = fetchedCuotas;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error al cargar las cuotas: $e";
          isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchCuotas();
            },
            child: const Text("Reintentar"),
          ),
        ],
      ),
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
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black87,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Detalle Financiamiento',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.3 * 255).toInt()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: authProvider.isLoading || isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh,
                                        color: Colors.black87,
                                        size: 20,
                                      ),
                                onPressed: (authProvider.isLoading || isLoading) ? null : _fetchCuotas,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Información del financiamiento
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.3 * 255).toInt()),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.3 * 255).toInt()),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.5 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.black87,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Financiamiento',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ID: ${widget.idFinanciamiento}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Moneda: ${widget.moneda}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha((0.2 * 255).toInt()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${cuotas.length} cuotas',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando cuotas...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
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
              'Error al cargar las cuotas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _fetchCuotas,
                  child: const Text('Reintentar'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _showErrorDialog,
                  child: const Text('Ver detalles'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (cuotas.isEmpty) {
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
              'No hay cuotas disponibles',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Este financiamiento no tiene cuotas registradas.',
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cuotas.length,
        itemBuilder: (context, index) {
          final cuota = cuotas[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: CuotaCard(
              cuota: cuota,
              moneda: widget.moneda,
            ),
          );
        },
      ),
    );
  }
}
