// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/status_badge.dart';
import 'booking_form_screen.dart';
import '../../services/receipt_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;
  

  const BookingDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late BookingModel booking;

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
  @override
  void initState() {
    super.initState();
    booking = widget.booking;
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

  Future<void> editBooking() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingFormScreen(booking: booking),
      ),
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
      final error = context.read<BookingProvider>().errorMessage ??
          'Gagal membatalkan booking.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
        ),
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
      appBar: AppBar(
        title: const Text('Detail Booking'),
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
            buildFacilityCard(),
            const SizedBox(height: 16),
            buildScheduleCard(),
            const SizedBox(height: 16),
            buildPurposeCard(),
            if (booking.status == 'rejected' &&
                booking.adminNote.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              buildRejectedCard(),
            ],
            const SizedBox(height: 24),
            if (booking.isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: bookingProvider.isLoading ? null : editBooking,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          bookingProvider.isLoading ? null : cancelBooking,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Batalkan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: openReceipt,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Lihat PDF'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: shareReceipt,
                      icon: const Icon(Icons.share),
                      label: const Text('Bagikan'),
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

  Widget buildRejectedCard() {
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