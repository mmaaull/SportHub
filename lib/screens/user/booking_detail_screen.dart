import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../services/receipt_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import 'booking_form_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late BookingModel booking;

  final ReceiptService receiptService = ReceiptService();

  @override
  void initState() {
    super.initState();
    booking = widget.booking;
  }

  Future<void> openReceipt() async {
    if (!booking.hasReceipt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surat tanda terima belum tersedia.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    await receiptService.previewReceipt(booking);
  }

  Future<void> shareReceipt() async {
    if (!booking.hasReceipt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surat tanda terima belum tersedia.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    await receiptService.shareReceipt(booking);
  }

  Future<void> refreshBooking() async {
    final latestBooking = await context.read<BookingProvider>().getBookingById(
      booking.id,
    );

    if (!mounted) return;

    if (latestBooking != null) {
      setState(() {
        booking = latestBooking;
      });
    }
  }

  Future<void> editBooking() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingFormScreen(booking: booking)),
    );

    if (!mounted) return;

    if (result == true) {
      await refreshBooking();
    }
  }

  Future<void> cancelBooking() async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Batalkan Booking?',
      message:
          'Booking yang dibatalkan tidak akan dihapus permanen, tetapi statusnya berubah menjadi cancelled.',
      confirmText: 'Batalkan',
      confirmColor: AppColors.danger,
    );

    if (!confirm) return;
    if (!mounted) return;

    final success = await context.read<BookingProvider>().cancelBooking(
      bookingId: booking.id,
      userId: booking.userId,
    );

    if (!mounted) return;

    if (!success) {
      final error =
          context.read<BookingProvider>().errorMessage ??
          'Gagal membatalkan booking.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    await refreshBooking();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking berhasil dibatalkan.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryDarkGreen,
        onRefresh: refreshBooking,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _DetailHeader(),
            Transform.translate(
              offset: const Offset(0, -34),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                child: Column(
                  children: [
                    buildSummaryCard(),
                    const SizedBox(height: 16),
                    buildBookingDetailCard(),
                    const SizedBox(height: 16),
                    buildUserInfoCard(),
                    const SizedBox(height: 16),
                    buildAdminStatusCard(),
                    if (booking.hasReceipt) ...[
                      const SizedBox(height: 16),
                      buildReceiptCard(),
                    ],
                    if (booking.isPending) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: bookingProvider.isLoading
                                  ? null
                                  : editBooking,
                              icon: const Icon(Icons.edit_outlined),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Edit Booking'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: bookingProvider.isLoading
                                  ? null
                                  : cancelBooking,
                              icon: const Icon(Icons.cancel_outlined),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Batalkan'),
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
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummaryCard() {
    return _PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookingVisual(sportType: booking.sportType),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.facilityName,
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
                const SizedBox(height: 8),
                Text(
                  '${booking.sportType} - ${booking.campus}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: booking.status),
                    _SmallBadge(
                      icon: Icons.confirmation_number_outlined,
                      text: booking.id.isEmpty ? '-' : booking.id,
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

  Widget buildBookingDetailCard() {
    return _DetailCard(
      title: 'Detail Booking',
      icon: Icons.event_note_outlined,
      children: [
        _DetailRow(
          icon: Icons.calendar_month_outlined,
          label: 'Tanggal',
          value: DateFormatter.formatDayDate(booking.date),
        ),
        const _SoftDivider(),
        _DetailRow(
          icon: Icons.access_time_rounded,
          label: 'Jam',
          value: '${booking.startTime} - ${booking.endTime}',
        ),
        const _SoftDivider(),
        _DetailRow(
          icon: Icons.groups_outlined,
          label: 'Jumlah Peserta',
          value: '${booking.participantCount} peserta',
        ),
        const _SoftDivider(),
        _DetailRow(
          icon: Icons.flag_outlined,
          label: 'Tujuan Kegiatan',
          value: booking.purpose,
        ),
        const _SoftDivider(),
        _DetailRow(
          icon: Icons.notes_outlined,
          label: 'Catatan Tambahan',
          value: booking.note.trim().isEmpty ? '-' : booking.note,
        ),
      ],
    );
  }

  Widget buildUserInfoCard() {
    return _DetailCard(
      title: 'Informasi Pemesan',
      icon: Icons.person_pin_outlined,
      children: [
        _DetailRow(
          icon: Icons.person_outline,
          label: 'Nama Mahasiswa',
          value: booking.userName,
        ),
        const _SoftDivider(),
        _DetailRow(
          icon: Icons.badge_outlined,
          label: 'NIM',
          value: booking.userNim,
        ),
      ],
    );
  }

  Widget buildAdminStatusCard() {
    final reviewedBy = booking.isApproved
        ? booking.approvedByName
        : booking.isRejected
        ? booking.rejectedByName
        : '';
    final reviewedAt = booking.isApproved
        ? booking.approvedAt
        : booking.isRejected
        ? booking.rejectedAt
        : null;

    return _DetailCard(
      title: 'Status & Catatan Admin',
      icon: Icons.admin_panel_settings_outlined,
      children: [
        Row(
          children: [
            const _DetailIcon(icon: Icons.fact_check_outlined),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Status',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            StatusBadge(status: booking.status),
          ],
        ),
        const _SoftDivider(),
        _DetailRow(
          icon: Icons.verified_user_outlined,
          label: 'Disetujui/Ditolak oleh',
          value: reviewedBy.trim().isEmpty ? '-' : reviewedBy,
        ),
        const _SoftDivider(),
        _DetailRow(
          icon: Icons.history_rounded,
          label: 'Waktu persetujuan/penolakan',
          value: reviewedAt == null
              ? '-'
              : DateFormatter.formatDateTime(reviewedAt),
        ),
        const _SoftDivider(),
        _DetailRow(
          icon: Icons.sticky_note_2_outlined,
          label: 'Catatan admin',
          value: booking.adminNote.trim().isEmpty ? '-' : booking.adminNote,
          valueColor: booking.isRejected ? AppColors.danger : null,
        ),
      ],
    );
  }

  Widget buildReceiptCard() {
    return _PremiumCard(
      color: AppColors.approvedSurface,
      borderColor: AppColors.success.withValues(alpha: 0.24),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                child: Icon(Icons.receipt_long_outlined),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Surat Tanda Terima',
                  style: TextStyle(
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
          _DetailRow(
            icon: Icons.confirmation_number_outlined,
            label: 'No Surat',
            value: booking.receiptNumber,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Tunjukkan surat tanda terima kepada petugas saat menggunakan fasilitas.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: openReceipt,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Lihat PDF'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: shareReceipt,
                  icon: const Icon(Icons.share_outlined),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Bagikan'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader();

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
            bottom: -36,
            child: Icon(
              Icons.fact_check_outlined,
              size: 122,
              color: Colors.white.withValues(alpha: 0.08),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Pantau informasi pengajuan fasilitas.',
                        style: TextStyle(
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
    return _PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DetailIcon(icon: icon),
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

class _PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  const _PremiumCard({
    required this.child,
    required this.padding,
    this.color = AppColors.card,
    this.borderColor = AppColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BookingVisual extends StatelessWidget {
  final String sportType;

  const _BookingVisual({required this.sportType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -12,
            child: Icon(
              Icons.stadium_outlined,
              size: 52,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Center(
            child: Icon(_sportIcon(sportType), color: Colors.white, size: 36),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
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
                style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.28,
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

class _DetailIcon extends StatelessWidget {
  final IconData icon;

  const _DetailIcon({required this.icon});

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

class _SmallBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.lightGreenSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondaryGreen),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.5,
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
