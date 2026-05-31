// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/facility_model.dart';
import '../../providers/facility_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/activity_log_provider.dart';

class FacilityFormScreen extends StatefulWidget {
  final FacilityModel? facility;

  const FacilityFormScreen({
    super.key,
    this.facility,
  });

  @override
  State<FacilityFormScreen> createState() => _FacilityFormScreenState();
}

class _FacilityFormScreenState extends State<FacilityFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final sportTypeController = TextEditingController();
  final campusController = TextEditingController();
  final locationController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();
  final openTimeController = TextEditingController();
  final closeTimeController = TextEditingController();

  String selectedStatus = 'available';
  bool isBookable = true;

  bool get isEditMode => widget.facility != null;

  final statusOptions = const [
    'available',
    'maintenance',
    'unavailable',
  ];

  final sportTypeOptions = const [
    'Futsal',
    'Basket',
    'Renang',
    'Sepak Bola',
    'Tenis',
    'Atletik',
    'Lainnya',
  ];

  final campusOptions = const [
    'Kampus Lidah Wetan',
    'Kampus Ketintang',
  ];

  final categoryOptions = const [
    'Indoor',
    'Outdoor',
  ];

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      final facility = widget.facility!;

      nameController.text = facility.name;
      sportTypeController.text = facility.sportType;
      campusController.text = facility.campus;
      locationController.text = facility.location;
      categoryController.text = facility.category;
      descriptionController.text = facility.description;
      imageUrlController.text = facility.imageUrl;
      openTimeController.text = facility.openTime;
      closeTimeController.text = facility.closeTime;
      selectedStatus = facility.status;
      isBookable = facility.isBookable;
    } else {
      openTimeController.text = '07:00';
      closeTimeController.text = '21:00';
      sportTypeController.text = sportTypeOptions.first;
      campusController.text = campusOptions.first;
      categoryController.text = categoryOptions.first;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    sportTypeController.dispose();
    campusController.dispose();
    locationController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    openTimeController.dispose();
    closeTimeController.dispose();
    super.dispose();
  }

  Future<void> pickTime(TextEditingController controller) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final hour = pickedTime.hour.toString().padLeft(2, '0');
    final minute = pickedTime.minute.toString().padLeft(2, '0');

    controller.text = '$hour:$minute';
  }

  int timeToMinutes(String time) {
    final parts = time.split(':');

    if (parts.length != 2) return 0;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }

  bool validateOperationalTime() {
    final open = timeToMinutes(openTimeController.text);
    final close = timeToMinutes(closeTimeController.text);

    if (close <= open) {
      showError('Jam tutup harus lebih besar dari jam buka.');
      return false;
    }

    return true;
  }

  Future<void> saveFacility() async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!validateOperationalTime()) {
      return;
    }

    final provider = context.read<FacilityProvider>();
    final now = DateTime.now();

    final facility = FacilityModel(
      id: widget.facility?.id ?? '',
      name: nameController.text.trim(),
      sportType: sportTypeController.text.trim(),
      campus: campusController.text.trim(),
      location: locationController.text.trim(),
      category: categoryController.text.trim(),
      description: descriptionController.text.trim(),
      imageUrl: imageUrlController.text.trim(),
      status: selectedStatus,
      isBookable: isBookable,
      openTime: openTimeController.text.trim(),
      closeTime: closeTimeController.text.trim(),
      createdAt: widget.facility?.createdAt ?? now,
      updatedAt: now,
    );

    bool success;

    if (isEditMode) {
      success = await provider.updateFacility(facility);
    } else {
      success = await provider.addFacility(facility);
    }

    if (!mounted) return;

    if (!success) {
      showError(
        provider.errorMessage ??
            'Gagal menyimpan fasilitas. Silakan coba lagi.',
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditMode
              ? 'Fasilitas berhasil diperbarui.'
              : 'Fasilitas berhasil ditambahkan.',
        ),
        backgroundColor: AppColors.success,
      ),
      
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditMode
              ? 'Fasilitas berhasil diperbarui.'
              : 'Fasilitas berhasil ditambahkan.',
        ),
        backgroundColor: AppColors.success,
      ),
    );

    final admin = context.read<AuthProvider>().currentUser;
    if (admin != null) {
      await context.read<ActivityLogProvider>().createLog(
            adminId: admin.uid,
            adminName: admin.name,
            action: isEditMode ? 'update_facility' : 'add_facility',
            targetType: 'facility',
            targetId: facility.id,
            description: isEditMode
                ? 'Mengubah data fasilitas ${facility.name}.'
                : 'Menambahkan fasilitas baru ${facility.name}.',
          );
    }

    Navigator.pop(context, true);
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  String getStatusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Tersedia';
      case 'maintenance':
        return 'Maintenance';
      case 'unavailable':
        return 'Tidak Tersedia';
      case 'closed':
        return 'Tutup';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FacilityProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Fasilitas' : 'Tambah Fasilitas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              buildInfoCard(),
              const SizedBox(height: 18),
              buildFormCard(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              foregroundColor: AppColors.primary,
              child: Icon(
                isEditMode ? Icons.edit : Icons.add_business,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isEditMode
                    ? 'Ubah data fasilitas olahraga UNESA.'
                    : 'Tambahkan data fasilitas olahraga baru.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFormCard(FacilityProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CustomTextField(
              controller: nameController,
              label: 'Nama Fasilitas',
              prefixIcon: Icons.sports_soccer,
              validator: (value) {
                return Validators.required(value, 'Nama fasilitas');
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: sportTypeController.text,
              decoration: buildDropdownDecoration(
                label: 'Jenis Olahraga',
                icon: Icons.sports,
              ),
              items: sportTypeOptions.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                sportTypeController.text = value;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: campusController.text,
              decoration: buildDropdownDecoration(
                label: 'Kampus',
                icon: Icons.apartment_outlined,
              ),
              items: campusOptions.map((campus) {
                return DropdownMenuItem<String>(
                  value: campus,
                  child: Text(campus),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                campusController.text = value;
              },
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: locationController,
              label: 'Lokasi Detail',
              prefixIcon: Icons.location_on_outlined,
              validator: (value) {
                return Validators.required(value, 'Lokasi detail');
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: categoryController.text,
              decoration: buildDropdownDecoration(
                label: 'Kategori',
                icon: Icons.category_outlined,
              ),
              items: categoryOptions.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                categoryController.text = value;
              },
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: descriptionController,
              label: 'Deskripsi',
              prefixIcon: Icons.description_outlined,
              maxLines: 4,
              validator: (value) {
                return Validators.required(value, 'Deskripsi');
              },
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: imageUrlController,
              label: 'Image URL',
              prefixIcon: Icons.image_outlined,
              keyboardType: TextInputType.url,
              validator: (value) {
                return Validators.required(value, 'Image URL');
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: openTimeController,
                    label: 'Jam Buka',
                    prefixIcon: Icons.access_time,
                    readOnly: true,
                    onTap: () => pickTime(openTimeController),
                    validator: (value) {
                      return Validators.time(value, 'Jam buka');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: closeTimeController,
                    label: 'Jam Tutup',
                    prefixIcon: Icons.access_time_filled,
                    readOnly: true,
                    onTap: () => pickTime(closeTimeController),
                    validator: (value) {
                      return Validators.time(value, 'Jam tutup');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: buildDropdownDecoration(
                label: 'Status Fasilitas',
                icon: Icons.verified_outlined,
              ),
              items: statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(getStatusLabel(status)),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedStatus = value;

                  if (selectedStatus != 'available') {
                    isBookable = false;
                  }
                });
              },
            ),
            const SizedBox(height: 10),

            SwitchListTile(
              value: isBookable,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: const Text('Bisa Dibooking'),
              subtitle: const Text(
                'Jika aktif, user dapat mengajukan booking fasilitas ini.',
              ),
              onChanged: selectedStatus == 'available'
                  ? (value) {
                      setState(() {
                        isBookable = value;
                      });
                    }
                  : null,
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: isEditMode ? 'Simpan Perubahan' : 'Tambah Fasilitas',
              icon: isEditMode ? Icons.save : Icons.add,
              isLoading: provider.isLoading,
              onPressed: saveFacility,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration buildDropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}