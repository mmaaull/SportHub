// ignore_for_file: no_leading_underscores_for_local_identifiers, unused_element

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking_model.dart';
import '../models/facility_model.dart';
import 'notification_service.dart';
import 'activity_log_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final ActivityLogService _activityLogService = ActivityLogService();
  String _generateReceiptNumber(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final millis = date.millisecondsSinceEpoch.toString();

    final shortCode = millis.substring(millis.length - 6);

    return 'STT-UNESA-$year$month$day-$shortCode';
  }

  CollectionReference get _bookingsCollection =>
      _firestore.collection('bookings');

  CollectionReference get _facilitiesCollection =>
      _firestore.collection('facilities');

  Stream<List<BookingModel>> getAllBookingsStream() {
    return _bookingsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromDocument(doc);
      }).toList();
    });
  }

  Stream<List<BookingModel>> getUserBookingsStream(String userId) {
    return _bookingsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs.map((doc) {
        return BookingModel.fromDocument(doc);
      }).toList();

      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return bookings;
    });
  }

  Future<List<BookingModel>> getFacilitySchedules({
    required String facilityId,
  }) async {
    try {
      final snapshot = await _bookingsCollection
          .where('facilityId', isEqualTo: facilityId)
          .get();

      final schedules = snapshot.docs.map((doc) {
        return BookingModel.fromDocument(doc);
      }).where((booking) {
        return booking.status == 'pending' || booking.status == 'approved';
      }).toList();

      schedules.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);

        if (dateCompare != 0) {
          return dateCompare;
        }

        return a.startTime.compareTo(b.startTime);
      });

      return schedules;
    } catch (e) {
      throw Exception('Gagal mengambil jadwal fasilitas: $e');
    }
  }

  Future<List<BookingModel>> getAllSchedules() async {
    try {
      final snapshot = await _bookingsCollection.get();

      final schedules = snapshot.docs.map((doc) {
        return BookingModel.fromDocument(doc);
      }).where((booking) {
        return booking.status == 'pending' || booking.status == 'approved';
      }).toList();

      schedules.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);

        if (dateCompare != 0) {
          return dateCompare;
        }

        return a.startTime.compareTo(b.startTime);
      });

      return schedules;
    } catch (e) {
      throw Exception('Gagal mengambil semua jadwal: $e');
    }
  }

  Future<List<BookingModel>> getAllBookings() async {
    try {
      final snapshot = await _bookingsCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return BookingModel.fromDocument(doc);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil semua booking: $e');
    }
  }

  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final snapshot = await _bookingsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final bookings = snapshot.docs.map((doc) {
        return BookingModel.fromDocument(doc);
      }).toList();

      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return bookings;
    } catch (e) {
      throw Exception('Gagal mengambil booking user: $e');
    }
  }

  Future<BookingModel?> getBookingById(String id) async {
    try {
      final doc = await _bookingsCollection.doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return BookingModel.fromDocument(doc);
    } catch (e) {
      throw Exception('Gagal mengambil detail booking: $e');
    }
  }

  Future<void> createBooking(BookingModel booking) async {
    try {
      await _validateFacilityCanBeBooked(booking.facilityId);

      final hasConflict = await hasBookingConflict(
        facilityId: booking.facilityId,
        date: booking.date,
        startTime: booking.startTime,
        endTime: booking.endTime,
      );

      if (hasConflict) {
        throw Exception(
          'Jadwal booking bentrok dengan booking lain yang masih pending atau sudah approved.',
        );
      }

      final docRef = _bookingsCollection.doc();

      final newBooking = booking.copyWith(
        id: docRef.id,
        status: 'pending',
        adminNote: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newBooking.toMap());
      await _notificationService.createNotification(
        userId: newBooking.userId,
        title: 'Booking Berhasil Diajukan',
        message:
            'Booking ${newBooking.facilityName} berhasil diajukan dan menunggu persetujuan admin.',
        type: 'booking_created',
        bookingId: newBooking.id,
      );

      await _notificationService.notifyAllAdmins(
        title: 'Booking Baru Masuk',
        message:
            '${newBooking.userName} mengajukan booking ${newBooking.facilityName}.',
        type: 'booking_created',
        bookingId: newBooking.id,
      );
    } catch (e) {
      throw Exception('Gagal membuat booking: $e');
    }
  }

  Future<void> updateBooking(BookingModel booking) async {
    try {
      if (booking.status != 'pending') {
        throw Exception('Booking hanya bisa diedit jika status masih pending.');
      }

      await _validateFacilityCanBeBooked(booking.facilityId);

      final hasConflict = await hasBookingConflict(
        facilityId: booking.facilityId,
        date: booking.date,
        startTime: booking.startTime,
        endTime: booking.endTime,
        ignoreBookingId: booking.id,
      );

      if (hasConflict) {
        throw Exception(
          'Jadwal booking bentrok dengan booking lain yang masih pending atau sudah approved.',
        );
      }

      final updatedBooking = booking.copyWith(
        updatedAt: DateTime.now(),
      );

      await _bookingsCollection
          .doc(updatedBooking.id)
          .update(updatedBooking.toMap());
    } catch (e) {
      throw Exception('Gagal memperbarui booking: $e');
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();

      if (!doc.exists) {
        throw Exception('Data booking tidak ditemukan.');
      }

      final booking = BookingModel.fromDocument(doc);

      if (booking.status != 'pending') {
        throw Exception('Booking hanya bisa dibatalkan jika status pending.');
      }

      await _bookingsCollection.doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await _notificationService.createNotification(
        userId: booking.userId,
        title: 'Booking Dibatalkan',
        message: 'Booking ${booking.facilityName} berhasil dibatalkan.',
        type: 'booking_cancelled',
        bookingId: booking.id,
      );

      await _notificationService.notifyAllAdmins(
        title: 'Booking Dibatalkan User',
        message:
            '${booking.userName} membatalkan booking ${booking.facilityName}.',
        type: 'booking_cancelled',
        bookingId: booking.id,
      );

    } catch (e) {
      throw Exception('Gagal membatalkan booking: $e');
    }
  }

  Future<void> approveBooking({
    required String bookingId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();

      if (!doc.exists) {
        throw Exception('Data booking tidak ditemukan.');
      }

      final booking = BookingModel.fromDocument(doc);

      if (booking.status != 'pending') {
        throw Exception('Booking hanya bisa disetujui jika status pending.');
      }

      await _validateFacilityCanBeBooked(booking.facilityId);

      final hasConflict = await hasBookingConflict(
        facilityId: booking.facilityId,
        date: booking.date,
        startTime: booking.startTime,
        endTime: booking.endTime,
        ignoreBookingId: booking.id,
      );

      if (hasConflict) {
        throw Exception(
          'Booking tidak bisa disetujui karena jadwal bentrok dengan booking pending atau approved lainnya.',
        );
      }

      final now = DateTime.now();
      final receiptNumber = _generateReceiptNumber(now);

      await _bookingsCollection.doc(bookingId).update({
        'status': 'approved',
        'adminNote': '',
        'approvedBy': adminId,
        'approvedByName': adminName,
        'approvedAt': Timestamp.fromDate(now),
        'receiptNumber': receiptNumber,
        'receiptCreatedAt': Timestamp.fromDate(now),
        'receiptUrl': '',
        'updatedAt': Timestamp.fromDate(now),
      });

      await _activityLogService.createLog(
        adminId: adminId,
        adminName: adminName,
        action: 'approve_booking',
        targetType: 'booking',
        targetId: booking.id,
        description:
            'Menyetujui booking ${booking.facilityName} milik ${booking.userName} dengan nomor tanda terima $receiptNumber.',
      );

      // Jika kamu sudah memakai NotificationService dari Tahap 13,
      // letakkan notifikasi approved di sini.
      // Contoh:
      //
      await _notificationService.createNotification(
        userId: booking.userId,
        title: 'Booking Disetujui',
        message:
            'Booking ${booking.facilityName} telah disetujui. Nomor tanda terima: $receiptNumber.',
        type: 'booking_approved',
        bookingId: booking.id,
      );
    } catch (e) {
      throw Exception('Gagal menyetujui booking: $e');
    }
  }

  Future<void> rejectBooking({
    required String bookingId,
    required String adminNote,
    required String adminId,
    required String adminName,
  }) async {
    try {
      if (adminNote.trim().isEmpty) {
        throw Exception('Alasan penolakan wajib diisi.');
      }

      final doc = await _bookingsCollection.doc(bookingId).get();

      if (!doc.exists) {
        throw Exception('Data booking tidak ditemukan.');
      }

      final booking = BookingModel.fromDocument(doc);

      if (booking.status != 'pending') {
        throw Exception('Booking hanya bisa ditolak jika status pending.');
      }

      await _bookingsCollection.doc(bookingId).update({
        'status': 'rejected',
        'adminNote': adminNote.trim(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await _notificationService.createNotification(
        userId: booking.userId,
        title: 'Booking Ditolak',
        message:
            'Booking ${booking.facilityName} ditolak. Alasan: ${adminNote.trim()}',
        type: 'booking_rejected',
        bookingId: booking.id,
      );

      await _activityLogService.createLog(
        adminId: adminId,
        adminName: adminName,
        action: 'reject_booking',
        targetType: 'booking',
        targetId: booking.id,
        description:
            'Menolak booking ${booking.facilityName} milik ${booking.userName}. Alasan: ${adminNote.trim()}',
      );

      // Jika sebelumnya kamu sudah menambahkan NotificationService,
      // kode notifikasi rejected boleh tetap diletakkan setelah log ini.
    } catch (e) {
      throw Exception('Gagal menolak booking: $e');
    }
  }
  Future<Map<String, int>> getBookingStatistics() async {
    try {
      final snapshot = await _bookingsCollection.get();

      int total = 0;
      int pending = 0;
      int approved = 0;
      int rejected = 0;
      int cancelled = 0;

      for (final doc in snapshot.docs) {
        final booking = BookingModel.fromDocument(doc);

        total++;

        switch (booking.status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'cancelled': cancelled,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik booking: $e');
    }
  }

  Future<bool> hasBookingConflict({
    required String facilityId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? ignoreBookingId,
  }) async {
    try {
      final snapshot = await _bookingsCollection
          .where('facilityId', isEqualTo: facilityId)
          .get();

      final newDateKey = _dateKey(date);
      final newStart = _timeToMinutes(startTime);
      final newEnd = _timeToMinutes(endTime);


      for (final doc in snapshot.docs) {
        final existingBooking = BookingModel.fromDocument(doc);

        if (ignoreBookingId != null && existingBooking.id == ignoreBookingId) {
          continue;
        }

        final isActiveStatus = existingBooking.status == 'pending' ||
            existingBooking.status == 'approved';

        if (!isActiveStatus) {
          continue;
        }

        final existingDateKey = _dateKey(existingBooking.date);

        if (existingDateKey != newDateKey) {
          continue;
        }

        final existingStart = _timeToMinutes(existingBooking.startTime);
        final existingEnd = _timeToMinutes(existingBooking.endTime);

        final isOverlap = newStart < existingEnd && existingStart < newEnd;

        if (isOverlap) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw Exception('Gagal mengecek bentrok jadwal: $e');
    }
  }

  Future<void> _validateFacilityCanBeBooked(String facilityId) async {
    final doc = await _facilitiesCollection.doc(facilityId).get();

    if (!doc.exists) {
      throw Exception('Data fasilitas tidak ditemukan.');
    }

    final facility = FacilityModel.fromDocument(doc);

    if (!facility.isBookable) {
      throw Exception('Fasilitas ini sedang tidak dapat dibooking.');
    }

    if (facility.status != 'available') {
      throw Exception(
        'Fasilitas sedang ${_getFacilityStatusLabel(facility.status)} dan tidak dapat dibooking.',
      );
    }
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');

    if (parts.length != 2) {
      return 0;
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }

  String _dateKey(DateTime date) {
    final localDate = date.toLocal();
    final year = localDate.year.toString().padLeft(4, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');

      return '$year-$month-$day';
    }

  String _getFacilityStatusLabel(String status) {
    switch (status) {
      case 'maintenance':
        return 'maintenance';
      case 'unavailable':
        return 'tidak tersedia';
      case 'closed':
        return 'ditutup';
      default:
        return status;
    }
  }
}