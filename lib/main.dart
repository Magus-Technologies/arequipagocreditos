import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:arequipagocreditos/core/services/notification_service.dart';
import 'package:arequipagocreditos/presentation/pages/auth_bottom_nav.dart';
import 'package:arequipagocreditos/presentation/pages/pages.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dependency_injection.dart';
import 'presentation/providers/auth_provider.dart';

// Manejador de mensajes en segundo plano (debe estar fuera de cualquier clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    await Firebase.initializeApp();

    // Configurar notificaciones FCM (No bloqueamos el inicio de la app)
    final notificationService = NotificationService();
    notificationService.initializeFCM();

    // Registrar el manejador de notificaciones en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    log("❌ Error al inicializar Firebase: $e");
  }

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
  bool _expiryAlertShown = false;
  static const int _nearExpiryDays = 7;
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
            // Mostrar alerta una sola vez por sesión si hay documentos vencidos o próximos a vencer
            if (!_expiryAlertShown) {
              _expiryAlertShown =
                  true; // marcar inmediatamente para evitar múltiples invocaciones
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted) return;
                // Prefer server-provided alerts (if backend implements them), otherwise fallback to client-side checks
                final serverAlerts =
                    await context
                        .read<AuthProvider>()
                        .getServerDocumentAlerts();
                final expiredServer = serverAlerts['expired'] ?? <String>[];
                final nearServer = serverAlerts['near'] ?? <String>[];

                List<String> expired = expiredServer;
                List<String> near = nearServer;

                if (expired.isEmpty && near.isEmpty) {
                  if (!context.mounted) return;
                  expired =
                      context.read<AuthProvider>().getExpiredVehicleDocuments();
                  near = context
                      .read<AuthProvider>()
                      .getNearExpiryVehicleDocuments(_nearExpiryDays);
                }

                if (expired.isNotEmpty || near.isNotEmpty) {
                  final parts = <String>[];
                  if (expired.isNotEmpty) {
                    parts.add('Vencidos: ${expired.join(', ')}');
                  }
                  if (near.isNotEmpty) {
                    parts.add(
                      'A vencer en los próximos $_nearExpiryDays días: ${near.join(', ')}',
                    );
                  }

                  if (!context.mounted) return;
                  showDialog<void>(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Aviso de documentos'),
                        content: Text(parts.join('\n')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              });
            }

            return DashboardPage();
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return AuthBottomNav();
        }
      },
    );
  }
}
