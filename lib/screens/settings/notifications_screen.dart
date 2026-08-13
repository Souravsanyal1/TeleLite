import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _privateChats = true;
  bool _groupChats = true;
  bool _channels = true;
  bool _inAppSound = true;
  bool _inAppVibrate = true;
  bool _badgeCounter = true;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      if (!mounted) return;
      if (result.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission granted!')),
        );
      } else if (result.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification permission denied'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _onToggleNotification(Function() toggle) async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final req = await Permission.notification.request();
      if (!req.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification permission required'),
              action: SnackBarAction(
                label: 'Enable',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
    }
    setState(toggle);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications and Sounds'),
      ),
      body: ListView(
        children: [
          _buildHeader('MESSAGE NOTIFICATIONS', isDark),
          SwitchListTile(
            title: const Text('Private Chats'),
            subtitle: const Text('Tap to customize sound & alerts'),
            value: _privateChats,
            onChanged: (val) => _onToggleNotification(() => _privateChats = val),
            secondary: const Icon(Icons.person_outline, color: TeleTheme.primary),
          ),
          SwitchListTile(
            title: const Text('Group Chats'),
            subtitle: const Text('Tap to customize sound & alerts'),
            value: _groupChats,
            onChanged: (val) => _onToggleNotification(() => _groupChats = val),
            secondary: const Icon(Icons.group_outlined, color: Colors.amber),
          ),
          SwitchListTile(
            title: const Text('Channels'),
            subtitle: const Text('Tap to customize sound & alerts'),
            value: _channels,
            onChanged: (val) => _onToggleNotification(() => _channels = val),
            secondary: const Icon(Icons.campaign_outlined, color: Colors.purple),
          ),

          const Divider(),
          _buildHeader('IN-APP NOTIFICATIONS', isDark),
          SwitchListTile(
            title: const Text('In-App Sounds'),
            value: _inAppSound,
            onChanged: (val) => _onToggleNotification(() => _inAppSound = val),
            secondary: const Icon(Icons.volume_up_outlined, color: Colors.cyan),
          ),
          SwitchListTile(
            title: const Text('In-App Vibration'),
            value: _inAppVibrate,
            onChanged: (val) => _onToggleNotification(() => _inAppVibrate = val),
            secondary: const Icon(Icons.vibration_outlined, color: Colors.teal),
          ),

          const Divider(),
          _buildHeader('BADGE COUNTER', isDark),
          SwitchListTile(
            title: const Text('Include Unread Messages'),
            subtitle: const Text('Show unread message badge on app icon'),
            value: _badgeCounter,
            onChanged: (val) => _onToggleNotification(() => _badgeCounter = val),
            secondary: const Icon(Icons.mark_chat_unread_outlined, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }
}
