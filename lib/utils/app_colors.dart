import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryDarkGreen = Color(0xFF004225);
  static const Color secondaryGreen = Color(0xFF006B4F);
  static const Color accentGreen = Color(0xFF00A878);
  static const Color lightGreenSurface = Color(0xFFEAF6F0);

  static const Color background = Color(0xFFF8FAF9);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color muted = Color(0xFF9CA3AF);

  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF16A34A);
  static const Color info = Color(0xFF2563EB);

  static const Color primary = primaryDarkGreen;
  static const Color secondary = secondaryGreen;

  static const Color pending = warning;
  static const Color approved = success;
  static const Color rejected = danger;
  static const Color cancelled = Color(0xFF6B7280);

  static const Color pendingSurface = Color(0xFFFFF7E6);
  static const Color approvedSurface = Color(0xFFEAF8EF);
  static const Color rejectedSurface = Color(0xFFFDECEC);
  static const Color cancelledSurface = Color(0xFFF3F4F6);
  static const Color infoSurface = Color(0xFFEFF6FF);

  static const List<Color> headerGradient = <Color>[
    primaryDarkGreen,
    secondaryGreen,
  ];

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pending;
      case 'approved':
        return approved;
      case 'rejected':
        return rejected;
      case 'cancelled':
      case 'canceled':
        return cancelled;
      case 'available':
      case 'tersedia':
        return success;
      case 'maintenance':
        return warning;
      case 'unavailable':
      case 'closed':
      case 'tidak tersedia':
        return danger;
      default:
        return info;
    }
  }

  static Color statusSurface(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'maintenance':
        return pendingSurface;
      case 'approved':
      case 'available':
      case 'tersedia':
        return approvedSurface;
      case 'rejected':
      case 'unavailable':
      case 'closed':
      case 'tidak tersedia':
        return rejectedSurface;
      case 'cancelled':
      case 'canceled':
        return cancelledSurface;
      default:
        return infoSurface;
    }
  }
}
