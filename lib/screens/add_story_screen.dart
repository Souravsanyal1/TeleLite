import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/story_service.dart';

import '../services/cloudinary_service.dart';

class AddStoryScreen extends StatefulWidget {
  final File mediaFile;
  final bool isVideo;

  const AddStoryScreen({super.key, required this.mediaFile, this.isVideo = false});

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  final TextEditingController _captionController = TextEditingController();
  final StoryService _storyService = StoryService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isPosting = false;

  int _selectedDuration = 24;
  String _selectedPrivacy = 'everyone';

  void _showPublishSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Publish story as', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.grey),
                    title: Text('My Story', style: TextStyle(color: Colors.white)),
                    subtitle: Text('personal account', style: TextStyle(color: Colors.white54)),
                    trailing: Icon(Icons.chevron_right, color: Colors.white54),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(color: Colors.white24),
                  const Text('Who can view your story', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildPrivacyOption(
                    icon: Icons.public,
                    title: 'Everyone',
                    value: 'everyone',
                    currentValue: _selectedPrivacy,
                    onTap: () {
                      setSheetState(() => _selectedPrivacy = 'everyone');
                      setState(() => _selectedPrivacy = 'everyone');
                    },
                  ),
                  _buildPrivacyOption(
                    icon: Icons.contacts,
                    title: 'Contacts',
                    value: 'contacts',
                    currentValue: _selectedPrivacy,
                    onTap: () {
                      setSheetState(() => _selectedPrivacy = 'contacts');
                      setState(() => _selectedPrivacy = 'contacts');
                    },
                  ),
                  _buildPrivacyOption(
                    icon: Icons.star,
                    title: 'Close Friends',
                    value: 'close_friends',
                    currentValue: _selectedPrivacy,
                    iconColor: Colors.green,
                    onTap: () {
                      setSheetState(() => _selectedPrivacy = 'close_friends');
                      setState(() => _selectedPrivacy = 'close_friends');
                    },
                  ),
                  const Divider(color: Colors.white24),
                  SwitchListTile(
                    title: const Text('Allow Screenshots', style: TextStyle(color: Colors.white)),
                    value: true,
                    onChanged: (v) {},
                    activeThumbColor: Colors.blue,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Keep on My Page', style: TextStyle(color: Colors.white)),
                    value: true,
                    onChanged: (v) {},
                    activeThumbColor: Colors.blue,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  const Text('Keep this story on your page even after it expires. Privacy settings will apply.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isPosting ? null : () {
                        Navigator.pop(context);
                        _publishStory();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: _isPosting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Post Story', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrivacyOption({
    required IconData icon,
    required String title,
    required String value,
    required String currentValue,
    required VoidCallback onTap,
    Color iconColor = Colors.blueAccent,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Radio<String>(
        value: value,
        groupValue: currentValue,
        onChanged: (v) => onTap(),
        activeColor: Colors.blueAccent,
      ),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }

  void _publishStory() async {
    setState(() => _isPosting = true);

    try {
      final secureUrl = await _cloudinaryService.uploadFile(
        widget.mediaFile,
        isVideo: widget.isVideo,
      );

      if (secureUrl == null) throw Exception('Failed to get secure URL from Cloudinary');

      await _storyService.uploadStory(
        mediaUrl: secureUrl,
        mediaType: widget.isVideo ? 'video' : 'image',
        customDurationHours: _selectedDuration,
        customPrivacy: _selectedPrivacy,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story posted successfully!'),
          backgroundColor: TeleTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('WEEKLY_LIMIT_REACHED')
              ? 'Weekly limit reached. Upgrade to Premium!'
              : 'Failed to post story: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Image Preview
            Center(
              child: widget.isVideo
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, size: 100, color: Colors.white54),
                        SizedBox(height: 16),
                        Text('Video Selected', style: TextStyle(color: Colors.white70)),
                      ],
                    )
                  : Image.file(
                      widget.mediaFile,
                      fit: BoxFit.contain,
                    ),
            ),

            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Bar with Caption and Post Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, bottom: 16, top: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _captionController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Add a caption...',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            PopupMenuButton<int>(
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white70, width: 1.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Text('$_selectedDuration', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              color: const Color(0xFF2C2C2C),
                              onSelected: (value) => setState(() => _selectedDuration = value),
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 6, child: Text('6 hours', style: TextStyle(color: Colors.white))),
                                const PopupMenuItem(value: 12, child: Text('12 hours', style: TextStyle(color: Colors.white))),
                                const PopupMenuItem(value: 24, child: Text('24 hours', style: TextStyle(color: Colors.white))),
                                const PopupMenuItem(value: 48, child: Text('48 hours', style: TextStyle(color: Colors.white))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isPosting ? null : _showPublishSettings,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _isPosting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                children: [
                                  Text('NEXT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Icon(Icons.chevron_right, color: Colors.white, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
