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
    
    final storyCountQuery = await _firestore
        .collection('stories')
        .where('ownerId', isEqualTo: currentUser.uid)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .count()
        .get();
    
    // 3. Limit check (Max 4 stories per 7 days for free users)
    if ((storyCountQuery.count ?? 0) >= 4) {
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
        .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .count()
        .get();
    return query.count ?? 0;
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
    };

    await _firestore.collection('stories').add(storyData);
  }

  Stream<List<Story>> getActiveStories() {
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Story.fromFirestore(doc))
          .where((story) => !story.isDeleted)
          .toList();
    });
  }

  Future<void> markStoryAsViewed(String storyId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final storyRef = _firestore.collection('stories').doc(storyId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(storyRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final viewers = List<String>.from(data['viewers'] ?? []);
      
      if (!viewers.contains(currentUser.uid)) {
        viewers.add(currentUser.uid);
        transaction.update(storyRef, {
          'viewers': viewers,
          'viewersCount': viewers.length,
        });
      }
    });
  }
}
