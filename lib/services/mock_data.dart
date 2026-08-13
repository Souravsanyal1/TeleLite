import 'package:flutter/material.dart';
import '../models/models.dart';

class TelegramDataService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  final List<Chat> _chats = [
    Chat(
      id: '1',
      name: 'John Doe',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      lastMessage: 'Hey! Did you check out the new Telegram Lite UI spec?',
      time: '10:42 AM',
      unreadCount: 2,
      isOnline: true,
      isPinned: true,
      category: ChatCategory.personal,
    ),
    Chat(
      id: '2',
      name: 'Sky-Lite Dev Group',
      avatarUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=150',
      lastMessage: 'Alex: Fixed the SSE transport for Stitch MCP server!',
      time: '9:15 AM',
      unreadCount: 5,
      isGroup: true,
      isPinned: true,
      category: ChatCategory.work,
    ),
    Chat(
      id: '3',
      name: 'Sarah Connor',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      lastMessage: '🔒 Secret Chat established.',
      time: 'Yesterday',
      isSecret: true,
      isOnline: true,
      category: ChatCategory.personal,
    ),
    Chat(
      id: '4',
      name: 'Telegram News',
      avatarUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150',
      lastMessage: 'Telegram v10.8 update is now live with voice message transcription!',
      time: 'Yesterday',
      isVerified: true,
      category: ChatCategory.channels,
    ),
    Chat(
      id: '5',
      name: 'Michael Scott',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      lastMessage: 'That’s what she said! 😂',
      time: 'Aug 11',
      category: ChatCategory.personal,
    ),
    Chat(
      id: '6',
      name: 'Flutter Developers Community',
      avatarUrl: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=150',
      lastMessage: 'Dart 3.12 release notes are available. Check out records and patterns!',
      time: 'Aug 10',
      isGroup: true,
      category: ChatCategory.work,
    ),
  ];

  List<Chat> get chats => _chats;

  final Map<String, List<Message>> _chatMessages = {
    '1': [
      Message(
        id: 'm1',
        chatId: '1',
        senderName: 'John Doe',
        text: 'Hey there! How is the Telegram Lite project going?',
        time: '10:35 AM',
        isSentByMe: false,
      ),
      Message(
        id: 'm2',
        chatId: '1',
        senderName: 'Me',
        text: 'Going great! Built the UI in Flutter matching Stitch specs perfectly.',
        time: '10:38 AM',
        isSentByMe: true,
        isRead: true,
      ),
      Message(
        id: 'm3',
        chatId: '1',
        senderName: 'John Doe',
        text: 'Awesome! Did you check out the new Telegram Lite UI spec?',
        time: '10:42 AM',
        isSentByMe: false,
      ),
    ],
    '2': [
      Message(
        id: 'm4',
        chatId: '2',
        senderName: 'Alex',
        text: 'Fixed the SSE transport for Stitch MCP server!',
        time: '9:15 AM',
        isSentByMe: false,
      ),
    ],
    '3': [
      Message(
        id: 'm5',
        chatId: '3',
        senderName: 'Sarah Connor',
        text: '🔒 Secret Chat established.',
        time: 'Yesterday',
        isSentByMe: false,
      ),
    ],
  };

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
      time: '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      isSentByMe: true,
      isRead: false,
    );

    if (_chatMessages.containsKey(chatId)) {
      _chatMessages[chatId]!.add(newMsg);
    } else {
      _chatMessages[chatId] = [newMsg];
    }

    // Update last message in chat list
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

  final List<Contact> _contacts = [
    Contact(
      id: 'c1',
      name: 'Alex Rivera',
      phone: '+1 555-0192',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      isOnline: true,
    ),
    Contact(
      id: 'c2',
      name: 'Emma Watson',
      phone: '+1 555-0143',
      avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
      isOnline: true,
    ),
    Contact(
      id: 'c3',
      name: 'John Doe',
      phone: '+1 555-0182',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      isOnline: true,
    ),
    Contact(
      id: 'c4',
      name: 'Michael Scott',
      phone: '+1 555-0199',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      isOnline: false,
      lastSeen: '2 hours ago',
    ),
    Contact(
      id: 'c5',
      name: 'Sarah Connor',
      phone: '+1 555-0177',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      isOnline: true,
    ),
  ];

  List<Contact> get contacts => _contacts;

  final List<CallItem> _calls = [
    CallItem(
      id: 'cl1',
      name: 'John Doe',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      time: 'Today, 10:40 AM',
      isVideo: true,
      isOutgoing: true,
    ),
    CallItem(
      id: 'cl2',
      name: 'Sarah Connor',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      time: 'Yesterday, 8:12 PM',
      isVideo: false,
      isOutgoing: false,
      isMissed: true,
    ),
    CallItem(
      id: 'cl3',
      name: 'Alex Rivera',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      time: 'Aug 11, 4:20 PM',
      isVideo: false,
      isOutgoing: false,
    ),
  ];

  List<CallItem> get calls => _calls;
}
