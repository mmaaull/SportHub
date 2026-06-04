import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/receipt_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/status_badge.dart';

class AdminBookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const AdminBookingDetailScreen({super.key, required this.booking});

  @override
  State<AdminBookingDetailScreen> createState() =>
      _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen> {
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

  Future<void> approveBooking() async {
    final confirm = await _showApproveDialog();

    if (confirm != true) return;
    if (!mounted) return;

    final admin = context.read<AuthProvider>().currentUser;
    if (admin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data admin tidak ditemukan. Silakan login ulang.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final provider = context.read<BookingProvider>();
    final success = await provider.approveBooking(
      bookingId: booking.id,
      adminId: admin.uid,
      adminName: admin.name,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal approve booking.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    await refreshBooking();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking berhasil disetujui.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> rejectBooking() async {
    final noteController = TextEditingController();

    final adminNote = await _showRejectDialog(noteController);

    noteController.dispose();

    if (adminNote == null) return;

    if (adminNote.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan penolakan wajib diisi.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!mounted) return;

    final admin = context.read<AuthProvider>().currentUser;
    if (admin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data admin tidak ditemukan. Silakan login ulang.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final provider = context.read<BookingProvider>();
    final success = await provider.rejectBooking(
      bookingId: booking.id,
      adminNote: adminNote,
      adminId: admin.uid,
      adminName: admin.name,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal reject booking.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    await refreshBooking();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking berhasil ditolak.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<bool?> _showApproveDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Approve Booking?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          content: Text(
            'Setujui booking "${booking.facilityName}" dari ${booking.userName}?',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showRejectDialog(TextEditingController noteController) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Reject Booking',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          content: TextField(
            controller: noteController,
            maxLines: 4,
            cursorColor: AppColors.secondaryGreen,
            decoration: InputDecoration(
              labelText: 'Alasan Penolakan',
              hintText: 'Contoh: Jadwal bentrok dengan agenda kampus',
              prefixIcon: const Icon(Icons.notes_outlined),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: AppColors.secondaryGreen,
                  width: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, noteController.text.trim());
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryDarkGreen,
        onRefresh: refreshBooking,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _AdminDetailHeader(booking: booking),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSummaryCard(),
                  if (booking.hasReceipt) ...[
                    const SizedBox(height: 16),
                    buildReceiptCard(),
                  ],
                  const SizedBox(height: 16),
                  buildUserCard(),
                  const SizedBox(height: 16),
                  buildFacilityCard(),
                  const SizedBox(height: 16),
                  buildScheduleCard(),
                  const SizedBox(height: 16),
                  buildPurposeCard(),
                  const SizedBox(height: 16),
                  buildAdminStatusCard(),
                  if (booking.isPending) ...[
                    const SizedBox(height: 22),
                    _AdminDecisionPanel(
                      isLoading: provider.isLoading,
                      onReject: rejectBooking,
                      onApprove: approveBooking,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: 32,
            ),
          ),
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
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${booking.sportType} - ${booking.campus}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                StatusBadge(status: booking.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusCard() {
    return buildAdminStatusCard();
  }

  Widget buildReceiptCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(
        color: AppColors.approvedSurface,
        borderColor: AppColors.success.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.receipt_long_outlined,
            title: 'Surat Tanda Terima',
            color: AppColors.success,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Nomor Surat',
            value: booking.receiptNumber,
          ),
          const _SoftDivider(),
          _DetailRow(
            icon: Icons.person_pin_outlined,
            label: 'Disetujui Oleh',
            value: booking.approvedByName.isEmpty
                ? 'Admin UNESA SportHub'
                : booking.approvedByName,
          ),
          const _SoftDivider(),
          _DetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'Tanggal Disetujui',
            value: booking.approvedAt == null
                ? '-'
                : DateFormatter.formatDateTime(booking.approvedAt!),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: openReceipt,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Lihat Surat PDF'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Surat ini dapat ditunjukkan kepada petugas saat fasilitas digunakan.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserCard() {
    return _InfoCard(
      title: 'Informasi Pemesan',
      icon: Icons.person_outline,
      rows: [
        _DetailRow(
          icon: Icons.person_outline,
          label: 'Nama Mahasiswa',
          value: booking.userName,
        ),
        _DetailRow(
          icon: Icons.badge_outlined,
          label: 'NIM',
          value: booking.userNim,
        ),
      ],
    );
  }

  Widget buildFacilityCard() {
    return _InfoCard(
      title: 'Informasi Fasilitas',
      icon: Icons.stadium_outlined,
      rows: [
        _DetailRow(
          icon: Icons.sports_soccer,
          label: 'Fasilitas',
          value: booking.facilityName,
        ),
        _DetailRow(
          icon: Icons.sports,
          label: 'Jenis Olahraga',
          value: booking.sportType,
        ),
        _DetailRow(
          icon: Icons.apartment_outlined,
          label: 'Kampus',
          value: booking.campus,
        ),
      ],
    );
  }

  Widget buildScheduleCard() {
    return _InfoCard(
      title: 'Detail Booking',
      icon: Icons.event_note_outlined,
      rows: [
        _DetailRow(
          icon: Icons.confirmation_number_outlined,
          label: 'No. Booking',
          value: booking.id.isEmpty ? '-' : booking.id,
        ),
        _DetailRow(
          icon: Icons.calendar_month_outlined,
          label: 'Tanggal',
          value: DateFormatter.formatDayDate(booking.date),
        ),
        _DetailRow(
          icon: Icons.access_time,
          label: 'Jam',
          value: '${booking.startTime} - ${booking.endTime}',
        ),
        _DetailRow(
          icon: Icons.groups_outlined,
          label: 'Jumlah Peserta',
          value: '${booking.participantCount} peserta',
        ),
      ],
    );
  }

  Widget buildPurposeCard() {
    return _InfoCard(
      title: 'Tujuan Kegiatan',
      icon: Icons.flag_outlined,
      rows: [
        _DetailRow(
          icon: Icons.flag_outlined,
          label: 'Tujuan',
          value: booking.purpose,
        ),
        _DetailRow(
          icon: Icons.notes_outlined,
          label: 'Catatan User',
          value: booking.note.trim().isEmpty ? '-' : booking.note,
        ),
        _DetailRow(
          icon: Icons.history,
          label: 'Dibuat Pada',
          value: DateFormatter.formatDateTime(booking.createdAt),
        ),
      ],
    );
  }

  Widget buildAdminStatusCard() {
    return _InfoCard(
      title: 'Status & Catatan Admin',
      icon: Icons.admin_panel_settings_outlined,
      rows: [
        _StatusRow(status: booking.status),
        _DetailRow(
          icon: Icons.verified_user_outlined,
          label: booking.isRejected ? 'Ditolak Oleh' : 'Disetujui Oleh',
          value: _decisionAdminName(),
        ),
        _DetailRow(
          icon: Icons.schedule_outlined,
          label: booking.isRejected ? 'Waktu Penolakan' : 'Waktu Persetujuan',
          value: _decisionTime(),
        ),
        _DetailRow(
          icon: Icons.notes_outlined,
          label: 'Catatan Admin',
          value: booking.adminNote.trim().isEmpty ? '-' : booking.adminNote,
        ),
      ],
    );
  }

  Widget buildAdminNoteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(
        color: AppColors.rejectedSurface,
        borderColor: AppColors.danger.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.report_problem_outlined,
            title: 'Alasan Penolakan',
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          Text(
            booking.adminNote.trim().isEmpty ? '-' : booking.adminNote,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  String _decisionAdminName() {
    if (booking.isApproved) {
      return booking.approvedByName.trim().isEmpty
          ? '-'
          : booking.approvedByName;
    }

    if (booking.isRejected) {
      return booking.rejectedByName.trim().isEmpty
          ? '-'
          : booking.rejectedByName;
    }

    return '-';
  }

  String _decisionTime() {
    if (booking.isApproved && booking.approvedAt != null) {
      return DateFormatter.formatDateTime(booking.approvedAt!);
    }

    if (booking.isRejected && booking.rejectedAt != null) {
      return DateFormatter.formatDateTime(booking.rejectedAt!);
    }

    return '-';
  }

  BoxDecoration _cardDecoration({
    Color color = AppColors.card,
    Color borderColor = AppColors.border,
  }) {
    return BoxDecoration(
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
    );
  }
}

class _AdminDetailHeader extends StatelessWidget {
  final BookingModel booking;

  const _AdminDetailHeader({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
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
            bottom: -28,
            child: Icon(
              Icons.receipt_long_outlined,
              color: Colors.white.withValues(alpha: 0.08),
              size: 132,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Detail Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  booking.facilityName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormatter.formatDayDate(booking.date),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${booking.startTime} - ${booking.endTime}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: booking.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> rows;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title),
          const SizedBox(height: 14),
          for (var index = 0; index < rows.length; index++) ...[
            rows[index],
            if (index != rows.length - 1) const _SoftDivider(),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.color = AppColors.primaryDarkGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.lightGreenSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.secondaryGreen, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
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
                  fontWeight: FontWeight.w800,
                  height: 1.35,
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

class _StatusRow extends StatelessWidget {
  final String status;

  const _StatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.statusSurface(status),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.fact_check_outlined,
            color: AppColors.statusColor(status),
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              StatusBadge(status: status),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminDecisionPanel extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const _AdminDecisionPanel({
    required this.isLoading,
    required this.onReject,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onReject,
              icon: const Icon(Icons.cancel_outlined),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Reject'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onApprove,
              icon: const Icon(Icons.check_circle_outline),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Approve'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 13),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}
