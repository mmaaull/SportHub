// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/facility_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/facility_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/facility_card.dart';
import '../../widgets/loading_widget.dart';
import '../auth/login_screen.dart';
import 'facility_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import '../../providers/notification_provider.dart';
import '../notifications/notifications_screen.dart';

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

    Future.microtask(() async {
      final facilityProvider = context.read<FacilityProvider>();
      await facilityProvider.seedInitialFacilities();
      await facilityProvider.loadFacilities();

      final user = context.read<AuthProvider>().currentUser;

      if (user != null) {
        await context.read<NotificationProvider>().loadUnreadCount(user.uid);
      }
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

  Future<void> refreshFacilities() async {
    await context.read<FacilityProvider>().loadFacilities();
  }

  void openFacilityDetail(FacilityModel facility) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FacilityDetailScreen(facility: facility),
      ),
    );
  }

  Widget getSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return buildHomePage();
      case 1:
        return const MyBookingsScreen();
      case 2:
        return const ProfileScreen();
      default:
        return buildHomePage();
    }
  }

  String getAppBarTitle() {
    switch (selectedIndex) {
      case 0:
        return 'UNESA SportHub';
      case 1:
        return 'Booking Saya';
      case 2:
        return 'Profil';
      default:
        return 'UNESA SportHub';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(getAppBarTitle()),
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
      body: getSelectedPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Fasilitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget buildHomePage() {
    return Consumer2<AuthProvider, FacilityProvider>(
      builder: (context, authProvider, facilityProvider, child) {
        final user = authProvider.currentUser;
        final facilities = facilityProvider.filteredFacilities;

        return RefreshIndicator(
          onRefresh: refreshFacilities,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Datang,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.name ?? 'Mahasiswa',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.nim ?? '-',
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Fasilitas Olahraga',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih fasilitas olahraga UNESA yang ingin kamu booking.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: searchController,
                onChanged: facilityProvider.searchFacilities,
                decoration: InputDecoration(
                  hintText: 'Cari fasilitas, olahraga, kampus...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            facilityProvider.searchFacilities('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              buildFilterSection(facilityProvider),
              const SizedBox(height: 18),
              if (facilityProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: LoadingWidget(
                    message: 'Memuat fasilitas...',
                  ),
                )
              else if (facilityProvider.errorMessage != null)
                EmptyState(
                  icon: Icons.error_outline,
                  title: 'Terjadi Kesalahan',
                  message: facilityProvider.errorMessage!,
                  buttonText: 'Coba Lagi',
                  onPressed: refreshFacilities,
                )
              else if (facilities.isEmpty)
                EmptyState(
                  icon: Icons.search_off,
                  title: 'Fasilitas tidak ditemukan',
                  message:
                      'Coba gunakan kata kunci lain atau reset filter pencarian.',
                  buttonText: 'Reset Filter',
                  onPressed: () {
                    searchController.clear();
                    facilityProvider.resetFilter();
                  },
                )
              else
                ...facilities.map((facility) {
                  return FacilityCard(
                    facility: facility,
                    onTap: () => openFacilityDetail(facility),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget buildFilterSection(FacilityProvider facilityProvider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: facilityProvider.selectedSportType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Jenis Olahraga',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: facilityProvider.sportTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  facilityProvider.filterBySportType(value);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: facilityProvider.selectedCampus,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Kampus',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: facilityProvider.campuses.map((campus) {
                  return DropdownMenuItem<String>(
                    value: campus,
                    child: Text(
                      campus,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  facilityProvider.filterByCampus(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: facilityProvider.sortBy,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Urutkan',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
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
                  facilityProvider.sortFacilities(value);
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  searchController.clear();
                  facilityProvider.resetFilter();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}