import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  ];

  bool _isPremium = false;
  final _firestore = FirebaseFirestore.instance;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    if (_currentUser == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _isPremium = doc.data()?['isPremium'] == true;
        });
      }
    } catch (e) {
      debugPrint('_loadPremiumStatus error: $e');
    }
  }

  void _showPremiumPaywall() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 64, color: Color(0xFFE94057)),
              const SizedBox(height: 16),
              const Text(
                'Telegram Premium Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Non-premium users can only have up to 2 chat folders. Subscribe to Telegram Premium to create up to 30 custom chat folders.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EA6FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addFolderDialog() {
    if (!_isPremium && _folders.length >= 2) {
      _showPremiumPaywall();
      return;
    }
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
