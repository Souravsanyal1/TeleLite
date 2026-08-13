import 'package:flutter/material.dart';

import '../models/models.dart';

class TelegramDataService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  void setPremium(bool value) {
    _isPremium = value;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  final List<Chat> _chats = [];
  List<Chat> get chats => _chats;

  // In-memory member store: chatId -> list of GroupMember
  final Map<String, List<GroupMember>> _groupMembers = {};

  List<GroupMember> getMembersForChat(String chatId) {
    return _groupMembers[chatId] ?? [];
  }

  final Map<String, List<Message>> _chatMessages = {};

  List<Message> getMessagesForChat(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  void sendMessage(String chatId, String text, {String? mediaUrl}) {
    if (text.trim().isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) return;

    final newMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderName: 'Me',
      text: text.trim(),
      time:
          '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      isSentByMe: true,
      isRead: false,
      mediaUrl: mediaUrl,
    );

    if (_chatMessages.containsKey(chatId)) {
      _chatMessages[chatId]!.add(newMsg);
    } else {
      _chatMessages[chatId] = [newMsg];
    }

    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final old = _chats[index];
      _chats[index] = old.copyWith(
        lastMessage: text.trim(),
        time: newMsg.time,
        unreadCount: 0,
      );
    }

    notifyListeners();
  }

  void clearChatMessages(String chatId) {
    _chatMessages[chatId] = [];
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      _chats[index] = _chats[index].copyWith(
        lastMessage: 'Chat history cleared',
      );
    }
    notifyListeners();
  }

  /// Create a new Group chat with selected members
  Chat createGroupChat({
    required String name,
    required String avatarUrl,
    String? description,
    List<Contact> members = const [],
  }) {
    final chatId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final inviteLink = 'telelite.app/joinchat/${chatId.substring(6, 14)}';

    final memberIds = members.map((m) => m.id).toList();
    final memberObjects = members.map((m) => GroupMember(
          id: m.id,
          name: m.name,
          avatarUrl: m.avatarUrl,
          username: m.username,
          isOnline: m.isOnline,
        )).toList();

    // Add current user as owner/admin
    memberObjects.insert(0, GroupMember(
      id: 'me',
      name: 'You',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      isAdmin: true,
      isOwner: true,
      isOnline: true,
    ));

    final newChat = Chat(
      id: chatId,
      name: name,
      avatarUrl: avatarUrl.isNotEmpty
          ? avatarUrl
          : 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=150',
      lastMessage: description?.isNotEmpty == true ? description! : 'Group created',
      time: 'Just now',
      isGroup: true,
      category: ChatCategory.work,
      ownerId: 'me',
      memberIds: ['me', ...memberIds],
      adminIds: ['me'],
      description: description,
      inviteLink: inviteLink,
      memberCount: memberObjects.length,
    );
    _chats.insert(0, newChat);
    _groupMembers[chatId] = memberObjects;
    _chatMessages[chatId] = [
      Message(
        id: 'init_$chatId',
        chatId: chatId,
        senderName: 'System',
        text: 'Group "$name" was created. ${memberObjects.length} members.',
        time: 'Just now',
        isSentByMe: false,
      ),
    ];
    notifyListeners();
    return newChat;
  }

  /// Create a new Channel
  Chat createChannelChat({
    required String name,
    required String description,
    String? username,
    String avatarUrl = '',
  }) {
    final chatId = 'channel_${DateTime.now().millisecondsSinceEpoch}';
    final inviteLink = username != null && username.isNotEmpty
        ? 'telelite.app/$username'
        : 'telelite.app/joinchat/${chatId.substring(8, 16)}';

    final newChat = Chat(
      id: chatId,
      name: name,
      avatarUrl: avatarUrl.isNotEmpty
          ? avatarUrl
          : 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150',
      lastMessage: description.isNotEmpty ? description : 'Channel created',
      time: 'Just now',
      isVerified: true,
      isChannel: true,
      category: ChatCategory.channels,
      ownerId: 'me',
      memberIds: ['me'],
      adminIds: ['me'],
      username: username,
      description: description,
      inviteLink: inviteLink,
      memberCount: 1,
    );
    _chats.insert(0, newChat);
    _groupMembers[chatId] = [
      GroupMember(
        id: 'me',
        name: 'You',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        isAdmin: true,
        isOwner: true,
        isOnline: true,
      ),
    ];
    _chatMessages[chatId] = [
      Message(
        id: 'init_$chatId',
        chatId: chatId,
        senderName: name,
        text: 'Welcome to $name channel!',
        time: 'Just now',
        isSentByMe: false,
      ),
    ];
    notifyListeners();
    return newChat;
  }

  /// Update group/channel info
  void updateGroupInfo(
    String chatId, {
    String? name,
    String? avatarUrl,
    String? username,
    String? description,
  }) {
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index == -1) return;
    _chats[index] = _chats[index].copyWith(
      name: name,
      avatarUrl: avatarUrl,
      username: username,
      description: description,
    );
    notifyListeners();
  }

  /// Add members to a group
  void addMembersToGroup(String chatId, List<Contact> newMembers) {
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index == -1) return;

    final existing = _groupMembers[chatId] ?? [];
    final existingIds = existing.map((m) => m.id).toSet();

    final toAdd = newMembers
        .where((m) => !existingIds.contains(m.id))
        .map((m) => GroupMember(
              id: m.id,
              name: m.name,
              avatarUrl: m.avatarUrl,
              username: m.username,
              isOnline: m.isOnline,
            ))
        .toList();

    if (toAdd.isEmpty) return;

    _groupMembers[chatId] = [...existing, ...toAdd];
    final newMemberIds = [
      ..._chats[index].memberIds,
      ...toAdd.map((m) => m.id),
    ];
    _chats[index] = _chats[index].copyWith(
      memberIds: newMemberIds,
      memberCount: newMemberIds.length,
    );

    final names = toAdd.map((m) => m.name).join(', ');
    _chatMessages[chatId] ??= [];
    _chatMessages[chatId]!.add(Message(
      id: 'add_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderName: 'System',
      text: '$names joined the group.',
      time:
          '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      isSentByMe: false,
    ));

    notifyListeners();
  }

  /// Remove a member from a group
  void removeMemberFromGroup(String chatId, String memberId) {
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index == -1) return;

    final members = _groupMembers[chatId] ?? [];
    final removed = members.firstWhere(
      (m) => m.id == memberId,
      orElse: () => GroupMember(id: memberId, name: 'Member', avatarUrl: ''),
    );

    _groupMembers[chatId] = members.where((m) => m.id != memberId).toList();
    final newIds = _chats[index].memberIds.where((id) => id != memberId).toList();
    _chats[index] = _chats[index].copyWith(
      memberIds: newIds,
      memberCount: newIds.length,
    );

    _chatMessages[chatId] ??= [];
    _chatMessages[chatId]!.add(Message(
      id: 'remove_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderName: 'System',
      text: '${removed.name} was removed from the group.',
      time:
          '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      isSentByMe: false,
    ));

    notifyListeners();
  }

  /// Promote a member to admin
  void promoteToAdmin(String chatId, String memberId) {
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index == -1) return;
    final newAdmins = [..._chats[index].adminIds, memberId];
    _chats[index] = _chats[index].copyWith(adminIds: newAdmins);

    final members = _groupMembers[chatId] ?? [];
    _groupMembers[chatId] = members.map((m) {
      if (m.id == memberId) {
        return GroupMember(
          id: m.id,
          name: m.name,
          avatarUrl: m.avatarUrl,
          username: m.username,
          isOnline: m.isOnline,
          isAdmin: true,
          isOwner: m.isOwner,
        );
      }
      return m;
    }).toList();

    notifyListeners();
  }

  Chat createSecretChat({required String name, required String avatarUrl}) {
    final newChat = Chat(
      id: 'secret_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      avatarUrl: avatarUrl.isNotEmpty
          ? avatarUrl
          : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      lastMessage: '🔒 Secret Chat established',
      time: 'Just now',
      isSecret: true,
      isOnline: true,
      isPremium: _isPremium,
      isStealthMode: false,
      disableSharing: false,
      category: ChatCategory.personal,
    );
    _chats.insert(0, newChat);
    _chatMessages[newChat.id] = [
      Message(
        id: 'init_${newChat.id}',
        chatId: newChat.id,
        senderName: 'System',
        text: '🔒 End-to-end encrypted secret chat established with $name.',
        time: 'Just now',
        isSentByMe: false,
      ),
    ];
    notifyListeners();
    return newChat;
  }

  void addContact(Contact contact) {
    if (!_contacts.any((c) => c.phone == contact.phone || c.id == contact.id)) {
      _contacts.insert(0, contact);
      notifyListeners();
    }
  }

  final List<Contact> _contacts = [];
  List<Contact> get contacts => _contacts;

  final List<CallItem> _calls = [];
  List<CallItem> get calls => _calls;
}
