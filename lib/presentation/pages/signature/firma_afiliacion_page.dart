import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import '../../providers/signature_provider.dart';
import 'signature_canvas_page.dart';

class FirmaAfiliacionPage extends StatefulWidget {
  const FirmaAfiliacionPage({super.key});

  @override
  State<FirmaAfiliacionPage> createState() => _FirmaAfiliacionPageState();
}

class _FirmaAfiliacionPageState extends State<FirmaAfiliacionPage> {
  String? localPath;
  bool isLoadingPdf = true;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    final authProvider = context.read<AuthProvider>();
    final url = authProvider.currentUser?.contratoAfiliacionUrl;

    if (url == null) {
      setState(() {
        isLoadingPdf = false;
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/contrato_afiliacion.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) {
        setState(() {
          localPath = file.path;
          isLoadingPdf = false;
        });
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      if (mounted) {
        setState(() {
          isLoadingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sigProvider = context.watch<SignatureProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrato de Afiliación'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false, // No volver atrás, es obligatorio
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Por favor, lea el contrato y firme al final para continuar.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: isLoadingPdf
                    ? const Center(child: CircularProgressIndicator())
                    : localPath != null
                        ? PDFView(
                            filePath: localPath,
                          )
                        : const Center(child: Text('Error al cargar el PDF')),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: localPath == null || sigProvider.isLoading ? null : _goToSign,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: sigProvider.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('FIRMAR CONTRATO'),
                  ),
                ),
              ),
            ],
          ),
          if (sigProvider.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _goToSign() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const SignatureCanvasPage(title: 'Firma de Afiliación'),
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
      tipo: 'afiliacion',
      id: user.idConductor,
      firmaBase64: base64Firma,
      nroDocumento: user.nroDocumento,
    );

    if (success && mounted) {
      // Refrescar usuario para actualizar estado de firma
      await authProvider.refreshUserDataFromRemote();
      // El AppWrapper en main.dart detectará el cambio y mostrará DashboardPage
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
