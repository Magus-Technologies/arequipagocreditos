import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/evento_models.dart';
import '../pages/evento_detalle_page.dart';
import '../providers/evento_provider.dart';
import 'evento_banner_dialog.dart';

/// Aviso FLOTANTE del evento para quien todavía NO inició sesión: al abrir la pantalla de bienvenida, si hay un evento PÚBLICO activo, sale
/// una ventana con su banner, nombre, fecha, lugar y precio, y el botón «Ver evento y comprar» (abre su detalle, donde se compra como
/// invitado, SIN cuenta). Debajo, «Ya tengo cuenta · Iniciar sesión» (llama a [onIniciarSesion]). «Ahora no» la cierra. Un evento privado
/// (solo clientes GO) no llega aquí: el servidor no se lo manda a quien no inició sesión.
///
/// No dibuja nada en la pantalla (es solo el disparador). Sale UNA vez por evento y por apertura del app; sin evento, sin conexión
/// o si la persona ya se fue de la bienvenida (p. ej. tocó «Iniciar sesión» antes de que llegara la respuesta) no sale nada.
class EventoInvitadoAviso extends StatefulWidget {
  final VoidCallback onIniciarSesion;

  /// Qué hacer al tocar «Ver evento y comprar». Por defecto abre el detalle del evento (se cambia en pruebas).
  final void Function(EventoModel evento)? onVerEvento;

  const EventoInvitadoAviso({super.key, required this.onIniciarSesion, this.onVerEvento});

  /// Eventos (por id) cuyo aviso ya se mostró en esta apertura del app.
  static final Set<int> _mostrados = <int>{};

  /// Solo para pruebas.
  static void reiniciarSesion() => _mostrados.clear();

  @override
  State<EventoInvitadoAviso> createState() => _EventoInvitadoAvisoState();
}

class _EventoInvitadoAvisoState extends State<EventoInvitadoAviso> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrar());
  }

  Future<void> _mostrar() async {
    if (!mounted) return;
    final provider = context.read<EventoProvider>();
    await provider.cargarActivoPublico(); // nunca lanza
    if (!mounted) return;

    final evento = provider.eventoPublico;
    if (evento == null || evento.esPrivado || EventoInvitadoAviso._mostrados.contains(evento.id)) return;
    // Si la persona ya abrió «Iniciar sesión» u otra pantalla, la ventana no se le pone encima.
    if (ModalRoute.of(context)?.isCurrent != true) return;

    EventoInvitadoAviso._mostrados.add(evento.id);
    final eleccion = await showDialog<Object?>(
      context: context,
      builder: (_) => EventoBannerDialog(evento: evento, invitado: true),
    );
    if (!mounted) return;
    if (eleccion == true) {
      final verEvento = widget.onVerEvento;
      if (verEvento != null) {
        verEvento(evento);
      } else {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventoDetallePage(evento: evento, realizado: false)));
      }
    } else if (eleccion == 'sesion') {
      widget.onIniciarSesion();
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
