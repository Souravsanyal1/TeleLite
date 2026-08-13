import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/cloudinary_service.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';

class GroupManagementScreen extends StatefulWidget {
  final Chat chat;
  final TelegramDataService dataService;

  const GroupManagementScreen({
    super.key,
    required this.chat,
    required this.dataService,
  });

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Chat _chat;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _chat = widget.chat;
    _nameController.text = _chat.name;
    _descController.text = _chat.description ?? '';
    _usernameController.text = _chat.username ?? '';
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
  }

  /// Load logged-in user's real name and photo from Firestore
  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final name = data['displayName'] ?? user.displayName ?? 'You';
        final photo = data['photoUrl'] ?? user.photoURL ?? '';
        final username = data['username'] ?? '';
        // Update the 'me' member in the group's member list
        final members = widget.dataService.getMembersForChat(_chat.id);
        final meIdx = members.indexWhere((m) => m.id == 'me');
        if (meIdx != -1) {
          members[meIdx] = GroupMember(
            id: 'me',
            name: name,
            avatarUrl: photo,
            username: username.isNotEmpty ? username : null,
            isAdmin: members[meIdx].isAdmin,
            isOwner: members[meIdx].isOwner,
            isOnline: true,
          );
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('_loadCurrentUser error: $e');
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Chat get _latestChat => widget.dataService.chats
      .firstWhere((c) => c.id == _chat.id, orElse: () => _chat);

  Future<void> _saveInfo() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    widget.dataService.updateGroupInfo(
      _chat.id,
      name: _nameController.text.trim(),
      username: _usernameController.text.trim().isNotEmpty
          ? _usernameController.text.trim()
          : null,
      description: _descController.text.trim(),
    );
    setState(() {
      _isSaving = false;
      _chat = _latestChat;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved!'),
          backgroundColor: TeleTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyInviteLink() {
    final link = _chat.inviteLink ?? '';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $link'),
        backgroundColor: TeleTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Pick a photo (gallery) and upload to Cloudinary, then update group avatar
  Future<void> _pickAndUploadPhoto() async {
    if (kIsWeb) {
      // Web: use URL dialog fallback
      _showPhotoUrlDialog();
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);
      final file = File(picked.path);
      final url = await CloudinaryService().uploadFile(file);
      if (url != null && mounted) {
        widget.dataService.updateGroupInfo(_chat.id, avatarUrl: url);
        setState(() {
          _chat = _latestChat;
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo updated!'),
            backgroundColor: TeleTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _isUploadingPhoto = false);
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPhotoUrlDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Photo URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/photo.jpg',
            labelText: 'Image URL',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                widget.dataService.updateGroupInfo(_chat.id, avatarUrl: url);
                setState(() => _chat = _latestChat);
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: TeleTheme.primary),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _openAddMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddMembersScreen(
          chat: _chat,
          dataService: widget.dataService,
        ),
      ),
    ).then((_) => setState(() => _chat = _latestChat));
  }

  // Member removal is disabled — no deleting from groups/channels.

  void _promoteToAdmin(GroupMember member) {
    widget.dataService.promoteToAdmin(_chat.id, member.id);
    setState(() => _chat = _latestChat);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member.name} is now an admin!'),
        backgroundColor: TeleTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? TeleTheme.bgDark : TeleTheme.bgLight;
    final cardColor = isDark ? const Color(0xFF1A2330) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black45;

    return AnimatedBuilder(
      animation: widget.dataService,
      builder: (context, _) {
        _chat = _latestChat;
        final members = widget.dataService.getMembersForChat(_chat.id);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _chat.isChannel ? 'Channel Settings' : 'Group Settings',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            backgroundColor: isDark ? const Color(0xFF1A2330) : Colors.white,
            bottom: TabBar(
              controller: _tabController,
              labelColor: TeleTheme.primary,
              unselectedLabelColor: subColor,
              indicatorColor: TeleTheme.primary,
              tabs: [
                const Tab(icon: Icon(Icons.info_outline), text: 'Info'),
                Tab(
                  icon: Icon(
                      _chat.isChannel ? Icons.people_outline : Icons.people),
                  text: _chat.isChannel ? 'Subscribers' : 'Members',
                ),
                const Tab(icon: Icon(Icons.link), text: 'Invite'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // ── TAB 1: INFO ──
              _buildInfoTab(isDark, cardColor, textColor, subColor),

              // ── TAB 2: MEMBERS ──
              _buildMembersTab(isDark, cardColor, textColor, subColor, members),

              // ── TAB 3: INVITE ──
              _buildInviteTab(isDark, cardColor, textColor, subColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(
      bool isDark, Color cardColor, Color textColor, Color subColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Avatar + name header
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _chat.isChannel
                                ? [
                                    const Color(0xFF0088CC),
                                    const Color(0xFF006193)
                                  ]
                                : [
                                    const Color(0xFF8A2387),
                                    const Color(0xFFE94057)
                                  ],
                          ),
                        ),
                        child: ClipOval(
                          child: _chat.avatarUrl.isNotEmpty
                              ? Image.network(
                                  _chat.avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    _chat.isChannel
                                        ? Icons.campaign
                                        : Icons.group,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                )
                              : Icon(
                                  _chat.isChannel
                                      ? Icons.campaign
                                      : Icons.group,
                                  color: Colors.white,
                                  size: 48,
                                ),
                        ),
                      ),
                      // Upload spinner overlay
                      if (_isUploadingPhoto)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black45,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                      // Camera badge
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _isUploadingPhoto
                                ? Colors.grey
                                : TeleTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? TeleTheme.bgDark
                                  : TeleTheme.bgLight,
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  _chat.name,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
                if (_chat.memberCount > 0)
                  Text(
                    '${_chat.memberCount} member${_chat.memberCount != 1 ? 's' : ''}',
                    style: TextStyle(color: subColor, fontSize: 14),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Edit Name
          _buildInputCard(
            cardColor: cardColor,
            icon: _chat.isChannel ? Icons.campaign : Icons.group,
            label: _chat.isChannel ? 'Channel Name' : 'Group Name',
            controller: _nameController,
            textColor: textColor,
            hintColor: subColor,
          ),
          const SizedBox(height: 12),

          // Description
          _buildInputCard(
            cardColor: cardColor,
            icon: Icons.description_outlined,
            label: 'Description',
            controller: _descController,
            textColor: textColor,
            hintColor: subColor,
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          // Username
          _buildInputCard(
            cardColor: cardColor,
            icon: Icons.alternate_email,
            label: 'Username (optional)',
            controller: _usernameController,
            textColor: textColor,
            hintColor: subColor,
            prefix: '@',
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveInfo,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              style: FilledButton.styleFrom(
                backgroundColor: TeleTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(bool isDark, Color cardColor, Color textColor,
      Color subColor, List<GroupMember> members) {
    return Column(
      children: [
        // Add Members Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAddMembers,
              icon: const Icon(Icons.person_add, color: TeleTheme.primary),
              label: const Text('Add Members',
                  style: TextStyle(
                      color: TeleTheme.primary, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TeleTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${members.length} member${members.length != 1 ? 's' : ''}',
              style: TextStyle(color: subColor, fontSize: 13),
            ),
          ),
        ),

        Expanded(
          child: members.isEmpty
              ? Center(
                  child: Text('No members yet',
                      style: TextStyle(color: subColor)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: members.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                  itemBuilder: (_, i) {
                    final m = members[i];
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: NetworkImage(m.avatarUrl.isNotEmpty
                                ? m.avatarUrl
                                : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                          ),
                          if (m.isOnline)
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
                                    color: isDark
                                        ? TeleTheme.bgDark
                                        : TeleTheme.bgLight,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        m.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: textColor),
                      ),
                      subtitle: m.username != null
                          ? Text('@${m.username}',
                              style: TextStyle(color: subColor, fontSize: 12))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (m.isOwner)
                            _roleBadge('Owner', const Color(0xFFE91E63))
                          else if (m.isAdmin)
                            _roleBadge('Admin', TeleTheme.primary),
                          if (!m.isOwner && m.id != 'me' && !m.isAdmin)
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: subColor),
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'promote',
                                    child: Row(
                                      children: [
                                        Icon(Icons.admin_panel_settings,
                                            color: TeleTheme.primary, size: 18),
                                        SizedBox(width: 8),
                                        Text('Make Admin'),
                                      ],
                                    )),
                              ],
                              onSelected: (v) {
                                if (v == 'promote') _promoteToAdmin(m);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInviteTab(
      bool isDark, Color cardColor, Color textColor, Color subColor) {
    final link = _chat.inviteLink ?? 'No link generated';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: TeleTheme.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.link,
                      color: TeleTheme.primary, size: 36),
                ),
                const SizedBox(height: 16),
                Text('Invite Link',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                const SizedBox(height: 8),
                Text(
                  'Share this link so others can join directly',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subColor, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(10)
                        : Colors.black.withAlpha(8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          link,
                          style: const TextStyle(
                              color: TeleTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      GestureDetector(
                        onTap: _copyInviteLink,
                        child: const Icon(Icons.copy,
                            color: TeleTheme.primary, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _copyInviteLink,
              icon: const Icon(Icons.copy),
              label: const Text('Copy Invite Link'),
              style: FilledButton.styleFrom(
                backgroundColor: TeleTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share sheet coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.share, color: TeleTheme.primary),
              label: const Text('Share via...',
                  style: TextStyle(color: TeleTheme.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TeleTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required Color cardColor,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required Color textColor,
    required Color hintColor,
    int maxLines = 1,
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: textColor),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: hintColor, fontSize: 13),
          prefixIcon: Icon(icon, color: TeleTheme.primary, size: 20),
          prefixText: prefix,
          prefixStyle: const TextStyle(
              color: TeleTheme.primary, fontWeight: FontWeight.bold),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _roleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// ─── Add Members Sub-Screen ─────────────────────────────────────────────────
class _AddMembersScreen extends StatefulWidget {
  final Chat chat;
  final TelegramDataService dataService;

  const _AddMembersScreen({
    required this.chat,
    required this.dataService,
  });

  @override
  State<_AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<_AddMembersScreen> {
  final Set<String> _selectedIds = {};
  String _searchQuery = '';

  List<Contact> get _filteredContacts => widget.dataService.contacts
      .where((c) =>
          !widget.chat.memberIds.contains(c.id) &&
          (_searchQuery.isEmpty ||
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.phone.contains(_searchQuery)))
      .toList();

  void _addSelected() {
    final toAdd = widget.dataService.contacts
        .where((c) => _selectedIds.contains(c.id))
        .toList();
    widget.dataService.addMembersToGroup(widget.chat.id, toAdd);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${toAdd.length} member(s)!'),
        backgroundColor: TeleTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black45;
    final contacts = _filteredContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Members'),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: _addSelected,
              child: Text(
                'Add (${_selectedIds.length})',
                style: const TextStyle(
                    color: TeleTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF262D36)
                    : const Color(0xFFEBEFEF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: contacts.isEmpty
                ? Center(
                    child: Text(
                      'All contacts are already members',
                      style: TextStyle(color: subColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (_, i) {
                      final c = contacts[i];
                      final selected = _selectedIds.contains(c.id);
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(c.avatarUrl),
                        ),
                        title: Text(c.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textColor)),
                        subtitle: Text(
                          c.username != null ? '@${c.username}' : c.phone,
                          style: TextStyle(color: subColor, fontSize: 12),
                        ),
                        trailing: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? TeleTheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: selected
                                  ? TeleTheme.primary
                                  : (isDark ? Colors.white38 : Colors.black26),
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        onTap: () => setState(() {
                          selected
                              ? _selectedIds.remove(c.id)
                              : _selectedIds.add(c.id);
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
