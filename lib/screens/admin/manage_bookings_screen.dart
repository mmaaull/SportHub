// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'admin_booking_detail_screen.dart';
import '../../providers/auth_provider.dart';

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

    Future.microtask(() {
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve Booking?'),
          content: Text(
            'Setujui booking untuk fasilitas "${booking.facilityName}"?',
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking berhasil disetujui.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> rejectBooking(BookingModel booking) async {
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
              hintText: 'Contoh: Jadwal bentrok dengan kegiatan kampus',
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking berhasil ditolak.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final bookings = bookingProvider.filteredAllBookings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Booking'),
      ),
      body: RefreshIndicator(
        onRefresh: loadBookings,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            buildHeader(bookingProvider),
            const SizedBox(height: 16),
            buildStatusFilter(bookingProvider),
            const SizedBox(height: 16),
            if (bookingProvider.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 70),
                child: LoadingWidget(
                  message: 'Memuat semua booking...',
                ),
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
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          right: 4,
                          bottom: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: bookingProvider.isLoading
                                    ? null
                                    : () => rejectBooking(booking),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: bookingProvider.isLoading
                                    ? null
                                    : () => approveBooking(booking),
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
                      ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(BookingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            child: Icon(
              Icons.fact_check_outlined,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manajemen Booking',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.totalBooking} Total Booking',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.pendingBooking} pending perlu diproses',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusFilter(BookingProvider provider) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statusOptions.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final status = statusOptions[index];
          final selected = provider.selectedStatus == status;

          return ChoiceChip(
            label: Text(status),
            selected: selected,
            selectedColor: AppColors.primary.withOpacity(0.18),
            labelStyle: TextStyle(
              color: selected ? AppColors.primary : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (_) {
              provider.filterByStatus(status);
            },
          );
        },
      ),
    );
  }
}