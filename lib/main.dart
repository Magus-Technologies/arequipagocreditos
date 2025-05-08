import 'package:arequipagocreditos/models/conductor.dart';
import 'package:arequipagocreditos/screen/dashboard_screen.dart';
import 'package:arequipagocreditos/screen/login_screen.dart';
import 'package:arequipagocreditos/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Conductor? user = await ApiService.getLoggedUser();
  bool loggedIn = user != null;

  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery True Love',
      theme: ThemeData(primarySwatch: Colors.red),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => isLoggedIn ? DashboardScreen() : LoginScreen(),
      },
    );
  }
}
