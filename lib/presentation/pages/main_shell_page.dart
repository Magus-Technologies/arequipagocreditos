import 'package:arequipagocreditos/presentation/pages/beneficios_page.dart';
import 'package:arequipagocreditos/presentation/pages/dashboard_page.dart';
import 'package:arequipagocreditos/presentation/pages/documentos_firmados_page.dart';
import 'package:arequipagocreditos/presentation/pages/mas_page.dart';
import 'package:arequipagocreditos/presentation/pages/servicios_taller_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Punto de entrada principal de la app luego del login: una barra de
/// navegación inferior fija (Inicio/Beneficios/Servicios/Documentos/Más)
/// sobre un IndexedStack, para no perder el estado de cada pestaña al
/// cambiar entre ellas.
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  // Cada página raíz de pestaña recibe showBackButton/isNav en false: no hay
  // una ruta previa que cerrar, esta barra reemplaza esa navegación.
  final List<Widget> _pages = const [
    DashboardPage(),
    BeneficiosPage(isNav: true),
    ServiciosTallerPage(showBackButton: false),
    DocumentosFirmadosPage(showBackButton: false),
    MasPage(),
  ];

  Future<void> _abrirWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/51982934377?text=Hola,%20tengo%20una%20consulta',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // Flotante y persistente en las 5 pestañas, no solo en el home.
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirWhatsApp(context),
        backgroundColor: const Color(0xFF25D366),
        tooltip: 'Contactar por WhatsApp',
        child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'Beneficios'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car_filled), label: 'Servicios'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: 'Documentos'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Más'),
        ],
      ),
    );
  }
}
