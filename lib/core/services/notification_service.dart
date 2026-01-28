import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:arequipagocreditos/core/constants/api_constants.dart';
import 'package:arequipagocreditos/data/models/notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final String _baseUrl = ApiConstants.baseUrl;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal de notificación para Android (necesario para banners en primer plano)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
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

      // 1. Suscribirse a un tema global para anuncios generales
      await _fcm.subscribeToTopic('all_users');

      // Obtener el token del dispositivo
      String? token = await _fcm.getToken();
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

        // Mostrar banner manual en primer plano
        _showLocalNotification(message);
      });

      // Manejar clics en notificaciones cuando la app está en segundo plano pero no cerrada
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log(
          '🖱️ La app se abrió desde una notificación: ${message.notification?.title}',
        );
      });
    } catch (e) {
      log('❌ Error al inicializar FCM: $e');
    }
  }

  /// Inicializa el plugin de notificaciones locales
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings);

    // Crear el canal en Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  /// Muestra una notificación local (usado para banners en primer plano)
  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    // Usamos el icono con transparencia que acabas de agregar
    String iconName = 'ic_notification';

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: _channel.importance,
            priority: Priority.high,
            icon: iconName,
            color: const Color(0xFFFEEC38), // Amarillo brillante (Arequipa)
          ),
        ),
      );
    }
  }

  /// Sincroniza el usuario, envía el token al backend y gestiona suscripciones a temas
  Future<void> _syncUserWithFCM(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conductorJson = prefs.getString('conductor');
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
        await _fcm.subscribeToTopic('conductores');
        await _fcm.unsubscribeFromTopic('clientes');
      } else if (tipoUsuario == 2) {
        await _fcm.subscribeToTopic('clientes');
        await _fcm.unsubscribeFromTopic('conductores');
      }

      // 3. Enviar token al backend
      final url = Uri.parse('${ApiConstants.baseUrl}/update-datos-usuario');
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
        Uri.parse("$_baseUrl/notifications/$idConductor/$tipoUsuario"),
        headers: ApiConstants.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);

        // Parseamos la lista de notificaciones usando el modelo
        final List<dynamic> rawNotifications = body['notifications'] ?? [];
        final List<NotificationModel> notifications =
            rawNotifications
                .map((notif) => NotificationModel.fromJson(notif))
                .toList();

        return {
          'unread_count': body['unread_count'] ?? 0,
          'notifications': notifications,
        };
      } else {
        return null;
      }
    } catch (e) {
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
          "$_baseUrl/notifications/$notificationId/$idConductor/$tipoUsuario/read",
        ),
        headers: ApiConstants.defaultHeaders,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
