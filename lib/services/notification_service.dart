import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  CollectionReference get _usersCollection => _firestore.collection('users');

  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        return NotificationModel.fromDocument(doc);
      }).toList();

      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    });
  }

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final notifications = snapshot.docs.map((doc) {
        return NotificationModel.fromDocument(doc);
      }).toList();

      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    } catch (e) {
      throw Exception('Gagal mengambil notifikasi: $e');
    }
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String bookingId = '',
  }) async {
    try {
      final docRef = _notificationsCollection.doc();

      final notification = NotificationModel(
        id: docRef.id,
        userId: userId,
        title: title,
        message: message,
        type: type,
        bookingId: bookingId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await docRef.set(notification.toMap());
    } catch (e) {
      throw Exception('Gagal membuat notifikasi: $e');
    }
  }

  Future<void> notifyAllAdmins({
    required String title,
    required String message,
    required String type,
    String bookingId = '',
  }) async {
    try {
      final snapshot = await _usersCollection
          .where('role', isEqualTo: 'admin')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final adminId = data['uid'] ?? doc.id;

        await createNotification(
          userId: adminId,
          title: title,
          message: message,
          type: type,
          bookingId: bookingId,
        );
      }
    } catch (e) {
      throw Exception('Gagal mengirim notifikasi admin: $e');
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Gagal menghitung notifikasi belum dibaca: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Gagal menandai notifikasi sebagai dibaca: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal menandai semua notifikasi: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus notifikasi: $e');
    }
  }
}