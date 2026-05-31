// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadNotifications();
    });
  }

  Future<void> loadNotifications() async {
    final user = context.read<AuthProvider>().currentUser;

    if (user == null) {
      return;
    }

    await context.read<NotificationProvider>().loadNotifications(user.uid);
  }

  Future<void> markAllAsRead() async {
    final user = context.read<AuthProvider>().currentUser;

    if (user == null) {
      return;
    }

    final success =
        await context.read<NotificationProvider>().markAllAsRead(user.uid);

    if (!mounted) return;

    if (!success) {
      final error = context.read<NotificationProvider>().errorMessage ??
          'Gagal menandai semua notifikasi.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai sudah dibaca.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> markAsRead(NotificationModel notification) async {
    final user = context.read<AuthProvider>().currentUser;

    if (user == null || notification.isRead) {
      return;
    }

    await context.read<NotificationProvider>().markAsRead(
          notificationId: notification.id,
          userId: user.uid,
        );
  }

  Future<void> deleteNotification(NotificationModel notification) async {
    final user = context.read<AuthProvider>().currentUser;

    if (user == null) {
      return;
    }

    final success =
        await context.read<NotificationProvider>().deleteNotification(
              notificationId: notification.id,
              userId: user.uid,
            );

    if (!mounted) return;

    if (!success) {
      final error = context.read<NotificationProvider>().errorMessage ??
          'Gagal menghapus notifikasi.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifikasi'),
        ),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'User Tidak Ditemukan',
          message: 'Silakan login ulang untuk melihat notifikasi.',
        ),
      );
    }

    final notifications = notificationProvider.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (notifications.any((item) => !item.isRead))
            TextButton(
              onPressed: notificationProvider.isLoading ? null : markAllAsRead,
              child: const Text(
                'Baca Semua',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadNotifications,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            buildHeader(notificationProvider.unreadCount),
            const SizedBox(height: 18),
            if (notificationProvider.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: LoadingWidget(
                  message: 'Memuat notifikasi...',
                ),
              )
            else if (notificationProvider.errorMessage != null)
              EmptyState(
                icon: Icons.error_outline,
                title: 'Terjadi Kesalahan',
                message: notificationProvider.errorMessage!,
                buttonText: 'Coba Lagi',
                onPressed: loadNotifications,
              )
            else if (notifications.isEmpty)
              const EmptyState(
                icon: Icons.notifications_none,
                title: 'Belum Ada Notifikasi',
                message:
                    'Notifikasi booking dan aktivitas aplikasi akan muncul di sini.',
              )
            else
              ...notifications.map((notification) {
                return Dismissible(
                  key: ValueKey(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) {
                    deleteNotification(notification);
                  },
                  child: _NotificationCard(
                    notification: notification,
                    onTap: () => markAsRead(notification),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            child: Icon(
              Icons.notifications,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pusat Notifikasi',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unreadCount belum dibaca',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(notification.type);
    final icon = _getTypeIcon(notification.type);

    return Card(
      elevation: notification.isRead ? 1 : 3,
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? Colors.white : color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: notification.isRead
              ? Colors.transparent
              : color.withOpacity(0.35),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.w600 : FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 6),
              Text(
                DateFormatter.formatDateTime(notification.createdAt),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'booking_created':
        return AppColors.info;
      case 'booking_approved':
        return AppColors.success;
      case 'booking_rejected':
        return AppColors.danger;
      case 'booking_cancelled':
        return AppColors.cancelled;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'booking_created':
        return Icons.event_available;
      case 'booking_approved':
        return Icons.check_circle_outline;
      case 'booking_rejected':
        return Icons.cancel_outlined;
      case 'booking_cancelled':
        return Icons.block;
      default:
        return Icons.notifications_none;
    }
  }
}