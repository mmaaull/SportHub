// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import 'booking_detail_screen.dart';
import 'booking_form_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
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
    final user = context.read<AuthProvider>().currentUser;

    if (user == null) {
      return;
    }

    await context.read<BookingProvider>().loadUserBookings(user.uid);
  }

  Future<void> openBookingDetail(BookingModel booking) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(booking: booking),
      ),
    );

    if (!mounted) return;

    await loadBookings();
  }

  Future<void> openEditBooking(BookingModel booking) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingFormScreen(booking: booking),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await loadBookings();
    }
  }

  Future<void> cancelBooking(BookingModel booking) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Batalkan Booking?',
      message:
          'Booking yang dibatalkan tidak akan dihapus, tetapi statusnya berubah menjadi cancelled.',
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking berhasil dibatalkan.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();

    final user = authProvider.currentUser;
    final bookings = bookingProvider.filteredUserBookings;

    if (user == null) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'User Tidak Ditemukan',
        message: 'Silakan login ulang untuk melihat data booking.',
      );
    }

    return RefreshIndicator(
      onRefresh: loadBookings,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          buildHeader(user.name),
          const SizedBox(height: 16),
          buildStatusFilter(bookingProvider),
          const SizedBox(height: 16),
          if (bookingProvider.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 70),
              child: LoadingWidget(
                message: 'Memuat booking...',
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
              message:
                  'Booking yang kamu ajukan akan muncul di halaman ini.',
            )
          else
            ...bookings.map((booking) {
              return BookingCard(
                booking: booking,
                showUserActions: true,
                onTap: () => openBookingDetail(booking),
                onEdit: () => openEditBooking(booking),
                onCancel: () => cancelBooking(booking),
              );
            }),
        ],
      ),
    );
  }

  Widget buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            radius: 28,
            child: Icon(
              Icons.event_note,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Booking',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusFilter(BookingProvider bookingProvider) {
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
          final selected = bookingProvider.selectedStatus == status;

          return ChoiceChip(
            label: Text(status),
            selected: selected,
            selectedColor: AppColors.primary.withOpacity(0.18),
            labelStyle: TextStyle(
              color: selected ? AppColors.primary : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (_) {
              bookingProvider.filterByStatus(status);
            },
          );
        },
      ),
    );
  }
}