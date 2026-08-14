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
  final bool isPremium;
  final DateTime? premiumExpiry;

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
    this.isPremium = false,
    this.premiumExpiry,
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
    bool? isPremium,
    DateTime? premiumExpiry,
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
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
    );
  }

  /// Check if premium is still active (not expired)
  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiry == null) return isPremium; // lifetime
    return DateTime.now().isBefore(premiumExpiry!);
  }

  /// Remaining premium time as human-readable string
  String get premiumRemainingText {
    if (!isPremiumActive) return 'Expired';
    if (premiumExpiry == null) return 'Lifetime';
    final diff = premiumExpiry!.difference(DateTime.now());
    if (diff.inHours >= 1) return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    return '${diff.inMinutes}m left';
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

class AdminProfile {
  final String name;
  final String title;
  final String email;
  final String phone;
  final String avatarUrl;
  final String telegramBotToken;
  final String telegramChatId;
  final bool isSuperAdmin;

  AdminProfile({
    this.name = 'Super Admin (Kirito)',
    this.title = 'Chief System Administrator',
    this.email = 'kirito231411@gmail.com',
    this.phone = '+880 1711 000000',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    this.telegramBotToken =
        '8553809069:AAHmbtMKsyLp0lT8oppp3kW5EVH4NsHvCeE',
    this.telegramChatId = '8553809069',
    this.isSuperAdmin = true,
  });

  AdminProfile copyWith({
    String? name,
    String? title,
    String? email,
    String? phone,
    String? avatarUrl,
    String? telegramBotToken,
    String? telegramChatId,
    bool? isSuperAdmin,
  }) {
    return AdminProfile(
      name: name ?? this.name,
      title: title ?? this.title,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'title': title,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'telegramBotToken': telegramBotToken,
      'telegramChatId': telegramChatId,
      'isSuperAdmin': isSuperAdmin,
    };
  }

  factory AdminProfile.fromMap(Map<String, dynamic> map) {
    return AdminProfile(
      name: (map['name'] ?? 'Super Admin (Kirito)').toString(),
      title: (map['title'] ?? 'Chief System Administrator').toString(),
      email: (map['email'] ?? 'kirito231411@gmail.com').toString(),
      phone: (map['phone'] ?? '+880 1711 000000').toString(),
      avatarUrl: (map['avatarUrl'] ??
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150')
          .toString(),
      telegramBotToken: (map['telegramBotToken'] ??
              '8553809069:AAHmbtMKsyLp0lT8oppp3kW5EVH4NsHvCeE')
          .toString(),
      telegramChatId: (map['telegramChatId'] ?? '8553809069').toString(),
      isSuperAdmin: map['isSuperAdmin'] != false,
    );
  }
}
