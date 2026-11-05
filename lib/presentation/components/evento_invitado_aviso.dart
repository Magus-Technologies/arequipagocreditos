import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/evento_provider.dart';
import 'evento_banner_dialog.dart';

/// Aviso FLOTANTE del evento para quien todavía NO inició sesión: al abrir la pantalla de bienvenida, si hay un evento activo, sale una
/// ventana con su banner, nombre y fecha, y el botón «Ver más detalle · Inicia sesión para continuar» (llama a [onIniciarSesion]).
/// «Ahora no» la cierra. El detalle completo (lugar, precio y compra) queda detrás del inicio de sesión.
///
/// No dibuja nada en la pantalla (es solo el disparador). Sale UNA vez por evento y por apertura del app; sin evento, sin conexión
/// o si la persona ya se fue de la bienvenida (p. ej. tocó «Iniciar sesión» antes de que llegara la respuesta) no sale nada.
class EventoInvitadoAviso extends StatefulWidget {
  final VoidCallback onIniciarSesion;

  const EventoInvitadoAviso({super.key, required this.onIniciarSesion});

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
    if (evento == null || EventoInvitadoAviso._mostrados.contains(evento.id)) return;
    // Si la persona ya abrió «Iniciar sesión» u otra pantalla, la ventana no se le pone encima.
    if (ModalRoute.of(context)?.isCurrent != true) return;

    EventoInvitadoAviso._mostrados.add(evento.id);
    final entrar = await showDialog<bool>(
      context: context,
      builder: (_) => EventoBannerDialog(evento: evento, invitado: true),
    );
    if (entrar == true && mounted) widget.onIniciarSesion();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
