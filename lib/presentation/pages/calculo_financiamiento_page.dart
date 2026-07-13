import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financiamiento_servicio_provider.dart';
import '../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'signature/firma_documento_page.dart';
import 'financiamiento_detalle_page.dart';
import '../widgets/image_full_screen_view.dart';
import '../../core/constants/api_constants.dart';

class CalculoFinanciamientoPage extends StatefulWidget {
  const CalculoFinanciamientoPage({super.key});

  @override
  State<CalculoFinanciamientoPage> createState() =>
      _CalculoFinanciamientoPageState();
}

class _CalculoFinanciamientoPageState extends State<CalculoFinanciamientoPage> {
  bool _isFinanciado = true;
  int _selectedCuotas = 2;
  int _selectedFrecuenciaPagoId = 1;
  String _metodoPago = 'CAJA_AREQUIPA';
  double _selectedPorcentajeInicial = 30.0;
  final TextEditingController _operacionController = TextEditingController();
  final TextEditingController _montoLibreController = TextEditingController();

  static const Map<String, String> kMetodoPagoLabels = {
    'CAJA_AREQUIPA': 'Caja Arequipa',
    'EFECTIVO': 'Efectivo',
    'YAPE': 'Yape',
    'PLIN': 'Plin',
    'POS': 'POS',
    'QR': 'QR',
    'TARJETA': 'Tarjeta',
    'TRANSFERENCIA_BCP': 'Transferencia BCP',
    'TRANSFERENCIA_BBVA': 'Transferencia BBVA',
    'TRANSFERENCIA_INTERBANK': 'Transferencia Interbank',
    'TRANSFERENCIA_SCOTIABANK': 'Transferencia Scotiabank',
    'TRANSFERENCIA_BN': 'Transferencia BN',
    'DEPOSITO_BCP': 'Depósito BCP',
    'DEPOSITO_BBVA': 'Depósito BBVA',
    'DEPOSITO_INTERBANK': 'Depósito Interbank',
    'PAGO_BONO': 'Pago con Bono',
  };

  final Map<int, String> _frecuenciasMap = {
    1: 'Semanal',
    2: 'Quincenal',
    3: 'Mensual',
  };

