import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/telegram_controller.dart';
import '../models/models.dart';
import '../services/mock_data.dart';
import '../services/story_service.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';
import 'add_story_screen.dart';
import 'create_group_screen.dart';
import '../widgets/story_row_widget.dart';
import '../models/story_model.dart';
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
  final StoryService _storyService = StoryService();
  TelegramController get _controller => TelegramController.to;

  Future<void> _pickMediaForStory() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickMedia();
      if (pickedFile != null && mounted) {
        final pathLower = pickedFile.path.toLowerCase();
        final isVideo = pathLower.endsWith('.mp4') || pathLower.endsWith('.mov') || pathLower.endsWith('.avi');
        
        Get.to(() => AddStoryScreen(
          mediaFile: File(pickedFile.path),
          isVideo: isVideo,
        ));
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Failed to pick media: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final filteredChats = _controller.chats.where((chat) {
        final matchesSearch = chat.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            chat.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());

        if (!matchesSearch) return false;
        if (_selectedCategory == ChatCategory.all) return true;
        if (_selectedCategory == ChatCategory.unread) return chat.unreadCount > 0;
        return chat.category == _selectedCategory;
      }).toList();

    final currentUser = FirebaseAuth.instance.currentUser;
    final allowedUserIds = <String>[
      ...widget.dataService.contacts.map((c) => c.id),
      ...widget.dataService.chats.map((c) => c.id),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TeleLite'),
        toolbarHeight: 64,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Stories Row
                StreamBuilder<List<Story>>(
                  stream: _storyService.getActiveStories(
                    currentUserId: currentUser?.uid,
                    allowedOwnerIds: allowedUserIds,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    final stories = snapshot.data ?? [];
                    return StoryRowWidget(
                      stories: stories,
                      onAddStoryTap: _pickMediaForStory,
                    );
                  },
                ),
                
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
              ],
            ),
          ),

          // Chat List
          filteredChats.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No chats found',
                      style: TextStyle(
                          color: isDark ? Colors.grey : Colors.grey[600]),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chat = filteredChats[index];
                      return _buildChatItem(context, chat, isDark);
                    },
                    childCount: filteredChats.length,
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
            onPressed: _pickMediaForStory,
            backgroundColor: isDark ? const Color(0xFF262D36) : Colors.white,
            elevation: 2,
            child: Icon(Icons.camera_alt, color: isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          // New Group / Channel popup
          FloatingActionButton(
            heroTag: 'newChat',
            onPressed: () => _showNewChatMenu(context),
            backgroundColor: TeleTheme.primary,
            child: const Icon(Icons.edit, color: Colors.white),
          ),
        ],
      ),
    );
    });
  }

  void _showNewChatMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2330) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'New Conversation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _menuTile(
                context: context,
                icon: Icons.group_add,
                color: const Color(0xFF8A2387),
                title: 'New Group',
                subtitle: 'Add members and start a group chat',
                onTap: () {
                  Get.back();
                  Get.to(() => CreateGroupScreen(
                    dataService: widget.dataService,
                    isChannel: false,
                  ));
                },
              ),
              _menuTile(
                context: context,
                icon: Icons.campaign,
                color: TeleTheme.primary,
                title: 'New Channel',
                subtitle: 'Broadcast to unlimited subscribers',
                onTap: () {
                  Get.back();
                  Get.to(() => CreateGroupScreen(
                    dataService: widget.dataService,
                    isChannel: true,
                  ));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
            fontSize: 13, color: isDark ? Colors.white54 : Colors.black45),
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
        Get.to(() => ChatDetailScreen(
          chat: chat,
          dataService: widget.dataService,
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar with Group/Channel/Online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: chat.avatarUrl.isNotEmpty
                      ? NetworkImage(chat.avatarUrl)
                      : null,
                  backgroundColor: chat.isChannel
                      ? TeleTheme.primary.withAlpha(51)
                      : chat.isGroup
                          ? const Color(0xFF8A2387).withAlpha(51)
                          : TeleTheme.primary.withAlpha(51),
                  child: chat.avatarUrl.isEmpty
                      ? Icon(
                          chat.isChannel
                              ? Icons.campaign
                              : chat.isGroup
                                  ? Icons.group
                                  : Icons.person,
                          color: TeleTheme.primary,
                        )
                      : null,
                ),
                // Group icon badge
                if (chat.isGroup || chat.isChannel)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: chat.isChannel
                            ? TeleTheme.primary
                            : const Color(0xFF8A2387),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF181C20) : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        chat.isChannel ? Icons.campaign : Icons.group,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (chat.isOnline && !chat.isStealthMode)
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
                          color: isDark ? const Color(0xFF181C20) : Colors.white,
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
                          child: Icon(Icons.lock, size: 14, color: Colors.green),
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
                      if (chat.emojiStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            chat.emojiStatus!,
                            style: const TextStyle(fontSize: 16),
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
                  const SizedBox(height: 2),
                  // Member count for groups/channels
                  if (chat.isGroup || chat.isChannel)
                    Text(
                      chat.isChannel
                          ? '${chat.memberCount} subscriber${chat.memberCount != 1 ? 's' : ''}'
                          : '${chat.memberCount} member${chat.memberCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  const SizedBox(height: 2),
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
