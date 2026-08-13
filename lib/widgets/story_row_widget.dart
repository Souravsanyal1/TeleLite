import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/story_model.dart';
import '../screens/story_viewer_page.dart';

class StoryRowWidget extends StatelessWidget {
  final List<Story> stories;
  final VoidCallback onAddStoryTap;

  const StoryRowWidget({
    super.key,
    required this.stories,
    required this.onAddStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildMyStoryButton(context);
          }
          final story = stories[index - 1];
          return _buildStoryAvatar(context, story, currentUserId);
        },
      ),
    );
  }

  Widget _buildMyStoryButton(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: onAddStoryTap,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.grey.withAlpha(50), width: 2.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.5),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: currentUser?.photoURL != null
                      ? NetworkImage(currentUser!.photoURL!)
                      : const NetworkImage(
                              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150')
                          as ImageProvider,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: const Color(0xFF0088CC), // Primary Blue as requested
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).appBarTheme.backgroundColor ??
                        Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.add, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryAvatar(
      BuildContext context, Story story, String currentUserId) {
    final isViewed = story.viewers.contains(currentUserId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryViewerPage(
                stories: stories,
                initialIndex: stories.indexOf(story),
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isViewed ? const Color(0xFF8E8E93) : const Color(0xFF34C759),
              width: 3,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(story.ownerAvatar),
              child: story.mediaType == 'video'
                  ? const Icon(Icons.play_arrow, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
