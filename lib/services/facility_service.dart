import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/facility_model.dart';

class FacilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _facilitiesCollection =>
      _firestore.collection('facilities');

  Stream<List<FacilityModel>> getFacilitiesStream() {
    return _facilitiesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FacilityModel.fromDocument(doc);
      }).toList();
    });
  }

  Future<List<FacilityModel>> getAllFacilities() async {
    try {
      final snapshot = await _facilitiesCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return FacilityModel.fromDocument(doc);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data fasilitas: $e');
    }
  }

  Future<FacilityModel?> getFacilityById(String id) async {
    try {
      final doc = await _facilitiesCollection.doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return FacilityModel.fromDocument(doc);
    } catch (e) {
      throw Exception('Gagal mengambil detail fasilitas: $e');
    }
  }

  Future<void> addFacility(FacilityModel facility) async {
    try {
      final docRef = _facilitiesCollection.doc();

      final newFacility = facility.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newFacility.toMap());
    } catch (e) {
      throw Exception('Gagal menambahkan fasilitas: $e');
    }
  }

  Future<void> updateFacility(FacilityModel facility) async {
    try {
      final updatedFacility = facility.copyWith(
        updatedAt: DateTime.now(),
      );

      await _facilitiesCollection
          .doc(updatedFacility.id)
          .update(updatedFacility.toMap());
    } catch (e) {
      throw Exception('Gagal memperbarui fasilitas: $e');
    }
  }

  Future<void> deleteFacility(String id) async {
    try {
      await _facilitiesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus fasilitas: $e');
    }
  }

  Future<void> seedInitialFacilities() async {
    try {
      final snapshot = await _facilitiesCollection.limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        return;
      }

      final now = DateTime.now();

      final facilities = [
        FacilityModel(
          id: '',
          name: 'GOR Futsal Internasional UNESA',
          sportType: 'Futsal',
          campus: 'Kampus Lidah Wetan',
          location: 'Area GOR Internasional UNESA',
          category: 'Indoor',
          description:
              'Fasilitas olahraga indoor untuk kegiatan futsal mahasiswa, latihan, dan event kampus.',
          imageUrl:
              'https://images.unsplash.com/photo-1579952363873-27f3bade9f55',
          status: 'available',
          isBookable: true,
          openTime: '07:00',
          closeTime: '21:00',
          createdAt: now,
          updatedAt: now,
        ),
        FacilityModel(
          id: '',
          name: 'GOR Bola Basket UNESA',
          sportType: 'Basket',
          campus: 'Kampus Lidah Wetan',
          location: 'Kompleks Olahraga UNESA',
          category: 'Indoor',
          description:
              'GOR untuk latihan bola basket, pertandingan internal, dan kegiatan UKM olahraga.',
          imageUrl:
              'https://images.unsplash.com/photo-1546519638-68e109498ffc',
          status: 'available',
          isBookable: true,
          openTime: '07:00',
          closeTime: '21:00',
          createdAt: now,
          updatedAt: now,
        ),
        FacilityModel(
          id: '',
          name: 'Kolam Renang UNESA',
          sportType: 'Renang',
          campus: 'Kampus Lidah Wetan',
          location: 'Area Kolam Renang UNESA',
          category: 'Outdoor',
          description:
              'Kolam renang kampus untuk latihan renang, pembelajaran olahraga air, dan kegiatan mahasiswa.',
          imageUrl:
              'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7',
          status: 'available',
          isBookable: true,
          openTime: '08:00',
          closeTime: '17:00',
          createdAt: now,
          updatedAt: now,
        ),
        FacilityModel(
          id: '',
          name: 'Lapangan Sepak Bola / Atletik Kampus Ketintang',
          sportType: 'Sepak Bola',
          campus: 'Kampus Ketintang',
          location: 'Lapangan Utama Kampus Ketintang',
          category: 'Outdoor',
          description:
              'Lapangan outdoor untuk sepak bola, atletik, latihan fisik, dan kegiatan olahraga mahasiswa.',
          imageUrl:
              'https://images.unsplash.com/photo-1459865264687-595d652de67e',
          status: 'available',
          isBookable: true,
          openTime: '06:00',
          closeTime: '18:00',
          createdAt: now,
          updatedAt: now,
        ),
        FacilityModel(
          id: '',
          name: 'Lapangan Tenis Kampus Ketintang',
          sportType: 'Tenis',
          campus: 'Kampus Ketintang',
          location: 'Area Lapangan Tenis Ketintang',
          category: 'Outdoor',
          description:
              'Lapangan tenis untuk latihan, pertandingan internal, dan kegiatan olahraga civitas akademika.',
          imageUrl:
              'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6',
          status: 'available',
          isBookable: true,
          openTime: '06:00',
          closeTime: '18:00',
          createdAt: now,
          updatedAt: now,
        ),
        FacilityModel(
          id: '',
          name: 'Lapangan Bola Basket Kampus Ketintang',
          sportType: 'Basket',
          campus: 'Kampus Ketintang',
          location: 'Area Lapangan Basket Ketintang',
          category: 'Outdoor',
          description:
              'Lapangan basket outdoor untuk mahasiswa, latihan komunitas, dan kegiatan olahraga kampus.',
          imageUrl:
              'https://images.unsplash.com/photo-1505666287802-931dc83948e9',
          status: 'available',
          isBookable: true,
          openTime: '06:00',
          closeTime: '18:00',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final facility in facilities) {
        await addFacility(facility);
      }
    } catch (e) {
      throw Exception('Gagal menambahkan data fasilitas awal: $e');
    }
  }
}