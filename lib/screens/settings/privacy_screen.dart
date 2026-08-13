import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _passcodeLock = false;
  bool _twoStepVerification = true;
  String _lastSeen = 'Everybody';
  String _phoneNumberVisibility = 'My Contacts';

  void _showPrivacyPicker(String title, String currentVal, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...['Everybody', 'My Contacts', 'Nobody'].map((opt) {
                return ListTile(
                  title: Text(opt),
                  trailing: currentVal == opt ? const Icon(Icons.check, color: TeleTheme.primary) : null,
                  onTap: () {
                    onSelect(opt);
                    Navigator.pop(context);
                  },
                );
              }),
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
            onChanged: (val) => setState(() => _passcodeLock = val),
            secondary: const Icon(Icons.lock_outline, color: Colors.amber),
          ),

          const Divider(),
          _buildHeader('PRIVACY', isDark),
          ListTile(
            leading: const Icon(Icons.phone_outlined, color: Colors.blue),
            title: const Text('Phone Number'),
            subtitle: Text(_phoneNumberVisibility),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showPrivacyPicker('Who can see my phone number?', _phoneNumberVisibility, (val) {
                setState(() => _phoneNumberVisibility = val);
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time, color: Colors.purple),
            title: const Text('Last Seen & Online'),
            subtitle: Text(_lastSeen),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showPrivacyPicker('Who can see my last seen time?', _lastSeen, (val) {
                setState(() => _lastSeen = val);
              });
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
