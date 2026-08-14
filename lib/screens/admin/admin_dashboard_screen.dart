import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/telegram_controller.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _personalMessageController =
      TextEditingController();
  final TextEditingController _personalPhotoController =
      TextEditingController();

  final TextEditingController _officialNameController =
      TextEditingController();
  final TextEditingController _officialDescController =
      TextEditingController();
  final TextEditingController _officialPhotoController =
      TextEditingController();

  bool _isChannel = false;
  bool _isAutoJoin = true;
  String _selectedUserId = 'u1';

  @override
  void dispose() {
    _personalMessageController.dispose();
    _personalPhotoController.dispose();
    _officialNameController.dispose();
    _officialDescController.dispose();
    _officialPhotoController.dispose();
    super.dispose();
  }

  void _handleSendPersonalOfficialMessage() {
    final text = _personalMessageController.text.trim();
    final photoUrl = _personalPhotoController.text.trim();

    if (text.isEmpty) {
      Get.snackbar('Required', 'Please enter personal official message text.',
          backgroundColor: Colors.amber[800], colorText: Colors.white);
      return;
    }

    TelegramController.to.sendPersonalOfficialMessage(
      userId: _selectedUserId,
      text: text,
      mediaUrl: photoUrl.isNotEmpty ? photoUrl : null,
    );

    _personalMessageController.clear();
    _personalPhotoController.clear();

    Get.snackbar(
      'Official Message Sent',
      'Personal official message dispatched from TeleLite Official.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _handleCreateOfficialGroupOrChannel() {
    final name = _officialNameController.text.trim();
    final desc = _officialDescController.text.trim();
    final photoUrl = _officialPhotoController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Required', 'Please enter Official Group/Channel name.',
          backgroundColor: Colors.amber[800], colorText: Colors.white);
      return;
    }

    final newChat = TelegramController.to.createOfficialGroupOrChannel(
      name: name,
      description: desc,
      isChannel: _isChannel,
      isAutoJoin: _isAutoJoin,
      avatarUrl: photoUrl,
    );

    _officialNameController.clear();
    _officialDescController.clear();
    _officialPhotoController.clear();

    Get.snackbar(
      'Official ${_isChannel ? "Channel" : "Group"} Created!',
      '${newChat.name} created. ${_isAutoJoin ? "(Auto-Join Enabled for New Users)" : ""}',
      backgroundColor: TeleTheme.primary,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = AdminService.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final stats = service.stats.value;
      final usersList = service.users;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== FEATURE 1: USER COUNT & STATS ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard Overview',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1. Total Users Stats, Personal Messages & Official Auto-Join Groups',
                      style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stat Cards Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Users (কতজন ইউজার)',
                    value: '${stats.totalUsers}',
                    subtitle: '↑ ${stats.usersToday} joined today',
                    icon: Icons.people_alt,
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Online Active Users',
                    value: '${(stats.totalUsers * 0.42).toInt()}',
                    subtitle: '🟢 Active on TeleLite Gateway',
                    icon: Icons.online_prediction,
                    color: Colors.green,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Official Auto-Join Channels',
                    value:
                        '${TelegramController.to.chats.where((c) => c.isOfficial).length}',
                    subtitle: '⭐ Auto-join new users',
                    icon: Icons.verified,
                    color: TeleTheme.primary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ==================== FEATURE 2 & 3: PERSONAL MESSAGE & OFFICIAL GROUP CREATION ====================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 3: SEND PERSONAL OFFICIAL MESSAGE
                Expanded(
                  child: Container(
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
                        const Row(
                          children: [
                            Icon(Icons.send_rounded, color: TeleTheme.primary),
                            SizedBox(width: 10),
                            Text(
                              '3. Send Personal Official Message',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Send direct official message to individual user as TeleLite Official:',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 16),

                        // Select Target User Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedUserId,
                          decoration: InputDecoration(
                            labelText: 'Select Target User',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          items: usersList.map((u) {
                            return DropdownMenuItem(
                              value: u.id,
                              child: Text('👤 ${u.name} (@${u.username})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedUserId = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // Message Text Field
                        TextField(
                          controller: _personalMessageController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Personal Official Message Text',
                            hintText:
                                'e.g. Welcome to TeleLite! Here is your official welcome guide...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Optional Photo URL
                        TextField(
                          controller: _personalPhotoController,
                          decoration: InputDecoration(
                            labelText: 'Photo Attachment URL (Optional)',
                            hintText: 'https://images.unsplash.com/photo-...',
                            prefixIcon: const Icon(Icons.image_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _handleSendPersonalOfficialMessage,
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Send Official Personal Message'),
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
                ),

                const SizedBox(width: 24),

                // SECTION 4: CREATE OFFICIAL GROUP / CHANNEL (WITH AUTO JOIN)
                Expanded(
                  child: Container(
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
                        const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.amber),
                            SizedBox(width: 10),
                            Text(
                              '4. Create Official Group / Channel',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'New registered users will automatically join this Official Group/Channel:',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 16),

                        // Name Field
                        TextField(
                          controller: _officialNameController,
                          decoration: InputDecoration(
                            labelText: 'Official Group / Channel Name',
                            hintText: 'e.g. TeleLite Official Updates',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description Field
                        TextField(
                          controller: _officialDescController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Official channel for TeleLite news...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Photo URL
                        TextField(
                          controller: _officialPhotoController,
                          decoration: InputDecoration(
                            labelText: 'Avatar Photo URL (Optional)',
                            hintText: 'https://images.unsplash.com/...',
                            prefixIcon: const Icon(Icons.add_a_photo_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Type Switch & Auto Join Checkbox
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Group'),
                                selected: !_isChannel,
                                onSelected: (sel) =>
                                    setState(() => _isChannel = !sel),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Channel'),
                                selected: _isChannel,
                                onSelected: (sel) =>
                                    setState(() => _isChannel = sel),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Auto-Join for New Users (নতুন ইউজার অটো জয়েন হবে)',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          value: _isAutoJoin,
                          onChanged: (val) =>
                              setState(() => _isAutoJoin = val ?? true),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _handleCreateOfficialGroupOrChannel,
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Create Official Auto-Join Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2330) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withAlpha(30),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
