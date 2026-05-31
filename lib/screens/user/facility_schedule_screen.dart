import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/booking_model.dart';
import '../../models/facility_model.dart';
import '../../providers/booking_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/status_badge.dart';

class FacilityScheduleScreen extends StatefulWidget {
  final FacilityModel facility;

  const FacilityScheduleScreen({
    super.key,
    required this.facility,
  });

  @override
  State<FacilityScheduleScreen> createState() => _FacilityScheduleScreenState();
}

class _FacilityScheduleScreenState extends State<FacilityScheduleScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadSchedules();
    });
  }

  Future<void> loadSchedules() async {
    await context.read<BookingProvider>().loadFacilitySchedules(
          widget.facility.id,
        );
  }

  List<BookingModel> getEventsForDay(DateTime day) {
    return context.read<BookingProvider>().schedules.where((booking) {
      return booking.date.year == day.year &&
          booking.date.month == day.month &&
          booking.date.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final selectedSchedules = bookingProvider.getSchedulesByDate(selectedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jadwal Fasilitas'),
      ),
      body: RefreshIndicator(
        onRefresh: loadSchedules,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            buildHeader(),
            const SizedBox(height: 18),
            if (bookingProvider.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: LoadingWidget(
                  message: 'Memuat jadwal fasilitas...',
                ),
              )
            else if (bookingProvider.errorMessage != null)
              EmptyState(
                icon: Icons.error_outline,
                title: 'Terjadi Kesalahan',
                message: bookingProvider.errorMessage!,
                buttonText: 'Coba Lagi',
                onPressed: loadSchedules,
              )
            else ...[
              buildCalendar(),
              const SizedBox(height: 18),
              buildSelectedDateTitle(selectedSchedules.length),
              const SizedBox(height: 12),
              if (selectedSchedules.isEmpty)
                const EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'Tidak Ada Jadwal',
                  message:
                      'Belum ada booking pending atau approved pada tanggal ini.',
                )
              else
                ...selectedSchedules.map((booking) {
                  return _ScheduleCard(booking: booking);
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildHeader() {
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
                  'Kalender Jadwal',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.facility.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.facility.campus,
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

class _ScheduleCard extends StatelessWidget {
  final BookingModel booking;

  const _ScheduleCard({
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
                  child: Icon(Icons.access_time),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${booking.startTime} - ${booking.endTime}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.person_outline,
              text: '${booking.userName} - ${booking.userNim}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.flag_outlined,
              text: booking.purpose,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.groups_outlined,
              text: '${booking.participantCount} peserta',
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