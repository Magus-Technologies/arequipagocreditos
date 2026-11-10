import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../components/evento_invitado_aviso.dart';
import 'auth_bottom_nav.dart';
import 'conductor_estado_page.dart';
import 'conductor_register_page.dart';
import 'eventos_page.dart';
// TK-0444: sin la opción PASAJERO ya no hace falta la pantalla de selección; REGISTRARTE abre el formulario directo.
// import 'register_selection_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<int?> _solicitudGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.conductorPreRegistroIdKey);
  }

  void _abrirIniciarSesion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthBottomNav(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandYellow,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Hero(
                    tag: 'credigo-logo',
                    child: SvgPicture.asset('images/credigo_inicio.svg', height: 190),
                  ),
                ),
              ),
              // Hay un evento PÚBLICO activo y la persona todavía no inició sesión: sale una ventana flotante con el banner; «Ver evento y
              // comprar» abre el detalle y compra como invitado, sin cuenta. No ocupa lugar en la pantalla (es solo el disparador).
              EventoInvitadoAviso(onIniciarSesion: () => _abrirIniciarSesion(context)),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 350),
                        reverseTransitionDuration: const Duration(
                          milliseconds: 300,
                        ),
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                const ConductorRegisterPage(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                            reverseCurve: Curves.easeInCubic,
                          );
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(curved),
                            child: FadeTransition(
                              opacity: curved,
                              child: child,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'REGISTRAR CONDUCTOR',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _abrirIniciarSesion(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // TK-0450: los eventos públicos se ven (y se compran) sin cuenta ni sesión: acceso fijo desde la bienvenida.
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  key: const Key('welcome_eventos'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EventosPage()),
                  ),
                  icon: const Icon(Icons.celebration_rounded, size: 20),
                  label: const Text(
                    'EVENTOS',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 1.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              FutureBuilder<int?>(
                future: _solicitudGuardada(),
                builder: (context, snapshot) {
                  if (snapshot.data == null) return const SizedBox(height: 40);
                  return Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 28),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ConductorEstadoPage(conductorId: snapshot.data),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.assignment_outlined,
                        size: 18,
                        color: Colors.black87,
                      ),
                      label: const Text(
                        'Ver estado de mi solicitud',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
