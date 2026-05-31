// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/facility_model.dart';
import '../../providers/facility_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/facility_card.dart';
import '../../widgets/loading_widget.dart';
import 'facility_form_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/activity_log_provider.dart';

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

    Future.microtask(() async {
      final provider = context.read<FacilityProvider>();
      await provider.seedInitialFacilities();
      await provider.loadFacilities();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> refreshFacilities() async {
    await context.read<FacilityProvider>().loadFacilities();
  }

  Future<void> openAddFacility() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FacilityFormScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await refreshFacilities();
    }
  }

  Future<void> openEditFacility(FacilityModel facility) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FacilityFormScreen(facility: facility),
      ),
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

    final admin = context.read<AuthProvider>().currentUser;
    if (admin != null) {
      await context.read<ActivityLogProvider>().createLog(
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
      appBar: AppBar(
        title: const Text('Kelola Fasilitas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddFacility,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Consumer<FacilityProvider>(
        builder: (context, provider, child) {
          final facilities = provider.filteredFacilities;

          return RefreshIndicator(
            onRefresh: refreshFacilities,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                buildHeader(provider.facilities.length),
                const SizedBox(height: 18),
                buildSearchBox(provider),
                const SizedBox(height: 14),
                buildFilterSection(provider),
                const SizedBox(height: 18),
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 70),
                    child: LoadingWidget(
                      message: 'Memuat fasilitas...',
                    ),
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
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildHeader(int totalFacilities) {
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
              Icons.sports_soccer,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manajemen Fasilitas',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalFacilities Fasilitas',
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

  Widget buildSearchBox(FacilityProvider provider) {
    return TextField(
      controller: searchController,
      onChanged: provider.searchFacilities,
      decoration: InputDecoration(
        hintText: 'Cari fasilitas...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  searchController.clear();
                  provider.searchFacilities('');
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
    );
  }

  Widget buildFilterSection(FacilityProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: provider.selectedSportType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Olahraga',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
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
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: provider.selectedCampus,
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
                items: provider.campuses.map((campus) {
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
                  provider.filterByCampus(value);
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
                value: provider.sortBy,
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
                  provider.sortFacilities(value);
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  searchController.clear();
                  provider.resetFilter();
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