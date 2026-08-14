import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _botTokenController;
  late TextEditingController _chatIdController;

  XFile? _pickedAvatarImage;
  Uint8List? _pickedAvatarBytes;
  bool _isSaving = false;

  AdminService get _adminService => AdminService.to;

  @override
  void initState() {
    super.initState();
    final profile = _adminService.adminProfile.value;
    _nameController = TextEditingController(text: profile.name);
    _titleController = TextEditingController(text: profile.title);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _avatarUrlController = TextEditingController(text: profile.avatarUrl);
    _botTokenController = TextEditingController(text: profile.telegramBotToken);
    _chatIdController = TextEditingController(text: profile.telegramChatId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    _botTokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  ImageProvider? _getAvatarImage(String avatarUrl) {
    // Picked image bytes take highest priority
    if (_pickedAvatarBytes != null) {
      return MemoryImage(_pickedAvatarBytes!);
    }
    // On web, picked XFile path is a blob URL
    if (_pickedAvatarImage != null && kIsWeb) {
      return NetworkImage(_pickedAvatarImage!.path);
    }
    // Base64 data URL saved in Firestore
    if (avatarUrl.startsWith('data:image')) {
      final dataStr = avatarUrl.split(',').last;
      return MemoryImage(base64Decode(dataStr));
    }
    // Firestore saved HTTP URL
    if (avatarUrl.startsWith('http') || avatarUrl.startsWith('blob:')) {
      return NetworkImage(avatarUrl);
    }
    return null;
  }

  Future<void> _pickAvatarFromDevice() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedAvatarImage = image;
        _pickedAvatarBytes = bytes;
        _avatarUrlController.text = image.name;
      });
    }
  }

  void _handleSaveProfile() async {
    final name = _nameController.text.trim();
    final title = _titleController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final botToken = _botTokenController.text.trim();
    final chatId = _chatIdController.text.trim();

    // Convert picked image bytes to base64 data URL for Firestore persistence
    String avatarUrl;
    if (_pickedAvatarBytes != null) {
      final base64Str = base64Encode(_pickedAvatarBytes!);
      avatarUrl = 'data:image/jpeg;base64,$base64Str';
    } else {
      avatarUrl = _adminService.adminProfile.value.avatarUrl;
    }

    if (name.isEmpty || email.isEmpty) {
      Get.snackbar('Required Fields', 'Please enter Admin Name and Email.',
          backgroundColor: Colors.amber[800], colorText: Colors.white);
      return;
    }

    setState(() => _isSaving = true);

    final updatedProfile = _adminService.adminProfile.value.copyWith(
      name: name,
      title: title.isNotEmpty ? title : 'System Administrator',
      email: email,
      phone: phone,
      avatarUrl: avatarUrl.isNotEmpty
          ? avatarUrl
          : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      telegramBotToken: botToken,
      telegramChatId: chatId,
    );

    await _adminService.saveAdminProfileToFirestore(updatedProfile);

    setState(() => _isSaving = false);

    Get.snackbar(
      'Profile Saved Live! ✅',
      'Admin profile details synced across Firestore and TeleLite Admin Panel.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final profile = _adminService.adminProfile.value;

      return Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TeleTheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded,
                        color: TeleTheme.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3. Admin Profile & System Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Manage Super Admin credentials, avatar photo, and Telegram bot configuration',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Admin Header Badge Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E2732) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: TeleTheme.primary,
                            backgroundImage: _getAvatarImage(profile.avatarUrl),
                            child: (profile.avatarUrl.isEmpty &&
                                    _pickedAvatarImage == null)
                                ? Text(
                                    profile.name.isNotEmpty
                                        ? profile.name[0]
                                        : 'A',
                                    style: const TextStyle(
                                        fontSize: 28, color: Colors.white),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: TeleTheme.primary,
                              child: IconButton(
                                iconSize: 14,
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: _pickAvatarFromDevice,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  profile.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withAlpha(40),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber),
                                  ),
                                  child: const Text(
                                    'SUPER ADMIN',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.title,
                              style: const TextStyle(
                                  fontSize: 13, color: TeleTheme.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${profile.email} • ${profile.phone}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Profile Edit Form Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E2732) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👤 Personal Credentials',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Admin Full Name
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Admin Full Name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Admin Title / Role
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Admin Designation / Title',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email & Phone Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Admin Email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Admin Phone Number',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Avatar Device Picker Button
                      OutlinedButton.icon(
                        onPressed: _pickAvatarFromDevice,
                        icon: const Icon(Icons.add_a_photo_rounded,
                            color: Colors.amber),
                        label: Text(
                          _pickedAvatarImage == null
                              ? '📷 Pick Avatar Photo from Device Gallery'
                              : '✅ Photo Selected (${_pickedAvatarImage!.name})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Divider(),
                      const SizedBox(height: 16),

                      const Text(
                        '🤖 Telegram Bot Gateway Settings',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Telegram Bot Token
                      TextField(
                        controller: _botTokenController,
                        decoration: InputDecoration(
                          labelText: 'Telegram Bot Token (@TeleLiteGuardianBot)',
                          prefixIcon: const Icon(Icons.vpn_key),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Telegram Chat ID
                      TextField(
                        controller: _chatIdController,
                        decoration: InputDecoration(
                          labelText: 'Telegram Admin Chat ID',
                          prefixIcon: const Icon(Icons.chat_bubble_outline),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Save Button
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSaveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving ? 'Saving...' : '💾 Save Admin Profile (Live)',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: TeleTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
