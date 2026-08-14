import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:telegram_lite/services/sms_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? _activeOtpCode;
  String? _activePhoneNumber;

  String? get activePhoneNumber => _activePhoneNumber;

  // Store last OTP sent timestamp per phone number (10 minutes rate limit)
  static final Map<String, DateTime> _otpCooldowns = {};

  // Check remaining rate limit cooldown seconds (10 minutes = 600 seconds)
  int getOtpCooldownSeconds(String phoneNumber) {
    final formatted = SmsNetBdService.formatPhoneNumber(phoneNumber);
    if (!_otpCooldowns.containsKey(formatted)) return 0;

    final lastSent = _otpCooldowns[formatted]!;
    final elapsedSeconds = DateTime.now().difference(lastSent).inSeconds;
    final remainingSeconds = 600 - elapsedSeconds;
    return remainingSeconds > 0 ? remainingSeconds : 0;
  }

  // Send real SMS OTP via sms.net.bd Gateway with 10-minute per-person Rate Limiting
  Future<SmsNetBdResult> sendSmsNetBdOtp(String phoneNumber) async {
    _activePhoneNumber = SmsNetBdService.formatPhoneNumber(phoneNumber);

    final cooldownSeconds = getOtpCooldownSeconds(_activePhoneNumber!);
    if (cooldownSeconds > 0) {
      final mins = cooldownSeconds ~/ 60;
      final secs = cooldownSeconds % 60;
      final formattedTime =
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      return SmsNetBdResult(
        isSuccess: false,
        errorCode: 429,
        message:
            'Rate Limit Exceeded: Please wait $formattedTime ($mins min $secs sec) before requesting a new OTP.',
      );
    }

    final result =
        await SmsNetBdService.sendOtpSms(phoneNumber: _activePhoneNumber!);
    if (result.isSuccess && result.otpCode != null) {
      _activeOtpCode = result.otpCode;
      _otpCooldowns[_activePhoneNumber!] = DateTime.now();
      debugPrint('Generated SMS OTP: $_activeOtpCode for $_activePhoneNumber');
    }
    return result;
  }

  // Verify entered 6-digit OTP code against sms.net.bd generated code
  Future<bool> verifySmsNetBdOtp(String enteredCode) async {
    final cleanEntered = enteredCode.trim();
    if (_activeOtpCode != null && cleanEntered == _activeOtpCode) {
      // Ensure user is signed in to Firebase Auth
      if (_auth.currentUser == null) {
        try {
          await _auth.signInAnonymously();
        } catch (e) {
          debugPrint('Anonymous auth error: $e');
        }
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  // Native Firebase Phone Number Verification (SMS OTP fallback)
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

  // Sign In using native SMS OTP credential
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

  // Check if username is already taken by another user in Firestore
  Future<bool> isUsernameAvailable(String username) async {
    final clean = username.trim().replaceAll('@', '').toLowerCase();
    if (clean.isEmpty) return false;

    try {
      final snap = await _firestore
          .collection('users')
          .where('username', isEqualTo: clean)
          .get();

      if (snap.docs.isEmpty) return true;
      if (snap.docs.length == 1 && snap.docs.first.id == currentUser?.uid) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('isUsernameAvailable error: $e');
      return true;
    }
  }

  // Real-time stream of all registered users in Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>?> get registeredUsersStream {
    return _firestore.collection('users').snapshots().handleError((e) {
      debugPrint('registeredUsersStream error: $e');
      return null;
    });
  }

  // Find a registered user by phone number
  Future<DocumentSnapshot<Map<String, dynamic>>?> findUserByPhoneNumber(
      String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    try {
      final snap = await _firestore.collection('users').get();
      for (var doc in snap.docs) {
        final dbPhone = (doc.data()['phoneNumber'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\D'), '');
        if (dbPhone.isNotEmpty &&
            (dbPhone == cleanPhone ||
                cleanPhone.endsWith(dbPhone) ||
                dbPhone.endsWith(cleanPhone))) {
          return doc;
        }
      }
    } catch (e) {
      debugPrint('findUserByPhoneNumber error: $e');
    }
    return null;
  }

  bool _isProfileCompletedLocally = false;

  bool hasCompletedProfile(DocumentSnapshot<Map<String, dynamic>>? doc) {
    if (_isProfileCompletedLocally) return true;
    if (currentUser?.displayName != null &&
        currentUser!.displayName!.trim().isNotEmpty) {
      return true;
    }
    if (doc != null && doc.exists) return true;
    return false;
  }

  // Firestore Profile Operations under users/{uid}
  Future<void> createOrUpdateUserProfile({
    required String name,
    required String username,
    String? bio,
    String? photoUrl,
    String? profileColor,
    String? emojiStatus,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isProfileCompletedLocally = true;
    final docRef = _firestore.collection('users').doc(user.uid);
    final now = DateTime.now().toIso8601String();
    final cleanUsername = username.trim().replaceAll('@', '');

    final data = {
      'uid': user.uid,
      'phoneNumber': _activePhoneNumber ?? user.phoneNumber ?? '',
      'username': cleanUsername,
      'displayName': name.trim(),
      'photoUrl': photoUrl ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      'bio': bio?.trim() ?? 'Hey there! I am using TeleLite.',
      'lastSeen': now,
      'isOnline': true,
      'phoneNumberVisibility': 'My Contacts',
    };

    if (profileColor != null) data['profileColor'] = profileColor;
    if (emojiStatus != null) data['emojiStatus'] = emojiStatus;

    try {
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        data['createdAt'] = now;
      }
      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore set profile error: $e');
    }

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
    try {
      return await _firestore.collection('users').doc(user.uid).get();
    } catch (e) {
      debugPrint('Firestore getUserProfile error: $e');
      return null;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>?> get userProfileStream {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    // Trigger background auto-migration
    _checkAndAutoMigrate(user);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .handleError((error) {
      debugPrint('Firestore userProfileStream error: $error');
      return null;
    });
  }

  Future<void> _checkAndAutoMigrate(User user) async {
    try {
      final docSnap = await _firestore.collection('users').doc(user.uid).get();
      if (!docSnap.exists) {
        final phone = _activePhoneNumber ?? user.phoneNumber;
        if (phone != null && phone.isNotEmpty) {
          final oldDoc = await findUserByPhoneNumber(phone);
          if (oldDoc != null && oldDoc.id != user.uid) {
            final data = oldDoc.data();
            if (data != null) {
              data['uid'] = user.uid;
              await _firestore.collection('users').doc(user.uid).set(data);
              _isProfileCompletedLocally = true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Auto-migration error: $e');
    }
  }

  Future<void> updatePremiumStatus(bool isPremium) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'isPremium': isPremium,
        'premiumSubscribedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore updatePremiumStatus error: $e');
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    _isProfileCompletedLocally = false;
    _activeOtpCode = null;
    _activePhoneNumber = null;
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
