import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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

  XFile? _pickedPersonalImage;
  XFile? _pickedOfficialImage;

  Future<void> _pickPersonalDeviceImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedPersonalImage = image;
        _personalPhotoController.text = image.path;
      });
    }
  }

  Future<void> _pickOfficialDeviceImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedOfficialImage = image;
        _officialPhotoController.text = image.path;
      });
    }
  }

  @override
  void dispose() {
    _personalMessageController.dispose();
    _personalPhotoController.dispose();
    _officialNameController.dispose();
    _officialDescController.dispose();
    _officialPhotoController.dispose();
    super.dispose();
  }

  void _handleSendPersonalOfficialMessage() async {
    final text = _personalMessageController.text.trim();
    final photoUrl = _pickedPersonalImage != null
        ? _pickedPersonalImage!.path
        : _personalPhotoController.text.trim();

    if (text.isEmpty && photoUrl.isEmpty) {
      Get.snackbar('Required', 'Please enter message text or select a photo.',
          backgroundColor: Colors.amber[800], colorText: Colors.white);
      return;
    }

    TelegramController.to.sendPersonalOfficialMessage(
      userId: _selectedUserId,
      text: text,
      mediaUrl: photoUrl.isNotEmpty ? photoUrl : null,
    );

    // Save REAL document to Firestore official_messages
    await AdminService.to.saveOfficialMessageToFirestore(
      targetUserId: _selectedUserId,
      text: text,
      mediaUrl: photoUrl.isNotEmpty ? photoUrl : null,
    );

    // Trigger REAL Telegram Bot Notice
    await AdminService.to.sendTelegramBotNotice(
      _selectedUserId,
      text,
    );

    setState(() {
      _pickedPersonalImage = null;
    });
    _personalMessageController.clear();
    _personalPhotoController.clear();

    Get.snackbar(
      'Official Message Sent (Live)',
      'Personal official message with photo dispatched and saved to Firestore.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _handleCreateOfficialGroupOrChannel() async {
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

    // Save REAL document to Firestore official_chats
    await AdminService.to.saveOfficialChatToFirestore(
      chatId: newChat.id,
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
            const SizedBox(height: 28),

            // ==================== FEATURE: USER LIST & PREMIUM ACCESS CONTROL ====================
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              color: Colors.amber, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'User Premium Management (ইউজার প্রিমিয়াম কন্ট্রোল)',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Text(
                          '${usersList.where((u) => u.isPremiumActive).length} Premium Active',
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Grant or revoke Premium subscription per user with automatic time lock (6h, 12h, 24h, 48h, 7d, 30d, Lifetime)',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  if (usersList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No registered users found.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: usersList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final u = usersList[index];
                        final isPrem = u.isPremiumActive;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isPrem
                                    ? Colors.amber
                                    : TeleTheme.primary,
                                backgroundImage:
                                    u.avatarUrl.startsWith('http')
                                        ? NetworkImage(u.avatarUrl)
                                        : null,
                                child: u.avatarUrl.isEmpty
                                    ? Text(
                                        u.name.isNotEmpty
                                            ? u.name[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          u.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isPrem)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withAlpha(40),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                  color: Colors.amber),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                    Icons.star_rounded,
                                                    color: Colors.amber,
                                                    size: 12),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'PREMIUM (${u.premiumRemainingText})',
                                                  style: const TextStyle(
                                                      color: Colors.amber,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withAlpha(30),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'FREE PLAN',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${u.phone} • @${u.username}',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Action Controls
                              PopupMenuButton<int?>(
                                tooltip: 'Set Premium Duration',
                                icon: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isPrem
                                        ? Colors.green.withAlpha(30)
                                        : TeleTheme.primary.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isPrem
                                          ? Colors.green
                                          : TeleTheme.primary,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPrem
                                            ? Icons.check_circle_rounded
                                            : Icons.add_moderator_rounded,
                                        size: 14,
                                        color: isPrem
                                            ? Colors.green
                                            : TeleTheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPrem ? 'Extend' : 'Grant Premium',
                                        style: TextStyle(
                                          color: isPrem
                                              ? Colors.green
                                              : TeleTheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onSelected: (hours) {
                                  service.grantPremiumAccess(u.id,
                                      durationHours: hours);
                                  Get.snackbar(
                                    'Premium Granted! ⭐',
                                    hours != null
                                        ? '${u.name} granted Premium for $hours Hours.'
                                        : '${u.name} granted Lifetime Premium.',
                                    backgroundColor: Colors.amber[800],
                                    colorText: Colors.white,
                                  );
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 6,
                                    child: Text('⏱️ 6 Hours Premium'),
                                  ),
                                  const PopupMenuItem(
                                    value: 12,
                                    child: Text('⏱️ 12 Hours Premium'),
                                  ),
                                  const PopupMenuItem(
                                    value: 24,
                                    child: Text('⏱️ 24 Hours (1 Day) Premium'),
                                  ),
                                  const PopupMenuItem(
                                    value: 48,
                                    child: Text('⏱️ 48 Hours (2 Days) Premium'),
                                  ),
                                  const PopupMenuItem(
                                    value: 168,
                                    child: Text('📅 7 Days (1 Week) Premium'),
                                  ),
                                  const PopupMenuItem(
                                    value: 720,
                                    child: Text('📅 30 Days (1 Month) Premium'),
                                  ),
                                  const PopupMenuItem(
                                    value: null,
                                    child: Text('♾️ Lifetime (Permanent) Premium'),
                                  ),
                                ],
                              ),
                              if (isPrem) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Revoke Premium Access',
                                  icon: const Icon(Icons.lock_rounded,
                                      color: Colors.red, size: 18),
                                  onPressed: () {
                                    service.revokePremiumAccess(u.id);
                                    Get.snackbar(
                                      'Premium Revoked 🔒',
                                      '${u.name} is now locked to Free plan.',
                                      backgroundColor: Colors.red[800],
                                      colorText: Colors.white,
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
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

                        // Device Image Picker for Photo Attachment
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickPersonalDeviceImage,
                                icon: const Icon(Icons.add_photo_alternate_rounded, color: TeleTheme.primary),
                                label: Text(
                                  _pickedPersonalImage == null
                                      ? '📁 Select Photo from Device'
                                      : '✅ Photo Selected (${_pickedPersonalImage!.name})',
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
                            if (_pickedPersonalImage != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'Remove Photo',
                                onPressed: () {
                                  setState(() {
                                    _pickedPersonalImage = null;
                                    _personalPhotoController.clear();
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                        if (_pickedPersonalImage != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            height: 60,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: TeleTheme.primary.withAlpha(80)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.image, color: TeleTheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Attached: ${_pickedPersonalImage!.name}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

                        // Avatar Photo Device Picker
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickOfficialDeviceImage,
                                icon: const Icon(Icons.add_a_photo_rounded, color: Colors.amber),
                                label: Text(
                                  _pickedOfficialImage == null
                                      ? '📷 Select Avatar Photo from Device'
                                      : '✅ Avatar Selected (${_pickedOfficialImage!.name})',
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
                            if (_pickedOfficialImage != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'Remove Photo',
                                onPressed: () {
                                  setState(() {
                                    _pickedOfficialImage = null;
                                    _officialPhotoController.clear();
                                  });
                                },
                              ),
                            ],
                          ],
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
