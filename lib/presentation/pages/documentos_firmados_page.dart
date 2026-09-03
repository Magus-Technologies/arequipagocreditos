import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financiamiento_servicio_provider.dart';
import '../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../widgets/image_full_screen_view.dart';
import 'pdf_viewer_page.dart';

class DocumentosFirmadosPage extends StatefulWidget {
  /// false cuando esta pantalla vive como pestaña raíz de [MainShellPage].
  final bool showBackButton;

  const DocumentosFirmadosPage({super.key, this.showBackButton = true});

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
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary,
              AppTheme.primary.withAlpha((0.8 * 255).toInt()),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Consumer<FinanciamientoServicioProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Error al cargar documentos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.error!,
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      final listado = provider.documentosFirmados;
                      if (listado == null || listado.documentos.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description_outlined, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Sin documentos firmados',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aún no tienes documentos firmados',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          _buildResumen(listado.resumen),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              if (widget.showBackButton)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.3 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              else
                const SizedBox(width: 48),
              const Expanded(
                child: Text(
                  'Documentos Firmados',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.3 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha((0.3 * 255).toInt()),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.5 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_special, color: Colors.black87, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Documentos',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Contratos y afiliaciones',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumen(dynamic resumen) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1F2937),
              const Color(0xFF374151),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.15 * 255).toInt()),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              resumen.nombreConductor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'DNI: ${resumen.nroDocumento}',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: _buildResumenItem('Total', resumen.totalDocumentos.toString(), Icons.folder_copy)),
                  VerticalDivider(color: Colors.white24, thickness: 1, width: 1),
                  Expanded(child: _buildResumenItem('Contratos', resumen.contratos.toString(), Icons.description)),
                  VerticalDivider(color: Colors.white24, thickness: 1, width: 1),
                  Expanded(child: _buildResumenItem('Afiliación', resumen.afiliaciones.toString(), Icons.person_add)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(dynamic doc) {
    final bool isFinanciamiento = doc.tipo == 'financiamiento';
    final Color accentColor = isFinanciamiento ? Colors.blue.shade600 : Colors.green.shade600;
    final IconData icon = isFinanciamiento ? Icons.description : Icons.person_add;

    final String? rawPdfUrl = doc.contratoUrl ??
        (doc.tipo == 'conductor'
            ? context.read<AuthProvider>().currentUser?.contratoAfiliacionUrl
            : null);
    final String? pdfUrl = (rawPdfUrl != null && rawPdfUrl.isNotEmpty)
        ? ApiConstants.normalizeUrl(rawPdfUrl)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.06 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withAlpha((0.12 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  doc.nombreDocumento,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (pdfUrl != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 14, color: Colors.red.shade600),
                      const SizedBox(width: 3),
                      Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Firmado el: ${DateFormat('dd/MM/yyyy HH:mm').format(doc.firmadoAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFinanciamiento) ...[
                    _buildDetailRow(Icons.group, 'Grupo', doc.grupoFinanciamiento ?? '-'),
                    _buildDetailRow(Icons.attach_money, 'Monto', 'S/ ${doc.montoTotal?.toStringAsFixed(2) ?? '0.00'}'),
                    _buildDetailRow(Icons.calendar_month, 'Cuotas', '${doc.cantidadCuotas} (${doc.frecuenciaPago})'),
                  ],
                  _buildDetailRow(Icons.person, 'Firmado por', doc.nombreFirmante),
                  _buildDetailRow(Icons.work, 'Cargo', doc.cargo),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final url = ApiConstants.normalizeUrl(doc.firmaUrl);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageFullScreenView(
                                  imageUrl: url,
                                  heroTag: 'firma_${doc.id}_${doc.tipo}',
                                  title: 'Firma de ${doc.nombreFirmante}',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.image, size: 16),
                          label: const Text('Ver Firma'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (pdfUrl != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfViewerPage(
                                    title: doc.nombreDocumento,
                                    pdfUrl: pdfUrl,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const Text('Ver PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

}
