import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _passcodeLock = false;
  bool _twoStepVerification = true;
  bool _stealthMode = false;
  String _lastSeen = 'Everybody';
  String _phoneNumberVisibility = 'My Contacts';
  bool _isSaving = false;
  bool _isPremium = false;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final _firestore = FirebaseFirestore.instance;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkBiometricPermission();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    if (_currentUser == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _phoneNumberVisibility = data['phoneNumberVisibility'] ?? 'My Contacts';
          _lastSeen = data['lastSeenVisibility'] ?? 'Everybody';
          _stealthMode = data['stealthMode'] ?? false;
          _isPremium = data['isPremium'] == true;
        });
      }
    } catch (e) {
      debugPrint('_loadPrivacySettings error: $e');
    }
  }

  Future<void> _saveToFirestore(Map<String, dynamic> fields) async {
    if (_currentUser == null) return;
    setState(() => _isSaving = true);
    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .set(fields, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _checkBiometricPermission() async {
    final status = await Permission.sensors.status;
    if (status.isDenied) await Permission.sensors.request();
  }

  Future<void> _handlePasscodeToggle(bool enabled) async {
    if (enabled) {
      try {
        final bool canCheck = await _localAuth.canCheckBiometrics;
        final bool isSupported = await _localAuth.isDeviceSupported();
        if (!canCheck && !isSupported) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometrics not available on this device')),
            );
          }
          setState(() => _passcodeLock = false);
          return;
        }
        final bool didAuth = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable Passcode & Biometric lock',
          options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
        );
        if (!mounted) return;
        if (didAuth) {
          setState(() => _passcodeLock = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric lock enabled!')),
          );
        } else {
          setState(() => _passcodeLock = false);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric error: ${e.toString()}')),
        );
      }
    } else {
      setState(() => _passcodeLock = false);
    }
  }

  void _showPrivacyPicker(
    String title,
    String currentVal,
    Future<void> Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...['Everybody', 'My Contacts', 'Nobody'].map((opt) {
                  return ListTile(
                    title: Text(opt),
                    trailing: currentVal == opt
                        ? const Icon(Icons.check, color: TeleTheme.primary)
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await onSelect(opt);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPremiumPaywall() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 64, color: Color(0xFFE94057)),
              const SizedBox(height: 16),
              const Text(
                'Telegram Premium Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Stealth Mode is an exclusive feature for Telegram Premium subscribers.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EA6FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy and Security'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          _buildHeader('SECURITY', isDark),
          SwitchListTile(
            title: const Text('Two-Step Verification'),
            subtitle: const Text('Enabled (Password + SMS)'),
            value: _twoStepVerification,
            onChanged: (val) => setState(() => _twoStepVerification = val),
            secondary: const Icon(Icons.security, color: Colors.green),
          ),
          SwitchListTile(
            title: const Text('Passcode Lock'),
            subtitle: const Text('Lock app with PIN or Biometrics'),
            value: _passcodeLock,
            onChanged: (val) => _handlePasscodeToggle(val),
            secondary: const Icon(Icons.lock_outline, color: Colors.amber),
          ),

          const Divider(),
          _buildHeader('PRIVACY', isDark),

          SwitchListTile(
            title: const Row(
              children: [
                Text('Stealth Mode '),
                Icon(Icons.star, size: 16, color: Color(0xFFE94057)),
              ],
            ),
            subtitle: const Text('Hide online status and read receipts'),
            value: _stealthMode,
            onChanged: (val) async {
              if (!_isPremium) {
                _showPremiumPaywall();
                return;
              }
              setState(() => _stealthMode = val);
              await _saveToFirestore({'stealthMode': val});
            },
            secondary: const Icon(Icons.visibility_off, color: Colors.indigo),
          ),

          ListTile(
            leading: const Icon(Icons.phone_outlined, color: Colors.blue),
            title: const Text('Phone Number'),
            subtitle: Text(_phoneNumberVisibility),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              _showPrivacyPicker(
                'Who can see my phone number?',
                _phoneNumberVisibility,
                (val) async {
                  setState(() => _phoneNumberVisibility = val);
                  await _saveToFirestore({'phoneNumberVisibility': val});
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Phone number visibility set to "$val"'),
                        backgroundColor: TeleTheme.primary,
                      ),
                    );
                  }
                },
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.access_time, color: Colors.purple),
            title: const Text('Last Seen & Online'),
            subtitle: Text(_lastSeen),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              _showPrivacyPicker(
                'Who can see my last seen time?',
                _lastSeen,
                (val) async {
                  setState(() => _lastSeen = val);
                  await _saveToFirestore({'lastSeenVisibility': val});
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Last seen visibility set to "$val"'),
                        backgroundColor: TeleTheme.primary,
                      ),
                    );
                  }
                },
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.block, color: Colors.redAccent),
            title: const Text('Blocked Users'),
            subtitle: const Text('0 contacts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
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
