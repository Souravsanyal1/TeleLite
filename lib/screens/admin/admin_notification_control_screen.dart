import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/telegram_controller.dart';
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
  final TextEditingController _photoUrlController = TextEditingController();

  String _selectedChannel = 'FCM Push'; // 'FCM Push', 'Telegram Bot'
  final String _selectedPriority = 'High';

  XFile? _pickedBroadcastImage;

  Future<void> _pickBroadcastDeviceImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedBroadcastImage = image;
        _photoUrlController.text = image.path;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _dispatchForceBroadcast() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final photoUrl = _pickedBroadcastImage != null
        ? _pickedBroadcastImage!.path
        : _photoUrlController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      Get.snackbar(
        'Required Fields',
        'Please enter both message title and broadcast content text.',
        backgroundColor: Colors.amber[800],
        colorText: Colors.white,
      );
      return;
    }

    // Send Force Broadcast Message with Photo Support
    TelegramController.to.sendForceBroadcastMessage(
      title: title,
      body: body,
      mediaUrl: photoUrl.isNotEmpty ? photoUrl : null,
    );

    AdminService.to.sendBroadcastPush(
      title: title,
      body: body,
      channel: _selectedChannel,
      priority: _selectedPriority,
      targetUserIds: [],
      imageUrl: photoUrl.isNotEmpty ? photoUrl : null,
    );

    setState(() {
      _pickedBroadcastImage = null;
    });
    _titleController.clear();
    _bodyController.clear();
    _photoUrlController.clear();

    Get.snackbar(
      'Force Broadcast Dispatched!',
      'Message & Photo broadcasted to all active users via $_selectedChannel.',
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
              '2. Force Message System (With Photo Support)',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Broadcast high-priority push messages with optional photo attachments to all TeleLite users',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Notification Creation Box
            Container(
              padding: const EdgeInsets.all(24),
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
                  const Row(
                    children: [
                      Icon(Icons.campaign_rounded,
                          color: TeleTheme.primary, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Compose Force Broadcast Message',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Notification Channel Selection
                  DropdownButtonFormField<String>(
                    value: _selectedChannel,
                    decoration: InputDecoration(
                      labelText: 'Broadcast Channel',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'FCM Push',
                        child: Text(
                            '📱 FCM Push Notification (In-App & Device Tray)'),
                      ),
                      DropdownMenuItem(
                        value: 'Telegram Bot',
                        child: Text('🤖 @TeleLiteGuardianBot Alert'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedChannel = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Title Field
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Force Message Title',
                      hintText: 'e.g. 📢 Important Update / Special Announcement',
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
                      labelText: 'Message Body Content',
                      hintText: 'Enter complete notification text message...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Device Image Picker for Broadcast Photo Attachment
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickBroadcastDeviceImage,
                          icon: const Icon(Icons.add_photo_alternate_rounded, color: TeleTheme.primary),
                          label: Text(
                            _pickedBroadcastImage == null
                                ? '📁 Select Broadcast Photo from Device'
                                : '✅ Photo Selected (${_pickedBroadcastImage!.name})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      if (_pickedBroadcastImage != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          tooltip: 'Remove Photo',
                          onPressed: () {
                            setState(() {
                              _pickedBroadcastImage = null;
                              _photoUrlController.clear();
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _dispatchForceBroadcast,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text(
                        'Dispatch Force Broadcast (With Photo)',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeleTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Notification History Logs
            Text(
              'Broadcast History Logs',
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
                separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? Colors.white12 : Colors.black12),
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
                            : Icons.campaign,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(log.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${log.body} • Delivered to ${log.targetCount} users'),
                    trailing: Text(
                      log.timestamp,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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
