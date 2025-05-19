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
      appBar: AppBar(
        title: const Text("Detalle Financiamiento"),
        backgroundColor: AppTheme.primary,
        elevation: 2,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  )
                  : errorMessage.isNotEmpty
                  ? Center(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _fetchCuotas, // Llama al método de actualización
                    color: Colors.amber, // Color del indicador de carga
                    child: ListView.builder(
                      itemCount: cuotas.length,
                      itemBuilder:
                          (context, index) => CuotaCard(
                            cuota: cuotas[index],
                            moneda: widget.moneda,
                          ),
                    ),
                  ),
        ),
      ),
    );
  }
}
