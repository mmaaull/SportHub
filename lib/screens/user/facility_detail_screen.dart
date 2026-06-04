import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/facility_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'booking_form_screen.dart';
import 'facility_schedule_screen.dart';

class FacilityDetailScreen extends StatelessWidget {
  final FacilityModel facility;

  const FacilityDetailScreen({super.key, required this.facility});

  bool get canBook {
    return facility.isBookable && facility.status == 'available';
  }

  void openBookingForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingFormScreen(facility: facility)),
    );
  }

  void openSchedule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FacilityScheduleScreen(facility: facility),
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
            expandedHeight: 315,
            pinned: true,
            backgroundColor: AppColors.primaryDarkGreen,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              facility.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: heroTag,
                child: _HeroImage(imageUrl: facility.imageUrl),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -34),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTitleCard(),
                    const SizedBox(height: 16),
                    buildInfoCard(),
                    const SizedBox(height: 16),
                    buildDescriptionCard(),
                    const SizedBox(height: 16),
                    buildFeaturedFacilitiesCard(),
                    const SizedBox(height: 16),
                    buildBookingInfoCard(),
                    const SizedBox(height: 104),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _StickyActionBar(
        canBook: canBook,
        onSchedule: () => openSchedule(context),
        onBooking: () => openBookingForm(context),
      ),
    );
  }

  Widget buildTitleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            facility.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  facility.location.trim().isEmpty
                      ? facility.campus
                      : '${facility.campus}, ${facility.location}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(status: facility.status),
              _GlassBadge(
                icon: facility.isBookable
                    ? Icons.event_available_outlined
                    : Icons.event_busy_outlined,
                text: facility.isBookable ? 'Bookable' : 'Nonaktif',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInfoCard() {
    return _DetailCard(
      title: 'Detail Fasilitas',
      icon: Icons.info_outline_rounded,
      children: [
        _InfoTile(
          icon: Icons.sports_soccer_outlined,
          title: 'Jenis Olahraga',
          value: facility.sportType,
        ),
        const _SoftDivider(),
        _InfoTile(
          icon: Icons.apartment_outlined,
          title: 'Kampus',
          value: facility.campus,
        ),
        const _SoftDivider(),
        _InfoTile(
          icon: Icons.location_on_outlined,
          title: 'Alamat',
          value: facility.location.trim().isEmpty ? '-' : facility.location,
        ),
        const _SoftDivider(),
        _InfoTile(
          icon: Icons.access_time_rounded,
          title: 'Jam Operasional',
          value: '${facility.openTime} - ${facility.closeTime}',
        ),
      ],
    );
  }

  Widget buildDescriptionCard() {
    return _DetailCard(
      title: 'Deskripsi',
      icon: Icons.description_outlined,
      children: [
        Text(
          facility.description.trim().isEmpty
              ? 'Belum ada deskripsi fasilitas.'
              : facility.description,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget buildFeaturedFacilitiesCard() {
    return _DetailCard(
      title: 'Fasilitas Unggulan',
      icon: Icons.star_outline_rounded,
      children: const [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _FeaturePill(icon: Icons.wc_outlined, text: 'Toilet'),
            _FeaturePill(
              icon: Icons.local_parking_outlined,
              text: 'Parkir Luas',
            ),
            _FeaturePill(icon: Icons.stadium_outlined, text: 'Tribun'),
            _FeaturePill(
              icon: Icons.meeting_room_outlined,
              text: 'Ruang Ganti',
            ),
          ],
        ),
      ],
    );
  }

  Widget buildBookingInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canBook ? AppColors.approvedSurface : AppColors.rejectedSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (canBook ? AppColors.success : AppColors.danger).withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            canBook ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: canBook ? AppColors.success : AppColors.danger,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              canBook
                  ? 'Fasilitas ini tersedia dan dapat diajukan untuk booking.'
                  : 'Fasilitas ini sedang tidak tersedia untuk booking.',
              style: TextStyle(
                color: canBook ? AppColors.success : AppColors.danger,
                fontSize: 13.5,
                height: 1.35,
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

class _HeroImage extends StatelessWidget {
  final String imageUrl;

  const _HeroImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return const _ImageFallback();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const _ImageLoading(),
          errorWidget: (context, url, error) => const _ImageFallback(),
        ),
        const _ImageScrim(),
      ],
    );
  }
}

class _ImageLoading extends StatelessWidget {
  const _ImageLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightGreenSurface,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryDarkGreen,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const _ImageScrim(),
          Positioned(
            right: 28,
            bottom: 46,
            child: Icon(
              Icons.stadium_outlined,
              size: 118,
              color: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          const Center(
            child: Icon(Icons.sports_soccer, color: Colors.white, size: 70),
          ),
        ],
      ),
    );
  }
}

class _ImageScrim extends StatelessWidget {
  const _ImageScrim();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.12),
            Colors.black.withValues(alpha: 0.46),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.children,
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
          Row(
            children: [
              _CardIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeaturePill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightGreenSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondaryGreen, size: 16),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GlassBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardIcon extends StatelessWidget {
  final IconData icon;

  const _CardIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.lightGreenSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.secondaryGreen, size: 21),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

class _StickyActionBar extends StatelessWidget {
  final bool canBook;
  final VoidCallback onSchedule;
  final VoidCallback onBooking;

  const _StickyActionBar({
    required this.canBook,
    required this.onSchedule,
    required this.onBooking,
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
              blurRadius: 18,
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSchedule,
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Lihat Jadwal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canBook ? onBooking : null,
                icon: const Icon(Icons.event_available_outlined),
                label: Text(canBook ? 'Ajukan Booking' : 'Tidak Tersedia'),
              ),
            ),
          ],
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
