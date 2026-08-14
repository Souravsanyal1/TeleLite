import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:get/get.dart';
import '../controllers/telegram_controller.dart';
import '../models/models.dart';
import '../services/cloudinary_service.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import 'group_management_screen.dart';
import 'user_profile_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final Chat chat;
  final TelegramDataService dataService;

  const ChatDetailScreen({
    super.key,
    required this.chat,
    required this.dataService,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  bool _isMuted = false;
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isUploadingAttachment = false;
  TelegramController get _controller => TelegramController.to;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.dataService.ensureChatExists(widget.chat);
      widget.dataService.markChatAsRead(widget.chat.id);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage({String? mediaUrl, String? textOverride}) {
    final text = textOverride ?? _textController.text;
    if (text.trim().isNotEmpty || (mediaUrl != null && mediaUrl.isNotEmpty)) {
      widget.dataService.sendMessage(
        widget.chat.id,
        text,
        mediaUrl: mediaUrl,
        fallbackChat: widget.chat,
      );
      if (textOverride == null) {
        _textController.clear();
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _openUserProfile() {
    if (widget.chat.isGroup || widget.chat.isChannel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupManagementScreen(
            chat: widget.chat,
            dataService: widget.dataService,
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          chat: widget.chat,
          dataService: widget.dataService,
        ),
      ),
    );
  }

  // ── Call Dialog / Active Call Screen ──────────────────────────────────────
  void _startCall(bool isVideo) {
    bool isMutedLocally = false;
    bool isSpeakerOn = false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setCallState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1418),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      isVideo ? 'Video Call' : 'Voice Call',
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 54,
                      backgroundImage: widget.chat.avatarUrl.isNotEmpty
                          ? NetworkImage(widget.chat.avatarUrl)
                          : null,
                      backgroundColor: TeleTheme.primary,
                      child: widget.chat.avatarUrl.isEmpty
                          ? Text(
                              widget.chat.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 36, color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.chat.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 14, color: Colors.greenAccent),
                        SizedBox(width: 6),
                        Text(
                          'End-to-End Encrypted',
                          style: TextStyle(
                              color: Colors.greenAccent, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Calling...',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),

                // Call Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Button
                    GestureDetector(
                      onTap: () {
                        setCallState(() => isMutedLocally = !isMutedLocally);
                      },
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: isMutedLocally
                            ? Colors.white
                            : Colors.white.withAlpha(30),
                        child: Icon(
                          isMutedLocally ? Icons.mic_off : Icons.mic,
                          color: isMutedLocally ? Colors.black : Colors.white,
                        ),
                      ),
                    ),

                    // End Call Button
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.red,
                        child: Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    // Speaker Button
                    GestureDetector(
                      onTap: () {
                        setCallState(() => isSpeakerOn = !isSpeakerOn);
                      },
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: isSpeakerOn
                            ? Colors.white
                            : Colors.white.withAlpha(30),
                        child: Icon(
                          isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          color: isSpeakerOn ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  // ── Attachment Menu (Gallery, Location, Contact, File) ───────────────────
  void _showAttachmentSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E242B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 24,
              runSpacing: 20,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildAttachOption(
                  icon: Icons.photo_library,
                  color: Colors.purpleAccent,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage();
                  },
                ),
                _buildAttachOption(
                  icon: Icons.insert_drive_file,
                  color: Colors.blueAccent,
                  label: 'Document',
                  onTap: () {
                    Navigator.pop(context);
                    _showUrlInputDialog('Send Document URL', (url) {
                      _sendMessage(mediaUrl: url, textOverride: '📄 Document');
                    });
                  },
                ),
                _buildAttachOption(
                  icon: Icons.location_on,
                  color: Colors.green,
                  label: 'Location',
                  onTap: () {
                    Navigator.pop(context);
                    _sendMessage(
                        textOverride:
                            '📍 Location: 23.8103° N, 90.4125° E (Dhaka, Bangladesh)');
                  },
                ),
                _buildAttachOption(
                  icon: Icons.person,
                  color: Colors.orange,
                  label: 'Contact',
                  onTap: () {
                    Navigator.pop(context);
                    _sendMessage(
                        textOverride:
                            '👤 Contact Card: TeleLite Support (+880 1700000000)');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withAlpha(35),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    if (kIsWeb) {
      _showUrlInputDialog('Send Photo URL', (url) {
        _sendMessage(mediaUrl: url, textOverride: '📷 Photo');
      });
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() => _isUploadingAttachment = true);
      final file = File(picked.path);
      final url = await _cloudinaryService.uploadFile(file);
      setState(() => _isUploadingAttachment = false);

      if (url != null) {
        _sendMessage(mediaUrl: url, textOverride: '📷 Photo');
      }
    } catch (e) {
      setState(() => _isUploadingAttachment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    }
  }

  void _showUrlInputDialog(String title, Function(String) onConfirm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/media.png',
            labelText: 'URL',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onConfirm(text);
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: TeleTheme.primary),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // ── Emoji Picker Sheet ───────────────────────────────────────────────────
  void _showEmojiSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const emojis = [
      '😃',
      '😊',
      '😂',
      '❤️',
      '👍',
      '🔥',
      '🎉',
      '🙏',
      '🚀',
      '💡',
      '✨',
      '👏',
      '🥳',
      '😍',
      '💯',
      '⚡',
      '📌',
      '😎',
      '🌟',
      '💙',
      '🙈',
      '🎁',
      '🏆',
      '🙌',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E242B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (_, index) {
                    return GestureDetector(
                      onTap: () {
                        _textController.text += emojis[index];
                        _textController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _textController.text.length),
                        );
                      },
                      child: Center(
                        child: Text(
                          emojis[index],
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.dataService,
      builder: (context, _) {
        var messages = widget.dataService.getMessagesForChat(widget.chat.id);
        if (_searchQuery.isNotEmpty) {
          messages = messages
              .where((m) =>
                  m.text.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        return Scaffold(
          appBar: AppBar(
            leadingWidth: 30,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  )
                : GestureDetector(
                    onTap: _openUserProfile,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: widget.chat.avatarUrl.isNotEmpty
                              ? NetworkImage(widget.chat.avatarUrl)
                              : null,
                          backgroundColor: TeleTheme.primary,
                          child: widget.chat.avatarUrl.isEmpty
                              ? Text(
                                  widget.chat.name.isNotEmpty
                                      ? widget.chat.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.chat.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.chat.isGroup
                                    ? '${widget.chat.memberCount} members'
                                    : widget.chat.isChannel
                                        ? '${widget.chat.memberCount} subscribers'
                                        : ((widget.chat.isOnline &&
                                                !widget.chat.isStealthMode)
                                            ? 'online'
                                            : 'last seen recently'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            actions: [
              if (_isSearching)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.call_outlined),
                  onPressed: () => _startCall(false),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'group_settings':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupManagementScreen(
                              chat: widget.chat,
                              dataService: widget.dataService,
                            ),
                          ),
                        );
                        break;
                      case 'view_profile':
                        _openUserProfile();
                        break;
                      case 'mute':
                        setState(() => _isMuted = !_isMuted);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isMuted
                                ? 'Muted notifications for ${widget.chat.name}'
                                : 'Unmuted notifications for ${widget.chat.name}'),
                          ),
                        );
                        break;
                      case 'search':
                        setState(() => _isSearching = true);
                        break;
                      case 'clear':
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear Chat History?'),
                            content: Text(
                                'Are you sure you want to clear all messages with ${widget.chat.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  widget.dataService
                                      .clearChatMessages(widget.chat.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Chat history cleared')),
                                  );
                                },
                                child: const Text('Clear',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        break;
                      case 'block':
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Blocked ${widget.chat.name}')),
                        );
                        break;
                      case 'leave':
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Left ${widget.chat.name}')),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (widget.chat.isGroup || widget.chat.isChannel)
                      PopupMenuItem(
                        value: 'group_settings',
                        child: Row(
                          children: [
                            const Icon(Icons.settings,
                                color: TeleTheme.primary, size: 20),
                            const SizedBox(width: 10),
                            Text(widget.chat.isChannel
                                ? 'Channel Settings'
                                : 'Group Settings'),
                          ],
                        ),
                      ),
                    if (!widget.chat.isGroup && !widget.chat.isChannel)
                      const PopupMenuItem(
                        value: 'view_profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline,
                                color: TeleTheme.primary, size: 20),
                            SizedBox(width: 10),
                            Text('View Profile / Details'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'mute',
                      child: Row(
                        children: [
                          Icon(
                            _isMuted
                                ? Icons.notifications_active
                                : Icons.notifications_off_outlined,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(_isMuted
                              ? 'Unmute Notifications'
                              : 'Mute Notifications'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'search',
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 10),
                          Text('Search in Chat'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.cleaning_services_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Clear History'),
                        ],
                      ),
                    ),
                    if (!widget.chat.isGroup && !widget.chat.isChannel)
                      const PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block,
                                color: Colors.redAccent, size: 20),
                            SizedBox(width: 10),
                            Text('Block User',
                                style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    if (widget.chat.isGroup || widget.chat.isChannel)
                      PopupMenuItem(
                        value: 'leave',
                        child: Row(
                          children: [
                            const Icon(Icons.exit_to_app,
                                color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              widget.chat.isChannel
                                  ? 'Leave Channel'
                                  : 'Leave Group',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          body: Container(
            color: isDark ? const Color(0xFF0F1418) : const Color(0xFFE6EBF0),
            child: Column(
              children: [
                // Date Chip
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black38 : Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                if (widget.chat.disableSharing)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: isDark ? Colors.black26 : Colors.black12,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.security, size: 14, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          'Sharing & Forwarding restricted',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                // Uploading Banner
                if (_isUploadingAttachment)
                  Container(
                    width: double.infinity,
                    color: TeleTheme.primary.withAlpha(40),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: TeleTheme.primary)),
                        SizedBox(width: 8),
                        Text('Uploading media...',
                            style: TextStyle(
                                fontSize: 13,
                                color: TeleTheme.primary,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                // Message List
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? 'No messages matching "$_searchQuery"'
                                : 'No messages yet. Say hi!',
                            style: TextStyle(
                                color:
                                    isDark ? Colors.white38 : Colors.black38),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            return _buildMessageBubble(msg, isDark);
                          },
                        ),
                ),

                // Message Input Field
                _buildInputBar(isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message msg, bool isDark) {
    final isMe = msg.isSentByMe;

    final receivedColor = widget.chat.profileColor != null
        ? Color(int.parse(widget.chat.profileColor!.replaceFirst('#', '0xFF')))
        : (isDark
            ? TeleTheme.receivedBubbleDark
            : TeleTheme.receivedBubbleLight);

    final bubbleColor = isMe
        ? (isDark ? TeleTheme.sentBubbleDark : TeleTheme.sentBubbleLight)
        : receivedColor;

    final textColor = isMe
        ? (isDark ? Colors.white : Colors.black87)
        : (widget.chat.profileColor != null
            ? Colors.white
            : (isDark ? Colors.white : Colors.black87));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 8,
          runSpacing: 4,
          children: [
            // Render photo/media attachment if present
            if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  msg.mediaUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey.withAlpha(40),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insert_drive_file, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Media attachment'),
                      ],
                    ),
                  ),
                ),
              ),

            if (msg.text.isNotEmpty)
              Text(
                msg.text,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                  height: 1.3,
                ),
              ),

            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      (msg.isRead && !widget.chat.isStealthMode)
                          ? Icons.done_all
                          : Icons.done,
                      size: 14,
                      color: TeleTheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E242B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: _showAttachmentSheet,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2B333E)
                      : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _textController,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.sentiment_satisfied_alt_outlined,
                  color: Colors.grey),
              onPressed: _showEmojiSheet,
            ),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: TeleTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
