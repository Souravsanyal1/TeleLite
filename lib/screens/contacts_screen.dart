import 'package:flutter/material.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';

class ContactsScreen extends StatelessWidget {
  final TelegramDataService dataService;

  const ContactsScreen({super.key, required this.dataService});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contacts = dataService.contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          // Action items
          _buildActionItem(
            icon: Icons.group_add_outlined,
            title: 'New Group',
            isDark: isDark,
            onTap: () {},
          ),
          _buildActionItem(
            icon: Icons.lock_outline,
            title: 'New Secret Chat',
            isDark: isDark,
            onTap: () {},
          ),
          _buildActionItem(
            icon: Icons.campaign_outlined,
            title: 'New Channel',
            isDark: isDark,
            onTap: () {},
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              'Sorted by last seen',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),

          ...contacts.map((contact) => ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(contact.avatarUrl),
                    ),
                    if (contact.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: TeleTheme.onlineSuccess,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF181C20) : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  contact.isOnline ? 'online' : 'last seen ${contact.lastSeen}',
                  style: TextStyle(
                    fontSize: 13,
                    color: contact.isOnline ? TeleTheme.primary : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                onTap: () {},
              )),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: TeleTheme.primary, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: TeleTheme.primary,
        ),
      ),
      onTap: onTap,
    );
  }
}
