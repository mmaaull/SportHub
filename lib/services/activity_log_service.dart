import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_log_model.dart';

class ActivityLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _activityLogsCollection =>
      _firestore.collection('activity_logs');

  Future<void> createLog({
    required String adminId,
    required String adminName,
    required String action,
    required String targetType,
    required String targetId,
    required String description,
  }) async {
    try {
      final docRef = _activityLogsCollection.doc();

      final log = ActivityLogModel(
        id: docRef.id,
        adminId: adminId,
        adminName: adminName,
        action: action,
        targetType: targetType,
        targetId: targetId,
        description: description,
        createdAt: DateTime.now(),
      );

      await docRef.set(log.toMap());
    } catch (e) {
      throw Exception('Gagal menyimpan riwayat aktivitas: $e');
    }
  }

  Future<List<ActivityLogModel>> getAllLogs() async {
    try {
      final snapshot = await _activityLogsCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ActivityLogModel.fromDocument(doc);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil riwayat aktivitas: $e');
    }
  }

  Stream<List<ActivityLogModel>> getLogsStream() {
    return _activityLogsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ActivityLogModel.fromDocument(doc);
      }).toList();
    });
  }
}