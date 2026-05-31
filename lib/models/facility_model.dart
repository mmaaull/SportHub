import 'package:cloud_firestore/cloud_firestore.dart';

class FacilityModel {
  final String id;
  final String name;
  final String sportType;
  final String campus;
  final String location;
  final String category;
  final String description;
  final String imageUrl;
  final String status;
  final bool isBookable;
  final String openTime;
  final String closeTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  FacilityModel({
    required this.id,
    required this.name,
    required this.sportType,
    required this.campus,
    required this.location,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.isBookable,
    required this.openTime,
    required this.closeTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FacilityModel.fromMap(Map<String, dynamic> map) {
    return FacilityModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sportType: map['sportType'] ?? '',
      campus: map['campus'] ?? '',
      location: map['location'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      status: map['status'] ?? 'available',
      isBookable: map['isBookable'] ?? true,
      openTime: map['openTime'] ?? '07:00',
      closeTime: map['closeTime'] ?? '21:00',
      createdAt: _convertTimestamp(map['createdAt']),
      updatedAt: _convertTimestamp(map['updatedAt']),
    );
  }

  factory FacilityModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FacilityModel.fromMap({
      ...data,
      'id': data['id'] ?? doc.id,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sportType': sportType,
      'campus': campus,
      'location': location,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'isBookable': isBookable,
      'openTime': openTime,
      'closeTime': closeTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FacilityModel copyWith({
    String? id,
    String? name,
    String? sportType,
    String? campus,
    String? location,
    String? category,
    String? description,
    String? imageUrl,
    String? status,
    bool? isBookable,
    String? openTime,
    String? closeTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FacilityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sportType: sportType ?? this.sportType,
      campus: campus ?? this.campus,
      location: location ?? this.location,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      isBookable: isBookable ?? this.isBookable,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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