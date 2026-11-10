import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/elegir_documento.dart';
import '../../data/datasources/documentos_pendientes_remote_datasource.dart';
import '../../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'perfil_page.dart';

// Los que usan esta pantalla (y las pruebas) la siguen encontrando aquí.
export '../../core/utils/elegir_documento.dart' show ElegirDocumento;

/// «Actualizar mis datos»: lo que el servidor pide actualizar (`datos_pendientes`) y qué puede hacer el cliente con cada cosa.
///
/// - DNI/CE (anverso y reverso) y recibo de servicios: los sube aquí. NO entran directo: quedan «En revisión» hasta que el personal
///   los apruebe; si los rechaza, se muestra el motivo y se sube otro.
/// - Foto de perfil y SOAT: se actualizan desde el perfil (ya existían).
/// - Teléfono, correo y fecha de nacimiento: los cambia su asesor.
class ActualizarDatosPage extends StatefulWidget {
  const ActualizarDatosPage({super.key, this.servicio, this.elegirDocumento = elegirDocumentoDelCelular});

  /// Solo para pruebas: el servicio que sube el documento.
  final DocumentosPendientesRemoteDataSource? servicio;

  final ElegirDocumento elegirDocumento;

  @override
  State<ActualizarDatosPage> createState() => _ActualizarDatosPageState();
}

class _ActualizarDatosPageState extends State<ActualizarDatosPage> {
  late final DocumentosPendientesRemoteDataSource _servicio =
      widget.servicio ?? DocumentosPendientesRemoteDataSource(client: http.Client());

  String? _subiendo; // código del pendiente que se está enviando

  Future<void> _subir(Map<String, dynamic> pendiente) async {
    final auth = context.read<AuthProvider>();
    final cliente = auth.currentUser;
    if (cliente == null) return;

    final codigo = pendiente['codigo'].toString();
    final etiqueta = (pendiente['corto'] ?? pendiente['mensaje'] ?? 'documento').toString();
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
      await auth.refreshUserDataSilently();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Documento enviado. Nuestro equipo lo revisará y lo verás aquí como «En revisión».'),
          backgroundColor: Colors.green,
        ),
      );
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
    final pendientes = context.watch<AuthProvider>().currentUser?.datosPendientes ?? const <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Actualizar mis datos'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black87,
      ),
      body: pendientes.isEmpty
          ? Center(
              key: const Key('actualizar_datos_al_dia'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 56),
                    const SizedBox(height: 12),
                    const Text('¡Tus datos están al día!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      'Ya puedes solicitar tu financiamiento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Mientras tengas datos por actualizar no podrás solicitar un financiamiento.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35),
                ),
                const SizedBox(height: 12),
                for (final pendiente in pendientes) _tarjeta(pendiente),
              ],
            ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> pendiente) {
    final codigo = pendiente['codigo'].toString();
    final subible = pendiente['subible_desde_app'] == true;
    final envio = pendiente['envio'] is Map ? Map<String, dynamic>.from(pendiente['envio'] as Map) : null;
    final estado = envio?['estado']?.toString();

    final Widget accion;
    if (subible && estado == 'pendiente') {
      accion = _estado(
        key: Key('en_revision_$codigo'),
        color: Colors.amber.shade800,
        fondo: Colors.amber.shade50,
        icono: Icons.hourglass_top,
        titulo: 'En revisión',
        detalle: 'Nuestro equipo lo está revisando. Cuando lo aprueben, este aviso desaparece.',
      );
    } else if (subible) {
      accion = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (estado == 'rechazado') ...[
            _estado(
              key: Key('rechazado_$codigo'),
              color: Colors.red.shade700,
              fondo: Colors.red.shade50,
              icono: Icons.cancel_outlined,
              titulo: 'Rechazado',
              detalle: (envio?['motivo'] ?? 'Sube el documento de nuevo.').toString(),
            ),
            const SizedBox(height: 8),
          ],
          _boton(
            key: Key('subir_$codigo'),
            texto: estado == 'rechazado' ? 'Subir otro' : 'Subir documento',
            icono: Icons.upload_file,
            cargando: _subiendo == codigo,
            onPressed: _subiendo == null ? () => _subir(pendiente) : null,
          ),
        ],
      );
    } else if (codigo == 'foto_perfil' || codigo.startsWith('soat')) {
      accion = _boton(
        key: Key('ir_perfil_$codigo'),
        texto: codigo == 'foto_perfil' ? 'Cambiar foto de perfil' : 'Actualizar SOAT',
        icono: codigo == 'foto_perfil' ? Icons.camera_alt_outlined : Icons.directions_car_outlined,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PerfilPage())),
        relleno: false,
      );
    } else {
      accion = Text(
        'Comunícate con tu asesor para actualizarlo.',
        key: Key('asesor_$codigo'),
        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
      );
    }

    return Container(
      key: Key('pendiente_$codigo'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade500, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (pendiente['mensaje'] ?? '').toString(),
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if ((pendiente['descripcion'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pendiente['descripcion'].toString(),
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.3),
            ),
          ],
          const SizedBox(height: 10),
          accion,
        ],
      ),
    );
  }

  Widget _estado({
    required Key key,
    required Color color,
    required Color fondo,
    required IconData icono,
    required String titulo,
    required String detalle,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                const SizedBox(height: 2),
                Text(detalle, style: TextStyle(color: color, fontSize: 12.5, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _boton({
    required Key key,
    required String texto,
    required IconData icono,
    required VoidCallback? onPressed,
    bool cargando = false,
    bool relleno = true,
  }) {
    final contenido = cargando
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : Icon(icono, size: 18);

    return SizedBox(
      width: double.infinity,
      child: relleno
          ? ElevatedButton.icon(
              key: key,
              onPressed: onPressed,
              icon: contenido,
              label: Text(cargando ? 'Enviando…' : texto),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          : OutlinedButton.icon(
              key: key,
              onPressed: onPressed,
              icon: contenido,
              label: Text(texto),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
    );
  }
}
