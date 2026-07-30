import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/conductor_estado_model.dart';
import '../../data/models/izipay_models.dart';
import '../../theme/app_theme.dart';
import '../providers/catalogos_provider.dart';
import '../widgets/image_full_screen_view.dart';

class ConductorIzipayPage extends StatefulWidget {
  final ConductorEstadoModel estado;

  const ConductorIzipayPage({super.key, required this.estado});

  @override
  State<ConductorIzipayPage> createState() => _ConductorIzipayPageState();
}

class _ConductorIzipayPageState extends State<ConductorIzipayPage> {
  bool _loading = true;
  String? _error;
  IzipayInfoModel? _info;

  File? _captura;
  bool _enviando = false;
  bool _isPicking = false;
  final _operacionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _operacionController.dispose();
    super.dispose();
  }

  String _limpiarError(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _load() async {
    final catalogos = context.read<CatalogosProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final info = await catalogos.fetchIzipayInfo(widget.estado.id);
      if (mounted) {
        setState(() {
          _info = info;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _limpiarError(e);
        });
      }
    }
  }

  Future<void> _pickCaptura() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (image != null) {
        final file = File(image.path);
        if (file.lengthSync() > AppConstants.maxImageSizeInBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El archivo supera el tamaño máximo de 5 MB. Elige uno más liviano.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        setState(() => _captura = file);
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _enviarCaptura() async {
    if (_captura == null || _enviando) return;
    final catalogos = context.read<CatalogosProvider>();
    setState(() => _enviando = true);

    try {
      final response = await catalogos.subirCapturaIzipay(
        clienteConductorId: widget.estado.id,
        nroDocumento: widget.estado.nroDocumento,
        captura: _captura!,
        numeroOperacion: _operacionController.text.trim().isEmpty
            ? null
            : _operacionController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _captura = null;
        _operacionController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']?.toString() ?? 'Captura recibida. Será validada por nuestro equipo pronto.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_limpiarError(e)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandYellow,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
                  ),
                  const Expanded(
                    child: Text(
                      'Pago con IziPay',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            SvgPicture.asset('images/credigo_logo.svg', height: 48),
            const SizedBox(height: 4),
            const Text(
              'así fácil, así de rápido, así de go',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: Colors.black,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(30, 8, 30, 24),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }
    if (_error != null) {
      return _buildCard(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final info = _info!;
    final aPagar = info.aPagar;

    return Column(
      children: [
        _buildCard(
          child: Column(
            children: [
              const Text(
                'Escanea el código QR',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageFullScreenView(
                        imageUrl: info.qrUrl,
                        heroTag: 'izipay_qr',
                        title: 'QR IziPay',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'izipay_qr',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      info.qrUrl,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        alignment: Alignment.center,
                        child: const Icon(Icons.qr_code_2, size: 64, color: Colors.black26),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca el QR para ampliarlo',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const Divider(height: 24),
              if (aPagar != null) ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Monto a pagar',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'S/ ${aPagar.monto.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (aPagar.cuotaNumero != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Cuota ${aPagar.cuotaNumero}${aPagar.totalCuotas != null ? ' de ${aPagar.totalCuotas}' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Escanea el QR con tu app IziPay, paga el monto exacto y sube la captura del comprobante.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ] else
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Colors.black54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        info.mensaje ?? 'No tienes pagos pendientes por IziPay en este momento.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (aPagar != null) ...[
          const SizedBox(height: 16),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sube tu comprobante',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickCaptura,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _captura != null ? Colors.green.withValues(alpha: 0.05) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _captura != null ? Colors.green : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _captura != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                          color: _captura != null ? Colors.green : Colors.black45,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Captura del pago',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              if (_captura != null)
                                Text(
                                  _captura!.path.split('/').last,
                                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _operacionController,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Número de operación (Opcional)',
                    labelStyle: const TextStyle(color: Colors.black45),
                    prefixIcon: const Icon(Icons.tag, color: Colors.black87, size: 22),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_captura == null || _enviando) ? null : _enviarCaptura,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _enviando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'ENVIAR CAPTURA',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (info.capturas.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tus capturas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...info.capturas.map((c) => _buildCapturaRow(c)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 16, color: Colors.black54),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Pago 100% seguro — Tu información y pago están protegidos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildCapturaRow(IzipayCapturaItemModel captura) {
    final Color bg;
    final Color fg;
    final String texto;
    switch (captura.estado) {
      case 'aprobado':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        texto = 'Aprobada';
        break;
      case 'rechazado':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        texto = 'Rechazada';
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        texto = 'En validación';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  captura.fechaSubida ?? 'Captura enviada',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  texto,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
                ),
              ),
            ],
          ),
          if (captura.estado == 'rechazado') ...[
            if (captura.motivoRechazo?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Motivo: ${captura.motivoRechazo}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Puedes subir una nueva captura.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
