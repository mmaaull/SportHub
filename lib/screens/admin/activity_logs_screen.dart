// ignore_for_file: deprecated_member_use

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

    Future.microtask(() {
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
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas Admin'),
      ),
      body: RefreshIndicator(
        onRefresh: loadLogs,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            buildHeader(provider.logs.length),
            const SizedBox(height: 18),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 70),
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
    );
  }

  Widget buildHeader(int totalLogs) {
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
              Icons.history,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Log Aktivitas Sistem',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalLogs Aktivitas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mencatat aksi penting yang dilakukan admin.',
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
}

class _ActivityLogCard extends StatelessWidget {
  final ActivityLogModel log;

  const _ActivityLogCard({
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getActionColor(log.action);
    final icon = _getActionIcon(log.action);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(
          _getActionLabel(log.action),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.description),
              const SizedBox(height: 8),
              Text(
                'Admin: ${log.adminName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormatter.formatDateTime(log.createdAt),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        return AppColors.primary;
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
        return Icons.edit;
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