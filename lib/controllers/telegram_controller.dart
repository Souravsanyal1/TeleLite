import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/models.dart';

class TelegramController extends GetxController {
  static TelegramController get to => Get.isRegistered<TelegramController>()
      ? Get.find<TelegramController>()
      : Get.put(TelegramController(), permanent: true);

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;
  final RxBool isPremium = false.obs;

  final RxList<Chat> chats = <Chat>[].obs;
  final RxMap<String, List<GroupMember>> groupMembers = <String, List<GroupMember>>{}.obs;
  final RxMap<String, List<Message>> chatMessages = <String, List<Message>>{}.obs;
  final RxList<Contact> contacts = <Contact>[].obs;
  final RxList<CallItem> calls = <CallItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initDefaultData();
  }

  void setPremium(bool value) {
    isPremium.value = value;
  }

  void toggleTheme() {
    themeMode.value =
        themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void _initDefaultData() {
    final defaultChats = [
      Chat(
        id: 'telelite_support',
        name: 'TeleLite Official',
        avatarUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150',
        lastMessage: 'Welcome to TeleLite! Fast, secure & cloud-based messaging. 🚀',
        time: '10:30',
        unreadCount: 1,
        isVerified: true,
        isOnline: true,
        category: ChatCategory.all,
      ),
      Chat(
        id: 'sarah_connor',
        name: 'Sarah Connor',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        lastMessage: 'Hey! Did you check out the new TeleLite feature?',
        time: 'Yesterday',
        isOnline: true,
        category: ChatCategory.personal,
      ),
      Chat(
        id: 'flutter_devs',
        name: 'Flutter Developers',
        avatarUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=150',
        lastMessage: 'Alex: The new UI looks super clean and responsive!',
        time: 'Yesterday',
        isGroup: true,
        memberCount: 42,
        category: ChatCategory.work,
      ),
      Chat(
        id: 'tech_news',
        name: 'Tech & AI News',
        avatarUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=150',
        lastMessage: '📢 Gemini AI models now powered with live cloud processing.',
        time: 'Aug 12',
        isChannel: true,
        isVerified: true,
        memberCount: 1240,
        category: ChatCategory.channels,
      ),
    ];

    chats.assignAll(defaultChats);

    chatMessages['telelite_support'] = [
      Message(
        id: 'm1',
        chatId: 'telelite_support',
        senderName: 'TeleLite Official',
        text: 'Welcome to TeleLite! Fast, secure & cloud-based messaging. 🚀',
        time: '10:30',
        isSentByMe: false,
      ),
    ];

    chatMessages['sarah_connor'] = [
      Message(
        id: 'm2',
        chatId: 'sarah_connor',
        senderName: 'Sarah Connor',
        text: 'Hey! Did you check out the new TeleLite feature?',
        time: 'Yesterday',
        isSentByMe: false,
      ),
    ];

    chatMessages['flutter_devs'] = [
      Message(
        id: 'm3',
        chatId: 'flutter_devs',
        senderName: 'Alex',
        text: 'The new UI looks super clean and responsive!',
        time: 'Yesterday',
        isSentByMe: false,
      ),
    ];

    chatMessages['tech_news'] = [
      Message(
        id: 'm4',
        chatId: 'tech_news',
        senderName: 'Tech & AI News',
        text: '📢 Gemini AI models now powered with live cloud processing.',
        time: 'Aug 12',
        isSentByMe: false,
      ),
    ];

    contacts.assignAll([
      Contact(
        id: 'sarah_connor',
        name: 'Sarah Connor',
        phone: '+880 1711 112233',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        isOnline: true,
      ),
      Contact(
        id: 'john_doe',
        name: 'John Doe',
        phone: '+880 1812 345678',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        isOnline: false,
      ),
    ]);
  }

  List<GroupMember> getMembersForChat(String chatId) {
    return groupMembers[chatId] ?? [];
  }

  List<Message> getMessagesForChat(String chatId) {
    return chatMessages[chatId] ?? [];
  }

  void markChatAsRead(String chatId) {
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1 && chats[index].unreadCount > 0) {
      chats[index] = chats[index].copyWith(unreadCount: 0);
      chats.refresh();
    }
  }

  void ensureChatExists(Chat chat) {
    final index = chats.indexWhere((c) => c.id == chat.id);
    if (index == -1) {
      chats.insert(0, chat);
    }
  }

  Chat getOrCreateChatForContact(Contact contact) {
    final index = chats.indexWhere((c) => c.id == contact.id || c.name == contact.name);
    if (index != -1) {
      final existingChat = chats.removeAt(index);
      chats.insert(0, existingChat);
      return existingChat;
    }

    final newChat = Chat(
      id: contact.id.isNotEmpty ? contact.id : 'chat_${DateTime.now().millisecondsSinceEpoch}',
      name: contact.name,
      avatarUrl: contact.avatarUrl,
      lastMessage: 'Tap to send a message',
      time: 'Just now',
      isOnline: contact.isOnline,
      category: ChatCategory.personal,
    );

    chats.insert(0, newChat);
    return newChat;
  }

  void sendMessage(String chatId, String text, {String? mediaUrl, Chat? fallbackChat}) {
    if (text.trim().isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) return;

    final nowTime =
        '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}';

    final newMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderName: 'Me',
      text: text.trim(),
      time: nowTime,
      isSentByMe: true,
      isRead: false,
      mediaUrl: mediaUrl,
    );

    if (chatMessages.containsKey(chatId)) {
      chatMessages[chatId]!.add(newMsg);
      chatMessages.refresh();
    } else {
      chatMessages[chatId] = [newMsg];
    }

    final index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final old = chats.removeAt(index);
      chats.insert(
        0,
        old.copyWith(
          lastMessage: text.trim().isNotEmpty ? text.trim() : '📷 Photo',
          time: nowTime,
          unreadCount: 0,
        ),
      );
    } else if (fallbackChat != null) {
      chats.insert(
        0,
        fallbackChat.copyWith(
          lastMessage: text.trim().isNotEmpty ? text.trim() : '📷 Photo',
          time: nowTime,
          unreadCount: 0,
        ),
      );
    }
  }

  void clearChatMessages(String chatId) {
    chatMessages[chatId] = [];
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      chats[index] = chats[index].copyWith(
        lastMessage: 'Chat history cleared',
      );
      chats.refresh();
    }
  }

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

    chats.insert(0, newChat);
    groupMembers[chatId] = memberObjects;
    chatMessages[chatId] = [
      Message(
        id: 'init_$chatId',
        chatId: chatId,
        senderName: 'System',
        text: 'Group "$name" was created. ${memberObjects.length} members.',
        time: 'Just now',
        isSentByMe: false,
      ),
    ];
    return newChat;
  }

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

    chats.insert(0, newChat);
    groupMembers[chatId] = [
      GroupMember(
        id: 'me',
        name: 'You',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        isAdmin: true,
        isOwner: true,
        isOnline: true,
      ),
    ];
    chatMessages[chatId] = [
      Message(
        id: 'init_$chatId',
        chatId: chatId,
        senderName: name,
        text: 'Welcome to $name channel!',
        time: 'Just now',
        isSentByMe: false,
      ),
    ];
    return newChat;
  }

  void updateGroupInfo(
    String chatId, {
    String? name,
    String? avatarUrl,
    String? username,
    String? description,
  }) {
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index == -1) return;
    chats[index] = chats[index].copyWith(
      name: name,
      avatarUrl: avatarUrl,
      username: username,
      description: description,
    );
    chats.refresh();
  }

  void addMembersToGroup(String chatId, List<Contact> newMembers) {
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index == -1) return;

    final existing = groupMembers[chatId] ?? [];
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

    groupMembers[chatId] = [...existing, ...toAdd];
    final newMemberIds = [
      ...chats[index].memberIds,
      ...toAdd.map((m) => m.id),
    ];
    chats[index] = chats[index].copyWith(
      memberIds: newMemberIds,
      memberCount: newMemberIds.length,
    );

    final names = toAdd.map((m) => m.name).join(', ');
    chatMessages[chatId] ??= [];
    chatMessages[chatId]!.add(Message(
      id: 'add_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderName: 'System',
      text: '$names joined the group.',
      time:
          '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      isSentByMe: false,
    ));

    chats.refresh();
  }

  void removeMemberFromGroup(String chatId, String memberId) {
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index == -1) return;

    final members = groupMembers[chatId] ?? [];
    final removed = members.firstWhere(
      (m) => m.id == memberId,
      orElse: () => GroupMember(id: memberId, name: 'Member', avatarUrl: ''),
    );

    groupMembers[chatId] = members.where((m) => m.id != memberId).toList();
    final newIds = chats[index].memberIds.where((id) => id != memberId).toList();
    chats[index] = chats[index].copyWith(
      memberIds: newIds,
      memberCount: newIds.length,
    );

    chatMessages[chatId] ??= [];
    chatMessages[chatId]!.add(Message(
      id: 'remove_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderName: 'System',
      text: '${removed.name} was removed from the group.',
      time:
          '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      isSentByMe: false,
    ));

    chats.refresh();
  }

  void promoteToAdmin(String chatId, String memberId, {AdminRights? rights}) {
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index == -1) return;
    final newAdmins = [...chats[index].adminIds, memberId];
    chats[index] = chats[index].copyWith(adminIds: newAdmins);

    final members = groupMembers[chatId] ?? [];
    groupMembers[chatId] = members.map((m) {
      if (m.id == memberId) {
        return GroupMember(
          id: m.id,
          name: m.name,
          avatarUrl: m.avatarUrl,
          username: m.username,
          isOnline: m.isOnline,
          isAdmin: true,
          isOwner: m.isOwner,
          rights: rights ?? AdminRights(),
        );
      }
      return m;
    }).toList();

    chats.refresh();
  }

  void updateAdminRights(String chatId, String memberId, AdminRights rights) {
    promoteToAdmin(chatId, memberId, rights: rights);
  }

  void dismissAdmin(String chatId, String memberId) {
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index == -1) return;
    final newAdmins = chats[index].adminIds.where((id) => id != memberId).toList();
    chats[index] = chats[index].copyWith(adminIds: newAdmins);

    final members = groupMembers[chatId] ?? [];
    groupMembers[chatId] = members.map((m) {
      if (m.id == memberId) {
        return GroupMember(
          id: m.id,
          name: m.name,
          avatarUrl: m.avatarUrl,
          username: m.username,
          isOnline: m.isOnline,
          isAdmin: false,
          isOwner: m.isOwner,
          rights: null,
        );
      }
      return m;
    }).toList();

    chats.refresh();
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
      isPremium: isPremium.value,
      isStealthMode: false,
      disableSharing: false,
      category: ChatCategory.personal,
    );
    chats.insert(0, newChat);
    chatMessages[newChat.id] = [
      Message(
        id: 'init_${newChat.id}',
        chatId: newChat.id,
        senderName: 'System',
        text: '🔒 End-to-end encrypted secret chat established with $name.',
        time: 'Just now',
        isSentByMe: false,
      ),
    ];
    return newChat;
  }

  void addContact(Contact contact) {
    if (!contacts.any((c) => c.phone == contact.phone || c.id == contact.id)) {
      contacts.insert(0, contact);
    }
  }
}
