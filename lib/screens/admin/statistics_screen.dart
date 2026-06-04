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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
      body: RefreshIndicator(
        color: AppColors.primaryDarkGreen,
        onRefresh: loadData,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            buildHeader(bookingProvider),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bookingProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 64),
                      child: LoadingWidget(message: 'Memuat statistik...'),
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
          ],
        ),
      ),
    );
  }

  Widget buildHeader(BookingProvider provider) {
    return _StatisticsHeader(
      totalBooking: provider.totalBooking,
      pendingBooking: provider.pendingBooking,
      approvedBooking: provider.approvedBooking,
    );
  }

  Widget buildStatGrid(BookingProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 720 ? 4 : 2;
        final aspectRatio = width >= 720
            ? 1.55
            : width < 360
            ? 0.96
            : 1.08;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          children: [
            _StatCard(
              title: 'Pending',
              value: provider.pendingBooking.toString(),
              icon: Icons.schedule_rounded,
              color: AppColors.warning,
            ),
            _StatCard(
              title: 'Approved',
              value: provider.approvedBooking.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
            _StatCard(
              title: 'Rejected',
              value: provider.rejectedBooking.toString(),
              icon: Icons.cancel_outlined,
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
      },
    );
  }

  Widget buildPieChartCard(BookingProvider provider) {
    return _ChartShell(
      icon: Icons.donut_large_rounded,
      title: 'Persentase Status Booking',
      subtitle: 'Distribusi status dari seluruh booking user.',
      child: SizedBox(
        height: 272,
        child: PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 54,
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    touchedIndex = -1;
                    return;
                  }

                  touchedIndex = response.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            sections: buildPieSections(provider),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> buildPieSections(BookingProvider provider) {
    final data = [
      _ChartData(
        title: 'Pending',
        value: provider.pendingBooking,
        color: AppColors.warning,
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
      final radius = isTouched ? 80.0 : 68.0;
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
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0,
        ),
      );
    });
  }

  Widget buildBarChartCard(BookingProvider provider) {
    final values = [
      provider.pendingBooking,
      provider.approvedBooking,
      provider.rejectedBooking,
      provider.cancelledBooking,
    ];
    final maxValue = values.fold<int>(0, (max, value) {
      return value > max ? value : max;
    });

    return _ChartShell(
      icon: Icons.bar_chart_rounded,
      title: 'Jumlah Booking per Status',
      subtitle: 'Perbandingan kuantitas booking berdasarkan status.',
      child: SizedBox(
        height: 274,
        child: BarChart(
          BarChartData(
            maxY: maxValue == 0 ? 5 : maxValue.toDouble() + 2,
            barTouchData: BarTouchData(enabled: true),
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
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
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
                        return const _BottomTitle(text: 'Approve');
                      case 2:
                        return const _BottomTitle(text: 'Reject');
                      case 3:
                        return const _BottomTitle(text: 'Cancel');
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
                  color: AppColors.border.withValues(alpha: 0.9),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              buildBarGroup(
                x: 0,
                value: provider.pendingBooking,
                color: AppColors.warning,
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
          width: 24,
          borderRadius: BorderRadius.circular(9),
          color: color,
        ),
      ],
    );
  }

  Widget buildLegendCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.info_outline, title: 'Keterangan Status'),
          SizedBox(height: 14),
          _LegendItem(
            color: AppColors.warning,
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

class _StatisticsHeader extends StatelessWidget {
  final int totalBooking;
  final int pendingBooking;
  final int approvedBooking;

  const _StatisticsHeader({
    required this.totalBooking,
    required this.pendingBooking,
    required this.approvedBooking,
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
            right: -30,
            bottom: -30,
            child: Icon(
              Icons.analytics_outlined,
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
                        'Statistik Booking',
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Data berdasarkan status booking user.',
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

class _ChartData {
  final String title;
  final int value;
  final Color color;

  _ChartData({required this.title, required this.value, required this.color});
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
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.lightGreenSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.secondaryGreen, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomTitle extends StatelessWidget {
  final String text;

  const _BottomTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  letterSpacing: 0,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
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
