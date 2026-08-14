
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/telegram_controller.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_notification_control_screen.dart';
import 'admin_profile_screen.dart';

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
    AdminProfileScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {'title': '1. User Count & Stats', 'icon': Icons.people_alt_rounded},
    {'title': '2. Force Broadcast (With Photo)', 'icon': Icons.campaign_rounded},
    {'title': '3. Admin Profile Settings', 'icon': Icons.person_outline_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final controller = TelegramController.to;
    final adminService = AdminService.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Obx(() {
      final profile = adminService.adminProfile.value;

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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 2),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: TeleTheme.primary,
                backgroundImage: profile.avatarUrl.startsWith('data:image')
                    ? MemoryImage(base64Decode(profile.avatarUrl.split(',').last)) as ImageProvider
                    : (profile.avatarUrl.startsWith('http') || profile.avatarUrl.startsWith('blob:'))
                        ? NetworkImage(profile.avatarUrl)
                        : null,
                child: profile.avatarUrl.isEmpty
                    ? Text(profile.name.isNotEmpty ? profile.name[0] : 'A',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12))
                    : null,
              ),
            ),
            const SizedBox(width: 16),
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
    });
  }

  Widget _buildSidebarContent(bool isDark) {
    final profile = AdminService.to.adminProfile.value;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      children: [
        // Admin Profile Sidebar Card
        GestureDetector(
          onTap: () {
            setState(() => _selectedIndex = 2);
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TeleTheme.primary.withAlpha(isDark ? 30 : 15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TeleTheme.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: TeleTheme.primary,
                  backgroundImage: profile.avatarUrl.startsWith('data:image')
                      ? MemoryImage(base64Decode(profile.avatarUrl.split(',').last)) as ImageProvider
                      : (profile.avatarUrl.startsWith('http') || profile.avatarUrl.startsWith('blob:'))
                          ? NetworkImage(profile.avatarUrl)
                          : null,
                  child: profile.avatarUrl.isEmpty
                      ? Text(
                          profile.name.isNotEmpty ? profile.name[0] : 'A',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile.title,
                        style: const TextStyle(
                          fontSize: 11,
                          color: TeleTheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
