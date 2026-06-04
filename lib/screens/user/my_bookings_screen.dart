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
  final searchController = TextEditingController();

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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
      MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking)),
    );

    if (!mounted) return;

    await loadBookings();
  }

  Future<void> openEditBooking(BookingModel booking) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingFormScreen(booking: booking)),
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
      final error =
          context.read<BookingProvider>().errorMessage ??
          'Gagal membatalkan booking.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
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
    final bookings = filterBookings(bookingProvider.filteredUserBookings);

    if (user == null) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'User Tidak Ditemukan',
        message: 'Silakan login ulang untuk melihat data booking.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryDarkGreen,
      onRefresh: loadBookings,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          buildHeader(user.name),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildStatusFilter(bookingProvider),
                const SizedBox(height: 18),
                if (bookingProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 70),
                    child: LoadingWidget(message: 'Memuat booking...'),
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
                  EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: searchController.text.trim().isEmpty
                        ? 'Belum Ada Booking'
                        : 'Booking tidak ditemukan',
                    message: searchController.text.trim().isEmpty
                        ? 'Booking yang kamu ajukan akan muncul di halaman ini.'
                        : 'Coba gunakan kata kunci lain atau ubah filter status.',
                    buttonText: searchController.text.trim().isEmpty
                        ? null
                        : 'Reset Pencarian',
                    onPressed: searchController.text.trim().isEmpty
                        ? null
                        : () {
                            searchController.clear();
                            setState(() {});
                          },
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
          ),
        ],
      ),
    );
  }

  List<BookingModel> filterBookings(List<BookingModel> bookings) {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return bookings;
    }

    return bookings.where((booking) {
      return booking.facilityName.toLowerCase().contains(query) ||
          booking.sportType.toLowerCase().contains(query) ||
          booking.campus.toLowerCase().contains(query) ||
          booking.purpose.toLowerCase().contains(query) ||
          booking.status.toLowerCase().contains(query);
    }).toList();
  }

  Widget buildHeader(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
            right: -26,
            bottom: -18,
            child: Icon(
              Icons.event_note_outlined,
              color: Colors.white.withValues(alpha: 0.08),
              size: 118,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Booking Saya',
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
                const SizedBox(height: 12),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 22),
                _BookingSearchBar(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  onClear: () {
                    searchController.clear();
                    setState(() {});
                  },
                  onFilter: showStatusFilterSheet,
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
            label: Text(status == 'Semua' ? 'All' : status),
            selected: selected,
            showCheckmark: false,
            selectedColor: AppColors.primaryDarkGreen,
            backgroundColor: AppColors.card,
            side: BorderSide(
              color: selected ? AppColors.primaryDarkGreen : AppColors.border,
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
            onSelected: (_) {
              bookingProvider.filterByStatus(status);
            },
          );
        },
      ),
    );
  }

  void showStatusFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<BookingProvider>(
          builder: (context, bookingProvider, child) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Filter Status',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...statusOptions.map((status) {
                      final selected = bookingProvider.selectedStatus == status;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            bookingProvider.filterByStatus(status);
                            Navigator.maybePop(context);
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: selected
                                ? AppColors.lightGreenSurface
                                : AppColors.background,
                            foregroundColor: selected
                                ? AppColors.primaryDarkGreen
                                : AppColors.textSecondary,
                            child: Icon(statusIcon(status)),
                          ),
                          title: Text(
                            status == 'Semua' ? 'All' : status,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.primaryDarkGreen
                                  : AppColors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                )
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.block_rounded;
      default:
        return Icons.view_list_rounded;
    }
  }
}

class _BookingSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  const _BookingSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.secondaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AppColors.secondaryGreen,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
              decoration: const InputDecoration(
                hintText: 'Cari booking...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textSecondary,
              tooltip: 'Hapus pencarian',
            ),
          IconButton(
            onPressed: onFilter,
            icon: const Icon(Icons.tune_rounded),
            color: AppColors.primaryDarkGreen,
            tooltip: 'Filter',
          ),
        ],
      ),
    );
  }
}
