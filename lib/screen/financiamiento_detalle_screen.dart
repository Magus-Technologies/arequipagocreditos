import 'package:arequipagocreditos/components/cuota_card.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:arequipagocreditos/services/api_service.dart';
import 'package:arequipagocreditos/models/cuota_financiamiento.dart';

class DetalleFinanciamientoScreen extends StatefulWidget {
  final int idFinanciamiento;
  final String moneda;

  const DetalleFinanciamientoScreen({
    super.key,
    required this.idFinanciamiento,
    required this.moneda,
  });

  @override
  State<DetalleFinanciamientoScreen> createState() =>
      _DetalleFinanciamientoScreenState();
}

class _DetalleFinanciamientoScreenState
    extends State<DetalleFinanciamientoScreen> {
  List<CuotaFinanciamiento> cuotas = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCuotas();
  }

  Future<void> _fetchCuotas() async {
    try {
      List<CuotaFinanciamiento> fetchedCuotas = await ApiService.fetchCuotas(
        widget.idFinanciamiento,
      );
      setState(() {
        cuotas = fetchedCuotas;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Error"),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para toda la pantalla
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
          bottom: false, // Permite que el fondo blanco se extienda hasta abajo
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
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.black87,
                              size: 20,
                            ),
                            onPressed: _fetchCuotas,
                          ),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '#${widget.idFinanciamiento} - ${widget.moneda}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLoading)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.5 * 255).toInt()),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${cuotas.length} cuotas',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
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
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: _buildContent(),
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

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.amber,
              strokeWidth: 3,
            ),
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

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Error al cargar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchCuotas,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: RefreshIndicator(
        onRefresh: _fetchCuotas,
        color: AppTheme.primary,
        backgroundColor: Colors.white,
        child: cuotas.isEmpty
            ? _buildEmptyState()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: cuotas.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CuotaCard(
                      cuota: cuotas[index],
                      moneda: widget.moneda,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin cuotas disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay cuotas registradas para este financiamiento',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
