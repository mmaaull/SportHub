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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      loadData();
    });
  }

  Future<void> loadData() async {
    final facilityProvider = context.read<FacilityProvider>();
    final bookingProvider = context.read<BookingProvider>();

    await facilityProvider.loadFacilities();

    if (!mounted) return;

    await bookingProvider.loadAllSchedules();
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

    final selectedSchedules = getSchedulesBySelectedDate(
      bookingProvider.schedules,
    );

    final isLoading = bookingProvider.isLoading || facilityProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryDarkGreen,
        onRefresh: loadData,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            buildHeader(bookingProvider.schedules.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 64),
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
          ],
        ),
      ),
    );
  }

  Widget buildHeader(int totalSchedules) {
    return _AdminScheduleHeader(
      totalSchedules: totalSchedules,
      selectedDate: selectedDay,
    );
  }

  Widget buildFacilityFilter(List<FacilityModel> facilities) {
    final optionIds = {'Semua', ...facilities.map((facility) => facility.id)};
    final initialValue = optionIds.contains(selectedFacilityId)
        ? selectedFacilityId
        : 'Semua';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.tune_rounded,
            title: 'Filter Jadwal',
            subtitle: 'Pilih fasilitas untuk melihat jadwal tertentu.',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: initialValue,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filter Fasilitas',
              prefixIcon: Icon(Icons.sports_soccer_outlined),
            ),
            items: [
              const DropdownMenuItem(
                value: 'Semua',
                child: Text('Semua Fasilitas'),
              ),
              ...facilities.map((facility) {
                return DropdownMenuItem(
                  value: facility.id,
                  child: Text(facility.name, overflow: TextOverflow.ellipsis),
                );
              }),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedFacilityId = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildCalendar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
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
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: AppColors.danger),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primaryDarkGreen,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.accentGreen,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          weekendStyle: TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: AppColors.primaryDarkGreen,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primaryDarkGreen,
          ),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Widget buildSelectedDateTitle(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightGreenSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondaryGreen.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note, color: AppColors.primaryDarkGreen),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '${DateFormatter.formatDayDate(selectedDay)} ($total jadwal)',
              style: const TextStyle(
                color: AppColors.primaryDarkGreen,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
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
}

class _AdminScheduleHeader extends StatelessWidget {
  final int totalSchedules;
  final DateTime selectedDate;

  const _AdminScheduleHeader({
    required this.totalSchedules,
    required this.selectedDate,
  });

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
            bottom: -30,
            child: Icon(
              Icons.calendar_month_outlined,
              color: Colors.white.withValues(alpha: 0.08),
              size: 136,
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
                        'Kalender Jadwal',
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
                  '$totalSchedules Jadwal Aktif',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Booking pending dan approved dalam kalender admin.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_available_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          DateFormatter.formatDayDate(selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.lightGreenSurface,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppColors.secondaryGreen, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
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

class _AdminScheduleCard extends StatelessWidget {
  final BookingModel booking;

  const _AdminScheduleCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightGreenSurface,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.secondaryGreen,
                ),
              ),
              const SizedBox(width: 12),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.campus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 14),
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
          _InfoRow(icon: Icons.flag_outlined, text: booking.purpose),
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
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
