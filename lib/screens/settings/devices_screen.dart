import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final List<Map<String, String>> _otherSessions = [
    {
      'title': 'TeleLite Web • Chrome',
      'location': 'Dhaka, Bangladesh • 103.24.89.12',
      'time': 'Active now',
      'icon': 'web',
    },
    {
      'title': 'TeleLite Desktop • macOS',
      'location': 'Dhaka, Bangladesh • 103.24.89.14',
      'time': 'Yesterday at 9:15 PM',
      'icon': 'desktop',
    },
  ];

  void _terminateOtherSessions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate All Other Sessions?'),
        content: const Text(
          'Are you sure you want to log out from all other devices except this one?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _otherSessions.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All other sessions terminated.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Terminate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
      ),
      body: ListView(
        children: [
          // Current Device Header Card
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1E242B) : Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TeleTheme.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_android, color: TeleTheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Device (Flutter Mobile App)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'TeleLite v1.0.0 • Online',
                        style: TextStyle(
                          fontSize: 13,
                          color: TeleTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_otherSessions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _terminateOtherSessions,
                  icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
                  label: const Text(
                    'Terminate All Other Sessions',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'ACTIVE SESSIONS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),

          if (_otherSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No other active sessions.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ..._otherSessions.map((session) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    session['icon'] == 'web' ? Icons.language : Icons.desktop_mac,
                    color: Colors.amber[700],
                  ),
                ),
                title: Text(
                  session['title']!,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: Text('${session['location']}\n${session['time']}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _otherSessions.remove(session);
                    });
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}
