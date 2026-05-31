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
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.event_available),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      booking.facilityName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.person_outline,
                text: '${booking.userName} - ${booking.userNim}',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.sports_soccer,
                text: booking.sportType,
              ),
              const SizedBox(height: 8),
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
              if (booking.status == 'rejected' &&
                  booking.adminNote.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: AppColors.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Alasan ditolak: ${booking.adminNote}',
                    style: const TextStyle(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
              if (showUserActions && booking.isPending) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Batalkan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: AppColors.primary,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}