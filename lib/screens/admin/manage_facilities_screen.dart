import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/facility_model.dart';
import '../../providers/activity_log_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/facility_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/facility_card.dart';
import '../../widgets/loading_widget.dart';
import 'facility_form_screen.dart';

class ManageFacilitiesScreen extends StatefulWidget {
  const ManageFacilitiesScreen({super.key});

  @override
  State<ManageFacilitiesScreen> createState() => _ManageFacilitiesScreenState();
}

class _ManageFacilitiesScreenState extends State<ManageFacilitiesScreen> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      loadFacilities();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadFacilities() async {
    final provider = context.read<FacilityProvider>();

    await provider.seedInitialFacilities();
    await provider.loadFacilities();
  }

  Future<void> refreshFacilities() async {
    await context.read<FacilityProvider>().loadFacilities();
  }

  Future<void> openAddFacility() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FacilityFormScreen()),
    );

    if (!mounted) return;

    if (result == true) {
      await refreshFacilities();
    }
  }

  Future<void> openEditFacility(FacilityModel facility) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FacilityFormScreen(facility: facility)),
    );

    if (!mounted) return;

    if (result == true) {
      await refreshFacilities();
    }
  }

  Future<void> deleteFacility(FacilityModel facility) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Hapus Fasilitas?',
      message:
          'Data fasilitas "${facility.name}" akan dihapus dari Firestore. Lanjutkan?',
      confirmText: 'Hapus',
      confirmColor: AppColors.danger,
    );

    if (!confirm) return;
    if (!mounted) return;

    final provider = context.read<FacilityProvider>();
    final activityLogProvider = context.read<ActivityLogProvider>();
    final admin = context.read<AuthProvider>().currentUser;

    final success = await provider.deleteFacility(facility.id);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menghapus fasilitas.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fasilitas berhasil dihapus.'),
        backgroundColor: AppColors.success,
      ),
    );

    if (admin != null) {
      await activityLogProvider.createLog(
        adminId: admin.uid,
        adminName: admin.name,
        action: 'delete_facility',
        targetType: 'facility',
        targetId: facility.id,
        description: 'Menghapus fasilitas ${facility.name}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddFacility,
        backgroundColor: AppColors.primaryDarkGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: Consumer<FacilityProvider>(
        builder: (context, provider, child) {
          final facilities = provider.filteredFacilities;

          return RefreshIndicator(
            color: AppColors.primaryDarkGreen,
            onRefresh: refreshFacilities,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ManageFacilitiesHeader(
                  totalFacilities: provider.facilities.length,
                  searchController: searchController,
                  onSearchChanged: (value) {
                    setState(() {});
                    provider.searchFacilities(value);
                  },
                  onClearSearch: () {
                    searchController.clear();
                    provider.searchFacilities('');
                    setState(() {});
                  },
                  onFilter: () => showFilterSheet(provider),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildFilterChips(provider),
                      const SizedBox(height: 18),
                      if (provider.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 58),
                          child: LoadingWidget(message: 'Memuat fasilitas...'),
                        )
                      else if (provider.errorMessage != null)
                        EmptyState(
                          icon: Icons.error_outline,
                          title: 'Terjadi Kesalahan',
                          message: provider.errorMessage!,
                          buttonText: 'Coba Lagi',
                          onPressed: refreshFacilities,
                        )
                      else if (facilities.isEmpty)
                        EmptyState(
                          icon: Icons.sports_soccer_outlined,
                          title: 'Fasilitas Kosong',
                          message:
                              'Belum ada fasilitas yang sesuai dengan pencarian/filter.',
                          buttonText: 'Tambah Fasilitas',
                          onPressed: openAddFacility,
                        )
                      else
                        ...facilities.map((facility) {
                          return FacilityCard(
                            facility: facility,
                            showAdminActions: true,
                            onTap: () => openEditFacility(facility),
                            onEdit: () => openEditFacility(facility),
                            onDelete: () => deleteFacility(facility),
                          );
                        }),
                      const SizedBox(height: 86),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildFilterChips(FacilityProvider provider) {
    final filters = [
      _FilterChipData(
        label: provider.selectedSportType == 'Semua'
            ? 'Semua Olahraga'
            : provider.selectedSportType,
        icon: Icons.sports_soccer_outlined,
      ),
      _FilterChipData(
        label: provider.selectedCampus == 'Semua'
            ? 'Semua Kampus'
            : provider.selectedCampus,
        icon: Icons.location_on_outlined,
      ),
      _FilterChipData(label: provider.sortBy, icon: Icons.sort_rounded),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(filter.icon, size: 15, color: AppColors.secondaryGreen),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  filter.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void showFilterSheet(FacilityProvider provider) {
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
                        labelText: 'Olahraga',
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
                              setState(() {});
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

class _ManageFacilitiesHeader extends StatelessWidget {
  final int totalFacilities;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onFilter;

  const _ManageFacilitiesHeader({
    required this.totalFacilities,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            bottom: -26,
            child: Icon(
              Icons.stadium_outlined,
              color: Colors.white.withValues(alpha: 0.08),
              size: 128,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                    const Expanded(
                      child: Text(
                        'Kelola Fasilitas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '$totalFacilities Fasilitas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 20),
                _AdminSearchBar(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  onClear: onClearSearch,
                  onFilter: onFilter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  const _AdminSearchBar({
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
                hintText: 'Cari fasilitas...',
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

class _FilterChipData {
  final String label;
  final IconData icon;

  const _FilterChipData({required this.label, required this.icon});
}
