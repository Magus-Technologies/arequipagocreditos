import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/core/services/notification_service.dart';
import 'package:arequipagocreditos/data/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  Timer? _pollingTimer;
  String? _currentUserId;
  int? _currentTipo;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  /// Inicializa el servicio de notificaciones con polling
  Future<void> init(String userId, int tipo) async {
    _currentUserId = userId;
    _currentTipo = tipo;
    // 1. Consulta inmediata
    await refreshNotifications();

    // 2. Programar polling cada 10 minutos
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (_currentUserId != null) {
        refreshNotifications();
      }
    });
  }

  /// Consulta las notificaciones manualmente
  Future<void> refreshNotifications() async {
    if (_currentUserId == null) return;
    if (_currentTipo == null) return;
    final data = await _notificationService.fetchNotifications(
      _currentUserId!,
      _currentTipo!,
    );
    if (data != null) {
      _unreadCount = data['unread_count'] ?? 0;
      _notifications = data['notifications'] ?? [];
      notifyListeners();
    }
  }

  /// Marca una notificación como leída
  Future<void> markAsRead(String notificationId) async {
    if (_currentUserId == null) return;
    if (_currentTipo == null) return;
    final success = await _notificationService.markAsRead(
      notificationId,
      _currentUserId!,
      _currentTipo!,
    );
    if (success) {
      // Actualizamos localmente para feedback inmediato
      await refreshNotifications();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
