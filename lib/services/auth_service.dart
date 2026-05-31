import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final doc = await _usersCollection.doc(user.uid).get();

    if (!doc.exists) {
      return null;
    }

    return UserModel.fromDocument(doc);
  }

  Future<UserModel> register({
    required String name,
    required String nim,
    required String faculty,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Gagal membuat akun. User tidak ditemukan.');
      }

      final userModel = UserModel(
        uid: firebaseUser.uid,
        name: name.trim(),
        nim: nim.trim(),
        faculty: faculty.trim(),
        email: email.trim(),
        role: 'user',
        createdAt: DateTime.now(),
      );

      await _usersCollection.doc(firebaseUser.uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Terjadi kesalahan saat register: $e');
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Login gagal. User tidak ditemukan.');
      }

      final doc = await _usersCollection.doc(firebaseUser.uid).get();

      if (!doc.exists) {
        throw Exception('Data user tidak ditemukan di Firestore.');
      }

      return UserModel.fromDocument(doc);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Terjadi kesalahan saat login: $e');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String nim,
    required String faculty,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'name': name.trim(),
        'nim': nim.trim(),
        'faculty': faculty.trim(),
      });
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }

  Future<void> changeUserRole({
    required String uid,
    required String role,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'role': role,
      });
    } catch (e) {
      throw Exception('Gagal mengubah role user: $e');
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email sudah digunakan.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal gunakan 6 karakter.';
      case 'user-not-found':
        return 'User tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }
}