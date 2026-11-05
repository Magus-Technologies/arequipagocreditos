import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/auth_provider.dart';

/// Quién es la persona para el módulo «Eventos». No hay token: el servidor pide `cliente_conductor_id` + `nro_documento` y que
/// coincidan. El id es `clientes_conductores.id` (`idConductor` de la sesión).
class EventoPersona {
  final int id;
  final String documento;

  const EventoPersona({required this.id, required this.documento});

  /// La persona de la sesión, o null si todavía no se cargó el usuario.
  static EventoPersona? de(BuildContext context) {
    final usuario = context.read<AuthProvider>().currentUser;
    if (usuario == null) return null;
    return EventoPersona(id: usuario.idConductor, documento: usuario.nroDocumento);
  }
}
