import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MockUser {
  final String uid;
  final String email;
  MockUser({required this.uid, required this.email});
}

class AuthService {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static MockUser? _localCurrentUser;
  static final _localAuthStreamController = StreamController<User?>.broadcast();

  Stream<User?> get authStateChanges {
    try {
      final auth = _auth;
      if (auth != null) return auth.authStateChanges();
    } catch (_) {}
    return _localAuthStreamController.stream;
  }

  User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId => currentUser?.uid ?? _localCurrentUser?.uid;
  String? get currentUserEmail =>
      currentUser?.email ?? _localCurrentUser?.email;

  Future<void> signUp(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      final mockUid = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _localCurrentUser = MockUser(uid: mockUid, email: email);
      return;
    }
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      final mockUid = 'user_${email.split('@').first.toLowerCase()}';
      _localCurrentUser = MockUser(uid: mockUid, email: email);
      return;
    }
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
    _localCurrentUser = null;
  }

  void setLocalUser(String uid, String email) {
    _localCurrentUser = MockUser(uid: uid, email: email);
  }

  MockUser? get localUser => _localCurrentUser;

  Future<void> resetPassword(String email) async {
    try {
      await _auth?.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset email error: $e');
    }
  }
}
