import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/telegram_controller.dart';
import '../screens/force_message_inbox_screen.dart';
import 'notification_service.dart';

// Top-level entry-point background messaging handler required by FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message received: ${message.messageId}');
  // System tray notification is automatically displayed by OS/FCM SDK
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Set<String> _processedMessageIds = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Set top-level background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request Notification Permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM Permission Status: ${settings.authorizationStatus}');

    // 3. Get FCM Token & Save to Firestore
    await _retrieveAndSaveFcmToken();

    // 4. Listen for Token Refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      _saveFcmTokenToFirestore(newToken);
    });

    // 5. Handle Foreground Messages (In-App Banner + Inbox Sync)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleIncomingFcmMessage(message, isForeground: true);
    });

    // 6. Handle Notification Tap (App in Background -> Opened)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // 7. Handle Notification Tap (App Terminated -> Launched)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

    // 8. Listen for auth state changes to update token for logged-in user
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _retrieveAndSaveFcmToken();
      }
    });
  }

  // Retrieve & Save Token
  Future<void> _retrieveAndSaveFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM Device Token: $token');
        await _saveFcmTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('FCM getToken exception: $e');
    }
  }

  // Save FCM Token to Firestore under users/{uid}
  Future<void> _saveFcmTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    final uid = user?.uid ?? 'guest_device';

    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'isPremium': false,
        'country': 'BD',
        'devicePlatform': kIsWeb ? 'Web' : defaultTargetPlatform.name,
      }, SetOptions(merge: true));
      debugPrint('FCM token successfully saved to Firestore for user: $uid');
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  // Handle Incoming FCM Payload
  void _handleIncomingFcmMessage(RemoteMessage message, {required bool isForeground}) {
    final messageId = message.messageId ??
        message.data['messageId'] ??
        'msg_${DateTime.now().millisecondsSinceEpoch}';

    // Deduplicate: If messageId already processed, ignore!
    if (_processedMessageIds.contains(messageId)) {
      debugPrint('FCM Duplicate Message ignored: $messageId');
      return;
    }
    _processedMessageIds.add(messageId);

    final title = message.notification?.title ??
        message.data['title'] ??
        '📢 TeleLite Update';
    final body = message.notification?.body ??
        message.data['body'] ??
        'New force message received.';
    final mediaUrl = message.data['imageUrl'] ?? message.data['mediaUrl'];

    // Dispatch to TelegramController
    if (Get.isRegistered<TelegramController>()) {
      TelegramController.to.sendForceBroadcastMessage(
        title: title,
        body: body,
        mediaUrl: mediaUrl,
      );
    }

    // In Foreground: Display Top Notification Banner
    if (isForeground) {
      NotificationService.showInAppNotification(
        title: title,
        body: body,
        avatarUrl: mediaUrl,
        onTap: () => Get.to(() => const ForceMessageInboxScreen()),
      );
    }
  }

  // Handle Notification Tap Event (Background & Terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM Notification Tapped: ${message.data}');
    final type = message.data['type'] ?? 'force_message';
    final messageId = message.data['messageId'] ?? '';

    if (type == 'force_message' || type == 'inbox') {
      Get.to(() => ForceMessageInboxScreen(initialMessageId: messageId));
    }
  }
}
