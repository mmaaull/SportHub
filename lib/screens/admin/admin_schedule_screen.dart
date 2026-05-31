// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/booking_model.dart';
import '../../models/facility_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/facility_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  String selectedFacilityId = 'Semua';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadData();
    });
  }

  Future<void> loadData() async {
    await context.read<FacilityProvider>().loadFacilities();

    if (!mounted) return;

    await context.read<BookingProvider>().loadAllSchedules();
  }

  List<BookingModel> getFilteredSchedules(List<BookingModel> schedules) {
    if (selectedFacilityId == 'Semua') {
      return schedules;
    }

    return schedules.where((booking) {
      return booking.facilityId == selectedFacilityId;
    }).toList();
  }

  List<BookingModel> getEventsForDay(DateTime day) {
    final schedules = context.read<BookingProvider>().schedules;
    final filtered = getFilteredSchedules(schedules);

    return filtered.where((booking) {
      return booking.date.year == day.year &&
          booking.date.month == day.month &&
          booking.date.day == day.day;
    }).toList();
  }

  List<BookingModel> getSchedulesBySelectedDate(List<BookingModel> schedules) {
    final filtered = getFilteredSchedules(schedules);

    return filtered.where((booking) {
      return booking.date.year == selectedDay.year &&
          booking.date.month == selectedDay.month &&
          booking.date.day == selectedDay.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final facilityProvider = context.watch<FacilityProvider>();

    final selectedSchedules =
        getSchedulesBySelectedDate(bookingProvider.schedules);

    final isLoading = bookingProvider.isLoading || facilityProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kalender Jadwal Admin'),
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            buildHeader(bookingProvider.schedules.length),
            const SizedBox(height: 18),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: LoadingWidget(
                  message: 'Memuat kalender jadwal...',
                ),
              )
            else if (bookingProvider.errorMessage != null)
              EmptyState(
                icon: Icons.error_outline,
                title: 'Terjadi Kesalahan',
                message: bookingProvider.errorMessage!,
                buttonText: 'Coba Lagi',
                onPressed: loadData,
              )
            else ...[
              buildFacilityFilter(facilityProvider.facilities),
              const SizedBox(height: 18),
              buildCalendar(),
              const SizedBox(height: 18),
              buildSelectedDateTitle(selectedSchedules.length),
              const SizedBox(height: 12),
              if (selectedSchedules.isEmpty)
                const EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'Tidak Ada Jadwal',
                  message:
                      'Tidak ada booking pending atau approved pada tanggal ini.',
                )
              else
                ...selectedSchedules.map((booking) {
                  return _AdminScheduleCard(booking: booking);
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildHeader(int totalSchedules) {
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
              Icons.calendar_month,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kalender Jadwal Booking',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalSchedules Jadwal Aktif',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Menampilkan booking pending dan approved.',
                  style: TextStyle(
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

  Widget buildFacilityFilter(List<FacilityModel> facilities) {
    return DropdownButtonFormField<String>(
      value: selectedFacilityId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Filter Fasilitas',
        prefixIcon: const Icon(Icons.sports_soccer),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        const DropdownMenuItem(
          value: 'Semua',
          child: Text('Semua Fasilitas'),
        ),
        ...facilities.map((facility) {
          return DropdownMenuItem(
            value: facility.id,
            child: Text(
              facility.name,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedFacilityId = value;
        });
      },
    );
  }

  Widget buildCalendar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TableCalendar<BookingModel>(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) {
            return isSameDay(selectedDay, day);
          },
          eventLoader: getEventsForDay,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          onDaySelected: (selected, focused) {
            setState(() {
              selectedDay = selected;
              focusedDay = focused;
            });
          },
          calendarStyle: const CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
      ),
    );
  }

  Widget buildSelectedDateTitle(int total) {
    return Row(
      children: [
        const Icon(
          Icons.event_note,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${DateFormatter.formatDayDate(selectedDay)} ($total jadwal)',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminScheduleCard extends StatelessWidget {
  final BookingModel booking;

  const _AdminScheduleCard({
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.event),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    booking.facilityName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.access_time,
              text: '${booking.startTime} - ${booking.endTime}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.person_outline,
              text: '${booking.userName} - ${booking.userNim}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.flag_outlined,
              text: booking.purpose,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}