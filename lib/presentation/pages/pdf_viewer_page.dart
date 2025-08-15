import 'dart:convert';
import 'dart:typed_data';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:arequipagocreditos/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class PdfViewerPage extends StatefulWidget {
  final String pdfBase64;
  final int cuota;
  
  const PdfViewerPage({
    super.key,
    required this.pdfBase64,
    required this.cuota,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localPath;
  Uint8List? bytes;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = null;
      });

      bytes = base64Decode(widget.pdfBase64);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp_${widget.cuota}.pdf');
      await file.writeAsBytes(bytes!, flush: true);
      
      if (mounted) {
        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Error al preparar el PDF: $e';
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (bytes == null) return;

    try {
      // Muestra indicador de carga
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(width: 16),
                Text('Descargando archivo...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Obtén el directorio de descargas principal
      Directory? downloadDir = Directory('/storage/emulated/0/Download');

      if (!(await downloadDir.exists())) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo encontrar el directorio de descargas'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Guarda el archivo en la carpeta de descargas principal
      final fileName = 'voucher_cuota_${widget.cuota}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${downloadDir.path}/$fileName');
      await file.writeAsBytes(bytes!, flush: true);

      // Muestra un mensaje de éxito
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Archivo guardado como: $fileName'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar el archivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePdf() async {
    if (bytes == null) return;

    try {
      final temp = await getTemporaryDirectory();
      final fileName = 'voucher_cuota_${widget.cuota}.pdf';
      final path = '${temp.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(bytes!, flush: true);
      
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Voucher de la cuota ${widget.cuota}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir el archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Voucher - Cuota ${widget.cuota}'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!isLoading && !hasError) ...[
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return IconButton(
                  icon: const Icon(Icons.download_outlined),
                  onPressed: authProvider.isLoading ? null : _downloadPdf,
                  tooltip: 'Descargar PDF',
                );
              },
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: authProvider.isLoading ? null : _sharePdf,
                  tooltip: 'Compartir PDF',
                );
              },
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Preparando PDF...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (hasError || localPath == null) {
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
              'Error al cargar el PDF',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _preparePdf,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: PDFView(
          filePath: localPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          onRender: (pages) {
            // PDF rendered successfully
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                hasError = true;
                errorMessage = 'Error al renderizar el PDF: $error';
              });
            }
          },
          onPageError: (page, error) {
            if (mounted) {
              setState(() {
                hasError = true;
                errorMessage = 'Error en página $page: $error';
              });
            }
          },
        ),
      ),
    );
  }
}
