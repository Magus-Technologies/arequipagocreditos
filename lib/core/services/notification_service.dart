import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:arequipagocreditos/data/models/notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:arequipagocreditos/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:arequipagocreditos/presentation/pages/financiamiento_detalle_page.dart';
import 'package:arequipagocreditos/presentation/pages/notification_detail_page.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Callback que se invoca cuando llega una notificación push en primer plano
  /// para que el provider pueda refrescar la lista.
  static VoidCallback? onNotificationReceived;

  /// GlobalKey para navegar desde fuera del árbol de widgets.
  /// Registra esto en MaterialApp.navigatorKey en main.dart.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Datos de notificación pendientes cuando la app se abre desde estado terminado.
  /// AppWrapper los consume una vez que el usuario está autenticado.
  static Map<String, dynamic>? pendingNotificationData;

  // Canal de notificación para Android — debe coincidir con el canal configurado en FCM
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel_v2',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  /// Inicializa Firebase y FCM
  Future<void> initializeFCM() async {
    try {
      // Inicializar notificaciones locales para el primer plano
      await _initLocalNotifications();

      // Solicitar permisos (especialmente para iOS)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('✅ Permiso de notificaciones concedido');
      }

      // Configurar cómo se muestran las notificaciones cuando la app está abierta (iOS)
      // En iOS 14+ podemos usar esto para que el sistema muestre el banner automáticamente
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 1. Suscribirse a un tema global para anuncios generales
      _fcm.subscribeToTopic('all_users').catchError((e) {
        log("⚠️ subscribeToTopic all_users: $e");
      });

      // Obtener el token del dispositivo (con timeout para evitar ANR si GMS no responde)
      String? token = await _fcm.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (token != null) {
        log("📱 FCM Token: $token");
        // Sincronizar con el backend y temas específicos
        await _syncUserWithFCM(token);
      }

      // Escuchar cuando el token se actualice
      _fcm.onTokenRefresh.listen((newToken) {
        _syncUserWithFCM(newToken);
      });

      // Manejar mensajes en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log(
          '📩 Notificación recibida en primer plano: ${message.notification?.title}',
        );

        // En iOS, el sistema ya muestra el banner gracias a setForegroundNotificationPresentationOptions(alert: true)
        // En Android, necesitamos mostrarlo manualmente con flutter_local_notifications
        if (Platform.isAndroid) {
          _showLocalNotification(message);
        }

        // Notificar al provider para que refresque la lista
        onNotificationReceived?.call();
      });

      // Manejar clics en notificaciones cuando la app está en segundo plano pero no cerrada
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('🖱️ onMessageOpenedApp FIRED - title: ${message.notification?.title}');
        log('🖱️ onMessageOpenedApp data: ${message.data}');
        handleNotificationTap(message.data);
      });

      // Manejar el caso cuando la app se abre desde una notificación estando TERMINADA
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        log(
          '🏁 La app se inició desde una notificación (Terminada): ${initialMessage.notification?.title}',
        );
        // Guardamos los datos para que AppWrapper los procese una vez
        // que el usuario esté autenticado y el árbol de widgets listo.
        pendingNotificationData = initialMessage.data;
      }
    } catch (e) {
      log('❌ Error al inicializar FCM: $e');
    }
  }

  /// Navega según el tipo de notificación recibida.
  void handleNotificationTap(Map<String, dynamic> data) {
    final String? type = data['type']?.toString();
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (type == 'orden_pago') {
      final int financiamientoId =
          int.tryParse(data['financiamiento_id']?.toString() ?? '') ?? 0;
      if (financiamientoId == 0) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FinanciamientoDetallePage(
            idFinanciamiento: financiamientoId,
            moneda: 'S/.',
          ),
        ),
      );
    } else if (type == 'bulk' || type == 'personal') {
      // Construir un NotificationModel temporal desde el payload push
      final hasRichContent = (data['image_url'] != null && data['image_url'].toString().isNotEmpty) ||
          (data['file_url'] != null && data['file_url'].toString().isNotEmpty) ||
          (data['link'] != null && data['link'].toString().isNotEmpty);

      if (hasRichContent) {
        final notification = NotificationModel(
          id: data['notification_id']?.toString() ?? '',
          type: type!,
          notifiableType: '',
          notifiableId: 0,
          data: NotificationDataModel(
            title: data['title']?.toString() ?? '',
            message: data['message']?.toString() ?? '',
            type: type,
            imageUrl: data['image_url']?.toString(),
            fileUrl: data['file_url']?.toString(),
            fileName: data['file_name']?.toString(),
            link: data['link']?.toString(),
            extraData: {},
          ),
          createdAt: DateTime.now(),
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NotificationDetailPage(notification: notification),
          ),
        );
      }
    }
  }

  /// Inicializa el plugin de notificaciones locales
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(payload);
            handleNotificationTap(data);
          } catch (_) {}
        }
      },
    );

    // Crear el canal en Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  /// Muestra una notificación local (usado para banners en primer plano)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    const String iconName = 'ic_notification';

    if (notification == null) return;

    final String? imageUrl = message.data['image_url']?.toString();
    final String? link = message.data['link']?.toString();

    // Construir el body incluyendo el link si existe
    String body = notification.body ?? '';
    if (link != null && link.isNotEmpty) {
      body = '$body\n🔗 $link';
    }

    StyleInformation? styleInformation;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final ByteArrayAndroidBitmap bitmap =
              ByteArrayAndroidBitmap(response.bodyBytes);
          styleInformation = BigPictureStyleInformation(bitmap);
        }
      } catch (_) {}
    }

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: _channel.importance,
          priority: Priority.high,
          icon: iconName,
          color: const Color(0xFFFEEC38),
          styleInformation: styleInformation,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Sincroniza el usuario, envía el token al backend y gestiona suscripciones a temas
  Future<void> _syncUserWithFCM(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString(AppConstants.userStorageKey);
      if (conductorJson == null) return;

      final Map<String, dynamic> conductorData = jsonDecode(conductorJson);
      final Map<String, dynamic> conductorMap =
          (conductorData['conductor'] is Map)
              ? Map<String, dynamic>.from(conductorData['conductor'])
              : Map<String, dynamic>.from(conductorData);

      final int idUsuario =
          conductorMap['id_conductor'] is int
              ? conductorMap['id_conductor']
              : int.tryParse(
                    (conductorMap['id_conductor'] ?? '0').toString(),
                  ) ??
                  0;
      final int tipoUsuario =
          conductorMap['tipo'] is int
              ? conductorMap['tipo']
              : int.tryParse((conductorMap['tipo'] ?? '0').toString()) ?? 0;

      if (idUsuario == 0) return;

      // 2. Suscribirse a temas por tipo de usuario para envíos masivos segmentados
      if (tipoUsuario == 1) {
        _fcm.subscribeToTopic('conductores').catchError((e) {
          log("⚠️ subscribeToTopic conductores: $e");
        });
        _fcm.unsubscribeFromTopic('clientes').catchError((e) {});
      } else if (tipoUsuario == 2) {
        _fcm.subscribeToTopic('clientes').catchError((e) {
          log("⚠️ subscribeToTopic clientes: $e");
        });
        _fcm.unsubscribeFromTopic('conductores').catchError((e) {});
      }

      // 3. Enviar token al backend
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateDatosUsuarioEndpoint}');
      await http.post(
        url,
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode({
          'id_usuario': idUsuario,
          'tipo_usuario': tipoUsuario,
          'fcm_token': token,
        }),
      );
      log("🚀 Sincronización FCM exitosa (Token y Temas)");
    } catch (e) {
      log("❌ Error al sincronizar FCM: $e");
    }
  }

  /// Obtiene las notificaciones del conductor y el conteo de no leídas
  Future<Map<String, dynamic>?> fetchNotifications(
    String idConductor,
    int tipo,
  ) async {
    try {
      String tipoUsuario = tipo == 1 ? 'conductor' : 'cliente';
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.notificationsEndpoint}'
              .replaceAll('{id}', idConductor)
              .replaceAll('{tipo}', tipoUsuario),
        ),
        headers: ApiConstants.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);

        // Parseamos la lista de notificaciones usando el modelo
        final List<dynamic> rawNotifications = body['notifications'] ?? [];
        final List<NotificationModel> notifications = [];
        for (final notif in rawNotifications) {
          try {
            notifications.add(NotificationModel.fromJson(notif));
          } catch (e) {
            log('⚠️ Error parseando notificación: $e — data: $notif');
          }
        }

        return {
          'unread_count': body['unread_count'] ?? 0,
          'notifications': notifications,
        };
      } else {
        log('⚠️ fetchNotifications status: ${response.statusCode} body: ${response.body}');
        return null;
      }
    } catch (e) {
      log('❌ Error en fetchNotifications: $e');
      return null;
    }
  }

  /// Marca una notificación específica como leída
  Future<bool> markAsRead(
    String notificationId,
    String idConductor,
    int tipo,
  ) async {
    try {
      String tipoUsuario = tipo == 1 ? 'conductor' : 'cliente';
      final response = await http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.markAsReadEndpoint}'
              .replaceAll('{notificationId}', notificationId)
              .replaceAll('{id}', idConductor)
              .replaceAll('{tipo}', tipoUsuario),
        ),
        headers: ApiConstants.defaultHeaders,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Marca todas las notificaciones del usuario como leídas
  Future<bool> markAllAsRead(String idConductor, int tipo) async {
    try {
      final String tipoUsuario = tipo == 1 ? 'conductor' : 'cliente';
      final response = await http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.readAllNotificationsEndpoint}'
              .replaceAll('{id}', idConductor)
              .replaceAll('{tipo}', tipoUsuario),
        ),
        headers: ApiConstants.defaultHeaders,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Elimina una notificación específica
  Future<bool> deleteNotification(
    String notificationId,
    String idConductor,
    int tipo,
  ) async {
    try {
      String tipoUsuario = tipo == 1 ? 'conductor' : 'cliente';
      final response = await http.delete(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.deleteNotificationEndpoint}'
              .replaceAll('{notificationId}', notificationId)
              .replaceAll('{id}', idConductor)
              .replaceAll('{tipo}', tipoUsuario),
        ),
        headers: ApiConstants.defaultHeaders,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
