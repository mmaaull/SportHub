import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isUser => _currentUser?.role == 'user';

  Future<void> loadCurrentUser() async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.getCurrentUserData();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String nim,
    required String faculty,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.register(
        name: name,
        nim: nim,
        faculty: faculty,
        email: email,
        password: password,
      );

      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );

      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(_cleanErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String nim,
    required String faculty,
  }) async {
    if (_currentUser == null) {
      _setError('User belum login.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _authService.updateUserProfile(
        uid: _currentUser!.uid,
        name: name,
        nim: nim,
        faculty: faculty,
      );

      _currentUser = _currentUser!.copyWith(
        name: name,
        nim: nim,
        faculty: faculty,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearCurrentUser() {
    _currentUser = null;
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