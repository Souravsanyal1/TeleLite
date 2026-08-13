import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';
import 'add_story_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

class ChatsScreen extends StatefulWidget {
  final TelegramDataService dataService;

  const ChatsScreen({super.key, required this.dataService});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  ChatCategory _selectedCategory = ChatCategory.all;
  String _searchQuery = '';

  Future<void> _pickImageForStory() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddStoryScreen(imageFile: File(pickedFile.path)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    // Filter chats based on category and search query
    final filteredChats = widget.dataService.chats.where((chat) {
      final matchesSearch = chat.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          chat.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;
      if (_selectedCategory == ChatCategory.all) return true;
      if (_selectedCategory == ChatCategory.unread) return chat.unreadCount > 0;
      return chat.category == _selectedCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Lite'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImageForStory,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.withAlpha(50), width: 2.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(1.5),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundImage: currentUser?.photoURL != null
                                ? NetworkImage(currentUser!.photoURL!)
                                : const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150') as ImageProvider,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: TeleTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                          ),
                          child: const Icon(Icons.add, size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < (widget.dataService.chats.length > 3 ? 3 : widget.dataService.chats.length); i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: TeleTheme.primary, width: 2.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(1.5),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(widget.dataService.chats[i].avatarUrl),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF262D36) : const Color(0xFFEBEFEF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search chats, contacts...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Folder Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _buildCategoryChip('All Chats', ChatCategory.all),
                _buildCategoryChip('Personal', ChatCategory.personal),
                _buildCategoryChip('Work', ChatCategory.work),
                _buildCategoryChip('Unread', ChatCategory.unread),
                _buildCategoryChip('Channels', ChatCategory.channels),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.5),

          // Chat List
          Expanded(
            child: filteredChats.isEmpty
                ? Center(
                    child: Text(
                      'No chats found',
                      style: TextStyle(
                          color: isDark ? Colors.grey : Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      return _buildChatItem(context, chat, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'addStory',
            onPressed: _pickImageForStory,
            backgroundColor: isDark ? const Color(0xFF262D36) : Colors.white,
            elevation: 2,
            child: Icon(Icons.camera_alt, color: isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'newChat',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Start new conversation')),
              );
            },
            backgroundColor: TeleTheme.primary,
            child: const Icon(Icons.edit, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, ChatCategory category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedCategory = category);
          }
        },
        selectedColor: TeleTheme.primary,
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Chat chat, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chat: chat,
              dataService: widget.dataService,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar with Online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(chat.avatarUrl),
                  backgroundColor: TeleTheme.primary.withAlpha(51),
                ),
                if (chat.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: TeleTheme.onlineSuccess,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isDark ? const Color(0xFF181C20) : Colors.white,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Name & Last Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (chat.isSecret)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child:
                              Icon(Icons.lock, size: 14, color: Colors.green),
                        ),
                      Expanded(
                        child: Text(
                          chat.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified,
                              size: 16, color: TeleTheme.primary),
                        ),
                      if (chat.isPremium)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF8A2387), Color(0xFFE94057)],
                            ),
                          ),
                          child: const Icon(Icons.star,
                              color: Colors.white, size: 10),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        chat.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(Icons.push_pin,
                              size: 14, color: Colors.grey[500]),
                        ),
                      if (chat.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: TeleTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
