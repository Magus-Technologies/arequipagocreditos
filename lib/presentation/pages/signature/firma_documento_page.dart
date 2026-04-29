import 'dart:io';
import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:arequipagocreditos/core/constants/app_constants.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/signature_provider.dart';
import 'signature_canvas_page.dart';

class FirmaDocumentoPage extends StatefulWidget {
  final String title;
  final String pdfUrl;
  final String tipo;
  final int id;
  final VoidCallback? onSigned;
  final bool canPop;

  const FirmaDocumentoPage({
    super.key,
    required this.title,
    required this.pdfUrl,
    required this.tipo,
    required this.id,
    this.onSigned,
    this.canPop = true,
  });

  @override
  State<FirmaDocumentoPage> createState() => _FirmaDocumentoPageState();
}

class _FirmaDocumentoPageState extends State<FirmaDocumentoPage> {
  String? localPath;
  bool isLoadingPdf = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final normalizedUrl = ApiConstants.normalizeUrl(widget.pdfUrl);
      debugPrint('Downloading PDF from: $normalizedUrl');
      
      final response = await http.get(Uri.parse(normalizedUrl));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/documento_${widget.tipo}_${widget.id}.pdf');
        await file.writeAsBytes(bytes);
        if (mounted) {
          setState(() {
            localPath = file.path;
            isLoadingPdf = false;
          });
        }
      } else {
        throw Exception('Error al descargar el PDF: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      if (mounted) {
        setState(() {
          isLoadingPdf = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sigProvider = context.watch<SignatureProvider>();

    return PopScope(
      canPop: widget.canPop,
      child: Scaffold(
        backgroundColor: AppTheme.primary,
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: widget.canPop,
          leading: widget.canPop ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ) : null,
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
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
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha((0.05 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withAlpha((0.1 * 255).toInt()),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Por favor, revise detenidamente el documento antes de proceder con la firma.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: isLoadingPdf
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                ),
                              )
                            : localPath != null
                                ? PDFView(
                                  filePath: localPath,
                                  enableSwipe: true,
                                  swipeHorizontal: false,
                                  autoSpacing: false,
                                  pageFling: true,
                                )
                                : Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Error al cargar el PDF',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            errorMessage ?? 'Error desconocido',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                          const SizedBox(height: 24),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                isLoadingPdf = true;
                                                errorMessage = null;
                                              });
                                              _downloadPdf();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primary,
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text('Reintentar'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha((0.1 * 255).toInt()),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: (localPath != null && !sigProvider.isLoading)
                                ? _goToSign
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: sigProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'FIRMAR DOCUMENTO',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToSign() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => SignatureCanvasPage(title: 'Firma de ${widget.title}'),
      ),
    );

    if (result != null && mounted) {
      _submitSignature(result);
    }
  }

  void _submitSignature(String base64Firma) async {
    final authProvider = context.read<AuthProvider>();
    final sigProvider = context.read<SignatureProvider>();
    final user = authProvider.currentUser!;

    final success = await sigProvider.firmar(
      tipo: widget.tipo,
      id: widget.id,
      firmaBase64: base64Firma,
      nroDocumento: user.nroDocumento,
    );

    if (success) {
      // Si es afiliación, marcar como firmada en la clave dedicada
      if (widget.tipo == 'afiliacion') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.afiliacionFirmadaKey, true);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firma registrada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      if (widget.onSigned != null) {
        widget.onSigned!();
      }
      
      // Solo hacer pop si hay algo en el stack (para contratos)
      // En afiliación, el refresh de authProvider cambiará la vista automáticamente
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sigProvider.errorMessage ?? 'Error al firmar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
