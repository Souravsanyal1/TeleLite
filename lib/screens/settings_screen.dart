import 'package:flutter/material.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final TelegramDataService dataService;

  const SettingsScreen({super.key, required this.dataService});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                onPressed: () {},
              ),
            ],
          ),
          body: ListView(
            children: [
              // User Profile Header Card
              Container(
                color: isDark ? const Color(0xFF1E242B) : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: const NetworkImage(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                      ),
                      backgroundColor: TeleTheme.primary.withAlpha(51),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alex Johnson',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+1 555-0199 • @alex_johnson',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Building Telegram Lite in Flutter 🚀',
                            style: TextStyle(
                              fontSize: 13,
                              color: TeleTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Settings Sections
              _buildSectionHeader('General Settings', isDark),
              _buildSettingsTile(
                icon: Icons.bookmark_border,
                iconColor: Colors.blue,
                title: 'Saved Messages',
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.folder_open_outlined,
                iconColor: Colors.cyan,
                title: 'Chat Folders',
                subtitle: 'Personal, Work, Unread',
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.devices_outlined,
                iconColor: Colors.amber,
                title: 'Devices',
                subtitle: '2 active sessions',
                isDark: isDark,
              ),

              const SizedBox(height: 12),
              _buildSectionHeader('Privacy & Data', isDark),
              _buildSettingsTile(
                icon: Icons.notifications_none_outlined,
                iconColor: Colors.redAccent,
                title: 'Notifications and Sounds',
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                iconColor: Colors.green,
                title: 'Privacy and Security',
                subtitle: 'Two-Step Verification, Passcode',
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.pie_chart_outline,
                iconColor: Colors.purple,
                title: 'Data and Storage',
                subtitle: 'Network usage, Auto-download',
                isDark: isDark,
              ),
              _buildSettingsTile(
                icon: Icons.vpn_key_outlined,
                iconColor: Colors.orange,
                title: 'Proxy Settings',
                subtitle: 'Connected (SOCKS5)',
                isDark: isDark,
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
                icon: Icons.language_outlined,
                iconColor: Colors.teal,
                title: 'Language',
                subtitle: 'English',
                isDark: isDark,
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
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool isDark,
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
      onTap: () {},
    );
  }
}
