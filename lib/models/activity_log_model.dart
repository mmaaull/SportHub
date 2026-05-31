import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String adminId;
  final String adminName;
  final String action;
  final String targetType;
  final String targetId;
  final String description;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.description,
    required this.createdAt,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['id'] ?? '',
      adminId: map['adminId'] ?? '',
      adminName: map['adminName'] ?? '',
      action: map['action'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      description: map['description'] ?? '',
      createdAt: _convertTimestamp(map['createdAt']),
    );
  }

  factory ActivityLogModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ActivityLogModel.fromMap({
      ...data,
      'id': data['id'] ?? doc.id,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'adminName': adminName,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _convertTimestamp(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }
}