  List<String> get _metodos {
    final servicio = context.read<FinanciamientoServicioProvider>().selectedService;
    final lista = servicio?.detalleFinanciamiento?.metodosPago.isNotEmpty == true
        ? servicio!.detalleFinanciamiento!.metodosPago
        : servicio?.metodosPago;
    return (lista != null && lista.isNotEmpty) ? lista : const ['CAJA_AREQUIPA'];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FinanciamientoServicioProvider>();
      final servicio = provider.selectedService;
      if (servicio == null) return;

      final det = servicio.detalleFinanciamiento;
      setState(() {
        if (servicio.tipoPago == 1) {
          _isFinanciado = false;
        } else {
          _isFinanciado = true;
        }

        if (det != null) {
          _selectedCuotas = det.minCuotas > 0 ? det.minCuotas : det.cantidadCuotas;
          _selectedPorcentajeInicial = det.porcentajeInicialDefault > 0
              ? det.porcentajeInicialDefault
              : det.porcentajeInicial;

          final freq = det.frecuenciaPago.toLowerCase();
          if (freq.contains('semanal')) {
            _selectedFrecuenciaPagoId = 1;
          } else if (freq.contains('quincenal')) {
            _selectedFrecuenciaPagoId = 2;
          } else if (freq.contains('mensual')) {
            _selectedFrecuenciaPagoId = 3;
          }
        }

        if (servicio.modoCalculo == 'monto_libre') {
          _montoLibreController.text = servicio.precioServicio > 0
              ? servicio.precioServicio.toStringAsFixed(2)
              : '';
        }

        if (!_metodos.contains(_metodoPago)) {
          _metodoPago = _metodos.first;
        }
      });
    });
  }

  @override
  void dispose() {
    _operacionController.dispose();
    _montoLibreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanciamientoServicioProvider>();
    final servicio = provider.selectedService;

    if (servicio == null) {
      return const Scaffold(
        body: Center(child: Text('No hay servicio seleccionado')),
      );
    }

    final detalle = servicio.detalleFinanciamiento;
    final String modoCalculo = servicio.modoCalculo;

    final double? tope = detalle?.montoProducto;

    double precio;
    if (modoCalculo == 'fijo' && servicio.precioServicio <= 0) {
      precio = servicio.cuotaInicial + (servicio.cantidadCuotas * servicio.cuotaMensual);
    } else if (modoCalculo == 'monto_libre') {
      precio = double.tryParse(_montoLibreController.text) ?? 0.0;
    } else {
      precio = servicio.precioServicio;
    }

    double cuotaInicial = 0;
    double montoAFinanciar = 0;
    double montoCuota = 0;

    if (modoCalculo == 'fijo' && detalle != null) {
      cuotaInicial = servicio.cuotaInicial;
      montoAFinanciar = precio - cuotaInicial;
      montoCuota = servicio.cuotaMensual;
      _selectedCuotas = servicio.cantidadCuotas;
    } else if (_isFinanciado && detalle != null) {
      cuotaInicial = provider.calculateCuotaInicial(precio, _selectedPorcentajeInicial);
      montoAFinanciar = provider.calculateMontoAFinanciar(precio, cuotaInicial);
      montoCuota = provider.calculateCuotaMonto(montoAFinanciar, _selectedCuotas, 10.0);
    } else {
      cuotaInicial = precio;
      montoAFinanciar = 0;
      montoCuota = 0;
    }

    final notaServicio = servicio.notaImportante;
    final notaTaller = provider.selectedTaller?.notaImportante;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cálculo de Pago',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceSummary(servicio, precio, tope),
            if (notaServicio != null && notaServicio.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildNotaAlerta(notaServicio),
            ] else if (notaTaller != null && notaTaller.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildNotaAlerta(notaTaller),
            ],
            const SizedBox(height: 24),

            const Text(
              '¿Cómo deseas pagar?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (servicio.tipoPago == 3) ...[
              _buildPaymentTypeSelector(precio),
              const SizedBox(height: 24),
            ],

            if (_isFinanciado) ...[
              if (modoCalculo == 'fijo' && detalle != null) ...[
                _buildPlanFijoSummary(cuotaInicial, montoCuota, detalle),
              ] else if (modoCalculo != 'fijo' && detalle != null) ...[
                _buildFinancingOptions(detalle, montoCuota, provider, precio, cuotaInicial),
              ],
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            _buildInitialPaymentForm(cuotaInicial),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: provider.isLoading || precio <= 0
                    ? null
                    : () => _confirmarFinanciamiento(provider, cuotaInicial, montoCuota, precio),
                style: ElevatedButton.styleFrom(
                  backgroundColor: precio <= 0 ? Colors.grey.shade400 : Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ADQUIRIR SERVICIO',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      )),
    );
  }

  String? _validarMonto(double precio, double? tope) {
    if (precio <= 0) return 'Ingresa el monto del servicio';
    if (tope != null && precio > tope) {
      return 'El monto no puede superar S/ ${tope.toStringAsFixed(0)}';
    }
    return null;
  }

  Widget _buildServiceSummary(dynamic servicio, double precio, double? tope) {
    final bool tieneTope = tope != null && tope > 0;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (servicio.imagen != null && servicio.imagen!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageFullScreenView(
                            imageUrl: '${ApiConstants.imagenesBaseUrl}/${servicio.imagen!}',
                            heroTag: 'servicio_calc_image_${servicio.id}',
                            title: servicio.nombre,
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'servicio_calc_image_${servicio.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          '${ApiConstants.imagenesBaseUrl}/${servicio.imagen!}',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servicio.nombre,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      servicio.descripcion,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          if (servicio.modoCalculo == 'monto_libre') ...[
            const Text(
              'Ingresa el monto a financiar:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _montoLibreController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: 'S/ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                helperText: tieneTope ? 'Máximo permitido: S/ ${tope.toStringAsFixed(0)}' : null,
                errorText: _validarMonto(precio, tieneTope ? tope : null),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Precio Total:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  'S/ ${precio.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanFijoSummary(double cuotaInicial, double montoCuota, dynamic detalle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Inicial:', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('S/ ${cuotaInicial.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_selectedCuotas cuotas ${detalle.frecuenciaPago}:', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                'S/ ${montoCuota.toStringAsFixed(2)} c/u',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
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
                color: isSelected ? Colors.amber.shade800 : Colors.grey),
            const SizedBox(width: 16),
            Icon(icon, color: isSelected ? Colors.amber.shade800 : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.amber.shade800 : Colors.black87)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancingOptions(
    dynamic detalle,
    double montoCuota,
    FinanciamientoServicioProvider provider,
    double precio,
    double cuotaInicial,
  ) {
    List<DropdownMenuItem<int>> frecItems = [];
    if (detalle.frecuenciasDisponibles != null && detalle.frecuenciasDisponibles.isNotEmpty) {
      for (String freq in detalle.frecuenciasDisponibles) {
        int val = 1;
        if (freq.toLowerCase() == 'quincenal') val = 2;
        if (freq.toLowerCase() == 'mensual') val = 3;
        frecItems.add(DropdownMenuItem(value: val, child: Text(_frecuenciasMap[val] ?? freq)));
      }
    } else {
      frecItems = _frecuenciasMap.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList();
    }

    // Garantizar que el valor seleccionado siempre exista en la lista
    int effectiveFrecuencia = _selectedFrecuenciaPagoId;
    if (frecItems.isNotEmpty && !frecItems.any((item) => item.value == effectiveFrecuencia)) {
      effectiveFrecuencia = frecItems.first.value!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedFrecuenciaPagoId = effectiveFrecuencia);
      });
    }

    final double pMin = detalle.porcentajeInicialMin > 0 ? detalle.porcentajeInicialMin : detalle.porcentajeInicialDefault;
    final double pMax = detalle.porcentajeInicialMax > 0 ? detalle.porcentajeInicialMax : detalle.porcentajeInicialDefault;
    final bool porcentajeFijo = pMin >= pMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Opciones de cuotas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: List.generate(detalle.maxCuotas - detalle.minCuotas + 1, (index) {
            int val = detalle.minCuotas + index;
            bool isSel = _selectedCuotas == val;
            return ChoiceChip(
              label: Text('$val Cuotas'),
              selected: isSel,
              onSelected: (selected) {
                if (selected) setState(() => _selectedCuotas = val);
              },
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSel ? Colors.black : Colors.black87,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        const Text('Frecuencia de pago', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          child: DropdownButton<int>(
            value: effectiveFrecuencia,
            items: frecItems,
            onChanged: (val) => setState(() => _selectedFrecuenciaPagoId = val!),
            isExpanded: true,
            underline: const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 16),

        // Selector de porcentaje de inicial (solo cuando min != max)
        if (!porcentajeFijo) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('% de inicial', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                '${_selectedPorcentajeInicial.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          Slider(
            value: _selectedPorcentajeInicial.clamp(pMin, pMax),
            min: pMin,
            max: pMax,
            divisions: (pMax - pMin).round().clamp(1, 100),
            activeColor: AppTheme.primary,
            onChanged: (val) => setState(() => _selectedPorcentajeInicial = val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${pMin.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('${pMax.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 16),
        ],

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cuota inicial (${_selectedPorcentajeInicial.toStringAsFixed(0)}%):',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('S/ ${cuotaInicial.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('A financiar:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('S/ ${(precio - cuotaInicial).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_frecuenciasMap[_selectedFrecuenciaPagoId]} por cuota (c/10%):',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('S/ ${montoCuota.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    'S/ ${(cuotaInicial + montoCuota * _selectedCuotas).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotaAlerta(String nota) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF9A825), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nota,
              style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialPaymentForm(double monto) {
    final metodos = _metodos;
    final label = kMetodoPagoLabels[_metodoPago] ?? _metodoPago;
    final requiereOperacion = _metodoPago != 'EFECTIVO' && _metodoPago != 'CAJA_AREQUIPA';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isFinanciado
              ? 'Cuota Inicial a pagar: S/ ${monto.toStringAsFixed(2)}'
              : 'Total a pagar: S/ ${monto.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('Método de pago', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        if (metodos.length == 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Text('Pago por: $label', style: const TextStyle(fontSize: 15)),
              ],
            ),
          )
        else
          InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            child: DropdownButton<String>(
              value: _metodoPago,
              items: metodos
                  .map((m) => DropdownMenuItem(value: m, child: Text(kMetodoPagoLabels[m] ?? m)))
                  .toList(),
              onChanged: (val) => setState(() => _metodoPago = val!),
              isExpanded: true,
              underline: const SizedBox.shrink(),
            ),
          ),
        if (_metodoPago == 'CAJA_AREQUIPA') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El número de orden será el ID del financiamiento.\n'
                    'Realiza el pago en cualquier agente Caja Arequipa.',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
        ] else if (requiereOperacion) ...[
          const SizedBox(height: 16),
          const Text('Número de operación', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: _operacionController,
            decoration: InputDecoration(
              hintText: 'Ej: 123456789',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ],
    );
  }

  void _confirmarFinanciamiento(
    FinanciamientoServicioProvider provider,
    double cuotaInicial,
    double montoCuota,
    double precio,
  ) async {
    if (provider.selectedService!.modoCalculo == 'monto_libre' && precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese un monto válido')),
      );
      return;
    }

    final requiereOperacion = _metodoPago != 'EFECTIVO' && _metodoPago != 'CAJA_AREQUIPA';
    if (requiereOperacion && _operacionController.text.isEmpty) {
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

    final servicio = provider.selectedService!;
    final contrato = servicio.detalleFinanciamiento?.contrato;
    final contratoDisponible = contrato?.disponible == true && (contrato?.url ?? '').isNotEmpty;

    // Nuevo flujo: mostrar PDF del template → firmar → crear financiamiento con firma
    String? firmaBase64;
    String? nroDocumento;
    if (contratoDisponible) {
      final rawUrl = contrato!.url!;
      final pdfUrl = rawUrl.contains('?')
          ? '$rawUrl&beneficio_id=${servicio.id}'
          : '$rawUrl?beneficio_id=${servicio.id}';
      firmaBase64 = await _capturarFirmaConPdf(
        titulo: servicio.nombre,
        pdfUrl: pdfUrl,
      );
      if (firmaBase64 == null || !mounted) return; // usuario canceló
      nroDocumento = auth.currentUser?.nroDocumento;
    }

    await _ejecutarPost(provider, servicio, conductorId, cuotaInicial, montoCuota, precio, firmaBase64, nroDocumento);
  }

  Future<String?> _capturarFirmaConPdf({
    required String titulo,
    required String pdfUrl,
  }) async {
    return await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => FirmaDocumentoPage(
          title: titulo,
          pdfUrl: pdfUrl,
          tipo: 'contrato',
          id: 0,
          captureOnly: true,
        ),
      ),
    );
  }

  Future<void> _ejecutarPost(
    FinanciamientoServicioProvider provider,
    dynamic servicio,
    int conductorId,
    double cuotaInicial,
    double montoCuota,
    double precio,
    String? firmaBase64, [
    String? nroDocumento,
  ]) async {
    final bool esFinanciado = _isFinanciado || servicio.modoCalculo == 'fijo';
    final String? modalidadPago =
        servicio.tipoPago == 3 ? (esFinanciado ? 'financiado' : 'contado') : null;

    final result = await provider.createFinanciamiento(
      conductorId: conductorId,
      beneficioId: servicio.id,
      grupoId: servicio.grupoFinanciamientoId ?? 112,
      montoTotal: precio,
      cuotaInicial: cuotaInicial,
      metodoPago: _metodoPago,
      numeroOperacion: _metodoPago == 'CAJA_AREQUIPA' ? '' : _operacionController.text,
      modalidadPago: modalidadPago,
      montoCuota: esFinanciado ? montoCuota : 0,
      cantidadCuotas: esFinanciado ? _selectedCuotas : 0,
      frecuenciaPagoId: esFinanciado ? _selectedFrecuenciaPagoId : 1,
      fechaInicio: esFinanciado
          ? DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7)))
          : null,
      firmaBase64: firmaBase64,
      nroDocumento: nroDocumento,
    );

    if (!mounted) return;

    if (result != null) {
      final mensajeExito = _mensajeSegunEstadoApp(result.estadoApp);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeExito), backgroundColor: Colors.green),
      );

      // Si el usuario ya firmó en el flujo previo (captureOnly), ir directo al detalle
      final yaFirmo = firmaBase64 != null && firmaBase64.isNotEmpty;

      if (!yaFirmo && result.contratoUrl != null && result.contratoUrl!.isNotEmpty) {
        // Flujo sin pre-firma: mostrar el contrato firmado para firma posterior
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FirmaDocumentoPage(
              title: 'Contrato de Financiamiento',
              pdfUrl: result.contratoUrl!,
              tipo: 'contrato',
              id: result.idFinanciamiento,
              onSigned: () {
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FinanciamientoDetallePage(
              idFinanciamiento: result.idFinanciamiento,
              moneda: result.moneda,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Ocurrió un error al procesar la solicitud.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _mensajeSegunEstadoApp(String? estadoApp) {
    switch (estadoApp) {
      case 'aprobado':
        return 'Servicio aprobado. Ya puede proceder con el pago de su cuota inicial.';
      case 'pendiente_doble_validacion':
        return 'Solicitud enviada. Requiere revisión del administrador y del director.';
      case 'pendiente_aprobacion':
      default:
        return 'Solicitud enviada. Te notificaremos cuando sea revisada por el administrador.';
    }
  }
}
