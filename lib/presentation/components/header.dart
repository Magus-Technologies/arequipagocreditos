import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/presentation/components/component_quick_stat.dart';
import 'package:arequipagocreditos/presentation/components/header_icon.dart';
import 'package:arequipagocreditos/presentation/pages/perfil_page.dart';
import 'package:arequipagocreditos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/presentation/providers/resumen_crediticio_provider.dart';
import 'package:provider/provider.dart';

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
      final provider = Provider.of<ResumenCrediticioProvider>(context, listen: false);
      provider.fetchResumen(widget.conductor.idConductor);
    });
  }

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
                      builder: (context) => const PerfilPage(),
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
                  child: Center(child: Text('Error al cargar datos')), // Puedes personalizar el error
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
                      value: resumen != null ? resumen.creditosActivos.toString() : '-',
                      primaryColor: const Color(0xFF1F2937),
                      secondaryColor: const Color(0xFF374151),
                    ),
                    ComponentQuickStat(
                      emoji: '⭐',
                      label: 'Puntaje Crediticio',
                      value: resumen != null ? resumen.puntaje.toString() : '-',
                      primaryColor: AppTheme.primary,
                      secondaryColor: const Color(0xFFF59E0B),
                    ),
                    ComponentQuickStat(
                      emoji: '🎁',
                      label: 'Cupones Disponibles',
                      value: resumen != null ? resumen.cuponesDisponibles.toString() : '-',
                      primaryColor: const Color(0xFF4B5563),
                      secondaryColor: const Color(0xFF6B7280),
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
}
