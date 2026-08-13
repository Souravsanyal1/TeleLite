import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChatFoldersScreen extends StatefulWidget {
  const ChatFoldersScreen({super.key});

  @override
  State<ChatFoldersScreen> createState() => _ChatFoldersScreenState();
}

class _ChatFoldersScreenState extends State<ChatFoldersScreen> {
  final List<Map<String, dynamic>> _folders = [
    {'name': 'Personal', 'icon': Icons.person, 'chats': 12, 'color': Colors.blue},
    {'name': 'Work', 'icon': Icons.work, 'chats': 8, 'color': Colors.cyan},
    {'name': 'Unread', 'icon': Icons.mark_chat_unread, 'chats': 5, 'color': Colors.amber},
    {'name': 'Channels', 'icon': Icons.campaign, 'chats': 3, 'color': Colors.purple},
  ];

  void _addFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Folder Name (e.g. Crypto, Family)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _folders.add({
                    'name': controller.text.trim(),
                    'icon': Icons.folder_open,
                    'chats': 0,
                    'color': Colors.teal,
                  });
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: TeleTheme.primary),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Folders'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Create folders for different groups of chats and quickly switch between them.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: TeleTheme.primary,
              child: Icon(Icons.add, color: Colors.white),
            ),
            title: const Text(
              'Create New Folder',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: TeleTheme.primary,
              ),
            ),
            onTap: _addFolderDialog,
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'MY FOLDERS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
          ..._folders.map((folder) {
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (folder['color'] as Color).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(folder['icon'] as IconData, color: folder['color'] as Color),
              ),
              title: Text(
                folder['name'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: Text('${folder['chats']} included chats'),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                onPressed: () {
                  setState(() {
                    _folders.remove(folder);
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
