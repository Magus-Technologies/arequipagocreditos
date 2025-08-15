import 'package:arequipagocreditos/presentation/pages/pages.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dependency_injection.dart';
import 'presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: DependencyInjection.providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Arequipa Créditos',
        theme: ThemeData(primarySwatch: Colors.red),
        home: AppWrapper(),
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    // Verificar estado de autenticación al iniciar la app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return SplashPage();
          case AuthStatus.authenticated:
            return DashboardPage();
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return LoginPage();
        }
      },
    );
  }
}
