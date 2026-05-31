// ignore_for_file: annotate_overrides, override_on_non_overriding_member, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/status_badge.dart';
import '../../providers/auth_provider.dart';
import '../../services/receipt_service.dart';

class AdminBookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const AdminBookingDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  State<AdminBookingDetailScreen> createState() =>
      _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen> {
  late BookingModel booking;

  @override
  void initState() {
    super.initState();
    booking = widget.booking;
  }

  final ReceiptService receiptService = ReceiptService();
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
    final latestBooking = await context
        .read<BookingProvider>()
        .getBookingById(booking.id);

    if (!mounted) return;

    if (latestBooking != null) {
      setState(() {
        booking = latestBooking;
      });
    }
  }

  Future<void> approveBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve Booking?'),
          content: Text(
            'Setujui booking "${booking.facilityName}" dari ${booking.userName}?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

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

    final adminNote = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Booking'),
          content: TextField(
            controller: noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Alasan Penolakan',
              hintText: 'Contoh: Jadwal bentrok dengan agenda kampus',
              border: OutlineInputBorder(),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, noteController.text.trim());
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

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

  @override
  Widget buildReceiptCard() {
    return Card(
      elevation: 2,
      color: AppColors.success.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.receipt_long),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Surat Tanda Terima',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DetailRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Nomor Surat',
              value: booking.receiptNumber,
            ),
            const Divider(),
            _DetailRow(
              icon: Icons.person_pin_outlined,
              label: 'Disetujui Oleh',
              value: booking.approvedByName.isEmpty
                  ? 'Admin UNESA SportHub'
                  : booking.approvedByName,
            ),
            const Divider(),
            _DetailRow(
              icon: Icons.calendar_month_outlined,
              label: 'Tanggal Disetujui',
              value: booking.approvedAt == null
                  ? '-'
                  : DateFormatter.formatDateTime(booking.approvedAt!),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openReceipt,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Lihat Surat PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Booking Admin'),
      ),
      body: RefreshIndicator(
        onRefresh: refreshBooking,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            buildStatusCard(),
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
            if (booking.status == 'rejected' &&
                booking.adminNote.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              buildAdminNoteCard(),
            ],
            const SizedBox(height: 24),
            if (booking.isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: provider.isLoading ? null : rejectBooking,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : approveBooking,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve'),
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
      ),
    );
  }

  Widget buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Icon(
                Icons.fact_check_outlined,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Booking',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(status: booking.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUserCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Nama User',
              value: booking.userName,
            ),
            const Divider(),
            _DetailRow(
              icon: Icons.badge_outlined,
              label: 'NIM',
              value: booking.userNim,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFacilityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _DetailRow(
              icon: Icons.sports_soccer,
              label: 'Fasilitas',
              value: booking.facilityName,
            ),
            const Divider(),
            _DetailRow(
              icon: Icons.sports,
              label: 'Jenis Olahraga',
              value: booking.sportType,
            ),
            const Divider(),
            _DetailRow(
              icon: Icons.apartment_outlined,
              label: 'Kampus',
              value: booking.campus,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildScheduleCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _DetailRow(
              icon: Icons.calendar_month_outlined,
              label: 'Tanggal',
              value: DateFormatter.formatDayDate(booking.date),
            ),
            const Divider(),
            _DetailRow(
              icon: Icons.access_time,
              label: 'Jam',
              value: '${booking.startTime} - ${booking.endTime}',
            ),
            const Divider(),
            _DetailRow(
              icon: Icons.groups_outlined,
              label: 'Jumlah Peserta',
              value: '${booking.participantCount} peserta',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPurposeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _DetailRow(
              icon: Icons.flag_outlined,
              label: 'Tujuan',
              value: booking.purpose,
            ),
            const Divider(),
            _DetailRow(
              icon: Icons.notes_outlined,
              label: 'Catatan User',
              value: booking.note.trim().isEmpty ? '-' : booking.note,
            ),
            const Divider(),
            _DetailRow(
              icon: Icons.history,
              label: 'Dibuat Pada',
              value: DateFormatter.formatDateTime(booking.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAdminNoteCard() {
    return Card(
      elevation: 2,
      color: AppColors.danger.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.report_problem_outlined,
              color: AppColors.danger,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alasan Penolakan',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking.adminNote,
                    style: const TextStyle(
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
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