import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'English';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'native': 'English'},
    {'name': 'Bengali', 'native': 'বাংলা'},
    {'name': 'Spanish', 'native': 'Español'},
    {'name': 'French', 'native': 'Français'},
    {'name': 'German', 'native': 'Deutsch'},
    {'name': 'Japanese', 'native': '日本語'},
    {'name': 'Arabic', 'native': 'العربية'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filtered = _languages.where((lang) {
      return lang['name']!.toLowerCase().contains(query) ||
          lang['native']!.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search language...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final lang = filtered[index];
                final isSelected = _selectedLanguage == lang['name'];

                return ListTile(
                  title: Text(
                    lang['name']!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(lang['native']!),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: TeleTheme.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLanguage = lang['name']!;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Language changed to ${lang['name']}')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
