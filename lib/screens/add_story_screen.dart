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

  void _postStory() async {
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
          content: Text(e.toString() == 'Exception: WEEKLY_LIMIT_REACHED'
              ? 'Weekly limit reached (4 stories). Upgrade to Premium for unlimited stories!'
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
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isPosting ? null : _postStory,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: TeleTheme.primary,
                          shape: BoxShape.circle,
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
                            : const Icon(Icons.send,
                                color: Colors.white, size: 24),
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
