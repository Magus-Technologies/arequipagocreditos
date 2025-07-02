import 'dart:convert';
import 'dart:typed_data';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class PdfViewerScreen extends StatefulWidget {
  final String pdfBase64;
  final int cuota;
  const PdfViewerScreen({
    super.key,
    required this.pdfBase64,
    required this.cuota,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    bytes = base64Decode(widget.pdfBase64);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/temp.pdf');
    await file.writeAsBytes(bytes!, flush: true);
    setState(() => localPath = file.path);
  }

  Future<void> _downloadPdf() async {
    try {
      // Obtén el directorio de descargas principal
      Directory? downloadDir = Directory('/storage/emulated/0/Download');

      if (!(await downloadDir.exists())) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo encontrar el directorio de descargas'),
          ),
        );
        return;
      }

      // Guarda el archivo en la carpeta de descargas principal
      final file = File(
        '${downloadDir.path}/voucher-${widget.cuota.toString()}.pdf',
      );
      await file.writeAsBytes(bytes!, flush: true);

      // Muestra un mensaje de éxito
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Archivo Excel descargado con éxito en la carpeta de Descargas',
          ),
        ),
      );
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar el archivo Excel: $e')),
      );
    }
  }

  Future<void> _sharePdf() async {
    final temp = await getTemporaryDirectory();
    final path = '${temp.path}/voucher-${widget.cuota.toString()}.pdf';
    final bytes = base64Decode(widget.pdfBase64);
    File(path).writeAsBytesSync(bytes);
    Share.shareXFiles([XFile(path)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte PDF'),
        backgroundColor: AppTheme.primary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadPdf,
            tooltip: 'Descargar',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
            tooltip: 'Compartir',
          ),
        ],
      ),
      body:
          localPath == null
              ? const Center(child: CircularProgressIndicator())
              : PDFView(filePath: localPath!),
    );
  }
}

