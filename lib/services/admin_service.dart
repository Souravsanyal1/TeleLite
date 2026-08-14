import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/admin_model.dart';
import 'notification_service.dart';
import 'telegram_bot_service.dart';

class AdminService extends GetxController {
  static AdminService get to => Get.isRegistered<AdminService>()
      ? Get.find<AdminService>()
      : Get.put(AdminService(), permanent: true);

  final Rx<AdminStats> stats = AdminStats().obs;
  final RxList<AdminUser> users = <AdminUser>[].obs;
  final RxList<ReportItem> reports = <ReportItem>[].obs;
  final RxList<NotificationLog> logs = <NotificationLog>[].obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  void _loadInitialData() {
    users.assignAll([
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
      AdminUser(
        id: 'u3',
        name: 'Jane Smith',
        username: 'jane_s',
        phone: '+880 1913 998877',
        avatarUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        joinedTime: '1 week ago',
        storiesCount: 8,
        isBlocked: true,
        isOnline: false,
      ),
      AdminUser(
        id: 'u4',
        name: 'Alex Rivera',
        username: 'alex_r',
        phone: '+880 1614 554433',
        avatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        joinedTime: '2 weeks ago',
        storiesCount: 1,
        isBlocked: false,
        isOnline: true,
        telegramChatId: '456789123',
      ),
    ]);

    reports.assignAll([
      ReportItem(
        id: 'r1',
        reporterName: 'John Doe',
        reportedName: 'Jane Smith',
        reason: 'Spamming in channel',
        contentSnippet: 'Buy crypto now at discounted price!',
        time: '10 mins ago',
      ),
      ReportItem(
        id: 'r2',
        reporterName: 'Sarah Connor',
        reportedName: 'Alex Rivera',
        reason: 'Inappropriate media',
        contentSnippet: 'Flagged story content',
        time: '1 hour ago',
      ),
    ]);

    logs.assignAll([
      NotificationLog(
        id: 'l1',
        title: '📢 System Maintenance',
        body: 'TeleLite will undergo maintenance tonight at 12:00 AM.',
        channel: 'FCM Push',
        status: 'Sent',
        timestamp: '10:30 AM',
        targetCount: 1234,
      ),
      NotificationLog(
        id: 'l2',
        title: '🚨 High Traffic Alert',
        body: 'High server load detected on Realtime Gateway.',
        channel: 'Telegram Bot',
        status: 'Sent',
        timestamp: '09:15 AM',
        targetCount: 4,
      ),
    ]);
  }

  void toggleUserBlock(String userId) {
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final user = users[idx];
      final newStatus = !user.isBlocked;
      users[idx] = user.copyWith(isBlocked: newStatus);

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
        details: 'User: ${user.name} (@${user.username})\nStatus: ${newStatus ? "Blocked" : "Active"}',
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
  }) async {
    final count = targetUserIds.isEmpty ? users.length : targetUserIds.length;

    if (channel.contains('Telegram')) {
      await TelegramBotService().broadcastAdminAlert(
        title: title,
        details: body,
      );
    }

    final log = NotificationLog(
      id: 'l_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      channel: channel,
      status: 'Sent',
      timestamp:
          '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      targetCount: count,
    );

    logs.insert(0, log);

    NotificationService.showInAppNotification(
      title: 'Broadcast Sent ($channel)',
      body: 'Delivered to $count target user(s).',
    );
  }
}
