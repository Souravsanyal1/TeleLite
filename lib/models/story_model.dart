import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerAvatar;
  final String mediaUrl;
  final String mediaType;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int durationHours;
  final String privacy;
  final int viewersCount;
  final bool isDeleted;
  final List<String> viewers;

  Story({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerAvatar,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    required this.durationHours,
    required this.privacy,
    required this.viewersCount,
    required this.isDeleted,
    required this.viewers,
  });

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Story(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Unknown User',
      ownerAvatar: data['ownerAvatar'] ?? 'https://via.placeholder.com/150',
      mediaUrl: data['mediaUrl'] ?? '',
      mediaType: data['mediaType'] ?? 'image',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
      durationHours: data['durationHours'] ?? 24,
      privacy: data['privacy'] ?? 'everyone',
      viewersCount: data['viewersCount'] ?? 0,
      isDeleted: data['isDeleted'] ?? false,
      viewers: List<String>.from(data['viewers'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerAvatar': ownerAvatar,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'durationHours': durationHours,
      'privacy': privacy,
      'viewersCount': viewersCount,
      'isDeleted': isDeleted,
      'viewers': viewers,
    };
  }
}
