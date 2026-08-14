import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminNotificationControlScreen extends StatefulWidget {
  const AdminNotificationControlScreen({super.key});

  @override
  State<AdminNotificationControlScreen> createState() =>
      _AdminNotificationControlScreenState();
}

class _AdminNotificationControlScreenState
    extends State<AdminNotificationControlScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  String _selectedChannel = 'FCM Push'; // 'FCM Push', 'Telegram Bot'
  String _selectedPriority = 'High'; // 'High', 'Normal', 'Low'
  bool _selectAllUsers = true;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _dispatchNotification() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      Get.snackbar(
        'Required Fields',
        'Please enter both notification title and body message.',
        backgroundColor: Colors.amber[800],
        colorText: Colors.white,
      );
      return;
    }

    AdminService.to.sendBroadcastPush(
      title: title,
      body: body,
      channel: _selectedChannel,
      priority: _selectedPriority,
      targetUserIds: _selectAllUsers ? [] : ['u1'],
    );

    _titleController.clear();
    _bodyController.clear();

    Get.snackbar(
      'Notification Broadcasted',
      'Sent via $_selectedChannel with $_selectedPriority priority.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = AdminService.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final logs = service.logs;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Text(
              'Notification Control Center',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Broadcast Force FCM Notifications and Telegram Bot Alerts',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Notification Creation Box
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compose Broadcast Message',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Channel & Priority Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedChannel,
                          decoration: InputDecoration(
                            labelText: 'Notification Channel',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'FCM Push',
                              child: Text('📱 FCM Force Push Notification'),
                            ),
                            DropdownMenuItem(
                              value: 'Telegram Bot',
                              child: Text('🤖 Telegram Bot (@TeleLiteGuardianBot)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedChannel = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPriority,
                          decoration: InputDecoration(
                            labelText: 'Priority Level',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'High',
                              child: Text('🔴 High (Wake Device & Lockscreen)'),
                            ),
                            DropdownMenuItem(
                              value: 'Normal',
                              child: Text('🟡 Normal'),
                            ),
                            DropdownMenuItem(
                              value: 'Low',
                              child: Text('🟢 Low'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPriority = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title Field
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Notification Title',
                      hintText: 'e.g. 📢 Important System Update',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Body Field
                  TextField(
                    controller: _bodyController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Message Content',
                      hintText: 'Enter complete notification text...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _dispatchNotification,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text(
                        'Dispatch Force Broadcast',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeleTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Notification History Logs
            Text(
              'Recent Notification Logs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2330) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: log.channel.contains('Telegram')
                          ? Colors.blue
                          : TeleTheme.primary,
                      child: Icon(
                        log.channel.contains('Telegram')
                            ? Icons.smart_toy
                            : Icons.notifications,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(log.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${log.body} • Delivered to ${log.targetCount} users'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          log.timestamp,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(log.status,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10)),
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.zero,
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
