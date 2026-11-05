import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/evento_models.dart';
import '../../presentation/components/evento_banner_dialog.dart';
import '../../presentation/pages/evento_terminos_page.dart';
import '../../presentation/providers/evento_provider.dart';
import 'evento_persona.dart';

/// Aviso de EVENTO al entrar al inicio (tickets del 3er Aniversario y los que vengan).
///
/// Misma idea que [DatosPendientesGate]: una vez por sesión y por evento. La ventana muestra el banner; tocarlo lleva a los
/// términos y de ahí a la compra. Si dice «Ahora no», queda la entrada fija del inicio ([EventoAccesoCard]).
///
/// Un error de red acá se traga en silencio: este aviso NUNCA bloquea ni ensucia el inicio.
class EventoGate {
  /// «persona:evento» de los avisos ya mostrados en esta sesión del app.
  static final Set<String> _mostrados = <String>{};

  static String _clave(int clienteConductorId, int eventoId) => '$clienteConductorId:$eventoId';

  /// ¿Toca mostrar el aviso de este evento a esta persona? Solo si hay evento, no se le mostró ya y todavía puede comprar: quien
  /// ya llegó a su tope de tickets no necesita que se le invite a comprar (le queda la entrada fija del inicio).
  static bool debeMostrar(EventoModel? evento, int clienteConductorId) {
    if (evento == null) return false;
    final mis = evento.misTickets;
    if (mis != null && mis.disponibles <= 0) return false;
    return !_mostrados.contains(_clave(clienteConductorId, evento.id));
  }

  /// Solo para pruebas.
  static void reiniciarSesion() => _mostrados.clear();

  /// Pide el evento activo Y las compras de la persona, sin mostrar nada, para que la entrada fija del inicio aparezca sin
  /// esperar a que se cierren los otros avisos. Las compras hacen falta porque con el evento ya empezado el servidor deja de
  /// mandarlo como activo y quien pagó igual tiene que poder llegar a su código.
  static Future<void> precargar(BuildContext context) async {
    try {
      final persona = EventoPersona.de(context);
      if (persona == null) return;
      final provider = context.read<EventoProvider>();
      await Future.wait([
        provider.cargarActivo(clienteConductorId: persona.id, nroDocumento: persona.documento),
        provider.cargarMisCompras(clienteConductorId: persona.id, nroDocumento: persona.documento),
      ]);
    } catch (_) {
      // Sin conexión: no hay entrada fija ni aviso, y el inicio sigue igual.
    }
  }

  static Future<void> checkOnDashboard(BuildContext context) async {
    try {
      final persona = EventoPersona.de(context);
      if (persona == null) return;

      final provider = context.read<EventoProvider>();
      await provider.cargarActivo(clienteConductorId: persona.id, nroDocumento: persona.documento);
      if (!context.mounted) return;

      final evento = provider.evento;
      if (evento == null || !debeMostrar(evento, persona.id)) return;

      _mostrados.add(_clave(persona.id, evento.id));
      final comprar = await showDialog<bool>(
        context: context,
        builder: (_) => EventoBannerDialog(evento: evento),
      );

      if (comprar == true && context.mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventoTerminosPage()));
      }
    } catch (_) {
      // Nunca bloquea el inicio.
    }
  }
}
