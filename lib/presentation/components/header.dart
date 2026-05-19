import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/presentation/components/component_quick_stat.dart';
import 'package:arequipagocreditos/presentation/components/header_icon.dart';
import 'package:arequipagocreditos/presentation/pages/cupones_page.dart';
import 'package:arequipagocreditos/presentation/pages/perfil_page.dart';
import 'package:arequipagocreditos/presentation/pages/puntuacion_page.dart';
import 'package:arequipagocreditos/presentation/pages/notification_detail_page.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/presentation/providers/resumen_crediticio_provider.dart';
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

class _HeaderState extends State<Header> {
  @override
  void initState() {
    super.initState();
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

      final notifProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notifProvider.init(widget.conductor.idConductor.toString(), widget.conductor.tipo);
    });
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
          Consumer<ResumenCrediticioProvider>(
            builder: (context, resumenProvider, _) {
              if (resumenProvider.loading) {
                return const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (resumenProvider.error != null) {
                return SizedBox(
                  height: 90,
                  child: Center(
                    child: const Text('Error al cargar datos'),
                  ), // Puedes personalizar el error
                );
              }
              final resumen = resumenProvider.resumen;
              return SizedBox(
                height: 90,
                child: PageView(
                  padEnds: false,
                  controller: PageController(viewportFraction: 0.8),
                  children: [
                    ComponentQuickStat(
                      emoji: '💳',
                      label: 'Créditos Activos',
                      value:
                          resumen != null
                              ? resumen.creditosActivos.toString()
                              : '-',
                      primaryColor: const Color(0xFF1F2937),
                      secondaryColor: const Color(0xFF374151),
                    ),
                    ComponentQuickStat(
                      emoji: '⭐',
                      label: 'Puntaje Crediticio',
                      value: resumen != null ? resumen.puntaje.toString() : '-',
                      primaryColor: AppTheme.primary,
                      secondaryColor: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PuntuacionPage(),
                          ),
                        );
                      },
                    ),
                    ComponentQuickStat(
                      emoji: '🎁',
                      label: 'Cupones Disponibles',
                      value:
                          resumen != null
                              ? resumen.cuponesDisponibles.toString()
                              : '-',
                      primaryColor: const Color(0xFF4B5563),
                      secondaryColor: const Color(0xFF6B7280),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CuponesPage(),
                          ),
                        );
                      },
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
                        if (notifications.any((n) => !n.isRead))
                          isMarkingAll
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : TextButton(
                                  onPressed: () async {
                                    setModalState(() => isMarkingAll = true);
                                    await notifProvider.markAllAsRead();
                                    setModalState(() => isMarkingAll = false);
                                  },
                                  child: const Text('Limpiar todo'),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: notifs.length,
                                itemBuilder: (context, index) {
                                  final notification = notifs[index];
                                  final isRead = notification.isRead;

                                  return Dismissible(
                                    key: Key(notification.id),
                                    direction: isRead
                                        ? DismissDirection.none
                                        : DismissDirection.endToStart,
                                    confirmDismiss: (direction) async {
                                      if (direction == DismissDirection.endToStart) {
                                        await provider.markAsRead(notification.id);
                                        return false;
                                      }
                                      return false;
                                    },
                                    background: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white),
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
                                          // Si tiene contenido rico, navegar al detalle
                                          final hasRichContent = notification.data.hasImage ||
                                              notification.data.hasFile ||
                                              notification.data.hasLink;
                                          // ignore: use_build_context_synchronously
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            if (hasRichContent) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => NotificationDetailPage(
                                                    notification: notification,
                                                  ),
                                                ),
                                              );
                                            }
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
