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

    // Registrar callback para refrescar cuando llega una push en primer plano
    NotificationService.onNotificationReceived = () {
      refreshNotifications();
    };

    // 1. Consulta inmediata
    await refreshNotifications();

    // 2. Programar polling cada 10 minutos
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
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

  /// Marca todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    if (_currentUserId == null || _currentTipo == null) return;
    final success = await _notificationService.markAllAsRead(
      _currentUserId!,
      _currentTipo!,
    );
    if (success) {
      // Actualización optimista local antes de confirmar con el servidor
      _unreadCount = 0;
      _notifications = _notifications
          .map((n) => n.copyWith(readAt: DateTime.now()))
          .toList();
      notifyListeners();
    }
  }

  /// Elimina una notificación específica
  Future<bool> deleteNotification(String notificationId) async {
    if (_currentUserId == null || _currentTipo == null) return false;
    
    // Actualización optimista: remover localmente primero
    final removedIndex = _notifications.indexWhere((n) => n.id == notificationId);
    NotificationModel? removedNotification;
    if (removedIndex != -1) {
      removedNotification = _notifications[removedIndex];
      _notifications = List.from(_notifications)..removeAt(removedIndex);
      if (!removedNotification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      }
      notifyListeners();
    }

    final success = await _notificationService.deleteNotification(
      notificationId,
      _currentUserId!,
      _currentTipo!,
    );

    if (!success && removedNotification != null) {
      // Revertir si falló
      _notifications = List.from(_notifications)..insert(removedIndex, removedNotification);
      if (!removedNotification.isRead) {
        _unreadCount++;
      }
      notifyListeners();
    }

    return success;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    NotificationService.onNotificationReceived = null;
    super.dispose();
  }
}
