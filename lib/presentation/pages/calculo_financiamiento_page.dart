import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financiamiento_servicio_provider.dart';
import '../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'signature/firma_documento_page.dart';
import 'financiamiento_detalle_page.dart';

class CalculoFinanciamientoPage extends StatefulWidget {
  const CalculoFinanciamientoPage({super.key});

  @override
  State<CalculoFinanciamientoPage> createState() => _CalculoFinanciamientoPageState();
}

class _CalculoFinanciamientoPageState extends State<CalculoFinanciamientoPage> {
  bool _isFinanciado = true;
  int _selectedCuotas = 2;
  int _selectedFrecuenciaPagoId = 1; // 1=semanal, 2=quincenal, 3=mensual
  String _metodoPago = 'YAPE';
  final TextEditingController _operacionController = TextEditingController();
  
  final Map<int, String> _frecuencias = {
    1: 'Semanal',
    2: 'Quincenal',
    3: 'Mensual',
  };

  final List<String> _metodos = [
    'YAPE', 'PLIN', 'EFECTIVO', 'POS', 'QR', 'TARJETA',
    'TRANSFERENCIA_BCP', 'TRANSFERENCIA_BBVA', 'TRANSFERENCIA_INTERBANK',
    'TRANSFERENCIA_SCOTIABANK', 'TRANSFERENCIA_BN', 'DEPOSITO_BCP', 'DEPOSITO_BBVA'
  ];

  @override
  void dispose() {
    _operacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanciamientoServicioProvider>();
    final servicio = provider.selectedService;

    if (servicio == null) {
      return Scaffold(body: const Center(child: Text('No hay servicio seleccionado')));
    }

    final detalle = servicio.detalleFinanciamiento;
    
    // Cálculos
    final double precio = servicio.precioServicio;
    double cuotaInicial = 0;
    double montoAFinanciar = 0;
    double montoCuota = 0;

    if (_isFinanciado && detalle != null) {
      cuotaInicial = provider.calculateCuotaInicial(precio, detalle.porcentajeInicial);
      montoAFinanciar = provider.calculateMontoAFinanciar(precio, cuotaInicial);
      // Apply interest multiplier based on frecuencia (monthly has 10% extra)
      final double interesAplicable = (_selectedFrecuenciaPagoId == 3)
          ? detalle.interes * 1.1  // mensual: 10% adicional per spec
          : detalle.interes;
      montoCuota = provider.calculateCuotaMonto(montoAFinanciar, _selectedCuotas, interesAplicable);
    } else {
      cuotaInicial = precio;
      montoAFinanciar = 0;
      montoCuota = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo de Pago', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen del Servicio
            _buildServiceSummary(servicio),
            const SizedBox(height: 24),
            
            const Text(
              '¿Cómo deseas pagar?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Opciones de Pago (Contado / Financiado)
            _buildPaymentTypeSelector(precio),
            
            if (_isFinanciado && detalle != null) ...[
              const SizedBox(height: 24),
              _buildFinancingOptions(detalle, montoCuota, provider, servicio),
            ],
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Datos del Pago Inicial
            _buildInitialPaymentForm(cuotaInicial),
            
            const SizedBox(height: 32),
            
            // Botón de Acción
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : () => _confirmarFinanciamiento(provider, cuotaInicial, montoCuota),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: provider.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ADQUIRIR SERVICIO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSummary(dynamic servicio) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(servicio.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(servicio.descripcion, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Precio Total:', style: TextStyle(fontSize: 16)),
              Text('S/ ${servicio.precioServicio.toStringAsFixed(2)}', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelector(double precio) {
    return Column(
      children: [
        _buildPaymentOption(
          title: 'CONTADO',
          subtitle: 'Pago total de S/ ${precio.toStringAsFixed(2)}',
          isSelected: !_isFinanciado,
          onTap: () => setState(() => _isFinanciado = false),
          icon: Icons.money,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          title: 'FINANCIADO',
          subtitle: 'Paga una inicial y el resto en cuotas',
          isSelected: _isFinanciado,
          onTap: () => setState(() => _isFinanciado = true),
          icon: Icons.account_balance_wallet,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withAlpha((0.05 * 255).toInt()) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, 
              color: isSelected ? AppTheme.primary : Colors.grey),
            const SizedBox(width: 16),
            Icon(icon, color: isSelected ? AppTheme.primary : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primary : Colors.black87)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancingOptions(dynamic detalle, double montoCuota, FinanciamientoServicioProvider provider, dynamic servicio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Opciones de cuotas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: List.generate(
            detalle.maxCuotas - detalle.minCuotas + 1,
            (index) {
              int val = detalle.minCuotas + index;
              bool isSel = _selectedCuotas == val;
              return ChoiceChip(
                label: Text('$val Cuotas'),
                selected: isSel,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCuotas = val);
                },
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text('Frecuencia de pago', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedFrecuenciaPagoId,
          items: _frecuencias.entries.map((e) =>
            DropdownMenuItem(value: e.key, child: Text(e.value))
          ).toList(),
          onChanged: (val) => setState(() => _selectedFrecuenciaPagoId = val!),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cuota inicial (${detalle.porcentajeInicial.toStringAsFixed(0)}%):',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('S/ ${provider.calculateCuotaInicial(servicio!.precioServicio, detalle.porcentajeInicial).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_frecuencias[_selectedFrecuenciaPagoId]} por cuota:',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('S/ ${montoCuota.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitialPaymentForm(double monto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isFinanciado ? 'Cuota Inicial a pagar: S/ ${monto.toStringAsFixed(2)}' : 'Total a pagar: S/ ${monto.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('Método de pago', style: TextStyle(fontSize: 14, color: Colors.grey)),
        DropdownButtonFormField<String>(
          initialValue: _metodoPago,
          items: _metodos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (val) => setState(() => _metodoPago = val!),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Número de operación', style: TextStyle(fontSize: 14, color: Colors.grey)),
        TextField(
          controller: _operacionController,
          decoration: InputDecoration(
            hintText: 'Ej: 123456789',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }

  void _confirmarFinanciamiento(FinanciamientoServicioProvider provider, double cuotaInicial, double montoCuota) async {
    if (_operacionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese el número de operación')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final conductorId = auth.currentUser?.idConductor ?? 0;
    
    if (conductorId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del conductor')),
      );
      return;
    }

    final result = await provider.createFinanciamiento(
      conductorId: conductorId,
      beneficioId: provider.selectedService!.id,
      grupoId: provider.selectedService!.grupoFinanciamientoId ?? 112,
      montoTotal: provider.selectedService!.precioServicio,
      montoCuota: _isFinanciado ? montoCuota : 0,
      cantidadCuotas: _isFinanciado ? _selectedCuotas : 0,
      frecuenciaPagoId: _isFinanciado ? _selectedFrecuenciaPagoId : 1,
      fechaInicio: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))),
      cuotaInicial: cuotaInicial,
      metodoPago: _metodoPago,
      numeroOperacion: _operacionController.text,
    );

    if (result != null) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Financiamiento creado exitosamente. Proceda a firmar el contrato.')),
      );

      // Redirigir a firma
      if (result.contratoUrl != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FirmaDocumentoPage(
              title: 'Contrato de Financiamiento',
              pdfUrl: result.contratoUrl!,
              tipo: 'contrato',
              id: result.idFinanciamiento, // CORRECTED: was result.id
              onSigned: () {
                // Navegar al detalle de cuotas
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => FinanciamientoDetallePage(
                      idFinanciamiento: result.idFinanciamiento,
                      moneda: result.moneda,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.error}')),
      );
    }
  }
}
