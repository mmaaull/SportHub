import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../models/facility_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/facility_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/facility_card.dart';
import '../../widgets/loading_widget.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import 'booking_detail_screen.dart';
import 'facility_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final searchController = TextEditingController();

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final facilityProvider = context.read<FacilityProvider>();
      final authProvider = context.read<AuthProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final bookingProvider = context.read<BookingProvider>();

      loadInitialDashboardData(
        facilityProvider: facilityProvider,
        authProvider: authProvider,
        notificationProvider: notificationProvider,
        bookingProvider: bookingProvider,
      );
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> logout() async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Logout',
      message: 'Apakah kamu yakin ingin keluar?',
      confirmText: 'Logout',
      confirmColor: AppColors.danger,
    );

    if (!confirm) return;
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> loadInitialDashboardData({
    required FacilityProvider facilityProvider,
    required AuthProvider authProvider,
    required NotificationProvider notificationProvider,
    required BookingProvider bookingProvider,
  }) async {
    await facilityProvider.seedInitialFacilities();
    await facilityProvider.loadFacilities();

    final user = authProvider.currentUser;

    if (user != null) {
      await notificationProvider.loadUnreadCount(user.uid);
      await bookingProvider.loadUserBookings(user.uid);
    }
  }

  Future<void> refreshHome() async {
    final facilityProvider = context.read<FacilityProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final user = context.read<AuthProvider>().currentUser;

    await facilityProvider.loadFacilities();

    if (user != null) {
      await bookingProvider.loadUserBookings(user.uid);
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

  void openFacilityDetail(FacilityModel facility) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FacilityDetailScreen(facility: facility),
      ),
    );
  }

  void openBookingDetail(BookingModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking)),
    );
  }

  Widget getSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return buildHomePage();
      case 1:
        return const MyBookingsScreen();
      case 2:
        return const NotificationsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return buildHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: getSelectedPage(),
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note),
                label: 'My Bookings',
              ),
              NavigationDestination(
                icon: _NavIconWithBadge(
                  icon: Icons.notifications_outlined,
                  count: notificationProvider.unreadCount,
                ),
                selectedIcon: _NavIconWithBadge(
                  icon: Icons.notifications,
                  count: notificationProvider.unreadCount,
                ),
                label: 'Notifications',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildHomePage() {
    return Consumer4<
      AuthProvider,
      FacilityProvider,
      BookingProvider,
      NotificationProvider
    >(
      builder:
          (
            context,
            authProvider,
            facilityProvider,
            bookingProvider,
            notificationProvider,
            child,
          ) {
            final user = authProvider.currentUser;
            final facilities = facilityProvider.filteredFacilities;
            final bookings = bookingProvider.userBookings.take(3).toList();

            return RefreshIndicator(
              color: AppColors.primaryDarkGreen,
              onRefresh: refreshHome,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DashboardHeader(
                    userName: user?.name ?? 'Mahasiswa',
                    userNim: user?.nim ?? '-',
                    unreadCount: notificationProvider.unreadCount,
                    searchController: searchController,
                    onSearchChanged: facilityProvider.searchFacilities,
                    onClearSearch: () {
                      searchController.clear();
                      facilityProvider.searchFacilities('');
                    },
                    onOpenNotifications: openNotifications,
                    onOpenFilter: () => showFilterSheet(facilityProvider),
                    onLogout: logout,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryChips(
                          facilityProvider: facilityProvider,
                          onSelected: (label) {
                            applyCategoryFilter(facilityProvider, label);
                          },
                        ),
                        const SizedBox(height: 22),
                        _SectionTitle(
                          title: 'Fasilitas Populer',
                          actionText: 'Lihat Semua',
                          onAction: () {
                            searchController.clear();
                            facilityProvider.resetFilter();
                          },
                        ),
                        const SizedBox(height: 14),
                        buildFacilitySection(facilityProvider, facilities),
                        const SizedBox(height: 24),
                        _SectionTitle(
                          title: 'Booking Saya',
                          actionText: 'Lihat Semua',
                          onAction: () {
                            setState(() {
                              selectedIndex = 1;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        buildBookingSummary(bookingProvider, bookings),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget buildFacilitySection(
    FacilityProvider facilityProvider,
    List<FacilityModel> facilities,
  ) {
    if (facilityProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 32, bottom: 24),
        child: LoadingWidget(message: 'Memuat fasilitas...'),
      );
    }

    if (facilityProvider.errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Terjadi Kesalahan',
        message: facilityProvider.errorMessage!,
        buttonText: 'Coba Lagi',
        onPressed: refreshHome,
      );
    }

    if (facilities.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Fasilitas tidak ditemukan',
        message: 'Coba gunakan kata kunci lain atau reset filter pencarian.',
        buttonText: 'Reset Filter',
        onPressed: () {
          searchController.clear();
          facilityProvider.resetFilter();
        },
      );
    }

    return Column(
      children: facilities.map((facility) {
        return FacilityCard(
          facility: facility,
          onTap: () => openFacilityDetail(facility),
        );
      }).toList(),
    );
  }

  Widget buildBookingSummary(
    BookingProvider bookingProvider,
    List<BookingModel> bookings,
  ) {
    if (bookingProvider.isLoading && bookings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20, bottom: 18),
        child: LoadingWidget(message: 'Memuat booking...'),
      );
    }

    if (bookingProvider.errorMessage != null && bookings.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Terjadi Kesalahan',
        message: bookingProvider.errorMessage!,
        buttonText: 'Coba Lagi',
        onPressed: refreshHome,
      );
    }

    if (bookings.isEmpty) {
      return const _EmptyBookingSummary();
    }

    return Column(
      children: bookings.map((booking) {
        return BookingCard(
          booking: booking,
          onTap: () => openBookingDetail(booking),
        );
      }).toList(),
    );
  }

  void applyCategoryFilter(FacilityProvider facilityProvider, String label) {
    if (label == 'All') {
      searchController.clear();
      facilityProvider.resetFilter();
      return;
    }

    final matchingSportType = _matchFilterValue(
      facilityProvider.sportTypes,
      label,
    );
    final matchingCampus = _matchFilterValue(facilityProvider.campuses, label);

    if (matchingCampus != null && label.toLowerCase().contains('lidah') ||
        matchingCampus != null && label.toLowerCase().contains('ketintang')) {
      facilityProvider.filterBySportType('Semua');
      facilityProvider.filterByCampus(matchingCampus);
      return;
    }

    if (matchingSportType != null) {
      facilityProvider.filterByCampus('Semua');
      facilityProvider.filterBySportType(matchingSportType);
    }
  }

  String? _matchFilterValue(List<String> options, String label) {
    final normalizedLabel = label.toLowerCase();

    for (final option in options) {
      final normalizedOption = option.toLowerCase();

      if (normalizedOption == normalizedLabel ||
          normalizedOption.contains(normalizedLabel) ||
          normalizedLabel.contains(normalizedOption)) {
        return option;
      }
    }

    return null;
  }

  void showFilterSheet(FacilityProvider facilityProvider) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<FacilityProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Filter Fasilitas',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: provider.selectedSportType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Olahraga',
                        prefixIcon: Icon(Icons.sports_soccer_outlined),
                      ),
                      items: provider.sportTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        provider.filterBySportType(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: provider.selectedCampus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Kampus',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: provider.campuses.map((campus) {
                        return DropdownMenuItem<String>(
                          value: campus,
                          child: Text(campus, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        provider.filterByCampus(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: provider.sortBy,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Urutkan',
                        prefixIcon: Icon(Icons.sort_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Terbaru',
                          child: Text('Terbaru'),
                        ),
                        DropdownMenuItem(
                          value: 'Terlama',
                          child: Text('Terlama'),
                        ),
                        DropdownMenuItem(
                          value: 'Nama A-Z',
                          child: Text('Nama A-Z'),
                        ),
                        DropdownMenuItem(
                          value: 'Nama Z-A',
                          child: Text('Nama Z-A'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        provider.sortFacilities(value);
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              searchController.clear();
                              provider.resetFilter();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Terapkan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String userName;
  final String userNim;
  final int unreadCount;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenFilter;
  final VoidCallback onLogout;

  const _DashboardHeader({
    required this.userName,
    required this.userNim,
    required this.unreadCount,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenNotifications,
    required this.onOpenFilter,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const _HeaderPattern(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _BrandMark(),
                      const Spacer(),
                      _NotificationButton(
                        unreadCount: unreadCount,
                        onPressed: onOpenNotifications,
                      ),
                      const SizedBox(width: 10),
                      _HeaderIconButton(
                        icon: Icons.logout_rounded,
                        tooltip: 'Logout',
                        onPressed: onLogout,
                      ),
                      const SizedBox(width: 10),
                      _UserAvatar(name: userName),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '${_greeting()}, $userName!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Semangat berolahraga hari ini!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  if (userNim.trim().isNotEmpty && userNim != '-') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        'NIM $userNim',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SearchBar(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    onClear: onClearSearch,
                    onFilter: onOpenFilter,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.secondaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AppColors.secondaryGreen,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
              decoration: const InputDecoration(
                hintText: 'Cari fasilitas olahraga...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textSecondary,
              tooltip: 'Hapus pencarian',
            ),
          IconButton(
            onPressed: onFilter,
            icon: const Icon(Icons.tune_rounded),
            color: AppColors.primaryDarkGreen,
            tooltip: 'Filter',
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final FacilityProvider facilityProvider;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.facilityProvider,
    required this.onSelected,
  });

  static const categories = [
    'All',
    'Futsal',
    'Basket',
    'Renang',
    'Ketintang',
    'Lidah Wetan',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final label = categories[index];
          final selected = _isSelected(label);

          return ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            selectedColor: AppColors.primaryDarkGreen,
            backgroundColor: AppColors.card,
            side: BorderSide(
              color: selected ? AppColors.primaryDarkGreen : AppColors.border,
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
            onSelected: (_) => onSelected(label),
          );
        },
      ),
    );
  }

  bool _isSelected(String label) {
    if (label == 'All') {
      return facilityProvider.selectedSportType == 'Semua' &&
          facilityProvider.selectedCampus == 'Semua';
    }

    final lowerLabel = label.toLowerCase();
    final sportType = facilityProvider.selectedSportType.toLowerCase();
    final campus = facilityProvider.selectedCampus.toLowerCase();

    return sportType.contains(lowerLabel) ||
        lowerLabel.contains(sportType) && sportType != 'semua' ||
        campus.contains(lowerLabel) ||
        lowerLabel.contains(campus) && campus != 'semua';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onAction;

  const _SectionTitle({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionText)),
      ],
    );
  }
}

class _EmptyBookingSummary extends StatelessWidget {
  const _EmptyBookingSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.lightGreenSurface,
            foregroundColor: AppColors.primaryDarkGreen,
            child: Icon(Icons.event_available_outlined),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Booking yang kamu ajukan akan tampil di sini.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
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
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'UNESA\nSportHub',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
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
            child: _BadgeCount(count: unreadCount),
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

class _NavIconWithBadge extends StatelessWidget {
  final IconData icon;
  final int count;

  const _NavIconWithBadge({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -8,
            top: -6,
            child: _BadgeCount(count: count, compact: true),
          ),
      ],
    );
  }
}

class _BadgeCount extends StatelessWidget {
  final int count;
  final bool compact;

  const _BadgeCount({required this.count, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : count.toString();

    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 16 : 18,
        minHeight: compact ? 16 : 18,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.danger,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;

  const _UserAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: const TextStyle(
            color: AppColors.primaryDarkGreen,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
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

class _HeaderPattern extends StatelessWidget {
  const _HeaderPattern();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -58,
              child: _PatternRing(size: 180, opacity: 0.12),
            ),
            Positioned(
              left: -72,
              bottom: 58,
              child: _PatternRing(size: 162, opacity: 0.1),
            ),
            Positioned(
              right: 18,
              bottom: 96,
              child: Icon(
                Icons.stadium_outlined,
                color: Colors.white.withValues(alpha: 0.08),
                size: 108,
              ),
            ),
            Positioned(
              right: 92,
              top: 92,
              child: Icon(
                Icons.sports_basketball,
                color: Colors.white.withValues(alpha: 0.07),
                size: 56,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternRing extends StatelessWidget {
  final double size;
  final double opacity;

  const _PatternRing({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 24,
        ),
      ),
    );
  }
}
