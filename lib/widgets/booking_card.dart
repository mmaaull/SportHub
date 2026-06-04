import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';
import 'status_badge.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final bool showUserActions;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onEdit,
    this.onCancel,
    this.showUserActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BookingVisual(sportType: booking.sportType),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  booking.facilityName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16.5,
                                    height: 1.2,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(status: booking.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.sports_soccer_outlined,
                            text: booking.sportType,
                          ),
                          const SizedBox(height: 7),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            text: booking.campus,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.calendar_month_outlined,
                        text: DateFormatter.formatBookingTime(
                          date: booking.date,
                          startTime: booking.startTime,
                          endTime: booking.endTime,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.groups_outlined,
                        text: '${booking.participantCount} peserta',
                      ),
                      if (booking.userName.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.person_outline,
                          text: '${booking.userName} - ${booking.userNim}',
                        ),
                      ],
                    ],
                  ),
                ),
                if (booking.status == 'rejected' &&
                    booking.adminNote.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.rejectedSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      'Alasan ditolak: ${booking.adminNote}',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
                if (showUserActions) ...[
                  const Divider(height: 26, color: AppColors.border),
                  if (booking.isPending)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Booking'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCancel,
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('Batal'),
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
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Lihat Detail'),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingVisual extends StatelessWidget {
  final String sportType;

  const _BookingVisual({required this.sportType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -10,
            child: Icon(
              Icons.stadium_outlined,
              size: 46,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Center(
            child: Icon(_sportIcon(sportType), color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }

  IconData _sportIcon(String value) {
    final lowerValue = value.toLowerCase();

    if (lowerValue.contains('basket')) return Icons.sports_basketball;
    if (lowerValue.contains('renang')) return Icons.pool_rounded;
    if (lowerValue.contains('badminton')) return Icons.sports_tennis;
    if (lowerValue.contains('tenis')) return Icons.sports_tennis;
    if (lowerValue.contains('voli')) return Icons.sports_volleyball;

    return Icons.sports_soccer;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.secondaryGreen),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
