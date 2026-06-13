import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isOrganizer => _user?.isOrganizer ?? false;

  AuthProvider() {
    _service.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      _user = await _service.getUser(firebaseUser.uid);
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _error = null;
    try {
      _user = await _service.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _service.getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _error = null;
    try {
      _user = await _service.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _service.getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadAvatar(XFile file) async {
    if (_user == null) return null;
    try {
      return await _service.uploadAvatar(_user!.uid, file);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile({required String name, String? avatarUrl}) async {
    if (_user == null) return false;
    _error = null;
    try {
      await _service.updateProfile(
        uid: _user!.uid,
        name: name,
        avatarUrl: avatarUrl,
      );
      _user = UserModel(
        uid: _user!.uid,
        name: name,
        email: _user!.email,
        role: _user!.role,
        avatarUrl: avatarUrl ?? _user!.avatarUrl,
        createdAt: _user!.createdAt,
      );
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Failed to update profile';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
