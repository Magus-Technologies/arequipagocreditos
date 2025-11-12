import 'package:arequipagocreditos/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'beneficios_page.dart';

class AuthBottomNav extends StatefulWidget {
  const AuthBottomNav({super.key});

  @override
  State<AuthBottomNav> createState() => _AuthBottomNavState();
}

class _AuthBottomNavState extends State<AuthBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    LoginPage(),
    BeneficiosPage(isNav: true,),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Beneficios',
          ),
        ],
      ),
    );
  }
}