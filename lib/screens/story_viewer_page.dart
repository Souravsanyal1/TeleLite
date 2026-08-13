import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';

class StoryViewerPage extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> {
  late PageController _pageController;
  late int _currentIndex;
  final StoryService _storyService = StoryService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _markCurrentStoryAsViewed();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markCurrentStoryAsViewed() {
    if (widget.stories.isNotEmpty) {
      _storyService.markStoryAsViewed(widget.stories[_currentIndex].id);
    }
  }

  void _showViewersBottomSheet(Story story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            final details = story.viewerDetails;
            if (details.isEmpty) {
              return const Center(child: Text('No views yet', style: TextStyle(color: Colors.white70)));
            }
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Viewers', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: details.length,
                    itemBuilder: (context, index) {
                      final viewer = details[index];
                      final timestamp = viewer['timestamp'] as Timestamp;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(viewer['avatar'] ?? 'https://via.placeholder.com/150'),
                        ),
                        title: Text(viewer['name'] ?? 'User', style: const TextStyle(color: Colors.white)),
                        trailing: Text(_formatTimeAgo(timestamp.toDate()), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Content
          PageView.builder(
            controller: _pageController,
            itemCount: widget.stories.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _markCurrentStoryAsViewed();
            },
            itemBuilder: (context, index) {
              final story = widget.stories[index];
              return _buildStoryContent(story);
            },
          ),
          
          // Tap Controls (Left = Previous, Right = Next)
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentIndex < widget.stories.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Swipe down to close
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! > 10) {
                  Navigator.pop(context);
                }
              },
            ),
          ),

          // Top Bar (Back button + Viewer count + User Info)
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(widget.stories[_currentIndex].ownerAvatar),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.stories[_currentIndex].ownerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.stories[_currentIndex].viewersCount}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar (Viewers list for owner)
          if (widget.stories.isNotEmpty &&
              FirebaseAuth.instance.currentUser != null &&
              widget.stories[_currentIndex].ownerId == FirebaseAuth.instance.currentUser!.uid)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _showViewersBottomSheet(widget.stories[_currentIndex]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.stories[_currentIndex].viewerDetails.length} Viewers',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    return CachedNetworkImage(
      imageUrl: story.mediaUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.error, color: Colors.white),
      ),
    );
  }
}
