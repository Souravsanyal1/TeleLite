import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ProxyScreen extends StatefulWidget {
  const ProxyScreen({super.key});

  @override
  State<ProxyScreen> createState() => _ProxyScreenState();
}

class _ProxyScreenState extends State<ProxyScreen> {
  bool _useProxy = true;
  int _selectedProxy = 0;

  final List<Map<String, String>> _proxies = [
    {
      'server': 'proxy-nl-01.telelite.org',
      'port': '1080',
      'type': 'SOCKS5',
      'ping': '45 ms',
    },
    {
      'server': 'mtproto-sg-02.telelite.org',
      'port': '443',
      'type': 'MTProto',
      'ping': '112 ms',
    },
  ];

  void _addProxyDialog() {
    final serverCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '1080');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Proxy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serverCtrl,
              decoration: const InputDecoration(labelText: 'Server Host / IP'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (serverCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _proxies.add({
                    'server': serverCtrl.text.trim(),
                    'port': portCtrl.text.trim(),
                    'type': 'SOCKS5',
                    'ping': '88 ms',
                  });
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: TeleTheme.primary),
            child: const Text('Add Proxy', style: TextStyle(color: Colors.white)),
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
        title: const Text('Proxy Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use Proxy'),
            subtitle: Text(_useProxy ? 'Connected to Proxy' : 'Disabled'),
            value: _useProxy,
            onChanged: (val) => setState(() => _useProxy = val),
            secondary: Icon(
              Icons.vpn_key_outlined,
              color: _useProxy ? Colors.green : Colors.grey,
            ),
          ),
          const Divider(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'SAVED PROXIES',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),

          ...List.generate(_proxies.length, (index) {
            final p = _proxies[index];
            final isSelected = _selectedProxy == index && _useProxy;

            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? TeleTheme.primary : Colors.grey,
              ),
              title: Text(
                '${p['server']}:${p['port']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${p['type']} • ${p['ping']}'),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: TeleTheme.primary)
                  : const Icon(Icons.dns_outlined, color: Colors.grey),
              onTap: () {
                setState(() {
                  _useProxy = true;
                  _selectedProxy = index;
                });
              },
            );
          }),

          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.add_link, color: TeleTheme.primary),
            title: const Text(
              'Add Proxy Server',
              style: TextStyle(color: TeleTheme.primary, fontWeight: FontWeight.bold),
            ),
            onTap: _addProxyDialog,
          ),
        ],
      ),
    );
  }
}
