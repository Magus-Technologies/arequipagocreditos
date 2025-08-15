import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:arequipagocreditos/data/models/cuota_financiamiento_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class CuotaCard extends StatefulWidget {
  final CuotaFinanciamientoModel cuota;
  final String moneda;

  const CuotaCard({super.key, required this.cuota, required this.moneda});

  @override
  State<CuotaCard> createState() => _CuotaCardState();
}

class _CuotaCardState extends State<CuotaCard> {
  Uint8List? _pdfBytes;

  Future<void> _fetchPdf() async {
    final response = await http.post(
      Uri.parse('https://arequipago-ventas.pe/downloadReportFinance'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: 'idPago=${widget.cuota.idPago}',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _pdfBytes = base64Decode(data['pdfBase64']);
      });
    } else {
      throw Exception('Error al descargar el reporte');
    }
  }

  Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<Directory?> _getDownloadDir() async {
    final extDir = await getExternalStorageDirectory();
    if (extDir == null) return null;
    // extDir.path ≈ /storage/emulated/0/Android/data/tu.paquete/files
    final downloadPath = '${extDir.parent.parent.parent.parent.path}/Download';
    final downloadDir = Directory(downloadPath);
    return downloadDir.existsSync() ? downloadDir : null;
  }

  Future<void> _downloadPdf() async {
    // 1) Verifico permisos
    final granted = await _requestStoragePermission();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de almacenamiento denegado')),
      );
      return;
    }

    // 2) Obtengo directorio
    final downloadDir = await _getDownloadDir();
    if (downloadDir == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró la carpeta Descargas')),
      );
      return;
    }

    // 3) Nombre de archivo legible
    final filename =
        'voucher-cuota${widget.cuota.numeroCuota}-${widget.cuota.idPago}.pdf';
    final filePath = '${downloadDir.path}/$filename';
    final file = File(filePath);

    try {
      // 4) Escribo bytes
      await file.writeAsBytes(_pdfBytes!, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Voucher guardado: $filename')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar PDF: $e')));
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    final temp = await getTemporaryDirectory();
    final path =
        '${temp.path}/voucher-cuota${widget.cuota.numeroCuota}-${widget.cuota.idPago}.pdf';
    await File(path).writeAsBytes(_pdfBytes!, flush: true);
    await Share.shareXFiles([XFile(path)], text: 'Aquí tu voucher PDF');
  }

  void _onTapCard() async {
    try {
      // 1) Traer el PDF
      await _fetchPdf();
      if(!mounted) return;
      // 2) Mostrar diálogo con opciones
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('¿Qué deseas hacer?'),
              content: const Text('¿Quieres descargar o compartir el PDF?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _downloadPdf();
                  },
                  child: const Text('Descargar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _sharePdf();
                  },
                  child: const Text('Compartir'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPagado = widget.cuota.fechaPago != null;
    final accentColor = isPagado ? Colors.green : Colors.amber;

    return InkWell(
      onTap: isPagado ? _onTapCard : null,
      child: Card(
        color: Colors.white,
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Cuota ${widget.cuota.numeroCuota}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha((0.2 * 255).toInt()),  
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPagado ? "Pagado" : "Pendiente",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Monto
              Row(
                children: [
                  const Icon(Icons.money, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.moneda} ${widget.cuota.monto}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Fecha de vencimiento
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Vence: ${widget.cuota.fechaVencimiento}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
