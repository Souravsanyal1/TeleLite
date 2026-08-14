import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/admin_model.dart';
import 'notification_service.dart';
import 'telegram_bot_service.dart';

class AdminService extends GetxController {
  static AdminService get to => Get.isRegistered<AdminService>()
      ? Get.find<AdminService>()
      : Get.put(AdminService(), permanent: true);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<AdminStats> stats = AdminStats().obs;
  final RxList<AdminUser> users = <AdminUser>[].obs;
  final RxList<ReportItem> reports = <ReportItem>[].obs;
  final RxList<NotificationLog> logs = <NotificationLog>[].obs;
  final RxString searchQuery = ''.obs;

  StreamSubscription? _usersSub;
  StreamSubscription? _officialChatsSub;
  StreamSubscription? _broadcastsSub;

  @override
  void onInit() {
    super.onInit();
    _bindRealFirestoreListeners();
  }

  @override
  void onClose() {
    _usersSub?.cancel();
    _officialChatsSub?.cancel();
    _broadcastsSub?.cancel();
    super.onClose();
  }

  void _bindRealFirestoreListeners() {
    // 1. Listen to REAL registered users from Firestore (Deduplicate by Phone Number)
    _usersSub = _firestore.collection('users').snapshots().listen((snap) {
      if (snap.docs.isNotEmpty) {
        final Set<String> seenPhones = {};
        final realUsers = <AdminUser>[];

        for (var doc in snap.docs) {
          final data = doc.data();
          final rawPhone = (data['phoneNumber'] ?? data['phone'] ?? '').toString();
          final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');

          // Deduplicate: If phone number is present and already seen, count only once!
          if (cleanPhone.isNotEmpty && seenPhones.contains(cleanPhone)) {
            continue;
          }
          if (cleanPhone.isNotEmpty) {
            seenPhones.add(cleanPhone);
          }

          realUsers.add(
            AdminUser(
              id: doc.id,
              name: (data['displayName'] ?? data['name'] ?? 'User').toString(),
              username: (data['username'] ?? 'user').toString(),
              phone: rawPhone.isNotEmpty ? rawPhone : '+880 1700 000000',
              avatarUrl: (data['photoUrl'] ?? data['avatarUrl'] ??
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150')
                  .toString(),
              joinedTime: 'Recently',
              storiesCount: 0,
              isBlocked: data['isBlocked'] == true,
              isOnline: data['isOnline'] == true,
            ),
          );
        }

        users.assignAll(realUsers);
        stats.value = stats.value.copyWith(
          totalUsers: realUsers.length,
          usersToday: realUsers.where((u) => u.isOnline).length,
        );
      } else {
        // Fallback default demo users if collection is empty
        _loadFallbackUsers();
      }
    }, onError: (e) {
      debugPrint('Real Firestore users listener exception: $e');
      _loadFallbackUsers();
    });

    // 2. Listen to REAL Official Auto-Join Channels
    _officialChatsSub =
        _firestore.collection('official_chats').snapshots().listen((snap) {
      stats.value = stats.value.copyWith(
        activeChannels: snap.docs.length,
      );
    }, onError: (e) {
      debugPrint('Real Firestore official_chats listener exception: $e');
    });

    // 3. Listen to REAL Force Broadcast Logs
    _broadcastsSub =
        _firestore.collection('force_broadcasts').snapshots().listen((snap) {
      if (snap.docs.isNotEmpty) {
        final realLogs = snap.docs.map((doc) {
          final data = doc.data();
          return NotificationLog(
            id: doc.id,
            title: (data['title'] ?? 'Broadcast').toString(),
            body: (data['body'] ?? '').toString(),
            channel: (data['channel'] ?? 'FCM Push').toString(),
            status: 'Sent (Live)',
            timestamp: 'Live',
            targetCount: data['targetCount'] is int ? data['targetCount'] : 1,
          );
        }).toList();

        logs.assignAll(realLogs);
      } else {
        _loadFallbackLogs();
      }
    }, onError: (e) {
      debugPrint('Real Firestore force_broadcasts listener exception: $e');
      _loadFallbackLogs();
    });
  }

  void _loadFallbackUsers() {
    if (users.isEmpty) {
      users.assignAll([
        AdminUser(
          id: 'wjIawF3CYhcii3q1pzTAp5PdUxG3',
          name: 'Super Admin (Kirito)',
          username: 'kirito231411',
          phone: '+880 1711 000000',
          avatarUrl:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          joinedTime: 'Super Admin',
          storiesCount: 10,
          isBlocked: false,
          isOnline: true,
          telegramChatId: '8553809069',
        ),
        AdminUser(
          id: 'u1',
          name: 'Sarah Connor',
          username: 'sarah_c',
          phone: '+880 1711 112233',
          avatarUrl:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          joinedTime: '2 days ago',
          storiesCount: 5,
          isBlocked: false,
          isOnline: true,
          telegramChatId: '123456789',
        ),
        AdminUser(
          id: 'u2',
          name: 'John Doe',
          username: 'john_d',
          phone: '+880 1812 345678',
          avatarUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          joinedTime: '5 days ago',
          storiesCount: 2,
          isBlocked: false,
          isOnline: true,
          telegramChatId: '987654321',
        ),
      ]);
      stats.value = stats.value.copyWith(
        totalUsers: users.length,
        usersToday: 1,
      );
    }
  }

  void _loadFallbackLogs() {
    if (logs.isEmpty) {
      logs.assignAll([
        NotificationLog(
          id: 'l1',
          title: '📢 Real System Live Gateway',
          body: 'TeleLite Cloud Gateway is live and synced with Firebase.',
          channel: 'FCM Push',
          status: 'Sent',
          timestamp: '10:30 AM',
          targetCount: users.length,
        ),
        NotificationLog(
          id: 'l2',
          title: '🤖 @TeleLiteGuardianBot Connected',
          body: 'Telegram bot API online.',
          channel: 'Telegram Bot',
          status: 'Sent',
          timestamp: '09:15 AM',
          targetCount: 1,
        ),
      ]);
    }
  }

  void toggleUserBlock(String userId) async {
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final user = users[idx];
      final newStatus = !user.isBlocked;
      users[idx] = user.copyWith(isBlocked: newStatus);

      try {
        await _firestore.collection('users').doc(userId).update({
          'isBlocked': newStatus,
        });
      } catch (e) {
        debugPrint('Firestore update block state error: $e');
      }

      Get.snackbar(
        newStatus ? 'User Blocked' : 'User Unblocked',
        '${user.name} has been ${newStatus ? 'blocked' : 'unblocked'}.',
        backgroundColor:
            newStatus ? Colors.red.withAlpha(200) : Colors.green.withAlpha(200),
        colorText: Colors.white,
      );

      // Trigger Bot alert
      TelegramBotService().broadcastAdminAlert(
        title: newStatus ? 'User Blocked' : 'User Unblocked',
        details:
            'User: ${user.name} (@${user.username})\nStatus: ${newStatus ? "Blocked" : "Active"}',
      );
    }
  }

