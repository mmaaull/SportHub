import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final badgeColor = AppColors.statusColor(normalizedStatus);
    final badgeSurface = AppColors.statusSurface(normalizedStatus);
    final label = _getStatusLabel(normalizedStatus);
    final icon = _getStatusIcon(normalizedStatus);

    return Container(
      constraints: const BoxConstraints(maxWidth: 152),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: badgeColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: badgeColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: badgeColor,
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'available':
      case 'tersedia':
        return 'Tersedia';
      case 'maintenance':
        return 'Maintenance';
      case 'unavailable':
      case 'tidak tersedia':
        return 'Tidak Tersedia';
      case 'closed':
        return 'Tutup';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
      case 'canceled':
        return Icons.block;
      case 'available':
      case 'tersedia':
        return Icons.check_circle_outline;
      case 'maintenance':
        return Icons.build_circle_outlined;
      case 'unavailable':
      case 'tidak tersedia':
        return Icons.not_interested;
      case 'closed':
        return Icons.lock_outline;
      default:
        return Icons.info_outline;
    }
  }
}
