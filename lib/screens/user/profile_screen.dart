import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      loadProfileData();
    });
  }

  Future<void> loadProfileData() async {
    final user = context.read<AuthProvider>().currentUser;
    final bookingProvider = context.read<BookingProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    if (user == null) {
      return;
    }

    await bookingProvider.loadUserBookings(user.uid);
    await notificationProvider.loadUnreadCount(user.uid);
  }

  Future<void> logout() async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Keluar dari Akun?',
      message: 'Sesi login kamu akan diakhiri.',
      confirmText: 'Keluar',
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

  void showSimpleMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final bookingProvider = context.watch<BookingProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    if (user == null) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'User Tidak Ditemukan',
        message: 'Silakan login ulang untuk melihat profil.',
      );
    }

    final bookings = bookingProvider.userBookings;
    final approved = bookings.where((booking) => booking.isApproved).length;
    final pending = bookings.where((booking) => booking.isPending).length;

    return RefreshIndicator(
      color: AppColors.primaryDarkGreen,
      onRefresh: loadProfileData,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ProfileHeader(
            name: user.name,
            nim: user.nim,
            faculty: user.faculty,
            email: user.email,
            unreadCount: notificationProvider.unreadCount,
            onNotifications: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          Transform.translate(
            offset: const Offset(0, -34),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              child: Column(
                children: [
                  _AccountSummaryCard(
                    total: bookings.length,
                    approved: approved,
                    pending: pending,
                  ),
                  const SizedBox(height: 16),
                  _MenuCard(
                    isDarkMode: themeProvider.isDarkMode,
                    onToggleTheme: themeProvider.toggleTheme,
                    onEditProfile: () {
                      showSimpleMessage(
                        'Edit profil akan tersedia pada pengembangan berikutnya.',
                      );
                    },
                    onHistory: () {
                      showSimpleMessage(
                        'Riwayat booking tersedia di tab My Bookings.',
                      );
                    },
                    onNotifications: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    onHelp: () {
                      showSimpleMessage(
                        'Hubungi admin pengelola fasilitas untuk bantuan.',
                      );
                    },
                    onAbout: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'UNESA SportHub',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.sports_soccer,
                          color: AppColors.primaryDarkGreen,
                          size: 34,
                        ),
                        children: const [
                          Text(
                            'Aplikasi informasi dan booking fasilitas olahraga Universitas Negeri Surabaya.',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: context.watch<AuthProvider>().isLoading
                          ? null
                          : logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Keluar dari Akun'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(
                          color: AppColors.danger,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String nim;
  final String faculty;
  final String email;
  final int unreadCount;
  final VoidCallback onNotifications;

  const _ProfileHeader({
    required this.name,
    required this.nim,
    required this.faculty,
    required this.email,
    required this.unreadCount,
    required this.onNotifications,
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
            right: -28,
            bottom: -28,
            child: Icon(
              Icons.account_circle_outlined,
              size: 132,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
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
                  ],
                ),
                const SizedBox(height: 28),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.42),
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _initials(name),
                          style: const TextStyle(
                            color: AppColors.primaryDarkGreen,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.accentGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderPill(icon: Icons.badge_outlined, text: nim),
                    _HeaderPill(icon: Icons.school_outlined, text: faculty),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'U';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();

    return '${words.first.substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
  }
}

class _AccountSummaryCard extends StatelessWidget {
  final int total;
  final int approved;
  final int pending;

  const _AccountSummaryCard({
    required this.total,
    required this.approved,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Akun',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Total Booking',
                  value: total.toString(),
                  icon: Icons.event_note_outlined,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryItem(
                  label: 'Approved',
                  value: approved.toString(),
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryItem(
                  label: 'Pending',
                  value: pending.toString(),
                  icon: Icons.schedule_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;
  final VoidCallback onEditProfile;
  final VoidCallback onHistory;
  final VoidCallback onNotifications;
  final VoidCallback onHelp;
  final VoidCallback onAbout;

  const _MenuCard({
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onEditProfile,
    required this.onHistory,
    required this.onNotifications,
    required this.onHelp,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profil',
            onTap: onEditProfile,
          ),
          const _MenuDivider(),
          _MenuTile(
            icon: Icons.history_rounded,
            title: 'Riwayat Booking',
            onTap: onHistory,
          ),
          const _MenuDivider(),
          _MenuTile(
            icon: Icons.notifications_outlined,
            title: 'Notifikasi',
            onTap: onNotifications,
          ),
          const _MenuDivider(),
          _MenuTile(
            icon: Icons.dark_mode_outlined,
            title: 'Mode Gelap',
            trailing: Switch(
              value: isDarkMode,
              activeThumbColor: AppColors.primaryDarkGreen,
              onChanged: onToggleTheme,
            ),
          ),
          const _MenuDivider(),
          _MenuTile(icon: Icons.help_outline, title: 'Bantuan', onTap: onHelp),
          const _MenuDivider(),
          _MenuTile(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            onTap: onAbout,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minTileHeight: 60,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.lightGreenSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.secondaryGreen, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
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
        Material(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          child: IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.notifications_outlined),
            color: Colors.white,
            tooltip: 'Notifikasi',
          ),
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

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 72),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
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
  );
}
