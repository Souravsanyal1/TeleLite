import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';

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
    final isOnline = widget.chat?.isOnline ?? widget.contact?.isOnline ?? false;
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

          return _buildProfileBody(
            context: context,
            name: data?['displayName'] ?? name,
            subtitle: isOnline ? 'online' : 'last seen recently',
            phone: displayPhone,
            username:
                data?['username'] != null ? '@${data!['username']}' : username,
            bio: data?['bio'] ?? bio,
            photoUrl: data?['photoUrl'] ?? photoUrl,
            isOnline: data?['isOnline'] ?? isOnline,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit Profile screen')),
                    );
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
                                  Navigator.pop(context);
                                } else if (widget.contact != null &&
                                    widget.dataService != null) {
                                  final newChat =
                                      widget.dataService!.createSecretChat(
                                    name: widget.contact!.name,
                                    avatarUrl: widget.contact!.avatarUrl,
                                  );
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatDetailScreen(
                                        chat: newChat,
                                        dataService: widget.dataService!,
                                      ),
                                    ),
                                  );
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
                        SwitchListTile(
                          value: !_isMuted,
                          activeThumbColor: TeleTheme.primary,
                          title: const Text(
                            'Notifications',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            _isMuted ? 'Muted' : 'Enabled',
                            style: TextStyle(color: subTextColor, fontSize: 13),
                          ),
                          secondary: const Icon(
                              Icons.notifications_active_outlined,
                              color: TeleTheme.primary),
                          onChanged: (val) {
                            setState(() => _isMuted = !val);
                          },
                        ),
                        const Divider(height: 1, indent: 56),
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

                // Shared Media Preview Card
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Material(
                    color: cardBgColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Shared Media',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '12 photos',
                                style: TextStyle(
                                    color: subTextColor, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                final sampleImages = [
                                  'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?w=150',
                                  'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=150',
                                  'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=150',
                                  'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=150',
                                  'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=150',
                                ];
                                return Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: NetworkImage(sampleImages[
                                          index % sampleImages.length]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
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
