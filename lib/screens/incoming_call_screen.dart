import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/call_controller.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final String chatId;
  final String callerId;
  final String callerName;
  final bool isVideo;

  const IncomingCallScreen({
    super.key,
    required this.chatId,
    required this.callerId,
    required this.callerName,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    final CallController controller = CallController.to;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Caller Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 24),

            // Caller Name
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Call Status
            Text(
              isVideo ? 'Incoming Video Call...' : 'Incoming Voice Call...',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 40),

            // Encryption badge (Telegram style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.greenAccent),
                  SizedBox(width: 6),
                  Text(
                    'End-to-End Encrypted',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Accept / Decline Buttons (Telegram style)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline Button
                _buildCallButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  size: 70,
                  onTap: () {
                    controller.endCall();
                    Get.back();
                  },
                ),

                // Accept Button
                _buildCallButton(
                  icon: isVideo ? Icons.videocam : Icons.phone,
                  color: Colors.green,
                  size: 70,
                  onTap: () {
                    Get.back();
                    Get.to(() => CallScreen(
                          chatId: chatId,
                          isVideo: isVideo,
                          isCaller: false,
                        ));
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
