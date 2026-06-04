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

  const FacilityScheduleScreen({super.key, required this.facility});

  @override
  State<FacilityScheduleScreen> createState() => _FacilityScheduleScreenState();
}

class _FacilityScheduleScreenState extends State<FacilityScheduleScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
      body: RefreshIndicator(
        color: AppColors.primaryDarkGreen,
        onRefresh: loadSchedules,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _ScheduleHeader(),
            Transform.translate(
              offset: const Offset(0, -34),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildFacilitySummaryCard(),
                    const SizedBox(height: 16),
                    if (bookingProvider.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 70),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFacilitySummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.stadium_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.facility.name,
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
                  '${widget.facility.sportType} - ${widget.facility.campus}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                StatusBadge(status: widget.facility.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCalendar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
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
          outsideDaysVisible: false,
          selectedDecoration: BoxDecoration(
            color: AppColors.primaryDarkGreen,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.warning,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          weekendTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          markerDecoration: BoxDecoration(
            color: AppColors.accentGreen,
            shape: BoxShape.circle,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          weekendStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: AppColors.primaryDarkGreen,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primaryDarkGreen,
          ),
        ),
        calendarBuilders: CalendarBuilders<BookingModel>(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;

            final hasPending = events.any((booking) => booking.isPending);
            final markerColor = hasPending
                ? AppColors.warning
                : AppColors.accentGreen;

            return Positioned(
              bottom: 7,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (events.length > 1) ...[
                    const SizedBox(width: 3),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: markerColor.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildSelectedDateTitle(int total) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.lightGreenSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.event_note_outlined,
            color: AppColors.secondaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Jadwal pada ${DateFormatter.formatDayDate(selectedDay)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              height: 1.25,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.lightGreenSurface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$total',
            style: const TextStyle(
              color: AppColors.primaryDarkGreen,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 76),
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
            bottom: -34,
            child: Icon(
              Icons.calendar_month_outlined,
              color: Colors.white.withValues(alpha: 0.08),
              size: 132,
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
                        'Jadwal Fasilitas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Lihat kalender penggunaan fasilitas.',
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

class _ScheduleCard extends StatelessWidget {
  final BookingModel booking;

  const _ScheduleCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.lightGreenSurface,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: AppColors.secondaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.startTime} - ${booking.endTime}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      booking.facilityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.person_outline,
            text: '${booking.userName} - ${booking.userNim}',
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.flag_outlined, text: booking.purpose),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.groups_outlined,
            text: '${booking.participantCount} peserta',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondaryGreen, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryDarkGreen.withValues(alpha: 0.06),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
