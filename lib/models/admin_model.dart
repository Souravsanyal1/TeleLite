class AdminStats {
  final int totalUsers;
  final int totalMessages;
  final int pendingReports;
  final int activeBlocks;
  final int usersToday;
  final int messagesToday;

  final int activeChannels;

  AdminStats({
    this.totalUsers = 1234,
    this.totalMessages = 5678,
    this.pendingReports = 12,
    this.activeBlocks = 23,
    this.usersToday = 23,
    this.messagesToday = 45,
    this.activeChannels = 0,
  });

  AdminStats copyWith({
    int? totalUsers,
    int? totalMessages,
    int? pendingReports,
    int? activeBlocks,
    int? usersToday,
    int? messagesToday,
    int? activeChannels,
  }) {
    return AdminStats(
      totalUsers: totalUsers ?? this.totalUsers,
      totalMessages: totalMessages ?? this.totalMessages,
      pendingReports: pendingReports ?? this.pendingReports,
      activeBlocks: activeBlocks ?? this.activeBlocks,
      usersToday: usersToday ?? this.usersToday,
      messagesToday: messagesToday ?? this.messagesToday,
      activeChannels: activeChannels ?? this.activeChannels,
    );
  }
}

class AdminUser {
  final String id;
  final String name;
  final String username;
  final String phone;
  final String avatarUrl;
  final String joinedTime;
  final int storiesCount;
  final bool isBlocked;
  final bool isOnline;
  final String? telegramChatId;

  AdminUser({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.avatarUrl,
    required this.joinedTime,
    this.storiesCount = 0,
    this.isBlocked = false,
    this.isOnline = true,
    this.telegramChatId,
  });

  AdminUser copyWith({
    String? id,
    String? name,
    String? username,
    String? phone,
    String? avatarUrl,
    String? joinedTime,
    int? storiesCount,
    bool? isBlocked,
    bool? isOnline,
    String? telegramChatId,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedTime: joinedTime ?? this.joinedTime,
      storiesCount: storiesCount ?? this.storiesCount,
      isBlocked: isBlocked ?? this.isBlocked,
      isOnline: isOnline ?? this.isOnline,
      telegramChatId: telegramChatId ?? this.telegramChatId,
    );
  }
}

class ReportItem {
  final String id;
  final String reporterName;
  final String reportedName;
  final String reason;
  final String contentSnippet;
  final String time;
  final String status; // 'pending', 'resolved', 'dismissed'

  ReportItem({
    required this.id,
    required this.reporterName,
    required this.reportedName,
    required this.reason,
    required this.contentSnippet,
    required this.time,
    this.status = 'pending',
  });

  ReportItem copyWith({
    String? id,
    String? reporterName,
    String? reportedName,
    String? reason,
    String? contentSnippet,
    String? time,
    String? status,
  }) {
    return ReportItem(
      id: id ?? this.id,
      reporterName: reporterName ?? this.reporterName,
      reportedName: reportedName ?? this.reportedName,
      reason: reason ?? this.reason,
      contentSnippet: contentSnippet ?? this.contentSnippet,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}

class NotificationLog {
  final String id;
  final String title;
  final String body;
  final String channel; // 'Telegram Bot', 'FCM Push'
  final String status; // 'Sent', 'Pending', 'Failed'
  final String timestamp;
  final int targetCount;

  NotificationLog({
    required this.id,
    required this.title,
    required this.body,
    required this.channel,
    required this.status,
    required this.timestamp,
    required this.targetCount,
  });
}
