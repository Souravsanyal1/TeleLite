import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/premium_blocker.dart';

class EditProfileScreen extends StatefulWidget {
  final AuthService authService;
  final TelegramDataService dataService;
  final String currentName;
  final String currentUsername;
  final String currentBio;
  final String currentPhotoUrl;
  final bool isPremium;
  final String? currentProfileColor;
  final String? currentEmojiStatus;

  const EditProfileScreen({
    super.key,
    required this.authService,
    required this.dataService,
    required this.currentName,
    required this.currentUsername,
    required this.currentBio,
    required this.currentPhotoUrl,
    required this.isPremium,
    this.currentProfileColor,
    this.currentEmojiStatus,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late String _selectedAvatarUrl;
  String? _selectedProfileColor;
  String? _selectedEmojiStatus;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    // Remove the '@' if it exists in the current username
    final initialUsername = widget.currentUsername.startsWith('@') 
        ? widget.currentUsername.substring(1) 
        : widget.currentUsername;
    _usernameController = TextEditingController(text: initialUsername);
    _bioController = TextEditingController(text: widget.currentBio);
    _selectedAvatarUrl = widget.currentPhotoUrl;
    _selectedProfileColor = widget.currentProfileColor;
    _selectedEmojiStatus = widget.currentEmojiStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showCustomPhotoDialog() {
    final urlController = TextEditingController(text: _selectedAvatarUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Profile Photo'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://example.com/my-photo.jpg',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                setState(() {
                  _selectedAvatarUrl = urlController.text.trim();
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: TeleTheme.primary),
            child: const Text('Use Photo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleProfileSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final newUsername = _usernameController.text.trim();
      final currentRawUsername = widget.currentUsername.startsWith('@') 
          ? widget.currentUsername.substring(1) 
          : widget.currentUsername;

      // Only check uniqueness if the username has actually changed
      if (newUsername != currentRawUsername) {
        final isAvailable = await widget.authService.isUsernameAvailable(newUsername);
        if (!isAvailable) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Username @$newUsername is already taken.';
          });
          return;
        }
      }

      await widget.authService.createOrUpdateUserProfile(
        name: _nameController.text.trim(),
        username: newUsername,
        bio: _bioController.text.trim(),
        photoUrl: _selectedAvatarUrl,
        profileColor: _selectedProfileColor,
        emojiStatus: _selectedEmojiStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to save profile: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _handleProfileSave,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Avatar Selection
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: NetworkImage(_selectedAvatarUrl),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: TeleTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1c1c1d) : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: _showCustomPhotoDialog,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      value?.trim().isEmpty == true ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Username Input
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixText: '@ ',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty == true) {
                      return 'Username is required';
                    }
                    if (value!.contains(' ')) {
                      return 'Username cannot contain spaces';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Bio Input
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: Icon(Icons.info_outline),
                    border: OutlineInputBorder(),
                    hintText: 'A few words about you',
                  ),
                  maxLength: 70,
                ),
                const SizedBox(height: 16),

                // Premium Features Section
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Premium Features',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: TeleTheme.primary,
                    ),
                  ),
                ),
                
                // Profile Color
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _selectedProfileColor != null
                        ? Color(int.parse(_selectedProfileColor!.replaceFirst('#', '0xFF')))
                        : TeleTheme.primary,
                    child: const Icon(Icons.palette, color: Colors.white, size: 20),
                  ),
                  title: const Text('Name Color'),
                  subtitle: Text(_selectedProfileColor ?? 'Default'),
                  trailing: const Icon(Icons.star, color: Color(0xFFE94057), size: 20),
                  onTap: () {
                    if (!widget.isPremium) {
                      showPremiumRequiredDialog(context, 'Name and Profile Colors', widget.dataService, widget.authService);
                      return;
                    }
                    _showColorPicker();
                  },
                ),

                // Emoji Status
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF4CAF50),
                    child: Icon(Icons.emoji_emotions, color: Colors.white, size: 20),
                  ),
                  title: const Text('Emoji Status'),
                  subtitle: Text(_selectedEmojiStatus ?? 'None'),
                  trailing: const Icon(Icons.star, color: Color(0xFFE94057), size: 20),
                  onTap: () {
                    if (!widget.isPremium) {
                      showPremiumRequiredDialog(context, 'Emoji Statuses', widget.dataService, widget.authService);
                      return;
                    }
                    _showEmojiPicker();
                  },
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    final colors = ['#2196F3', '#E91E63', '#4CAF50', '#FF9800', '#9C27B0', '#009688', '#F44336'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Name Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((colorHex) {
            final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
            return GestureDetector(
              onTap: () {
                setState(() => _selectedProfileColor = colorHex);
                Navigator.pop(context);
              },
              child: CircleAvatar(
                backgroundColor: color,
                radius: 24,
                child: _selectedProfileColor == colorHex
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedProfileColor = null);
              Navigator.pop(context);
            },
            child: const Text('Reset to Default'),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    final emojis = ['🔥', '✨', '💤', '🎓', '💼', '🌴', '🚗', '🍔', '🎉', '🏆', '🎮', '🎧'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Emoji Status'),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () {
                setState(() => _selectedEmojiStatus = emoji);
                Navigator.pop(context);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedEmojiStatus = null);
              Navigator.pop(context);
            },
            child: const Text('Remove Status'),
          ),
        ],
      ),
    );
  }
}
