// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/booking_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadData();
    });
  }

  Future<void> loadData() async {
    await context.read<BookingProvider>().loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Statistik Booking'),
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            buildHeader(bookingProvider),
            const SizedBox(height: 18),
            if (bookingProvider.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: LoadingWidget(
                  message: 'Memuat statistik...',
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
            else if (bookingProvider.totalBooking == 0)
              const EmptyState(
                icon: Icons.bar_chart_outlined,
                title: 'Belum Ada Data Booking',
                message:
                    'Statistik akan muncul setelah user mengajukan booking.',
              )
            else ...[
              buildStatGrid(bookingProvider),
              const SizedBox(height: 18),
              buildPieChartCard(bookingProvider),
              const SizedBox(height: 18),
              buildBarChartCard(bookingProvider),
              const SizedBox(height: 18),
              buildLegendCard(),
            ],
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
              Icons.analytics_outlined,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistik Booking',
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
                const Text(
                  'Data berdasarkan status booking',
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

  Widget buildStatGrid(BookingProvider provider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.18,
      children: [
        _StatCard(
          title: 'Pending',
          value: provider.pendingBooking.toString(),
          icon: Icons.schedule,
          color: AppColors.pending,
        ),
        _StatCard(
          title: 'Approved',
          value: provider.approvedBooking.toString(),
          icon: Icons.check_circle,
          color: AppColors.success,
        ),
        _StatCard(
          title: 'Rejected',
          value: provider.rejectedBooking.toString(),
          icon: Icons.cancel,
          color: AppColors.danger,
        ),
        _StatCard(
          title: 'Cancelled',
          value: provider.cancelledBooking.toString(),
          icon: Icons.block,
          color: AppColors.cancelled,
        ),
      ],
    );
  }

  Widget buildPieChartCard(BookingProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Persentase Status Booking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 260,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }

                        touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: buildPieSections(provider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> buildPieSections(BookingProvider provider) {
    final data = [
      _ChartData(
        title: 'Pending',
        value: provider.pendingBooking,
        color: AppColors.pending,
      ),
      _ChartData(
        title: 'Approved',
        value: provider.approvedBooking,
        color: AppColors.success,
      ),
      _ChartData(
        title: 'Rejected',
        value: provider.rejectedBooking,
        color: AppColors.danger,
      ),
      _ChartData(
        title: 'Cancelled',
        value: provider.cancelledBooking,
        color: AppColors.cancelled,
      ),
    ];

    final filteredData = data.where((item) => item.value > 0).toList();

    return List.generate(filteredData.length, (index) {
      final item = filteredData[index];
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 78.0 : 66.0;
      final fontSize = isTouched ? 15.0 : 13.0;

      final percentage = provider.totalBooking == 0
          ? 0
          : (item.value / provider.totalBooking * 100);

      return PieChartSectionData(
        color: item.color,
        value: item.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget buildBarChartCard(BookingProvider provider) {
    final maxValue = [
      provider.pendingBooking,
      provider.approvedBooking,
      provider.rejectedBooking,
      provider.cancelledBooking,
    ].reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jumlah Booking per Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  maxY: maxValue == 0 ? 5 : maxValue.toDouble() + 2,
                  barTouchData: BarTouchData(
                    enabled: true,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) {
                            return const SizedBox.shrink();
                          }

                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const _BottomTitle(text: 'Pending');
                            case 1:
                              return const _BottomTitle(text: 'Approved');
                            case 2:
                              return const _BottomTitle(text: 'Rejected');
                            case 3:
                              return const _BottomTitle(text: 'Cancelled');
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.25),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    buildBarGroup(
                      x: 0,
                      value: provider.pendingBooking,
                      color: AppColors.pending,
                    ),
                    buildBarGroup(
                      x: 1,
                      value: provider.approvedBooking,
                      color: AppColors.success,
                    ),
                    buildBarGroup(
                      x: 2,
                      value: provider.rejectedBooking,
                      color: AppColors.danger,
                    ),
                    buildBarGroup(
                      x: 3,
                      value: provider.cancelledBooking,
                      color: AppColors.cancelled,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData buildBarGroup({
    required int x,
    required int value,
    required Color color,
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          width: 22,
          borderRadius: BorderRadius.circular(8),
          color: color,
        ),
      ],
    );
  }

  Widget buildLegendCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Keterangan Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 14),
            _LegendItem(
              color: AppColors.pending,
              title: 'Pending',
              description: 'Booking baru yang menunggu persetujuan admin.',
            ),
            _LegendItem(
              color: AppColors.success,
              title: 'Approved',
              description: 'Booking yang sudah disetujui admin.',
            ),
            _LegendItem(
              color: AppColors.danger,
              title: 'Rejected',
              description: 'Booking yang ditolak admin dengan alasan.',
            ),
            _LegendItem(
              color: AppColors.cancelled,
              title: 'Cancelled',
              description: 'Booking yang dibatalkan oleh user.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  final String title;
  final int value;
  final Color color;

  _ChartData({
    required this.title,
    required this.value,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTitle extends StatelessWidget {
  final String text;

  const _BottomTitle({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String title;
  final String description;

  const _LegendItem({
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}