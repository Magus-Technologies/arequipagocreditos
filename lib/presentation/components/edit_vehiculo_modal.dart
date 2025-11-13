import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';

class EditVehiculoModal extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const EditVehiculoModal({super.key, this.initialData});

  @override
  State<EditVehiculoModal> createState() => _EditVehiculoModalState();
}

class _EditVehiculoModalState extends State<EditVehiculoModal> {
  final _formKey = GlobalKey<FormState>();
  final placaCtl = TextEditingController();
  final soatCtl = TextEditingController();
  final revisionCtl = TextEditingController();
  final seguroCtl = TextEditingController();
  final colorCtl = TextEditingController();
  final anioCtl = TextEditingController();
  final marcaCtl = TextEditingController();
  final modeloCtl = TextEditingController();
  bool _loading = false;
  // store ISO dates for payload, while controllers show human-friendly format
  final Map<String, String> _isoDates = {};

  @override
  void initState() {
    super.initState();
    final d = widget.initialData ?? {};
    placaCtl.text = d['placa']?.toString() ?? '';
    // if incoming dates are ISO (yyyy-MM-dd) show them as dd/MM/yyyy but keep ISO in _isoDates
    if (d['soat'] != null && d['soat'].toString().isNotEmpty) {
      _isoDates['soat'] = d['soat'].toString();
      soatCtl.text = _isoToDisplay(d['soat'].toString());
    } else {
      soatCtl.text = '';
    }
    if (d['revision_tecnica'] != null && d['revision_tecnica'].toString().isNotEmpty) {
      _isoDates['revision_tecnica'] = d['revision_tecnica'].toString();
      revisionCtl.text = _isoToDisplay(d['revision_tecnica'].toString());
    } else {
      revisionCtl.text = '';
    }
    if (d['seguro_vehicular'] != null && d['seguro_vehicular'].toString().isNotEmpty) {
      _isoDates['seguro_vehicular'] = d['seguro_vehicular'].toString();
      seguroCtl.text = _isoToDisplay(d['seguro_vehicular'].toString());
    } else {
      seguroCtl.text = '';
    }
    colorCtl.text = d['color']?.toString() ?? '';
    anioCtl.text = d['anio']?.toString() ?? '';
    marcaCtl.text = d['marca']?.toString() ?? '';
    modeloCtl.text = d['modelo']?.toString() ?? '';
  }

  @override
  void dispose() {
    placaCtl.dispose();
    soatCtl.dispose();
    revisionCtl.dispose();
    seguroCtl.dispose();
    colorCtl.dispose();
    anioCtl.dispose();
    marcaCtl.dispose();
    modeloCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {

    setState(() => _loading = true);

    String? isoForKey(String key, TextEditingController ctl) {
      // prefer explicit _isoDates stored on pick
      if (_isoDates.containsKey(key)) return _isoDates[key];
      // otherwise try to parse display dd/MM/yyyy
      final d = _displayToDate(ctl.text);
      if (d != null) {
        return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }
      // fallback: if controller has something that looks like ISO, return it
      try {
        final maybe = DateTime.tryParse(ctl.text);
        if (maybe != null) return '${maybe.year.toString().padLeft(4, '0')}-${maybe.month.toString().padLeft(2, '0')}-${maybe.day.toString().padLeft(2, '0')}';
      } catch (_) {}
      return null;
    }

    final Map<String, dynamic> payload = {};
    if (placaCtl.text.isNotEmpty) payload['placa'] = placaCtl.text;
    final soatIso = isoForKey('soat', soatCtl);
    if (soatIso != null) payload['soat'] = soatIso;
    final revIso = isoForKey('revision_tecnica', revisionCtl);
    if (revIso != null) payload['revision_tecnica'] = revIso;
    final seguroIso = isoForKey('seguro_vehicular', seguroCtl);
    if (seguroIso != null) payload['seguro_vehicular'] = seguroIso;
    if (colorCtl.text.isNotEmpty) payload['color'] = colorCtl.text;
    if (anioCtl.text.isNotEmpty) payload['anio'] = int.tryParse(anioCtl.text);
    if (marcaCtl.text.isNotEmpty) payload['marca'] = marcaCtl.text;
    if (modeloCtl.text.isNotEmpty) payload['modelo'] = modeloCtl.text;
    try {
      final success = await context.read<AuthProvider>().updateVehicleData(payload);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos del vehículo actualizados')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          final msg = context.read<AuthProvider>().errorMessage ?? 'Error al actualizar';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDateAndSet(TextEditingController ctl, String key) async {
    // try to parse existing ISO date first, otherwise parse displayed dd/MM/yyyy
    DateTime initial;
    if (_isoDates.containsKey(key)) {
      initial = DateTime.tryParse(_isoDates[key]!) ?? DateTime.now();
    } else {
      initial = DateTime.tryParse(ctl.text) ?? _displayToDate(ctl.text) ?? DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      final iso = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _isoDates[key] = iso;
      ctl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year.toString().padLeft(4, '0')}';
      setState(() {});
    }
  }

  String _isoToDisplay(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  DateTime? _displayToDate(String display) {
    try {
      final parts = display.split('/');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // drag handle
                  Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),

                  Row(
                    children: [
                      const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.directions_car, color: Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Editar datos del vehículo', style: Theme.of(context).textTheme.titleLarge)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: placaCtl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Placa',
                            prefixIcon: const Icon(Icons.directions_car),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null; // placa optional
                            if (v.trim().length < 4) return 'Placa demasiado corta';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // SOAT (date picker)
                        GestureDetector(
                          onTap: () => _pickDateAndSet(soatCtl, 'soat'),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: soatCtl,
                              decoration: InputDecoration(
                                labelText: 'SOAT (fecha)',
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Revisión técnica (date picker)
                        GestureDetector(
                          onTap: () => _pickDateAndSet(revisionCtl, 'revision_tecnica'),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: revisionCtl,
                              decoration: InputDecoration(
                                labelText: 'Revisión técnica (fecha)',
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Seguro vehicular (date picker)
                        GestureDetector(
                          onTap: () => _pickDateAndSet(seguroCtl, 'seguro_vehicular'),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: seguroCtl,
                              decoration: InputDecoration(
                                labelText: 'Seguro vehicular (fecha)',
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: colorCtl,
                          decoration: InputDecoration(
                            labelText: 'Color',
                            prefixIcon: const Icon(Icons.color_lens),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Año: validate between 1900 and next year
                        TextFormField(
                          controller: anioCtl,
                          decoration: InputDecoration(
                            labelText: 'Año',
                            prefixIcon: const Icon(Icons.calendar_view_month),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = int.tryParse(v);
                            if (n == null) return 'Año inválido';
                            final current = DateTime.now().year;
                            if (n < 1900 || n > current + 1) return 'Año fuera de rango';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // two-column row for Marca / Modelo
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: marcaCtl,
                                decoration: InputDecoration(
                                  labelText: 'Marca',
                                  prefixIcon: const Icon(Icons.business),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: modeloCtl,
                                decoration: InputDecoration(
                                  labelText: 'Modelo',
                                  prefixIcon: const Icon(Icons.directions_car_filled),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _submit,
                            icon: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                            label: Text(_loading ? 'Guardando...' : 'Guardar'),
                            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
