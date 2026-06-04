import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/facility_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/confirm_dialog.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import 'activity_logs_screen.dart';
import 'admin_schedule_screen.dart';
import 'manage_bookings_screen.dart';
import 'manage_facilities_screen.dart';
import 'statistics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      loadDashboardData();
    });
  }

  Future<void> loadDashboardData() async {
    final facilityProvider = context.read<FacilityProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final user = context.read<AuthProvider>().currentUser;

    await facilityProvider.seedInitialFacilities();
    await bookingProvider.loadStatistics();

    if (user != null) {
      await notificationProvider.loadUnreadCount(user.uid);
    }
  }

  Future<void> refreshDashboard() async {
    final facilityProvider = context.read<FacilityProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final user = context.read<AuthProvider>().currentUser;

    await facilityProvider.loadFacilities();
    await bookingProvider.loadStatistics();

    if (user != null) {
      await notificationProvider.loadUnreadCount(user.uid);
    }
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );

    if (!mounted) return;

    final user = context.read<AuthProvider>().currentUser;

    if (user != null) {
      await context.read<NotificationProvider>().loadUnreadCount(user.uid);
    }
  }

  Future<void> logout() async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Logout',
      message: 'Apakah kamu yakin ingin keluar dari akun admin?',
      confirmText: 'Logout',
      confirmColor: AppColors.danger,
    );

    if (!confirm) return;
    if (!mounted) return;

    await context.read<AuthProvider>().logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final facilityProvider = context.watch<FacilityProvider>();
    final notificationProvider = context.watch<NotificationProvider>();

    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryDarkGreen,
        onRefresh: refreshDashboard,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _AdminHeader(
              name: user?.name ?? 'Admin',
              email: user?.email ?? '-',
              unreadCount: notificationProvider.unreadCount,
              onNotifications: openNotifications,
              onLogout: logout,
            ),
            Transform.translate(
              offset: const Offset(0, -34),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatsGrid(
                      totalFacilities: facilityProvider.facilities.length,
                      totalBooking: bookingProvider.totalBooking,
                      pendingBooking: bookingProvider.pendingBooking,
                      approvedBooking: bookingProvider.approvedBooking,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Menu Pengelolaan',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AdminMenuCard(
                      icon: Icons.calendar_month_outlined,
                      title: 'Kalender Jadwal',
                      description:
                          'Lihat jadwal booking fasilitas dalam bentuk kalender.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminScheduleScreen(),
                          ),
                        );
                      },
                    ),
                    _AdminMenuCard(
                      icon: Icons.edit_calendar_outlined,
                      title: 'CRUD Fasilitas',
                      description:
                          'Tambah, edit, dan hapus data fasilitas olahraga UNESA.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageFacilitiesScreen(),
                          ),
                        );
                      },
                    ),
                    _AdminMenuCard(
                      icon: Icons.fact_check_outlined,
                      title: 'Kelola Booking',
                      description: 'Lihat, approve, atau reject booking user.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageBookingsScreen(),
                          ),
                        );
                      },
                    ),
                    _AdminMenuCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Statistik',
                      description: 'Lihat statistik booking menggunakan chart.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StatisticsScreen(),
                          ),
                        );
                      },
                    ),
                    _AdminMenuCard(
                      icon: Icons.history_rounded,
                      title: 'Riwayat Aktivitas',
                      description: 'Lihat riwayat aktivitas admin.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ActivityLogsScreen(),
                          ),
                        );
                      },
                    ),
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

class _AdminHeader extends StatelessWidget {
  final String name;
  final String email;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onLogout;

  const _AdminHeader({
    required this.name,
    required this.email,
    required this.unreadCount,
    required this.onNotifications,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 78),
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
            right: -30,
            bottom: -34,
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white.withValues(alpha: 0.08),
              size: 138,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SportHubLogoMark(size: 46),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'UNESA SportHub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    _NotificationButton(
                      unreadCount: unreadCount,
                      onPressed: onNotifications,
                    ),
                    const SizedBox(width: 10),
                    _HeaderIconButton(
                      icon: Icons.logout_rounded,
                      tooltip: 'Logout',
                      onPressed: onLogout,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Panel Pengelola',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
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

class _StatsGrid extends StatelessWidget {
  final int totalFacilities;
  final int totalBooking;
  final int pendingBooking;
  final int approvedBooking;

  const _StatsGrid({
    required this.totalFacilities,
    required this.totalBooking,
    required this.pendingBooking,
    required this.approvedBooking,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 720 ? 4 : 2;
        final aspectRatio = width >= 720
            ? 1.55
            : width < 360
            ? 0.96
            : 1.08;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          children: [
            _StatCard(
              title: 'Fasilitas',
              value: totalFacilities.toString(),
              icon: Icons.stadium_outlined,
              color: AppColors.info,
            ),
            _StatCard(
              title: 'Total Booking',
              value: totalBooking.toString(),
              icon: Icons.event_note_outlined,
              color: AppColors.primaryDarkGreen,
            ),
            _StatCard(
              title: 'Pending',
              value: pendingBooking.toString(),
              icon: Icons.schedule_rounded,
              color: AppColors.warning,
            ),
            _StatCard(
              title: 'Approved',
              value: approvedBooking.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
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
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenSurface,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: AppColors.secondaryGreen, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onPressed;

  const _NotificationButton({
    required this.unreadCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HeaderIconButton(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifikasi',
          onPressed: onPressed,
        ),
        if (unreadCount > 0)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: Colors.white,
        tooltip: tooltip,
      ),
    );
  }
}
