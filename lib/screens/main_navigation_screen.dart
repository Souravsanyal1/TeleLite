import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import 'calls_screen.dart';
import 'chats_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final TelegramDataService dataService;
  final AuthService authService;

  const MainNavigationScreen({
    super.key,
    required this.dataService,
    required this.authService,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.dataService,
      builder: (context, _) {
        final totalUnread = widget.dataService.chats
            .fold<int>(0, (sum, chat) => sum + chat.unreadCount);

        final screens = [
          ChatsScreen(dataService: widget.dataService),
          CallsScreen(dataService: widget.dataService),
          ContactsScreen(
            dataService: widget.dataService,
            authService: widget.authService,
          ),
          SettingsScreen(
            dataService: widget.dataService,
            authService: widget.authService,
          ),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: totalUnread > 0,
                  label: Text(
                    totalUnread.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: TeleTheme.primary,
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                activeIcon: Badge(
                  isLabelVisible: totalUnread > 0,
                  label: Text(
                    totalUnread.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: TeleTheme.primary,
                  child: const Icon(Icons.chat_bubble),
                ),
                label: 'Chats',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.phone_outlined),
                activeIcon: Icon(Icons.phone),
                label: 'Calls',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Contacts',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
