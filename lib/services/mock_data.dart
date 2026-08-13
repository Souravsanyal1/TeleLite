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

  final Map<String, List<Message>> _chatMessages = {};

  List<Message> getMessagesForChat(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  void sendMessage(String chatId, String text) {
    if (text.trim().isEmpty) return;

    final newMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderName: 'Me',
      text: text.trim(),
      time:
          '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      isSentByMe: true,
      isRead: false,
    );

    if (_chatMessages.containsKey(chatId)) {
      _chatMessages[chatId]!.add(newMsg);
    } else {
      _chatMessages[chatId] = [newMsg];
    }

    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final oldChat = _chats[index];
      _chats[index] = Chat(
        id: oldChat.id,
        name: oldChat.name,
        avatarUrl: oldChat.avatarUrl,
        lastMessage: text.trim(),
        time: newMsg.time,
        unreadCount: 0,
        isOnline: oldChat.isOnline,
        isGroup: oldChat.isGroup,
        isSecret: oldChat.isSecret,
        isVerified: oldChat.isVerified,
        isPinned: oldChat.isPinned,
        category: oldChat.category,
      );
    }

    notifyListeners();
  }

  Chat createGroupChat({required String name, required String avatarUrl}) {
    final newChat = Chat(
      id: 'group_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      avatarUrl: avatarUrl.isNotEmpty
          ? avatarUrl
          : 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=150',
      lastMessage: 'Group created',
      time: 'Just now',
      isGroup: true,
      category: ChatCategory.work,
    );
    _chats.insert(0, newChat);
    _chatMessages[newChat.id] = [
      Message(
        id: 'init_${newChat.id}',
        chatId: newChat.id,
        senderName: 'System',
        text: 'Group "$name" was created.',
        time: 'Just now',
        isSentByMe: false,
      ),
    ];
    notifyListeners();
    return newChat;
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

  Chat createChannelChat({required String name, required String description}) {
    final newChat = Chat(
      id: 'channel_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      avatarUrl:
          'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150',
      lastMessage: description.isNotEmpty ? description : 'Channel created',
      time: 'Just now',
      isVerified: true,
      category: ChatCategory.channels,
    );
    _chats.insert(0, newChat);
    _chatMessages[newChat.id] = [
      Message(
        id: 'init_${newChat.id}',
        chatId: newChat.id,
        senderName: name,
        text: 'Welcome to $name channel!',
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
