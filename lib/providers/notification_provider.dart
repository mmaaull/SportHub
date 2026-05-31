import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _notifications = await _notificationService.getUserNotifications(userId);
      _unreadCount = _notifications.where((item) => !item.isRead).length;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _notificationService.getUserNotificationsStream(userId);
  }

  Future<void> loadUnreadCount(String userId) async {
    try {
      _unreadCount = await _notificationService.getUnreadCount(userId);
      notifyListeners();
    } catch (e) {
      _setError(_cleanErrorMessage(e));
    }
  }

  Future<bool> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    _clearError();

    try {
      await _notificationService.markAsRead(notificationId);
      await loadNotifications(userId);
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _notificationService.markAllAsRead(userId);
      await loadNotifications(userId);
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteNotification({
    required String notificationId,
    required String userId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _notificationService.deleteNotification(notificationId);
      await loadNotifications(userId);
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _cleanErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}