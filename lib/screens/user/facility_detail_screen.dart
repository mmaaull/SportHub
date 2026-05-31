// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/facility_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'booking_form_screen.dart';
import 'facility_schedule_screen.dart';

class FacilityDetailScreen extends StatelessWidget {
  final FacilityModel facility;

  const FacilityDetailScreen({
    super.key,
    required this.facility,
  });

  bool get canBook {
    return facility.isBookable && facility.status == 'available';
  }

  void openBookingForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingFormScreen(facility: facility),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = 'facility-image-${facility.id}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                facility.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Hero(
                tag: heroTag,
                child: CachedNetworkImage(
                  imageUrl: facility.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                  errorWidget: (context, url, error) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                          size: 56,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHeader(),
                  const SizedBox(height: 18),
                  buildInfoCard(),
                  const SizedBox(height: 18),
                  buildDescriptionCard(),
                  const SizedBox(height: 18),
                  buildBookingInfoCard(),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FacilityScheduleScreen(facility: facility),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Jadwal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canBook ? () => openBookingForm(context) : null,
                icon: const Icon(Icons.event_available),
                label: Text(
                  canBook ? 'Booking' : 'Tidak Tersedia',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.12),
              foregroundColor: AppColors.primary,
              radius: 28,
              child: const Icon(
                Icons.sports_soccer,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusBadge(status: facility.status),
                      _SmallBadge(
                        icon: Icons.category_outlined,
                        text: facility.category,
                      ),
                      _SmallBadge(
                        icon: Icons.sports,
                        text: facility.sportType,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.sports_soccer,
              title: 'Jenis Olahraga',
              value: facility.sportType,
            ),
            const Divider(),
            _InfoTile(
              icon: Icons.apartment_outlined,
              title: 'Kampus',
              value: facility.campus,
            ),
            const Divider(),
            _InfoTile(
              icon: Icons.location_on_outlined,
              title: 'Lokasi',
              value: facility.location,
            ),
            const Divider(),
            _InfoTile(
              icon: Icons.access_time,
              title: 'Jam Operasional',
              value: '${facility.openTime} - ${facility.closeTime}',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDescriptionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Deskripsi Fasilitas',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              facility.description.isEmpty
                  ? 'Belum ada deskripsi fasilitas.'
                  : facility.description,
              style: const TextStyle(
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBookingInfoCard() {
    return Card(
      elevation: 2,
      color: canBook
          ? AppColors.success.withOpacity(0.08)
          : AppColors.danger.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              canBook ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: canBook ? AppColors.success : AppColors.danger,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                canBook
                    ? 'Fasilitas ini tersedia dan dapat diajukan untuk booking.'
                    : 'Fasilitas ini sedang tidak tersedia untuk booking.',
                style: TextStyle(
                  color: canBook ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          foregroundColor: AppColors.primary,
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}