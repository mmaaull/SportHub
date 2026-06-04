import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/facility_model.dart';
import '../utils/app_colors.dart';
import 'status_badge.dart';

class FacilityCard extends StatelessWidget {
  final FacilityModel facility;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showAdminActions;

  const FacilityCard({
    super.key,
    required this.facility,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showAdminActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = 'facility-image-${facility.id}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                  child: Stack(
                    children: [
                      _FacilityImage(imageUrl: facility.imageUrl),
                      Positioned(
                        left: 14,
                        top: 14,
                        child: StatusBadge(status: facility.status),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: _BookableBadge(isBookable: facility.isBookable),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      runSpacing: 8,
                      spacing: 8,
                      children: [
                        _InfoPill(
                          icon: Icons.sports_soccer_outlined,
                          text: facility.sportType,
                        ),
                        _InfoPill(
                          icon: Icons.location_on_outlined,
                          text: facility.campus,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: AppColors.secondaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${facility.openTime} - ${facility.closeTime}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (showAdminActions) ...[
                      const Divider(height: 28, color: AppColors.border),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Edit'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Hapus'),
                              ),
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
                    ] else ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Lihat Detail'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityImage extends StatelessWidget {
  final String imageUrl;

  const _FacilityImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return const _ImageFallback();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: 178,
      fit: BoxFit.cover,
      placeholder: (context, url) {
        return const _ImageLoading();
      },
      errorWidget: (context, url, error) {
        return const _ImageFallback();
      },
    );
  }
}

class _ImageLoading extends StatelessWidget {
  const _ImageLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 178,
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
      width: double.infinity,
      height: 178,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 24,
            bottom: 18,
            child: Icon(
              Icons.stadium_outlined,
              size: 86,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          const Center(
            child: Icon(Icons.sports_soccer, size: 56, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _BookableBadge extends StatelessWidget {
  final bool isBookable;

  const _BookableBadge({required this.isBookable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBookable
                ? Icons.event_available_outlined
                : Icons.event_busy_outlined,
            color: isBookable ? AppColors.success : AppColors.danger,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            isBookable ? 'Bookable' : 'Nonaktif',
            style: TextStyle(
              color: isBookable ? AppColors.success : AppColors.danger,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightGreenSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.secondaryGreen),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
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
  }
}
