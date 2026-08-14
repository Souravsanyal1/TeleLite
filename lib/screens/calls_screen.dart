import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/telegram_controller.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';

class CallsScreen extends StatelessWidget {
  final TelegramDataService dataService;

  const CallsScreen({super.key, required this.dataService});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TelegramController.to;

    return Obx(() {
      final calls = controller.calls;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: calls.length,
        itemBuilder: (context, index) {
          final call = calls[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(call.avatarUrl),
            ),
            title: Text(
              call.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: call.isMissed
                    ? Colors.red
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            subtitle: Row(
              children: [
                Icon(
                  call.isOutgoing ? Icons.call_made : Icons.call_received,
                  size: 14,
                  color: call.isMissed ? Colors.red : TeleTheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  call.time,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                call.isVideo ? Icons.videocam_outlined : Icons.phone_outlined,
                color: TeleTheme.primary,
              ),
              onPressed: () {},
            ),
          );
        },
      ),
    );
    });
  }
}
