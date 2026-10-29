import 'dart:developer';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:arequipagocreditos/core/services/notification_service.dart';
import 'package:arequipagocreditos/core/utils/biometria_celular.dart';
import 'package:arequipagocreditos/presentation/pages/welcome_page.dart';
import 'package:arequipagocreditos/presentation/pages/pages.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dependency_injection.dart';
import 'presentation/providers/auth_provider.dart';
import 'package:arequipagocreditos/presentation/pages/signature/firma_documento_page.dart';

// Manejador de mensajes en segundo plano (debe estar fuera de cualquier clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('🔕 BG handler - notification payload: ${message.notification?.title}');
  log('🔕 BG handler - data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // El handler de background debe registrarse antes de Firebase.initializeApp()
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await Firebase.initializeApp();

    // Inicializar FCM antes de runApp para capturar getInitialMessage correctamente
    final notificationService = NotificationService();
    await notificationService.initializeFCM();
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
        title: 'CREDIGO DRIVERS',
        theme: ThemeData(primarySwatch: Colors.red),
        navigatorKey: NotificationService.navigatorKey,
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

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  bool _expiryAlertShown = false;
  static const int _nearExpiryDays = 7;
  DateTime? _pausedAt;
  bool _firmaPendiente = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.checkAuthStatus();
      // TK-0401: la sesión guardada puede ser de antes de que se publicara un contrato de afiliación nuevo: se consulta al
      // servidor para que, si hay que volver a firmar, el app lo bloquee desde el principio.
      if (mounted && auth.isAuthenticated) {
        auth.refreshUserDataSilently();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      context.read<AuthProvider>().persistSessionPause();
    } else if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().clearSessionPause();
      if (_pausedAt != null) {
        final elapsed = DateTime.now().difference(_pausedAt!);
        _pausedAt = null;
        final auth = context.read<AuthProvider>();
        if (elapsed.inMinutes >= AuthProvider.sessionTimeoutMinutes) {
          auth.logout(clearBiometric: false);
        } else if (elapsed.inSeconds >= AuthProvider.lockAfterSeconds &&
            auth.isAuthenticated &&
            auth.hasUsableAccessMethod) {
          // Volvió del segundo plano tras un rato: pedir PIN/biometría
          // (estilo Yape). Salidas cortas no molestan.
          auth.lock();
        }
      }

      // TK-0401: si mientras el app estaba en segundo plano se publicó un contrato de afiliación nuevo, se entera al volver y
      // lo bloquea hasta que firme.
      final autenticado = context.read<AuthProvider>();
      if (autenticado.isAuthenticated) {
        autenticado.refreshUserDataSilently();
      }
    }
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
            // Bloqueo de acceso (estilo Yape): se pide PIN/biometría al abrir
            // el app o al volver de un segundo plano largo, aunque la sesión
            // siga válida.
            if (authProvider.isLocked) {
              return const IngresarPinPage();
            }
            // Ofrecer configuración biométrica tras login manual con credenciales disponibles
            if (authProvider.needsBiometricSetupOffer) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted) return;
                // TK-0420: solo se ofrece si el celular tiene huella/rostro REGISTRADOS (no basta el sensor ni el bloqueo de pantalla).
                final canAuth = (await BiometriaCelular.consultar(_localAuth)).hayConfigurada;
                if (!context.mounted) return;
                if (!canAuth) {
                  context.read<AuthProvider>().declineBiometricSetup();
                  return;
                }
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    title: const Text('Acceso biométrico'),
                    content: const Text('¿Deseas activar el inicio de sesión con huella o Face ID para la próxima vez?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<AuthProvider>().declineBiometricSetup();
                        },
                        child: const Text('No, gracias'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await context.read<AuthProvider>().acceptBiometricSetup();
                        },
                        child: const Text('Activar'),
                      ),
                    ],
                  ),
                );
              });
            } else if (authProvider.needsBiometricSetupViaRelogin) {
              // Sesión restaurada automáticamente sin pasar por login manual
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted) return;
                // TK-0420: solo se ofrece si el celular tiene huella/rostro REGISTRADOS (no basta el sensor ni el bloqueo de pantalla).
                final canAuth = (await BiometriaCelular.consultar(_localAuth)).hayConfigurada;
                if (!context.mounted) return;
                if (!canAuth) {
                  context.read<AuthProvider>().declineBiometricSetup();
                  return;
                }
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    title: const Text('Acceso biométrico'),
                    content: const Text('¿Deseas activar el inicio de sesión con huella o Face ID? Necesitarás ingresar tus credenciales una vez para configurarlo.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<AuthProvider>().declineBiometricSetup();
                        },
                        child: const Text('No, gracias'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<AuthProvider>().logout(clearBiometric: false);
                        },
                        child: const Text('Activar'),
                      ),
                    ],
                  ),
                );
              });
            }
            // Procesar notificación pendiente (app abierta desde estado terminado)
            if (NotificationService.pendingNotificationData != null) {
              final data = NotificationService.pendingNotificationData!;
              NotificationService.pendingNotificationData = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                NotificationService().handleNotificationTap(data);
              });
            }
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

            if (authProvider.currentUser != null &&
                !authProvider.currentUser!.afiliacionFirmada &&
                authProvider.currentUser!.contratoAfiliacionUrl != null) {
              // TK-0401: si el contrato pasa a estar pendiente con la persona dentro de otra pantalla, se cierran las pantallas
              // abiertas para que el contrato quede a la vista y no se pueda seguir usando el app sin firmarlo. Solo al
              // pasar a pendiente (no en cada reconstrucción: cerraría la pantalla donde se dibuja la firma).
              if (!_firmaPendiente) {
                _firmaPendiente = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  NotificationService.navigatorKey.currentState?.popUntil((route) => route.isFirst);
                });
              }
              return FirmaDocumentoPage(
                // TK-0401: cada versión del contrato es una pantalla nueva (vuelve a descargar el PDF).
                key: ValueKey('afiliacion-v${authProvider.currentUser!.contratoAfiliacionVersion}'),
                version: authProvider.currentUser!.contratoAfiliacionVersion,
                title: 'Contrato de Afiliación',
                pdfUrl: authProvider.currentUser!.contratoAfiliacionUrl!,
                tipo: 'afiliacion',
                id: authProvider.currentUser!.idConductor,
                canPop: false,
                // TK-0401: si ya había firmado y se publicó una versión nueva, se le explica por qué vuelve a firmar.
                aviso: authProvider.currentUser!.afiliacionActualizada
                    ? 'Actualizamos nuestro contrato de afiliación. Revísalo y fírmalo para seguir usando la app.'
                    : null,
                onSigned: () => authProvider.refreshUserDataSilently(),
              );
            }

            _firmaPendiente = false;
            return const MainShellPage();
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return const WelcomePage();
        }
      },
    );
  }
}
