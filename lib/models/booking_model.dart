import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String userNim;
  final String facilityId;
  final String facilityName;
  final String sportType;
  final String campus;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String purpose;
  final int participantCount;
  final String note;
  final String status;
  final String adminNote;

  final String approvedBy;
  final String approvedByName;
  final DateTime? approvedAt;

  final String rejectedBy;
  final String rejectedByName;
  final DateTime? rejectedAt;

  final String receiptNumber;
  final DateTime? receiptCreatedAt;
  final String receiptUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userNim,
    required this.facilityId,
    required this.facilityName,
    required this.sportType,
    required this.campus,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.participantCount,
    required this.note,
    required this.status,
    required this.adminNote,
    this.approvedBy = '',
    this.approvedByName = '',
    this.approvedAt,
    this.rejectedBy = '',
    this.rejectedByName = '',
    this.rejectedAt,
    this.receiptNumber = '',
    this.receiptCreatedAt,
    this.receiptUrl = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userNim: map['userNim'] ?? '',
      facilityId: map['facilityId'] ?? '',
      facilityName: map['facilityName'] ?? '',
      sportType: map['sportType'] ?? '',
      campus: map['campus'] ?? '',
      date: _convertTimestamp(map['date']) ?? DateTime.now(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      purpose: map['purpose'] ?? '',
      participantCount: map['participantCount'] ?? 0,
      note: map['note'] ?? '',
      status: map['status'] ?? 'pending',
      adminNote: map['adminNote'] ?? '',
      approvedBy: map['approvedBy'] ?? '',
      approvedByName: map['approvedByName'] ?? '',
      approvedAt: _convertTimestamp(map['approvedAt']),
      rejectedBy: map['rejectedBy'] ?? '',
      rejectedByName: map['rejectedByName'] ?? '',
      rejectedAt: _convertTimestamp(map['rejectedAt']),
      receiptNumber: map['receiptNumber'] ?? '',
      receiptCreatedAt: _convertTimestamp(map['receiptCreatedAt']),
      receiptUrl: map['receiptUrl'] ?? '',
      createdAt: _convertTimestamp(map['createdAt']) ?? DateTime.now(),
      updatedAt: _convertTimestamp(map['updatedAt']) ?? DateTime.now(),
    );
  }

  factory BookingModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BookingModel.fromMap({
      ...data,
      'id': data['id'] ?? doc.id,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userNim': userNim,
      'facilityId': facilityId,
      'facilityName': facilityName,
      'sportType': sportType,
      'campus': campus,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'purpose': purpose,
      'participantCount': participantCount,
      'note': note,
      'status': status,
      'adminNote': adminNote,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt':
          approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
      'rejectedBy': rejectedBy,
      'rejectedByName': rejectedByName,
      'rejectedAt':
          rejectedAt == null ? null : Timestamp.fromDate(rejectedAt!),
      'receiptNumber': receiptNumber,
      'receiptCreatedAt': receiptCreatedAt == null
          ? null
          : Timestamp.fromDate(receiptCreatedAt!),
      'receiptUrl': receiptUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userNim,
    String? facilityId,
    String? facilityName,
    String? sportType,
    String? campus,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? purpose,
    int? participantCount,
    String? note,
    String? status,
    String? adminNote,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectedBy,
    String? rejectedByName,
    DateTime? rejectedAt,
    String? receiptNumber,
    DateTime? receiptCreatedAt,
    String? receiptUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userNim: userNim ?? this.userNim,
      facilityId: facilityId ?? this.facilityId,
      facilityName: facilityName ?? this.facilityName,
      sportType: sportType ?? this.sportType,
      campus: campus ?? this.campus,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      purpose: purpose ?? this.purpose,
      participantCount: participantCount ?? this.participantCount,
      note: note ?? this.note,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedByName: rejectedByName ?? this.rejectedByName,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receiptCreatedAt: receiptCreatedAt ?? this.receiptCreatedAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  bool get canBeEdited => status == 'pending';
  bool get canBeCancelled => status == 'pending';
  bool get canBeApprovedOrRejected => status == 'pending';

  bool get hasReceipt {
    return status == 'approved' && receiptNumber.trim().isNotEmpty;
  }

  static DateTime? _convertTimestamp(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}