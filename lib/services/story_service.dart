import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/story_model.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> canUploadStory() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    // 1. Check if user is premium
    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final isPremium = userDoc.data()?['isPremium'] == true;

    if (isPremium) return true; // Premium users have unlimited stories

    // 2. Count stories in the last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    
    final storyQuery = await _firestore
        .collection('stories')
        .where('ownerId', isEqualTo: currentUser.uid)
        .get();
        
    int recentStoryCount = 0;
    for (var doc in storyQuery.docs) {
      final data = doc.data();
      if (data['createdAt'] != null) {
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        if (createdAt.isAfter(sevenDaysAgo)) {
          recentStoryCount++;
        }
      }
    }
    
    // 3. Limit check (Max 4 stories per 7 days for free users)
    if (recentStoryCount >= 4) {
      throw Exception('WEEKLY_LIMIT_REACHED');
    }
    
    return true;
  }

  Future<int> getWeeklyStoryCount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final query = await _firestore
        .collection('stories')
        .where('ownerId', isEqualTo: currentUser.uid)
        .get();
        
    int count = 0;
    for (var doc in query.docs) {
      final data = doc.data();
      if (data['createdAt'] != null) {
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        if (createdAt.isAfter(sevenDaysAgo)) {
          count++;
        }
      }
    }
    return count;
  }

  Future<void> uploadStory({
    required String mediaUrl,
    required String mediaType,
    int? customDurationHours,
    String? customPrivacy,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Not logged in');

    // Check limit first
    await canUploadStory();

    // Fetch user details for defaults
    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data() ?? {};
    final isPremium = userData['isPremium'] == true;
    
    int durationHours = customDurationHours ?? userData['defaultDuration'] ?? 24;
    // Enforce 24h for free users even if their data says otherwise
    if (!isPremium) durationHours = 24;
    
    final privacy = customPrivacy ?? userData['storyPrivacy'] ?? 'everyone';


    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: durationHours));

    final storyData = {
      'ownerId': currentUser.uid,
      'ownerName': currentUser.displayName ?? currentUser.phoneNumber ?? 'User',
      'ownerAvatar': currentUser.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'durationHours': durationHours,
      'privacy': privacy,
      'viewersCount': 0,
      'isDeleted': false,
      'viewers': [],
      'viewerDetails': [],
    };

    await _firestore.collection('stories').add(storyData);
  }

  Stream<List<Story>> getActiveStories({
    String? currentUserId,
    List<String>? allowedOwnerIds,
  }) {
    return _firestore
        .collection('stories')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final allowedSet = (allowedOwnerIds ?? []).toSet();
      if (currentUserId != null) {
        allowedSet.add(currentUserId);
      }

      final stories = snapshot.docs
          .map((doc) => Story.fromFirestore(doc))
          .where((story) {
            if (story.isDeleted || !story.expiresAt.isAfter(now)) return false;

            // If currentUserId is provided, enforce contact/connection privacy:
            // User only sees stories from themselves or users they are connected with.
            if (currentUserId != null) {
              return allowedSet.contains(story.ownerId);
            }
            return true;
          })
          .toList();

      // Sort stories so that all stories from the same user are grouped together,
      // and within each user, ordered chronologically.
      stories.sort((a, b) {
        int ownerCompare = a.ownerId.compareTo(b.ownerId);
        if (ownerCompare != 0) return ownerCompare;
        return a.createdAt.compareTo(b.createdAt);
      });

      return stories;
    });
  }

  Stream<List<Story>> getUserStories(String userId) {
    return _firestore
        .collection('stories')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => Story.fromFirestore(doc))
          .where((story) => !story.isDeleted && story.expiresAt.isAfter(now))
          .toList();
    });
  }

  Future<void> markStoryAsViewed(String storyId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final storyRef = _firestore.collection('stories').doc(storyId);
    
    try {
      final snapshot = await storyRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final viewers = List<String>.from(data['viewers'] ?? []);
      
      if (!viewers.contains(currentUser.uid)) {
        await storyRef.update({
          'viewers': FieldValue.arrayUnion([currentUser.uid]),
          'viewerDetails': FieldValue.arrayUnion([{
            'uid': currentUser.uid,
            'name': currentUser.displayName ?? currentUser.phoneNumber ?? 'User',
            'avatar': currentUser.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
            'timestamp': Timestamp.now(),
          }]),
          'viewersCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error marking story as viewed: $e');
    }
  }
}
