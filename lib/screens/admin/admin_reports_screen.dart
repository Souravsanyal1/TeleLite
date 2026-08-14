import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/admin_service.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AdminService.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final reports = service.reports;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Content Moderation & Reports',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Review user reports and moderate flagged content',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Reports List Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2330) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                itemBuilder: (context, index) {
                  final item = reports[index];
                  final isResolved = item.status == 'resolved';

                  return ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          isResolved ? Colors.green : Colors.orange,
                      child: Icon(
                        isResolved ? Icons.check_circle : Icons.warning,
                        color: Colors.white,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.reporterName} reported ${item.reportedName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          item.time,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'Reason: ${item.reason}',
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F1418)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '"${item.contentSnippet}"',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                    trailing: isResolved
                        ? const Chip(
                            label: Text('Resolved',
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.green,
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    service.resolveReport(item.id, false),
                                child: const Text('Dismiss'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () =>
                                    service.resolveReport(item.id, true),
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: const Text('Delete & Resolve'),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
