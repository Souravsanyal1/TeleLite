import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Phone Number Verification (SMS OTP)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String verificationId) codeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 45),
    );
  }

  // Sign In using SMS OTP credential
  Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    final userCredential = await _auth.signInWithCredential(credential);
    notifyListeners();
    return userCredential;
  }

  // Firestore Profile Operations under users/{uid}
  Future<void> createOrUpdateUserProfile({
    required String name,
    required String username,
    String? bio,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnap = await docRef.get();
    final now = DateTime.now().toIso8601String();

    final cleanUsername = username.trim().replaceAll('@', '');

    final data = {
      'uid': user.uid,
      'phoneNumber': user.phoneNumber ?? '',
      'username': cleanUsername,
      'displayName': name.trim(),
      'photoUrl': photoUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      'bio': bio?.trim() ?? 'Hey there! I am using TeleLite.',
      'lastSeen': now,
      'isOnline': true,
    };

    if (!docSnap.exists) {
      data['createdAt'] = now;
    }

    await docRef.set(data, SetOptions(merge: true));

    try {
      await user.updateDisplayName(name.trim());
      await user.reload();
    } catch (e) {
      debugPrint('Failed to update display name: $e');
    }

    notifyListeners();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await _firestore.collection('users').doc(user.uid).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>?> get userProfileStream {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  Future<void> signOut() async {
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
