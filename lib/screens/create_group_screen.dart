import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/models.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import 'group_management_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  final TelegramDataService dataService;
  final bool isChannel;

  const CreateGroupScreen({
    super.key,
    required this.dataService,
    this.isChannel = false,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0 = select members (not for channel), 1 = set name/info
  final Set<String> _selectedContactIds = {};
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _usernameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Contact> get _selectedContacts => widget.dataService.contacts
      .where((c) => _selectedContactIds.contains(c.id))
      .toList();

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        widget.isChannel
            ? 'Please enter a channel name'
            : 'Please enter a group name',
        backgroundColor: Colors.red.withAlpha(200),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isCreating = true);
    await Future.delayed(const Duration(milliseconds: 600));

    Chat newChat;
    if (widget.isChannel) {
      newChat = widget.dataService.createChannelChat(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        username: _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : null,
      );
    } else {
      newChat = widget.dataService.createGroupChat(
        name: _nameController.text.trim(),
        avatarUrl: '',
        description: _descController.text.trim(),
        members: _selectedContacts,
      );
    }

    if (!mounted) return;
    setState(() => _isCreating = false);

    Get.back();
    Get.to(() => GroupManagementScreen(
      chat: newChat,
      dataService: widget.dataService,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Channel goes straight to step 1
    final effectiveStep = widget.isChannel ? 1 : _step;

    return Scaffold(
      backgroundColor: isDark ? TeleTheme.bgDark : TeleTheme.bgLight,
      appBar: AppBar(
        title: Text(
          widget.isChannel
              ? 'New Channel'
              : (_step == 0 ? 'Add Members' : 'New Group'),
        ),
        actions: [
          if (effectiveStep == 0 && _selectedContactIds.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Next',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          if (effectiveStep == 1)
            _isCreating
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                  )
                : TextButton(
                    onPressed: _create,
                    child: const Text('Create',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
        ],
      ),
      floatingActionButton: (effectiveStep == 0 && _selectedContactIds.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _step = 1),
              backgroundColor: TeleTheme.primary,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: Text(
                'Next (${_selectedContactIds.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: effectiveStep == 0
          ? _buildSelectMembers(isDark)
          : _buildGroupInfo(isDark),
    );
  }

  Widget _buildSelectMembers(bool isDark) {
    final contacts = widget.dataService.contacts;
    final filtered = contacts
        .where((c) =>
            _searchQuery.isEmpty ||
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.phone.contains(_searchQuery))
        .toList();

    return Column(
      children: [
        // Selected chips
        if (_selectedContactIds.isNotEmpty)
          Container(
            height: 72,
            color: isDark ? const Color(0xFF1A2330) : Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _selectedContacts.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: NetworkImage(c.avatarUrl),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _selectedContactIds.remove(c.id)),
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 10, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(c.name.split(' ').first,
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black54)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262D36) : const Color(0xFFEBEFEF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
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

        // Contact List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No contacts found',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black38),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final selected = _selectedContactIds.contains(c.id);
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(c.avatarUrl),
                          ),
                          if (c.isOnline)
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
                        c.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87),
                      ),
                      subtitle: Text(
                        c.username != null ? '@${c.username}' : c.phone,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black38),
                      ),
                      trailing: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? TeleTheme.primary
                              : (isDark
                                  ? Colors.white12
                                  : Colors.black.withAlpha(20)),
                          border: Border.all(
                            color: selected
                                ? TeleTheme.primary
                                : (isDark ? Colors.white24 : Colors.black26),
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedContactIds.remove(c.id);
                          } else {
                            _selectedContactIds.add(c.id);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGroupInfo(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1A2330) : Colors.white;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final textColor = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar picker placeholder
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.isChannel
                          ? [const Color(0xFF0088CC), const Color(0xFF006193)]
                          : [const Color(0xFF8A2387), const Color(0xFFE94057)],
                    ),
                  ),
                  child: Icon(
                    widget.isChannel ? Icons.campaign : Icons.group,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: TeleTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark ? TeleTheme.bgDark : TeleTheme.bgLight,
                          width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Name field
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _nameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText:
                    widget.isChannel ? 'Channel Name' : 'Group Name',
                hintStyle: TextStyle(color: hintColor),
                prefixIcon:
                    const Icon(Icons.edit, color: TeleTheme.primary, size: 20),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Description field
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _descController,
              style: TextStyle(color: textColor),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: widget.isChannel
                    ? 'Description (optional)'
                    : 'About this group (optional)',
                hintStyle: TextStyle(color: hintColor),
                prefixIcon:
                    const Icon(Icons.info_outline, color: TeleTheme.primary, size: 20),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Username field (channels only or optional for groups)
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _usernameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText:
                    widget.isChannel ? 'Public link (e.g. mychannel)' : 'Username (optional)',
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: const Icon(Icons.link, color: TeleTheme.primary, size: 20),
                prefixText: '@',
                prefixStyle:
                    const TextStyle(color: TeleTheme.primary, fontWeight: FontWeight.bold),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Selected members preview (groups only)
          if (!widget.isChannel && _selectedContacts.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_selectedContacts.length} member(s) will be added',
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedContacts
                  .map((c) => Chip(
                        avatar: CircleAvatar(
                          backgroundImage: NetworkImage(c.avatarUrl),
                        ),
                        label: Text(c.name.split(' ').first),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () =>
                            setState(() => _selectedContactIds.remove(c.id)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Create Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isCreating ? null : _create,
              icon: _isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(widget.isChannel ? Icons.campaign : Icons.group_add),
              label: Text(
                _isCreating
                    ? 'Creating...'
                    : (widget.isChannel ? 'Create Channel' : 'Create Group'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: TeleTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
