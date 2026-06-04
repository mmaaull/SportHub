import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'admin_booking_detail_screen.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  final statusOptions = const [
    'Semua',
    'Pending',
    'Approved',
    'Rejected',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      loadBookings();
    });
  }

  Future<void> loadBookings() async {
    final provider = context.read<BookingProvider>();
    await provider.loadAllBookings();
  }

  Future<void> openBookingDetail(BookingModel booking) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminBookingDetailScreen(booking: booking),
      ),
    );

    if (!mounted) return;

    await loadBookings();
  }

  Future<void> approveBooking(BookingModel booking) async {
    final confirm = await _showApproveDialog(booking);

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking berhasil disetujui.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> rejectBooking(BookingModel booking) async {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking berhasil ditolak.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<bool?> _showApproveDialog(BookingModel booking) {
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
            'Setujui booking untuk fasilitas "${booking.facilityName}"?',
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
              hintText: 'Contoh: Jadwal bentrok dengan kegiatan kampus',
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
    final bookingProvider = context.watch<BookingProvider>();
    final bookings = bookingProvider.filteredAllBookings;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryDarkGreen,
        onRefresh: loadBookings,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ManageBookingsHeader(
              totalBooking: bookingProvider.totalBooking,
              pendingBooking: bookingProvider.pendingBooking,
              approvedBooking: bookingProvider.approvedBooking,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildStatusFilter(bookingProvider),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Daftar Booking',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      _MiniCountPill(
                        icon: Icons.fact_check_outlined,
                        text: '${bookings.length} data',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (bookingProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 56),
                      child: LoadingWidget(message: 'Memuat semua booking...'),
                    )
                  else if (bookingProvider.errorMessage != null)
                    EmptyState(
                      icon: Icons.error_outline,
                      title: 'Terjadi Kesalahan',
                      message: bookingProvider.errorMessage!,
                      buttonText: 'Coba Lagi',
                      onPressed: loadBookings,
                    )
                  else if (bookings.isEmpty)
                    const EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'Belum Ada Booking',
                      message: 'Data booking user akan muncul di halaman ini.',
                    )
                  else
                    ...bookings.map((booking) {
                      return Column(
                        children: [
                          BookingCard(
                            booking: booking,
                            showUserActions: false,
                            onTap: () => openBookingDetail(booking),
                          ),
                          if (booking.isPending)
                            _AdminBookingActions(
                              isLoading: bookingProvider.isLoading,
                              onReject: () => rejectBooking(booking),
                              onApprove: () => approveBooking(booking),
                            ),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusFilter(BookingProvider provider) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statusOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statusOptions[index];
          final selected = provider.selectedStatus == status;

          return ChoiceChip(
            label: Text(status),
            selected: selected,
            showCheckmark: false,
            backgroundColor: AppColors.card,
            selectedColor: AppColors.lightGreenSurface,
            side: BorderSide(
              color: selected ? AppColors.secondaryGreen : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            labelStyle: TextStyle(
              color: selected
                  ? AppColors.primaryDarkGreen
                  : AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0,
            ),
            onSelected: (_) {
              provider.filterByStatus(status);
            },
          );
        },
      ),
    );
  }

  Widget buildHeader(BookingProvider provider) {
    return _ManageBookingsHeader(
      totalBooking: provider.totalBooking,
      pendingBooking: provider.pendingBooking,
      approvedBooking: provider.approvedBooking,
    );
  }
}

class _ManageBookingsHeader extends StatelessWidget {
  final int totalBooking;
  final int pendingBooking;
  final int approvedBooking;

  const _ManageBookingsHeader({
    required this.totalBooking,
    required this.pendingBooking,
    required this.approvedBooking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
            right: -30,
            bottom: -28,
            child: Icon(
              Icons.fact_check_outlined,
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
                        'Kelola Booking',
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
                  '$totalBooking Total Booking',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$pendingBooking pending perlu diproses',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderMetric(
                        label: 'Pending',
                        value: pendingBooking.toString(),
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeaderMetric(
                        label: 'Approved',
                        value: approvedBooking.toString(),
                        icon: Icons.check_circle_outline,
                      ),
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
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
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

class _AdminBookingActions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const _AdminBookingActions({
    required this.isLoading,
    required this.onReject,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onReject,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onApprove,
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
    );
  }
}

class _MiniCountPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniCountPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondaryGreen, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
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
