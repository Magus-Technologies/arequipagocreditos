import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financiamiento_servicio_provider.dart';
import '../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentosFirmadosPage extends StatefulWidget {
  const DocumentosFirmadosPage({super.key});

  @override
  State<DocumentosFirmadosPage> createState() => _DocumentosFirmadosPageState();
}

class _DocumentosFirmadosPageState extends State<DocumentosFirmadosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conductorId = context.read<AuthProvider>().currentUser?.idConductor ?? 0;
      if (conductorId != 0) {
        context.read<FinanciamientoServicioProvider>().loadDocumentosFirmados(conductorId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos Firmados', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<FinanciamientoServicioProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final listado = provider.documentosFirmados;
          if (listado == null || listado.documentos.isEmpty) {
            return const Center(child: Text('No tienes documentos firmados aún.'));
          }

          return Column(
            children: [
              _buildResumen(listado.resumen),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listado.documentos.length,
                  itemBuilder: (context, index) {
                    final doc = listado.documentos[index];
                    return _buildDocumentCard(doc);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumen(dynamic resumen) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha((0.1 * 255).toInt()), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(resumen.nombreConductor, 
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('DNI: ${resumen.nroDocumento}', 
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResumenItem('Total', resumen.totalDocumentos.toString()),
              _buildResumenItem('Contratos', resumen.contratos.toString()),
              _buildResumenItem('Afiliación', resumen.afiliaciones.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildDocumentCard(dynamic doc) {
    final bool isFinanciamiento = doc.tipo == 'financiamiento';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        title: Text(doc.nombreDocumento, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Firmado el: ${DateFormat('dd/MM/yyyy HH:mm').format(doc.firmadoAt)}', 
          style: const TextStyle(fontSize: 12)),
        leading: Icon(isFinanciamiento ? Icons.description : Icons.person_add, 
          color: isFinanciamiento ? Colors.blue : Colors.green),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFinanciamiento) ...[
                  _buildDetailRow('Grupo:', doc.grupoFinanciamiento ?? '-'),
                  _buildDetailRow('Monto:', 'S/ ${doc.montoTotal?.toStringAsFixed(2) ?? '0.00'}'),
                  _buildDetailRow('Cuotas:', '${doc.cantidadCuotas} (${doc.frecuenciaPago})'),
                ],
                _buildDetailRow('Firmado por:', doc.nombreFirmante),
                _buildDetailRow('Cargo:', doc.cargo),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openUrl(ApiConstants.normalizeUrl(doc.firmaUrl)),
                        icon: const Icon(Icons.image),
                        label: const Text('Ver Firma'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (doc.contratoUrl != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openUrl(ApiConstants.normalizeUrl(doc.contratoUrl)),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Ver PDF'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir la URL: $url')),
        );
      }
    }
  }
}
