import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android Initialization Settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Initialization Settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Create Android Notification Channel
      const androidChannel = AndroidNotificationChannel(
        'telelite_messages_channel',
        'TeleLite Messages',
        description: 'Notifications for incoming messages and calls',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialize warning: $e');
    }
  }

  // ==================== 1. IN-APP NOTIFICATION (GETX TOP BANNER) ====================
  static void showInAppNotification({
    required String title,
    required String body,
    String? avatarUrl,
    VoidCallback? onTap,
  }) {
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1E2732).withAlpha(240),
      colorText: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 14,
      duration: const Duration(seconds: 4),
      icon: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF0088CC),
        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? NetworkImage(avatarUrl)
            : null,
        child: (avatarUrl == null || avatarUrl.isEmpty)
            ? Text(
                title.isNotEmpty ? title[0].toUpperCase() : 'T',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      onTap: (_) {
        if (onTap != null) onTap();
      },
      boxShadows: [
        BoxShadow(
          color: Colors.black.withAlpha(80),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  // ==================== 2. OUT-OF-APP / SYSTEM NOTIFICATION ====================
  Future<void> showSystemNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'telelite_messages_channel',
      'TeleLite Messages',
      channelDescription: 'Notifications for incoming messages and calls',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('showSystemNotification error: $e');
    }
  }

  // Trigger Notification (Both In-App and System Notification)
  Future<void> notify({
    required String title,
    required String body,
    String? avatarUrl,
    VoidCallback? onTap,
  }) async {
    // Show In-App Snackbar banner
    showInAppNotification(
      title: title,
      body: body,
      avatarUrl: avatarUrl,
      onTap: onTap,
    );

    // Show Out-of-App system notification bar item
    await showSystemNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
    );
  }
}
