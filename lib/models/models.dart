enum ChatCategory { all, personal, work, unread, channels }

class Chat {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool isGroup;
  final bool isSecret;
  final bool isVerified;
  final bool isPinned;
  final ChatCategory category;

  Chat({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isGroup = false,
    this.isSecret = false,
    this.isVerified = false,
    this.isPinned = false,
    this.category = ChatCategory.personal,
  });
}

class Message {
  final String id;
  final String chatId;
  final String senderName;
  final String text;
  final String time;
  final bool isSentByMe;
  final bool isRead;
  final String? mediaUrl;

  Message({
    required this.id,
    required this.chatId,
    required this.senderName,
    required this.text,
    required this.time,
    required this.isSentByMe,
    this.isRead = true,
    this.mediaUrl,
  });
}

class Contact {
  final String id;
  final String name;
  final String phone;
  final String avatarUrl;
  final bool isOnline;
  final String lastSeen;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatarUrl,
    this.isOnline = false,
    this.lastSeen = 'Recently',
  });
}

class CallItem {
  final String id;
  final String name;
  final String avatarUrl;
  final String time;
  final bool isVideo;
  final bool isOutgoing;
  final bool isMissed;

  CallItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.time,
    this.isVideo = false,
    this.isOutgoing = true,
    this.isMissed = false,
  });
}
