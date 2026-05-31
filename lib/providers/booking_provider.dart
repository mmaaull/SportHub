// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> _allBookings = [];
  List<BookingModel> _userBookings = [];
  List<BookingModel> _schedules = [];
  List<BookingModel> get schedules => _schedules;

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, int> _statistics = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
    'cancelled': 0,
  };

  String _selectedStatus = 'Semua';

  List<BookingModel> get allBookings => _allBookings;
  List<BookingModel> get userBookings => _userBookings;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, int> get statistics => _statistics;
  String get selectedStatus => _selectedStatus;

  int get totalBooking => _statistics['total'] ?? 0;
  int get pendingBooking => _statistics['pending'] ?? 0;
  int get approvedBooking => _statistics['approved'] ?? 0;
  int get rejectedBooking => _statistics['rejected'] ?? 0;
  int get cancelledBooking => _statistics['cancelled'] ?? 0;

  List<BookingModel> get filteredAllBookings {
    if (_selectedStatus == 'Semua') {
      return _allBookings;
    }

    return _allBookings.where((booking) {
      return booking.status == _selectedStatus.toLowerCase();
    }).toList();
  }

  List<BookingModel> get filteredUserBookings {
    if (_selectedStatus == 'Semua') {
      return _userBookings;
    }

    return _userBookings.where((booking) {
      return booking.status == _selectedStatus.toLowerCase();
    }).toList();
  }

  Stream<List<BookingModel>> getAllBookingsStream() {
    return _bookingService.getAllBookingsStream();
  }

  Stream<List<BookingModel>> getUserBookingsStream(String userId) {
    return _bookingService.getUserBookingsStream(userId);
  }

  Future<void> loadFacilitySchedules(String facilityId) async {
  _setLoading(true);
  _clearError();

  try {
    _schedules = await _bookingService.getFacilitySchedules(
      facilityId: facilityId,
    );
  } catch (e) {
    _setError(_cleanErrorMessage(e));
  } finally {
    _setLoading(false);
  }
}

  Future<void> loadAllSchedules() async {
    _setLoading(true);
    _clearError();

    try {
      _schedules = await _bookingService.getAllSchedules();
    } catch (e) {
      _setError(_cleanErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  List<BookingModel> getSchedulesByDate(DateTime date) {
    return _schedules.where((booking) {
      return booking.date.year == date.year &&
          booking.date.month == date.month &&
          booking.date.day == date.day;
    }).toList();
  }
  
  Future<void> loadAllBookings() async {
    _setLoading(true);
    _clearError();

    try {
      _allBookings = await _bookingService.getAllBookings();
      await loadStatistics();
    } catch (e) {
      _setError(_cleanErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserBookings(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _userBookings = await _bookingService.getUserBookings(userId);
    } catch (e) {
      _setError(_cleanErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<BookingModel?> getBookingById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      return await _bookingService.getBookingById(id);
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createBooking(BookingModel booking) async {
    _setLoading(true);
    _clearError();

    try {
      await _bookingService.createBooking(booking);

      if (booking.userId.isNotEmpty) {
        await loadUserBookings(booking.userId);
      }

      await loadStatistics();

      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateBooking(BookingModel booking) async {
    _setLoading(true);
    _clearError();

    try {
      await _bookingService.updateBooking(booking);

      if (booking.userId.isNotEmpty) {
        await loadUserBookings(booking.userId);
      }

      await loadStatistics();

      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelBooking({
    required String bookingId,
    required String userId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _bookingService.cancelBooking(bookingId);
      await loadUserBookings(userId);
      await loadStatistics();
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveBooking({
    required String bookingId,
    required String adminId,
    required String adminName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _bookingService.approveBooking(
        bookingId: bookingId,
        adminId: adminId,
        adminName: adminName,
      );

      await loadAllBookings();
      await loadStatistics();
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectBooking({
    required String bookingId,
    required String adminNote,
    required String adminId,
    required String adminName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _bookingService.rejectBooking(
        bookingId: bookingId,
        adminNote: adminNote,
        adminId: adminId,
        adminName: adminName,
      );

      await loadAllBookings();
      await loadStatistics();

      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStatistics() async {
    try {
      _statistics = await _bookingService.getBookingStatistics();
      notifyListeners();
    } catch (e) {
      _setError(_cleanErrorMessage(e));
    }
  }

  void filterByStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void resetStatusFilter() {
    _selectedStatus = 'Semua';
    notifyListeners();
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