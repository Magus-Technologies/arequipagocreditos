import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/presentation/components/header_icon.dart';
import 'package:arequipagocreditos/presentation/pages/mi_nivel_page.dart';
import 'package:arequipagocreditos/presentation/pages/mis_financiamientos_page.dart';
import 'package:arequipagocreditos/presentation/pages/perfil_page.dart';
import 'package:arequipagocreditos/presentation/pages/puntuacion_page.dart';
import 'package:arequipagocreditos/presentation/pages/notification_detail_page.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/presentation/providers/resumen_crediticio_provider.dart';
import 'package:arequipagocreditos/presentation/providers/nivel_taller_provider.dart';
import 'package:arequipagocreditos/presentation/providers/notification_provider.dart';
import 'package:arequipagocreditos/data/models/notification_model.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

class Header extends StatefulWidget {
  final ConductorModel conductor;

  const Header({super.key, required this.conductor});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Llama al provider para cargar los datos después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ResumenCrediticioProvider>(
        context,
        listen: false,
      );
      provider.fetchResumen(
        widget.conductor.idConductor,
        widget.conductor.tipo,
      );

      Provider.of<NivelTallerProvider>(context, listen: false)
          .cargarNivel(widget.conductor.idConductor);

      final notifProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notifProvider.init(widget.conductor.idConductor.toString(), widget.conductor.tipo);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refrescar notificaciones cuando la app vuelve al primer plano
      final notifProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notifProvider.refreshNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ajusta aquí el nombre del campo si tu modelo usa otro (p.ej. fotoPerfil, foto_url...)
    final String? imageUrl = widget.conductor.fotoPerfil;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withAlpha((0.8 * 255).toInt()),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Primera fila: Avatar, saludo y acciones
          Row(
            children: [
              // Avatar del usuario: ahora HeaderIcon acepta imageUrl
              HeaderIcon(
                imageUrl: imageUrl,
                icon: Icons.person,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PerfilPage()),
                  );
                },
              ),
              const SizedBox(width: 16),
              // Saludo mejorado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${widget.conductor.nombres.split(' ')[0]} 👋',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Iconos de acción mejorados
              Row(
                children: [
                  HeaderIcon(
                    icon: Icons.headset_mic,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Próximamente: Soporte técnico'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Notifications Icon with Badge
                  Consumer<NotificationProvider>(
                    builder: (context, notifProvider, _) {
                      return Stack(
                        children: [
                          HeaderIcon(
                            icon: Icons.notifications_outlined,
                            onTap: () {
                              _showNotifications(
                                context,
                                notifProvider.notifications,
                                notifProvider,
                              );
                            },
                          ),
                          if (notifProvider.unreadCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${notifProvider.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Fila compacta: Créditos activos / Mi Nivel / Puntaje crediticio,
          // todas visibles a la vez (antes era un carrusel con Cupones, que
          // quedaba escondido salvo que la persona deslizara).
          Consumer<ResumenCrediticioProvider>(
            builder: (context, resumenProvider, _) {
              final resumen = resumenProvider.resumen;
              return SizedBox(
                height: 80,
                child: Row(
                  children: [
                    Expanded(
                      child: _CompactStat(
                        icon: const Icon(Icons.credit_card_rounded, color: Color(0xFFF7D046), size: 15),
                        label: 'Créditos activos',
                        value: resumenProvider.loading
                            ? '-'
                            : (resumen != null ? resumen.creditosActivos.toString() : '-'),
                        primaryColor: const Color(0xFF1B2A4A),
                        secondaryColor: const Color(0xFF2C4470),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MisFinanciamientosPage(conductor: widget.conductor)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Consumer<NivelTallerProvider>(
                        builder: (context, nivelProvider, _) {
                          final nivel = nivelProvider.nivel;
                          final colors = _coloresParaNivel(nivel?.nivelActual);
                          return _CompactStat(
                            icon: Icon(
                              Icons.emoji_events_rounded,
                              color: colors.$3 == Colors.white ? Colors.white : const Color(0xFFFFE082),
                              size: 15,
                            ),
                            label: 'Mi nivel',
                            value: nivelProvider.isLoading
                                ? '-'
                                : (nivel?.tieneNivel == true ? _capitalizar(nivel!.nivelActual!) : 'Sin nivel'),
                            primaryColor: colors.$1,
                            secondaryColor: colors.$2,
                            contentColor: colors.$3,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MiNivelPage()),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CompactStat(
                        icon: const Icon(Icons.star_rounded, color: Colors.white, size: 17),
                        label: 'Puntaje crediticio',
                        value: resumenProvider.loading
                            ? '-'
                            : (resumen != null ? resumen.puntaje.toString() : '-'),
                        primaryColor: const Color(0xFFF7A81B),
                        secondaryColor: const Color(0xFFEF7F1A),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PuntuacionPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNotifications(
    BuildContext context,
    List<NotificationModel> notifications,
    NotificationProvider notifProvider,
  ) {
    // Refrescar notificaciones al abrir el modal
    notifProvider.refreshNotifications();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        bool isMarkingAll = false;
        return StatefulBuilder(
          builder: (context, setModalState) {

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra superior decorativa
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notificaciones',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        // Acciones del panel. Se leen del provider (no de la
                        // lista recibida) para que se actualicen al borrar.
                        Consumer<NotificationProvider>(
                          builder: (context, provider, _) {
                            if (isMarkingAll) {
                              return const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            }

                            final lista = provider.notifications;
                            final hayNoLeidas = lista.any((n) => !n.isRead);
                            final hayLeidas = lista.any((n) => n.isRead);

                            if (lista.isEmpty) return const SizedBox.shrink();

                            return PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.black54),
                              tooltip: 'Opciones',
                              onSelected: (opcion) async {
                                if (opcion == 'marcar') {
                                  setModalState(() => isMarkingAll = true);
                                  await notifProvider.markAllAsRead();
                                  setModalState(() => isMarkingAll = false);
                                  return;
                                }

                                final todas = opcion == 'borrar_todas';
                                final confirmado = await _confirmarBorrado(context, todas: todas);
                                if (!confirmado) return;

                                setModalState(() => isMarkingAll = true);
                                await notifProvider.deleteAllNotifications(todas: todas);
                                setModalState(() => isMarkingAll = false);
                              },
                              itemBuilder: (context) => [
                                if (hayNoLeidas)
                                  const PopupMenuItem(
                                    value: 'marcar',
                                    child: _OpcionMenu(
                                      icono: Icons.done_all,
                                      texto: 'Marcar todo como leído',
                                    ),
                                  ),
                                if (hayLeidas)
                                  const PopupMenuItem(
                                    value: 'borrar_leidas',
                                    child: _OpcionMenu(
                                      icono: Icons.delete_sweep_outlined,
                                      texto: 'Borrar las leídas',
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'borrar_todas',
                                  child: _OpcionMenu(
                                    icono: Icons.delete_outline,
                                    texto: 'Borrar todas',
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Consumer<NotificationProvider>(
                      builder: (context, provider, _) {
                        final notifs = provider.notifications;
                        return notifs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      size: 80,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay notificaciones',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom),
                                itemCount: notifs.length,
                                itemBuilder: (context, index) {
                                  final notification = notifs[index];
                                  final isRead = notification.isRead;

                                  return Dismissible(
                                    key: Key(notification.id),
                                    direction: DismissDirection.horizontal,
                                    confirmDismiss: (direction) async {
                                      if (direction == DismissDirection.endToStart) {
                                        // Deslizar a la izquierda → Eliminar
                                        return await provider.deleteNotification(notification.id);
                                      } else if (direction == DismissDirection.startToEnd && !isRead) {
                                        // Deslizar a la derecha → Marcar como leída
                                        await provider.markAsRead(notification.id);
                                        return false;
                                      }
                                      return false;
                                    },
                                    background: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white),
                                    ),
                                    secondaryBackground: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.delete_outline, color: Colors.white),
                                    ),
                                    child: FadeInRight(
                                      delay: Duration(milliseconds: 50 * index),
                                      duration: const Duration(milliseconds: 300),
                                      child: _NotificationItem(
                                        notification: notification,
                                        onTap: () async {
                                          if (!isRead) {
                                            await provider.markAsRead(notification.id);
                                          }
                                          // Siempre se abre el detalle: en la lista el
                                          // mensaje se corta a 2 lineas, asi que el
                                          // usuario necesita verlo completo aunque la
                                          // notificacion no traiga imagen ni adjunto.
                                          // ignore: use_build_context_synchronously
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => NotificationDetailPage(
                                                  notification: notification,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

String _capitalizar(String texto) => texto.isEmpty ? texto : '${texto[0].toUpperCase()}${texto.substring(1)}';

/// Opcion del menu de acciones del panel de notificaciones.
class _OpcionMenu extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color? color;

  const _OpcionMenu({required this.icono, required this.texto, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 20, color: color ?? Colors.black54),
        const SizedBox(width: 12),
        Text(texto, style: TextStyle(fontSize: 14, color: color ?? Colors.black87)),
      ],
    );
  }
}

/// Confirma el borrado. Borrar TODAS incluye las no leidas, asi que se avisa.
Future<bool> _confirmarBorrado(BuildContext context, {required bool todas}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(todas ? '¿Borrar todas?' : '¿Borrar las leídas?'),
      content: Text(
        todas
            ? 'Se eliminarán todas tus notificaciones, incluidas las que todavía no leíste. No se puede deshacer.'
            : 'Se eliminarán las notificaciones que ya leíste. Las no leídas se mantienen.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Borrar'),
        ),
      ],
    ),
  );

  return confirmado ?? false;
}

/// (primario, secundario, color de contenido) para el degradado de la tarjeta
/// "Mi Nivel" segun el nivel actual. Oro va en dorado con texto oscuro (como
/// el diseño de gerencia); Bronce/Plata mantienen sus tonos con texto blanco.
(Color, Color, Color) _coloresParaNivel(String? nivel) {
  switch (nivel) {
    case 'oro':
      return (const Color(0xFFF7B500), const Color(0xFFEFA200), const Color(0xFF3A2700));
    case 'plata':
      return (const Color(0xFF9CA3AF), const Color(0xFF6B7280), Colors.white);
    case 'bronce':
      return (const Color(0xFFB45309), const Color(0xFF92400E), Colors.white);
    default:
      return (const Color(0xFF9CA3AF), const Color(0xFF6B7280), Colors.white);
  }
}

/// Tarjeta compacta para la fila de estadisticas del header (Creditos / Mi
/// Nivel / Puntaje): icono en circulo a la izquierda, titulo + valor a la
/// derecha y chevron en la esquina — diseño pedido por gerencia.
///
/// Ojo con el ancho: entran 3 por fila en un celular (~104dp), asi que el
/// icono es chico (27) y el titulo 2 lineas de 8.5 — si se agrandan, el texto
/// se corta (pasó con la primera version).
class _CompactStat extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final Color primaryColor;
  final Color secondaryColor;

  /// Color del texto, circulo del icono y chevron: blanco por defecto; oscuro
  /// en tarjetas claras (ej. nivel Oro).
  final Color contentColor;
  final VoidCallback? onTap;

  const _CompactStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryColor,
    required this.secondaryColor,
    this.contentColor = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withAlpha((0.28 * 255).toInt()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Chevron en la esquina (como las cards de Servicios), sin robar
              // ancho al titulo.
              Positioned(
                top: 7,
                right: 7,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 13,
                  color: contentColor.withAlpha((0.55 * 255).toInt()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  children: [
                    // Icono en circulo con aro translucido
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: contentColor.withAlpha((0.14 * 255).toInt()),
                        border: Border.all(
                          color: contentColor.withAlpha((0.45 * 255).toInt()),
                          width: 1.2,
                        ),
                      ),
                      child: icon,
                    ),
                    const SizedBox(width: 5),
                    // Titulo (arriba) + valor (abajo)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              color: contentColor,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              height: 1.12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value,
                            style: TextStyle(
                              color: contentColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBirthday = notification.data.type == 'birthday';
    final isRead = notification.isRead;

    // Colores y diseño basado en el tipo
    final Color primaryColor = isBirthday ? Colors.pink : AppTheme.primary;
    final IconData icon = isBirthday ? Icons.cake : Icons.notifications;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            isRead
                ? Colors.grey[50]
                : primaryColor.withAlpha((0.05 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isRead
                  ? Colors.grey[200]!
                  : primaryColor.withAlpha((0.2 * 255).toInt()),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono decorativo
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isRead
                            ? Colors.grey[200]
                            : primaryColor.withAlpha((0.1 * 255).toInt()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color:
                        isRead
                            ? Colors.grey[400]
                            : primaryColor.withAlpha((0.8 * 255).toInt()),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.data.title,
                              style: TextStyle(
                                fontWeight:
                                    isRead ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 15,
                                color:
                                    isRead ? Colors.grey[600] : Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            _getTimeAgo(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.data.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: isRead ? Colors.grey[400] : Colors.black54,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Indicadores de contenido rico
                      if (notification.data.hasImage ||
                          notification.data.hasFile ||
                          notification.data.hasLink) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (notification.data.hasImage)
                              _RichContentChip(
                                icon: Icons.image,
                                label: 'Imagen',
                                color: primaryColor,
                              ),
                            if (notification.data.hasFile)
                              _RichContentChip(
                                icon: Icons.attach_file,
                                label: notification.data.fileName ?? 'Archivo',
                                color: primaryColor,
                              ),
                            if (notification.data.hasLink)
                              _RichContentChip(
                                icon: Icons.link,
                                label: 'Enlace',
                                color: primaryColor,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withAlpha((0.4 * 255).toInt()),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }
}

class _RichContentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RichContentChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
