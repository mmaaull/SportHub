import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity_log_model.dart';
import '../../providers/activity_log_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      loadLogs();
    });
  }

  Future<void> loadLogs() async {
    await context.read<ActivityLogProvider>().loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityLogProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryDarkGreen,
        onRefresh: loadLogs,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            buildHeader(provider.logs.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Aktivitas Terbaru',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      _LogCountPill(total: provider.logs.length),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 56),
                      child: LoadingWidget(
                        message: 'Memuat riwayat aktivitas...',
                      ),
                    )
                  else if (provider.errorMessage != null)
                    EmptyState(
                      icon: Icons.error_outline,
                      title: 'Terjadi Kesalahan',
                      message: provider.errorMessage!,
                      buttonText: 'Coba Lagi',
                      onPressed: loadLogs,
                    )
                  else if (provider.logs.isEmpty)
                    const EmptyState(
                      icon: Icons.history,
                      title: 'Belum Ada Aktivitas',
                      message:
                          'Riwayat aktivitas admin akan muncul setelah admin melakukan aksi.',
                    )
                  else
                    ...provider.logs.map((log) {
                      return _ActivityLogCard(log: log);
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(int totalLogs) {
    return _ActivityLogsHeader(totalLogs: totalLogs);
  }
}

class _ActivityLogsHeader extends StatelessWidget {
  final int totalLogs;

  const _ActivityLogsHeader({required this.totalLogs});

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
              Icons.manage_search_rounded,
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
                        'Riwayat Aktivitas',
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
                  '$totalLogs Aktivitas Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Audit trail untuk aksi penting di UNESA SportHub.',
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
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Approve, reject, tambah, edit, dan hapus fasilitas tercatat otomatis.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
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

class _ActivityLogCard extends StatelessWidget {
  final ActivityLogModel log;

  const _ActivityLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = _getActionColor(log.action);
    final icon = _getActionIcon(log.action);

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getActionLabel(log.action),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActionBadge(color: color, text: _getTargetLabel()),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  log.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon: Icons.person_outline,
                      text: log.adminName.isEmpty ? 'Admin' : log.adminName,
                    ),
                    _MetaPill(
                      icon: Icons.schedule_outlined,
                      text: DateFormatter.formatDateTime(log.createdAt),
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

  String _getTargetLabel() {
    if (log.targetType.trim().isEmpty) return 'Sistem';

    switch (log.targetType) {
      case 'booking':
        return 'Booking';
      case 'facility':
        return 'Fasilitas';
      default:
        return log.targetType;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'approve_booking':
        return AppColors.success;
      case 'reject_booking':
        return AppColors.danger;
      case 'add_facility':
        return AppColors.info;
      case 'update_facility':
        return AppColors.warning;
      case 'delete_facility':
        return AppColors.danger;
      default:
        return AppColors.primaryDarkGreen;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'approve_booking':
        return Icons.check_circle_outline;
      case 'reject_booking':
        return Icons.cancel_outlined;
      case 'add_facility':
        return Icons.add_business;
      case 'update_facility':
        return Icons.edit_outlined;
      case 'delete_facility':
        return Icons.delete_outline;
      default:
        return Icons.history;
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'approve_booking':
        return 'Approve Booking';
      case 'reject_booking':
        return 'Reject Booking';
      case 'add_facility':
        return 'Tambah Fasilitas';
      case 'update_facility':
        return 'Edit Fasilitas';
      case 'delete_facility':
        return 'Hapus Fasilitas';
      default:
        return action;
    }
  }
}

class _ActionBadge extends StatelessWidget {
  final Color color;
  final String text;

  const _ActionBadge({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondaryGreen, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogCountPill extends StatelessWidget {
  final int total;

  const _LogCountPill({required this.total});

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
          const Icon(
            Icons.history_rounded,
            color: AppColors.secondaryGreen,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            '$total log',
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
