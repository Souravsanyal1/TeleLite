import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/telegram_controller.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_notification_control_screen.dart';

class AdminNavigationScreen extends StatefulWidget {
  const AdminNavigationScreen({super.key});

  @override
  State<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AdminNotificationControlScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {'title': '1. User Count & Stats', 'icon': Icons.people_alt_rounded},
    {'title': '2. Force Broadcast (With Photo)', 'icon': Icons.campaign_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final controller = TelegramController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: TeleTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'TeleLite Admin Panel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: 'Toggle Theme',
            onPressed: () => controller.toggleTheme(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: _buildSidebarContent(isDark),
            ),
      body: Row(
        children: [
          // Sidebar Drawer for Desktop view
          if (isDesktop)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151D2A) : Colors.grey[50],
                border: Border(
                  right: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
              ),
              child: _buildSidebarContent(isDark),
            ),

          // Main Page Content Area
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'TELELITE ADMIN CONTROLS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Navigation Items List
        ...List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          final isSelected = _selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              selected: isSelected,
              selectedTileColor: TeleTheme.primary.withAlpha(isDark ? 50 : 25),
              leading: Icon(
                item['icon'] as IconData,
                color: isSelected
                    ? TeleTheme.primary
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              title: Text(
                item['title'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? TeleTheme.primary
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              onTap: () {
                setState(() => _selectedIndex = index);
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          );
        }),

        const Divider(height: 32),

        // Telegram Bot Guardian Badge
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(isDark ? 40 : 20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withAlpha(80)),
          ),
          child: const Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.blue, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@TeleLiteGuardianBot',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    Text(
                      '🟢 Bot API Connected',
                      style: TextStyle(fontSize: 10, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
