import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../theme/app_theme.dart';
import 'auth_bottom_nav.dart';
import 'conductor_estado_page.dart';
import 'register_selection_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<int?> _solicitudGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.conductorPreRegistroIdKey);
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
                                const RegisterSelectionPage(),
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
                    'REGISTRARTE',
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthBottomNav(),
                      ),
                    );
                  },
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
