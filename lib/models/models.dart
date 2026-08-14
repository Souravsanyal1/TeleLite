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
  final bool isChannel;
  final bool isSecret;
  final bool isVerified;
  final bool isPinned;
  final bool isPremium;
  final bool isStealthMode;
  final bool disableSharing;
  final String? profileColor;
  final String? emojiStatus;
  final ChatCategory category;
  // Group/Channel management
  final String? ownerId;
  final List<String> memberIds;
  final List<String> adminIds;
  final String? username;
  final String? description;
  final String? inviteLink;
  final int memberCount;

  Chat({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isGroup = false,
    this.isChannel = false,
    this.isSecret = false,
    this.isVerified = false,
    this.isPinned = false,
    this.isPremium = false,
    this.isStealthMode = false,
    this.disableSharing = false,
    this.profileColor,
    this.emojiStatus,
    this.category = ChatCategory.personal,
    this.ownerId,
    this.memberIds = const [],
    this.adminIds = const [],
    this.username,
    this.description,
    this.inviteLink,
    this.memberCount = 0,
  });

  Chat copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? lastMessage,
    String? time,
    int? unreadCount,
    bool? isOnline,
    bool? isGroup,
    bool? isChannel,
    bool? isSecret,
    bool? isVerified,
    bool? isPinned,
    bool? isPremium,
    bool? isStealthMode,
    bool? disableSharing,
    String? profileColor,
    String? emojiStatus,
    ChatCategory? category,
    String? ownerId,
    List<String>? memberIds,
    List<String>? adminIds,
    String? username,
    String? description,
    String? inviteLink,
    int? memberCount,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      isGroup: isGroup ?? this.isGroup,
      isChannel: isChannel ?? this.isChannel,
      isSecret: isSecret ?? this.isSecret,
      isVerified: isVerified ?? this.isVerified,
      isPinned: isPinned ?? this.isPinned,
      isPremium: isPremium ?? this.isPremium,
      isStealthMode: isStealthMode ?? this.isStealthMode,
      disableSharing: disableSharing ?? this.disableSharing,
      profileColor: profileColor ?? this.profileColor,
      emojiStatus: emojiStatus ?? this.emojiStatus,
      category: category ?? this.category,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      username: username ?? this.username,
      description: description ?? this.description,
      inviteLink: inviteLink ?? this.inviteLink,
      memberCount: memberCount ?? this.memberCount,
    );
  }
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
  final bool isPremium;
  final bool isStealthMode;
  final String? profileColor;
  final String? emojiStatus;
  final String lastSeen;
  final String? username;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatarUrl,
    this.isOnline = false,
    this.isPremium = false,
    this.isStealthMode = false,
    this.profileColor,
    this.emojiStatus,
    this.lastSeen = 'Recently',
    this.username,
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

class AdminRights {
  final bool canChangeInfo;
  final bool canPostMessages;
  final bool canEditMessages;
  final bool canDeleteMessages;
  final bool canBanUsers;
  final bool canInviteUsers;
  final bool canPinMessages;
  final bool canManageCalls;
  final bool canAddAdmins;

  AdminRights({
    this.canChangeInfo = true,
    this.canPostMessages = true,
    this.canEditMessages = true,
    this.canDeleteMessages = true,
    this.canBanUsers = true,
    this.canInviteUsers = true,
    this.canPinMessages = true,
    this.canManageCalls = true,
    this.canAddAdmins = false,
  });

  AdminRights copyWith({
    bool? canChangeInfo,
    bool? canPostMessages,
    bool? canEditMessages,
    bool? canDeleteMessages,
    bool? canBanUsers,
    bool? canInviteUsers,
    bool? canPinMessages,
    bool? canManageCalls,
    bool? canAddAdmins,
  }) {
    return AdminRights(
      canChangeInfo: canChangeInfo ?? this.canChangeInfo,
      canPostMessages: canPostMessages ?? this.canPostMessages,
      canEditMessages: canEditMessages ?? this.canEditMessages,
      canDeleteMessages: canDeleteMessages ?? this.canDeleteMessages,
      canBanUsers: canBanUsers ?? this.canBanUsers,
      canInviteUsers: canInviteUsers ?? this.canInviteUsers,
      canPinMessages: canPinMessages ?? this.canPinMessages,
      canManageCalls: canManageCalls ?? this.canManageCalls,
      canAddAdmins: canAddAdmins ?? this.canAddAdmins,
    );
  }
}

/// A simple member model for group/channel membership display
class GroupMember {
  final String id;
  final String name;
  final String avatarUrl;
  final String? username;
  final bool isAdmin;
  final bool isOwner;
  final bool isOnline;
  final AdminRights? rights;

  GroupMember({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.username,
    this.isAdmin = false,
    this.isOwner = false,
    this.isOnline = false,
    this.rights,
  });
}
