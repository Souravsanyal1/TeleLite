import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isGuestMode = false;
  bool get isGuestMode => _isGuestMode;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  void enableGuestMode() {
    _isGuestMode = true;
    notifyListeners();
  }

  void exitGuestMode() {
    _isGuestMode = false;
    notifyListeners();
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isGuestMode = false;
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    notifyListeners();
    return credential;
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    _isGuestMode = false;
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (credential.user != null) {
      try {
        await credential.user!.updateDisplayName(name.trim());
        await credential.user!.reload();
      } catch (e) {
        debugPrint('Failed to update display name: $e');
      }
    }

    notifyListeners();
    return credential;
  }

  Future<void> signOut() async {
    _isGuestMode = false;
    if (_auth.currentUser != null) {
      try {
        await _auth.signOut();
      } catch (e) {
        debugPrint('Firebase signOut warning: $e');
      }
    }
    notifyListeners();
  }
}
