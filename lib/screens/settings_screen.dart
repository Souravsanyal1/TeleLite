import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import 'settings/chat_folders_screen.dart';
import 'settings/data_storage_screen.dart';
import 'settings/devices_screen.dart';
import 'settings/language_screen.dart';
import 'settings/notifications_screen.dart';
import 'settings/privacy_screen.dart';
import 'settings/proxy_screen.dart';
import 'settings/saved_messages_screen.dart';

import 'user_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  final TelegramDataService dataService;
  final AuthService authService;

  const SettingsScreen({
    super.key,
    required this.dataService,
    required this.authService,
  });

  void _openCurrentUserProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          isCurrentUser: true,
          authService: authService,
          dataService: dataService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = authService.currentUser;

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => dataService.toggleTheme(),
                tooltip: 'Toggle Theme',
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _openCurrentUserProfile(context),
                tooltip: 'View / Edit Profile',
              ),
            ],
          ),
          body: ListView(
            children: [
              // User Profile Header Card from Firestore
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                stream: authService.userProfileStream,
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final name = data?['displayName'] ?? currentUser?.displayName ?? 'TeleLite User';
                  final phone = data?['phoneNumber'] ?? currentUser?.phoneNumber ?? '+880 1XXXXXXXXX';
                  final username = data?['username'] != null ? '@${data!['username']}' : '@user';
                  final bio = data?['bio'] ?? 'Building Telegram Lite in Flutter 🚀';
                  final photoUrl = data?['photoUrl'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';

                  return Material(
                    color: isDark ? const Color(0xFF1E242B) : Colors.white,
                    child: InkWell(
                      onTap: () => _openCurrentUserProfile(context),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundImage: NetworkImage(photoUrl),
                              backgroundColor: TeleTheme.primary.withAlpha(51),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$phone • $username',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bio,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: TeleTheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // General Settings Section
              _buildSectionHeader('General Settings', isDark),
              _buildSettingsTile(
                context: context,
                icon: Icons.bookmark_border,
                iconColor: Colors.blue,
                title: 'Saved Messages',
                isDark: isDark,
                page: const SavedMessagesScreen(),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.folder_open_outlined,
                iconColor: Colors.cyan,
                title: 'Chat Folders',
                subtitle: 'Personal, Work, Unread',
                isDark: isDark,
                page: const ChatFoldersScreen(),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.devices_outlined,
                iconColor: Colors.amber,
                title: 'Devices',
                subtitle: '2 active sessions',
                isDark: isDark,
                page: const DevicesScreen(),
              ),

              const SizedBox(height: 12),
              _buildSectionHeader('Privacy & Data', isDark),
              _buildSettingsTile(
                context: context,
                icon: Icons.notifications_none_outlined,
                iconColor: Colors.redAccent,
                title: 'Notifications and Sounds',
                isDark: isDark,
                page: const NotificationsScreen(),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.lock_outline,
                iconColor: Colors.green,
                title: 'Privacy and Security',
                subtitle: 'Two-Step Verification, Passcode',
                isDark: isDark,
                page: const PrivacyScreen(),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.pie_chart_outline,
                iconColor: Colors.purple,
                title: 'Data and Storage',
                subtitle: 'Network usage, Auto-download',
                isDark: isDark,
                page: const DataStorageScreen(),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.vpn_key_outlined,
                iconColor: Colors.orange,
                title: 'Proxy Settings',
                subtitle: 'Connected (SOCKS5)',
                isDark: isDark,
                page: const ProxyScreen(),
              ),

              const SizedBox(height: 12),
              _buildSectionHeader('Appearance & Language', isDark),
              SwitchListTile(
                value: isDark,
                onChanged: (_) => dataService.toggleTheme(),
                title: const Text(
                  'Dark Mode',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                secondary: const Icon(Icons.dark_mode_outlined,
                    color: TeleTheme.primary),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.language_outlined,
                iconColor: Colors.teal,
                title: 'Language',
                subtitle: 'English',
                isDark: isDark,
                page: const LanguageScreen(),
              ),

              const SizedBox(height: 12),
              _buildSectionHeader('Account', isDark),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.redAccent, size: 22),
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: () {
                  authService.signOut();
                },
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Telegram Lite v1.0.0 (Stitch Pro UI)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: TeleTheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool isDark,
    required Widget page,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(38),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }
}