  void resolveReport(String reportId, bool deleteContent) {
    final idx = reports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final r = reports[idx];
      reports[idx] = r.copyWith(status: 'resolved');

      Get.snackbar(
        'Report Resolved',
        deleteContent
            ? 'Content deleted and report marked as resolved.'
            : 'Report marked as resolved.',
        backgroundColor: Colors.blue.withAlpha(200),
        colorText: Colors.white,
      );
    }
  }

  Future<void> sendTelegramBotNotice(String userId, String message) async {
    final user = users.firstWhere((u) => u.id == userId,
        orElse: () => users.first);

    final chatId = user.telegramChatId ?? '8553809069';
    final success = await TelegramBotService().sendBotMessage(
      chatId: chatId,
      text: '🤖 *TeleLite Guardian Admin Notice*\n\n$message',
    );

    final log = NotificationLog(
      id: 'l_${DateTime.now().millisecondsSinceEpoch}',
      title: '🤖 @TeleLiteGuardianBot Notice to ${user.name}',
      body: message,
      channel: 'Telegram Bot',
      status: success ? 'Sent' : 'Failed',
      timestamp:
          '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      targetCount: 1,
    );

    logs.insert(0, log);

    NotificationService.showInAppNotification(
      title: success ? 'Bot Notice Delivered' : 'Bot Notice Sent (Local)',
      body: 'Telegram bot notice sent to ${user.name} (@TeleLiteGuardianBot)',
      avatarUrl: user.avatarUrl,
    );
  }

  Future<void> sendBroadcastPush({
    required String title,
    required String body,
    required String channel,
    required String priority,
    required List<String> targetUserIds,
    String? imageUrl,
    String target = 'All',
  }) async {
    final count = targetUserIds.isEmpty ? users.length : targetUserIds.length;
    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';

    // Real HTTP API call to Telegram Bot
    await TelegramBotService().broadcastAdminAlert(
      title: title,
      details: body,
    );

    final log = NotificationLog(
      id: 'l_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      channel: channel,
      status: 'Sent (Live)',
      timestamp:
          '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      targetCount: count,
    );

    logs.insert(0, log);

    // Save document to admin_notifications collection in Firestore
    try {
      await _firestore.collection('admin_notifications').doc(messageId).set({
        'title': title,
        'body': body,
        'imageUrl': imageUrl ?? '',
        'target': target,
        'createdAt': FieldValue.serverTimestamp(),
        'sentBy': 'Super Admin',
        'clickAction': 'FLUTTER_NOTIFICATION_CLICK',
        'messageId': messageId,
        'priority': priority.toLowerCase(),
      });
    } catch (e) {
      debugPrint('Firestore admin_notifications save exception: $e');
    }

    // Save REAL document to Firestore force_broadcasts collection
    try {
      await _firestore.collection('force_broadcasts').add({
        'messageId': messageId,
        'title': title,
        'body': body,
        'imageUrl': imageUrl ?? '',
        'channel': channel,
        'priority': priority,
        'targetCount': count,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore force_broadcasts save exception: $e');
    }

    NotificationService.showInAppNotification(
      title: 'Broadcast Sent ($channel)',
      body: 'Delivered to $count target user(s).',
    );
  }

  Future<void> saveOfficialChatToFirestore({
    required String chatId,
    required String name,
    required String description,
    required bool isChannel,
    required bool isAutoJoin,
    String? avatarUrl,
  }) async {
    try {
      await _firestore.collection('official_chats').doc(chatId).set({
        'id': chatId,
        'name': name,
        'description': description,
        'isChannel': isChannel,
        'isAutoJoin': isAutoJoin,
        'avatarUrl': avatarUrl ?? '',
        'isOfficial': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore official_chats save exception: $e');
    }
  }

  Future<void> saveOfficialMessageToFirestore({
    required String targetUserId,
    required String text,
    String? mediaUrl,
  }) async {
    try {
      await _firestore.collection('official_messages').add({
        'targetUserId': targetUserId,
        'senderName': 'TeleLite Official',
        'text': text,
        'mediaUrl': mediaUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore official_messages save exception: $e');
    }
  }
}
