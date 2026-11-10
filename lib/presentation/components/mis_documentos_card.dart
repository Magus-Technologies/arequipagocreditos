import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/elegir_documento.dart';
import '../../data/datasources/documentos_pendientes_remote_datasource.dart';
import '../providers/auth_provider.dart';
import 'perfil_seccion_card.dart';

/// «Mis documentos» del perfil: los mismos documentos que tiene su formulario en el dashboard (DNI, recibo, licencia, tarjeta de
/// propiedad, SOAT…, según su tipo de cliente), cada uno con su estado.
///
/// Solo se puede SUBIR lo que le falta, lo que el personal rechazó o lo que su aviso pide (p. ej. SOAT vencido): un documento ya guardado
/// no se cambia desde el app (podría subir uno errado; para eso está su asesor). El servidor decide con `puede_subir`. Nada entra
/// directo: lo que sube queda «En revisión» hasta que el personal lo apruebe en el dashboard; si lo rechaza se muestra el motivo y se
/// sube otro. Si su tipo de cliente no tiene lista, la tarjeta no se dibuja.
class MisDocumentosCard extends StatefulWidget {
  const MisDocumentosCard({super.key, this.servicio, this.elegirDocumento = elegirDocumentoDelCelular});

  /// Solo para pruebas: el servicio que consulta y sube los documentos.
  final DocumentosPendientesRemoteDataSource? servicio;

  final ElegirDocumento elegirDocumento;

  @override
  State<MisDocumentosCard> createState() => _MisDocumentosCardState();
}

class _MisDocumentosCardState extends State<MisDocumentosCard> {
  late final DocumentosPendientesRemoteDataSource _servicio =
      widget.servicio ?? DocumentosPendientesRemoteDataSource(client: http.Client());

  List<Map<String, dynamic>>? _documentos;
  bool _cargando = true;
  String? _error;
  String? _subiendo; // código del documento que se está enviando

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final cliente = context.read<AuthProvider>().currentUser;
    if (cliente == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    if (mounted) setState(() => _cargando = true);
    try {
      final lista = await _servicio.listarMisDocumentos(clienteId: cliente.idConductor, nroDocumento: cliente.nroDocumento);
      if (!mounted) return;
      setState(() {
        _documentos = lista;
        _error = null;
      });
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos cargar tus documentos.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _subir(Map<String, dynamic> documento) async {
    final auth = context.read<AuthProvider>();
    final cliente = auth.currentUser;
    if (cliente == null) return;

    final codigo = documento['codigo'].toString();
    final etiqueta = documento['etiqueta'].toString();
    final messenger = ScaffoldMessenger.of(context);

    final archivo = await widget.elegirDocumento(context, 'Subir $etiqueta');
    if (archivo == null || !mounted) return;

    setState(() => _subiendo = codigo);
    try {
      await _servicio.subir(
        clienteId: cliente.idConductor,
        nroDocumento: cliente.nroDocumento,
        tipoDocumento: codigo,
        archivo: archivo,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Documento enviado. Nuestro equipo lo revisará y lo verás aquí como «En revisión».'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargar();
      // También su alerta de «Datos por actualizar» (banner del perfil y del dashboard).
      await auth.refreshUserDataSilently();
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el documento. Inténtalo de nuevo.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _subiendo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentos = _documentos;

    // Sin lista para su tipo de cliente: no hay nada que mostrar.
    if (documentos != null && documentos.isEmpty) return const SizedBox.shrink();

    const titulo = 'Mis documentos';
    const subtitulo = 'Sube los documentos que te falten o que tu aviso pida. Nuestro equipo los revisa antes de que cuenten.';

    if (documentos == null) {
      return PerfilSeccionCard(
        key: const Key('mis_documentos'),
        titulo: titulo,
        icono: Icons.folder_open_outlined,
        subtitulo: subtitulo,
        children: [
          if (_error != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error!, key: const Key('mis_documentos_error'), style: TextStyle(fontSize: 13.5, color: Colors.red.shade700)),
                const SizedBox(height: 6),
                TextButton.icon(
                  key: const Key('mis_documentos_reintentar'),
                  onPressed: _cargando ? null : _cargar,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.black87),
                ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      );
    }

    return PerfilSeccionCard(
      key: const Key('mis_documentos'),
      titulo: titulo,
      icono: Icons.folder_open_outlined,
      subtitulo: subtitulo,
      children: [for (final documento in documentos) _fila(documento)],
    );
  }

  Widget _fila(Map<String, dynamic> documento) {
    final codigo = documento['codigo'].toString();
    final guardado = documento['guardado'] == true;
    final enAlerta = documento['en_alerta'] == true;
    final puedeSubir = documento['puede_subir'] == true;
    final envio = documento['envio'] is Map ? Map<String, dynamic>.from(documento['envio'] as Map) : null;
    final estadoEnvio = envio?['estado']?.toString();

    final IconData icono;
    final Color color;
    final String estado;
    final String? accion; // texto del botón; null = no hay acción (en revisión)

    if (estadoEnvio == 'pendiente') {
      icono = Icons.hourglass_top;
      color = Colors.amber.shade800;
      estado = 'En revisión: lo está revisando nuestro equipo.';
      accion = null;
    } else if (estadoEnvio == 'rechazado') {
      icono = Icons.cancel_outlined;
      color = Colors.red.shade700;
      estado = 'Rechazado: ${(envio?['motivo'] ?? 'sube el documento de nuevo').toString()}';
      accion = puedeSubir ? 'Subir otro' : null;
    } else if (guardado && enAlerta) {
      // Lo tiene guardado, pero su aviso (p. ej. SOAT vencido) pide uno nuevo.
      icono = Icons.warning_amber_rounded;
      color = Colors.red.shade700;
      estado = 'Tu aviso pide subir uno vigente.';
      accion = puedeSubir ? 'Subir nuevo' : null;
    } else if (guardado) {
      icono = Icons.check_circle_outline;
      color = Colors.green.shade700;
      final fecha = documento['guardado_fecha']?.toString();
      estado = fecha == null || fecha.isEmpty ? 'Guardado' : 'Guardado el ${fechaLegible(fecha)}';
      // Ya guardado: no se cambia desde el app.
      accion = null;
    } else {
      icono = Icons.upload_file_outlined;
      color = enAlerta ? Colors.red.shade700 : Colors.grey.shade600;
      estado = enAlerta ? 'Falta: lo pide tu aviso de datos por actualizar.' : 'Aún no lo has subido.';
      accion = puedeSubir ? 'Subir' : null;
    }

    final subiendo = _subiendo == codigo;

    return Row(
      key: Key('doc_$codigo'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
          child: Icon(icono, size: 19, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                documento['etiqueta'].toString(),
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.2),
              ),
              const SizedBox(height: 2),
              Text(estado, key: Key('doc_estado_$codigo'), style: TextStyle(fontSize: 12.5, color: color, height: 1.25)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (subiendo)
          const Padding(
            padding: EdgeInsets.only(top: 8, right: 12),
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (accion != null)
          TextButton(
            key: Key('doc_subir_$codigo'),
            onPressed: _subiendo == null ? () => _subir(documento) : null,
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(accion, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
