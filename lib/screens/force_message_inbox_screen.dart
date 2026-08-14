import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';

class ForceMessageInboxScreen extends StatelessWidget {
  final String? initialMessageId;

  const ForceMessageInboxScreen({super.key, this.initialMessageId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.amber),
            SizedBox(width: 10),
            Text(
              'Inbox & Force Messages',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('admin_notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildFallbackInbox(isDark);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildFallbackInbox(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final id = docs[index].id;
              final title = (data['title'] ?? 'System Broadcast').toString();
              final body = (data['body'] ?? '').toString();
              final imageUrl = data['imageUrl']?.toString();
              final target = (data['target'] ?? 'All').toString();
              final isHighlighted = id == initialMessageId;

              return _buildNotificationCard(
                context: context,
                id: id,
                title: title,
                body: body,
                imageUrl: imageUrl,
                target: target,
                timeAgo: 'Just now',
                isHighlighted: isHighlighted,
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFallbackInbox(bool isDark) {
    final demoItems = [
      {
        'id': 'b1',
        'title': '🔔 TeleLite Critical Maintenance',
        'body':
            'Emergency database upgrade scheduled tonight. System services will remain uninterrupted.',
        'target': 'All',
        'timeAgo': '2 min ago',
      },
      {
        'id': 'b2',
        'title': '⚡ New High-Speed Cloud Server Live',
        'body':
            'We upgraded our media CDN for faster voice calls and 4K video downloads worldwide.',
        'target': 'Premium',
        'timeAgo': '1 hour ago',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: demoItems.length,
      itemBuilder: (context, index) {
        final item = demoItems[index];
        return _buildNotificationCard(
          context: context,
          id: item['id']!,
          title: item['title']!,
          body: item['body']!,
          imageUrl: null,
          target: item['target']!,
          timeAgo: item['timeAgo']!,
          isHighlighted: item['id'] == initialMessageId,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required String id,
    required String title,
    required String body,
    required String? imageUrl,
    required String target,
    required String timeAgo,
    required bool isHighlighted,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: isHighlighted ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isHighlighted
            ? const BorderSide(color: TeleTheme.primary, width: 2)
            : BorderSide.none,
      ),
      color: isDark ? const Color(0xFF1E2732) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: TeleTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Target: $target',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: TeleTheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
                height: 1.4,
              ),
            ),
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Get.snackbar(
                      'Acknowledged',
                      'Notification accepted.',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Read & Accept'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
