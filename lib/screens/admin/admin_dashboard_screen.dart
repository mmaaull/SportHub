// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/facility_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../auth/login_screen.dart';
import 'manage_facilities_screen.dart';
import 'manage_bookings_screen.dart';
import 'statistics_screen.dart';
import '../../providers/notification_provider.dart';
import '../notifications/notifications_screen.dart';
import 'activity_logs_screen.dart';
import 'admin_schedule_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await context.read<FacilityProvider>().seedInitialFacilities();
      if (!mounted) return;
      await context.read<BookingProvider>().loadStatistics();

      final user = context.read<AuthProvider>().currentUser;

      if (user != null) {
        await context.read<NotificationProvider>().loadUnreadCount(user.uid);
      }
    });
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
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final facilityProvider = context.watch<FacilityProvider>();

    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );

                      if (!mounted) return;

                      final user = context.read<AuthProvider>().currentUser;

                      if (user != null) {
                        await context
                            .read<NotificationProvider>()
                            .loadUnreadCount(user.uid);
                      }
                    },
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifikasi',
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          notificationProvider.unreadCount > 9
                              ? '9+'
                              : notificationProvider.unreadCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<FacilityProvider>().loadFacilities();
          if (!mounted) return;
          await context.read<BookingProvider>().loadStatistics();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panel Pengelola',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.name ?? 'Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.email ?? '-',
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ringkasan Sementara',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _StatCard(
                  title: 'Fasilitas',
                  value: facilityProvider.facilities.length.toString(),
                  icon: Icons.sports_soccer,
                  color: AppColors.info,
                ),
                _StatCard(
                  title: 'Total Booking',
                  value: bookingProvider.totalBooking.toString(),
                  icon: Icons.event_note,
                  color: AppColors.primary,
                ),
                _StatCard(
                  title: 'Pending',
                  value: bookingProvider.pendingBooking.toString(),
                  icon: Icons.schedule,
                  color: AppColors.pending,
                ),
                _StatCard(
                  title: 'Approved',
                  value: bookingProvider.approvedBooking.toString(),
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _AdminMenuCard(
              icon: Icons.calendar_month,
              title: 'Kalender Jadwal',
              description: 'Lihat jadwal booking fasilitas dalam bentuk kalender.',
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
              icon: Icons.edit_calendar,
              title: 'CRUD Fasilitas',
              description: 'Tambah, edit, dan hapus data fasilitas olahraga UNESA.',
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
              icon: Icons.bar_chart,
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
              icon: Icons.history,
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
    return Card(
      elevation: 2,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          foregroundColor: AppColors.primary,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}