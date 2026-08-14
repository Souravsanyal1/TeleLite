import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/models.dart';
import '../models/story_model.dart';
import '../services/auth_service.dart';
import '../services/mock_data.dart';
import '../services/story_service.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';
import 'auth/edit_profile_screen.dart';
import 'story_viewer_page.dart';

class UserProfileScreen extends StatefulWidget {
  final Chat? chat;
  final Contact? contact;
  final bool isCurrentUser;
  final TelegramDataService? dataService;
  final AuthService? authService;

  const UserProfileScreen({
    super.key,
    this.chat,
    this.contact,
    this.isCurrentUser = false,
    this.dataService,
    this.authService,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final StoryService _storyService = StoryService();
  bool _isMuted = false;
  bool _isBlocked = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isCurrentUser && widget.authService != null) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        stream: widget.authService!.userProfileStream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final currentUser = widget.authService!.currentUser;
          final name = data?['displayName'] ??
              currentUser?.displayName ??
              'TeleLite User';
          final phone = data?['phoneNumber'] ??
              currentUser?.phoneNumber ??
              '+880 1700000000';
          final username = data?['username'] != null
              ? '@${data!['username']}'
              : '@my_username';
          final bio = data?['bio'] ?? 'Building Telegram Lite in Flutter 🚀';
          final photoUrl = data?['photoUrl'] ??
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';

          return _buildProfileBody(
            context: context,
            name: name,
            subtitle: 'online',
            phone: phone,
            username: username,
            bio: bio,
            photoUrl: photoUrl,
            emojiStatus: data?['emojiStatus'],
            profileColor: data?['profileColor'],
            isOnline: true,
            isVerified: true,
            isCurrentUser: true,
            isDark: isDark,
          );
        },
      );
    }

    final name = widget.chat?.name ?? widget.contact?.name ?? 'Telegram User';
    final photoUrl = widget.chat?.avatarUrl ??
        widget.contact?.avatarUrl ??
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';
    final isStealthMode = widget.chat?.isStealthMode ?? widget.contact?.isStealthMode ?? false;
    final isOnline = (widget.chat?.isOnline ?? widget.contact?.isOnline ?? false) && !isStealthMode;
    final rawPhone = widget.contact?.phone.isNotEmpty == true
        ? widget.contact!.phone
        : '+880 1712 345678';
    final username =
        '@${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';
    final bio = widget.chat?.isSecret == true
        ? '🔒 End-to-end encrypted secret chat profile'
        : 'Hey there! I am using Telegram Lite.';
    final isVerified = widget.chat?.isVerified ?? false;

    // Check target UID if available from chat or contact ID
    final targetUid = widget.chat?.id ?? widget.contact?.id;

    if (targetUid != null && targetUid.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final visibility = data?['phoneNumberVisibility'] ?? 'My Contacts';
          final dbPhone = data?['phoneNumber'] ?? rawPhone;
          // Hide number unless user explicitly selected 'Everybody'
          final displayPhone = (visibility == 'Everybody') ? dbPhone : 'Hidden';

          final dbIsOnline = data?['isOnline'] ?? isOnline;
          final dbStealthMode = data?['stealthMode'] ?? isStealthMode;
          final finalIsOnline = dbIsOnline && !dbStealthMode;

          return _buildProfileBody(
            context: context,
            name: data?['displayName'] ?? name,
            subtitle: finalIsOnline ? 'online' : 'last seen recently',
            phone: displayPhone,
            username:
                data?['username'] != null ? '@${data!['username']}' : username,
            bio: data?['bio'] ?? bio,
            photoUrl: data?['photoUrl'] ?? photoUrl,
            emojiStatus: data?['emojiStatus'] ?? widget.chat?.emojiStatus ?? widget.contact?.emojiStatus,
            profileColor: data?['profileColor'] ?? widget.chat?.profileColor ?? widget.contact?.profileColor,
            isOnline: finalIsOnline,
            isVerified: isVerified,
            isCurrentUser: false,
            isDark: isDark,
          );
        },
      );
    }

    // Default fallback for mock contacts without Firestore document:
    // Phone is hidden unless privacy setting is 'Everybody'
    const defaultVisibility = 'My Contacts'; // Default is hidden
    final displayPhone =
        (defaultVisibility == 'Everybody') ? rawPhone : 'Hidden';

    return _buildProfileBody(
      context: context,
      name: name,
      subtitle: isOnline ? 'online' : 'last seen recently',
      phone: displayPhone,
      username: username,
      bio: bio,
      photoUrl: photoUrl,
      emojiStatus: widget.chat?.emojiStatus ?? widget.contact?.emojiStatus,
      profileColor: widget.chat?.profileColor ?? widget.contact?.profileColor,
      isOnline: isOnline,
      isVerified: isVerified,
      isCurrentUser: false,
      isDark: isDark,
    );
  }

  Widget _buildProfileBody({
    required BuildContext context,
    required String name,
    required String subtitle,
    required String phone,
    required String username,
    required String bio,
    required String photoUrl,
    String? emojiStatus,
    String? profileColor,
    required bool isOnline,
    required bool isVerified,
    required bool isCurrentUser,
    required bool isDark,
  }) {
    final bgColor = isDark ? const Color(0xFF17212B) : const Color(0xFFF1F5F9);
    final cardBgColor = isDark ? const Color(0xFF1E2C3A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // Header Sliver with Image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF17212B) : TeleTheme.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: '$name ($username) - TeleLite Profile'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile link copied to clipboard!')),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'block') {
                    setState(() => _isBlocked = !_isBlocked);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              _isBlocked ? 'User Blocked' : 'User Unblocked')),
                    );
                  } else if (value == 'edit') {
                    if (widget.authService != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            authService: widget.authService!,
                            dataService: widget.dataService!,
                            isPremium: widget.dataService?.isPremium ?? false,
                            currentName: name,
                            currentUsername: username,
                            currentBio: bio,
                            currentPhotoUrl: photoUrl,
                            currentProfileColor: profileColor,
                            currentEmojiStatus: emojiStatus,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AuthService is missing')),
                      );
                    }
                  } else if (value == 'share') {
                    Clipboard.setData(ClipboardData(text: '$name ($phone)'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact shared!')),
                    );
                  }
                },
                itemBuilder: (context) => [
                  if (isCurrentUser)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: TeleTheme.primary, size: 20),
                          SizedBox(width: 10),
                          Text('Edit Profile'),
                        ],
                      ),
                    )
                  else ...[
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 20),
                          SizedBox(width: 10),
                          Text('Share Contact'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(
                            _isBlocked ? Icons.lock_open : Icons.block,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isBlocked ? 'Unblock User' : 'Block User',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: TeleTheme.primary,
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                              fontSize: 72, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(204),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.verified,
                                    color: Colors.lightBlueAccent, size: 22),
                              ),
                            if (emojiStatus != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  emojiStatus,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            // Premium Badge
                            StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>?>(
                              stream: widget.authService?.userProfileStream,
                              builder: (context, snapshot) {
                                final isPrem = snapshot.data
                                            ?.data()?['isPremium'] ==
                                        true ||
                                    (isCurrentUser &&
                                        widget.dataService?.isPremium == true);
                                if (!isPrem) return const SizedBox.shrink();
                                return Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF8A2387),
                                        Color(0xFFE94057)
                                      ],
                                    ),
                                  ),
                                  child: const Icon(Icons.star,
                                      color: Colors.white, size: 16),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isOnline)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: TeleTheme.onlineSuccess,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: isOnline
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                fontWeight: isOnline
                                    ? FontWeight.w600
                                    : FontWeight.w400,
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
          ),

          // Content Sliver List
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Quick Action Bar (Message, Audio Call, Video Call, Mute)
                if (!isCurrentUser)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: cardBgColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.chat_bubble_outline,
                              label: 'Message',
                              color: TeleTheme.primary,
                              onTap: () {
                                if (widget.chat != null &&
                                    widget.dataService != null) {
                                  widget.dataService!.ensureChatExists(widget.chat!);
                                  Get.back();
                                } else if (widget.contact != null &&
                                    widget.dataService != null) {
                                  final chat = widget.dataService!
                                      .getOrCreateChatForContact(widget.contact!);
                                  Get.back();
                                  Get.to(() => ChatDetailScreen(
                                    chat: chat,
                                    dataService: widget.dataService!,
                                  ));
                                }
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.call_outlined,
                              label: 'Call',
                              color: TeleTheme.primary,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Calling $name...')),
                                );
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.videocam_outlined,
                              label: 'Video',
                              color: TeleTheme.primary,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Starting video call with $name...')),
                                );
                              },
                            ),
                            _buildActionButton(
                              icon: _isMuted
                                  ? Icons.notifications_off_outlined
                                  : Icons.notifications_none_outlined,
                              label: _isMuted ? 'Muted' : 'Mute',
                              color:
                                  _isMuted ? Colors.orange : TeleTheme.primary,
                              onTap: () {
                                setState(() => _isMuted = !_isMuted);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_isMuted
                                        ? 'Notifications muted for $name'
                                        : 'Notifications unmuted for $name'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Account Information Card
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: cardBgColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TeleTheme.primary,
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined,
                              color: TeleTheme.primary),
                          title: Text(phone,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500)),
                          subtitle: Text('Mobile',
                              style:
                                  TextStyle(color: subTextColor, fontSize: 13)),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: phone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Copied phone number $phone')),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.alternate_email,
                              color: TeleTheme.primary),
                          title: Text(username,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500)),
                          subtitle: Text('Username',
                              style:
                                  TextStyle(color: subTextColor, fontSize: 13)),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: username));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Copied username $username')),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.info_outline,
                              color: TeleTheme.primary),
                          title: Text(bio,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w400)),
                          subtitle: Text('Bio',
                              style:
                                  TextStyle(color: subTextColor, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Settings / Preferences Card
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: cardBgColor,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline,
                              color: Colors.green),
                          title: const Text(
                            'Encryption',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Messages and calls are end-to-end encrypted',
                            style: TextStyle(color: subTextColor, fontSize: 13),
                          ),
                          trailing: const Icon(Icons.verified_user,
                              color: Colors.green, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stories Grid Card
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Material(
                    color: cardBgColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stories',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<List<Story>>(
                            stream: _storyService.getUserStories(
                              widget.isCurrentUser 
                                  ? (widget.authService?.currentUser?.uid ?? '') 
                                  : (widget.chat?.id ?? widget.contact?.id ?? ''),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return const Center(child: Text('Error loading stories'));
                              }
                              
                              final stories = snapshot.data ?? [];
                              if (stories.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Text(
                                      'No active stories',
                                      style: TextStyle(color: subTextColor),
                                    ),
                                  ),
                                );
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.7,
                                ),
                                itemCount: stories.length,
                                itemBuilder: (context, index) {
                                  final story = stories[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StoryViewerPage(
                                            stories: stories,
                                            initialIndex: index,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image: NetworkImage(story.mediaUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
