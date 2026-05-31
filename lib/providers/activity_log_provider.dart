import 'package:flutter/material.dart';

import '../models/activity_log_model.dart';
import '../services/activity_log_service.dart';

class ActivityLogProvider extends ChangeNotifier {
  final ActivityLogService _activityLogService = ActivityLogService();

  List<ActivityLogModel> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ActivityLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadLogs() async {
    _setLoading(true);
    _clearError();

    try {
      _logs = await _activityLogService.getAllLogs();
    } catch (e) {
      _setError(_cleanErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<ActivityLogModel>> getLogsStream() {
    return _activityLogService.getLogsStream();
  }

  Future<bool> createLog({
    required String adminId,
    required String adminName,
    required String action,
    required String targetType,
    required String targetId,
    required String description,
  }) async {
    _clearError();

    try {
      await _activityLogService.createLog(
        adminId: adminId,
        adminName: adminName,
        action: action,
        targetType: targetType,
        targetId: targetId,
        description: description,
      );

      await loadLogs();
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    }
  }

  void clearError() {
    _clearError();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _cleanErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}