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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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

    final success = await context.read<NotificationProvider>().markAllAsRead(
      user.uid,
    );

    if (!mounted) return;

    if (!success) {
      final error =
          context.read<NotificationProvider>().errorMessage ??
          'Gagal menandai semua notifikasi.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
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

    final success = await context
        .read<NotificationProvider>()
        .deleteNotification(notificationId: notification.id, userId: user.uid);

    if (!mounted) return;

    if (!success) {
      final error =
          context.read<NotificationProvider>().errorMessage ??
          'Gagal menghapus notifikasi.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
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
        backgroundColor: AppColors.background,
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'User Tidak Ditemukan',
          message: 'Silakan login ulang untuk melihat notifikasi.',
        ),
      );
    }

    final notifications = notificationProvider.notifications;
    final hasUnread = notifications.any((item) => !item.isRead);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryDarkGreen,
        onRefresh: loadNotifications,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _NotificationsHeader(
              unreadCount: notificationProvider.unreadCount,
              showBackButton: Navigator.canPop(context),
              onMarkAll: hasUnread && !notificationProvider.isLoading
                  ? markAllAsRead
                  : null,
            ),
            Transform.translate(
              offset: const Offset(0, -34),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                child: Column(
                  children: [
                    _NotificationCenterCard(
                      unreadCount: notificationProvider.unreadCount,
                      onMarkAll: hasUnread && !notificationProvider.isLoading
                          ? markAllAsRead
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (notificationProvider.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 62),
                        child: LoadingWidget(message: 'Memuat notifikasi...'),
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
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  final int unreadCount;
  final bool showBackButton;
  final VoidCallback? onMarkAll;

  const _NotificationsHeader({
    required this.unreadCount,
    required this.showBackButton,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 76),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -30,
            child: Icon(
              Icons.notifications_outlined,
              color: Colors.white.withValues(alpha: 0.08),
              size: 126,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (showBackButton) ...[
                  Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                      tooltip: 'Kembali',
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifikasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Pantau pembaruan booking kamu.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onMarkAll,
                  child: const Text(
                    'Baca Semua',
                    style: TextStyle(color: Colors.white),
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

class _NotificationCenterCard extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onMarkAll;

  const _NotificationCenterCard({
    required this.unreadCount,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.lightGreenSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primaryDarkGreen,
              size: 28,
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
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$unreadCount belum dibaca',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onMarkAll, child: const Text('Baca Semua')),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(notification.type);
    final icon = _getTypeIcon(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.card
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: notification.isRead
              ? AppColors.border
              : color.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                height: 1.25,
                                fontWeight: notification.isRead
                                    ? FontWeight.w700
                                    : FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: AppColors.textSecondary,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              DateFormatter.formatDateTime(
                                notification.createdAt,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        return AppColors.primaryDarkGreen;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'booking_created':
        return Icons.event_available_outlined;
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
