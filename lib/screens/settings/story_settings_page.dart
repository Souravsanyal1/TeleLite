import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/story_service.dart';
import '../../services/mock_data.dart';
import '../../services/auth_service.dart';
import 'telegram_premium_screen.dart';

class StorySettingsPage extends StatefulWidget {
  final TelegramDataService dataService;
  final AuthService authService;

  const StorySettingsPage({
    super.key,
    required this.dataService,
    required this.authService,
  });

  @override
  State<StorySettingsPage> createState() => _StorySettingsPageState();
}

class _StorySettingsPageState extends State<StorySettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StoryService _storyService = StoryService();

  int _storyCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoryCount();
  }

  Future<void> _loadStoryCount() async {
    final count = await _storyService.getWeeklyStoryCount();
    if (mounted) {
      setState(() {
        _storyCount = count;
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrivacy(String value) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'storyPrivacy': value});
    }
  }

  Future<void> _updateDuration(int value) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'defaultDuration': value});
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Settings'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final isPremium = userData['isPremium'] == true;
          final privacy = userData['storyPrivacy'] ?? 'everyone';
          final duration = userData['defaultDuration'] ?? 24;

          return ListView(
            children: [
              _buildSectionHeader('Privacy'),
              _buildRadioTile(
                title: 'Everyone',
                value: 'everyone',
                groupValue: privacy,
                onChanged: (val) => _updatePrivacy(val),
              ),
              _buildRadioTile(
                title: 'My Contacts',
                value: 'contacts',
                groupValue: privacy,
                onChanged: (val) => _updatePrivacy(val),
              ),
              _buildRadioTile(
                title: 'Private',
                value: 'private',
                groupValue: privacy,
                onChanged: (val) => _updatePrivacy(val),
              ),
              const Divider(),
              _buildSectionHeader('Default Duration'),
              _buildRadioTile(
                title: '24 Hours',
                value: 24,
                groupValue: duration,
                onChanged: (val) => _updateDuration(val),
                isPremiumRequired: false,
              ),
              _buildRadioTile(
                title: '48 Hours',
                value: 48,
                groupValue: duration,
                onChanged: (val) => _updateDuration(val),
                isPremiumRequired: true,
                isPremium: isPremium,
              ),
              _buildRadioTile(
                title: '72 Hours',
                value: 72,
                groupValue: duration,
                onChanged: (val) => _updateDuration(val),
                isPremiumRequired: true,
                isPremium: isPremium,
              ),
              const Divider(),
              _buildSectionHeader('Weekly Usage'),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: isPremium
                                ? 1.0
                                : (_storyCount / 4.0).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[300],
                            color: isPremium
                                ? TeleTheme.primary
                                : (_storyCount >= 4
                                    ? Colors.red
                                    : Colors.green),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isPremium ? 'Unlimited' : '$_storyCount / 4 Stories',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPremium
                              ? TeleTheme.primary
                              : (_storyCount >= 4 ? Colors.red : Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_storyCount >= 4 && !isPremium && !_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  TelegramPremiumScreen(
                                      dataService: widget.dataService,
                                      authService: widget.authService,
                                  )));
                    },
                    child: const Text(
                      'Weekly story limit reached. Upgrade to Premium for unlimited stories.',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: TeleTheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required dynamic value,
    required dynamic groupValue,
    required Function(dynamic) onChanged,
    bool isPremiumRequired = false,
    bool isPremium = false,
  }) {
    final bool disabled = isPremiumRequired && !isPremium;

    return ListTile(
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(color: disabled ? Colors.grey : null),
          ),
          if (isPremiumRequired) ...[
            const SizedBox(width: 8),
            const Icon(Icons.star, color: Colors.amber, size: 16),
          ],
        ],
      ),
      leading: Radio(
        value: value,
        groupValue: groupValue,
        onChanged: disabled ? null : onChanged,
        activeColor: TeleTheme.primary,
      ),
      onTap: disabled
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('This feature requires Telegram Premium')),
              );
            }
          : () => onChanged(value),
    );
  }
}
