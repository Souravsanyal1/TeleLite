import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final AuthService authService;
  final String currentName;
  final String currentUsername;
  final String currentBio;
  final String currentPhotoUrl;

  const EditProfileScreen({
    super.key,
    required this.authService,
    required this.currentName,
    required this.currentUsername,
    required this.currentBio,
    required this.currentPhotoUrl,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
