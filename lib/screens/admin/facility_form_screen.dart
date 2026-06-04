import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/facility_model.dart';
import '../../providers/activity_log_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/facility_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class FacilityFormScreen extends StatefulWidget {
  final FacilityModel? facility;

  const FacilityFormScreen({super.key, this.facility});

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

  final statusOptions = const ['available', 'maintenance', 'unavailable'];

  final sportTypeOptions = const [
    'Futsal',
    'Basket',
    'Renang',
    'Sepak Bola',
    'Tenis',
    'Atletik',
    'Lainnya',
  ];

  final campusOptions = const ['Kampus Lidah Wetan', 'Kampus Ketintang'];

  final categoryOptions = const ['Indoor', 'Outdoor'];

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

    imageUrlController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryDarkGreen,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
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
    final activityLogProvider = context.read<ActivityLogProvider>();
    final admin = context.read<AuthProvider>().currentUser;
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

    if (admin != null) {
      await activityLogProvider.createLog(
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

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
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
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              _FacilityFormHeader(
                title: isEditMode ? 'Edit Fasilitas' : 'Tambah Fasilitas',
                subtitle: isEditMode
                    ? 'Perbarui data fasilitas olahraga UNESA.'
                    : 'Tambahkan data fasilitas olahraga baru.',
              ),
              Transform.translate(
                offset: const Offset(0, -34),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 98),
                  child: Column(
                    children: [
                      buildPreviewCard(),
                      const SizedBox(height: 16),
                      buildFormCard(provider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _SubmitBar(
        isEditMode: isEditMode,
        isLoading: provider.isLoading,
        onPressed: saveFacility,
      ),
    );
  }

  Widget buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _ImagePreview(imageUrl: imageUrlController.text.trim()),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameController.text.trim().isEmpty
                      ? 'Nama Fasilitas'
                      : nameController.text.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${sportTypeController.text} - ${campusController.text}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(
                      text: getStatusLabel(selectedStatus),
                      color: AppColors.statusColor(selectedStatus),
                    ),
                    _StatusPill(
                      text: isBookable ? 'Bookable' : 'Nonaktif',
                      color: isBookable ? AppColors.success : AppColors.danger,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormCard(FacilityProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Fasilitas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: nameController,
            label: 'Nama Fasilitas',
            prefixIcon: Icons.sports_soccer,
            onChanged: (_) => setState(() {}),
            validator: (value) {
              return Validators.required(value, 'Nama fasilitas');
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: sportTypeController.text,
            isExpanded: true,
            decoration: buildDropdownDecoration(
              label: 'Jenis Olahraga',
              icon: Icons.sports,
            ),
            items: sportTypeOptions.map((type) {
              return DropdownMenuItem<String>(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                sportTypeController.text = value;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: campusController.text,
            isExpanded: true,
            decoration: buildDropdownDecoration(
              label: 'Kampus',
              icon: Icons.apartment_outlined,
            ),
            items: campusOptions.map((campus) {
              return DropdownMenuItem<String>(
                value: campus,
                child: Text(campus, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                campusController.text = value;
              });
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
            initialValue: categoryController.text,
            isExpanded: true,
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
              setState(() {
                categoryController.text = value;
              });
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
          LayoutBuilder(
            builder: (context, constraints) {
              final openField = CustomTextField(
                controller: openTimeController,
                label: 'Jam Buka',
                prefixIcon: Icons.access_time,
                readOnly: true,
                onTap: () => pickTime(openTimeController),
                validator: (value) {
                  return Validators.time(value, 'Jam buka');
                },
              );
              final closeField = CustomTextField(
                controller: closeTimeController,
                label: 'Jam Tutup',
                prefixIcon: Icons.access_time_filled,
                readOnly: true,
                onTap: () => pickTime(closeTimeController),
                validator: (value) {
                  return Validators.time(value, 'Jam tutup');
                },
              );

              if (constraints.maxWidth < 360) {
                return Column(
                  children: [openField, const SizedBox(height: 16), closeField],
                );
              }

              return Row(
                children: [
                  Expanded(child: openField),
                  const SizedBox(width: 12),
                  Expanded(child: closeField),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            isExpanded: true,
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              value: isBookable,
              activeThumbColor: AppColors.primaryDarkGreen,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Bisa Dibooking',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              subtitle: const Text(
                'Jika aktif, user dapat mengajukan booking fasilitas ini.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              onChanged: selectedStatus == 'available'
                  ? (value) {
                      setState(() {
                        isBookable = value;
                      });
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration buildDropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon));
  }
}

class _FacilityFormHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FacilityFormHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 74),
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
            bottom: -34,
            child: Icon(
              Icons.add_business_outlined,
              color: Colors.white.withValues(alpha: 0.08),
              size: 132,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Row(
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
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

class _ImagePreview extends StatelessWidget {
  final String imageUrl;

  const _ImagePreview({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const _ImageFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        placeholder: (context, url) => const _ImageFallback(),
        errorWidget: (context, url, error) => const _ImageFallback(),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(Icons.stadium_outlined, color: Colors.white, size: 38),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final bool isEditMode;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitBar({
    required this.isEditMode,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: CustomButton(
          text: isEditMode ? 'Simpan Perubahan' : 'Tambah Fasilitas',
          icon: isEditMode ? Icons.save_outlined : Icons.add_rounded,
          isLoading: isLoading,
          onPressed: onPressed,
        ),
      ),
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
