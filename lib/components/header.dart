import 'package:arequipagocreditos/components/component_quick_stat.dart';
import 'package:arequipagocreditos/components/header_icon.dart';
import 'package:arequipagocreditos/models/conductor_model.dart';
import 'package:arequipagocreditos/screen/perfil_screen.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';

class Header extends StatefulWidget {
  final Conductor conductor;

  const Header({super.key, required this.conductor});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
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
              // Avatar del usuario con mejor diseño
              HeaderIcon(
                icon: Icons.person,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PerfilScreen(),
                    ),
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
                  HeaderIcon(
                    icon: Icons.notifications_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Próximamente: Notificaciones'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Carrusel de stats rápidas con diseño moderno
          SizedBox(
            height: 90,
            child: PageView(
              padEnds: false,
              controller: PageController(viewportFraction: 0.8),
              children: [
                ComponentQuickStat(
                  emoji: '💳',
                  label: 'Créditos Activos',
                  value: '${widget.conductor.tipo}',
                  primaryColor: const Color(0xFF1F2937), // Negro-gris elegante
                  secondaryColor: const Color(0xFF374151),
                ),
                ComponentQuickStat(
                  emoji: '⭐',
                  label: 'Puntaje Crediticio',
                  value: 'Excelente',
                  primaryColor: AppTheme.primary, // Amarillo de tu tema
                  secondaryColor: const Color(0xFFF59E0B), // Amarillo más oscuro
                ),
                ComponentQuickStat(
                  emoji: '🎁',
                  label: 'Cupones Disponibles',
                  value: '3 Nuevos',
                  primaryColor: const Color(0xFF4B5563), // Gris elegante
                  secondaryColor: const Color(0xFF6B7280),
                ),
                ComponentQuickStat(
                  emoji: '📊',
                  label: 'Historial Pagos',
                  value: 'Al día',
                  primaryColor: const Color(0xFF111827), // Negro profundo
                  secondaryColor: const Color(0xFF1F2937),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
