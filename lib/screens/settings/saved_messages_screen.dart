import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SavedMessagesScreen extends StatefulWidget {
  const SavedMessagesScreen({super.key});

  @override
  State<SavedMessagesScreen> createState() => _SavedMessagesScreenState();
}

class _SavedMessagesScreenState extends State<SavedMessagesScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _savedNotes = [
    {
      'text': '🔑 Server credentials and API endpoints for TeleLite production backend.',
      'time': '10:45 AM',
    },
    {
      'text': '📌 Read Flutter 3.12 release notes and patterns documentation.',
      'time': 'Yesterday',
    },
    {
      'text': '💡 Idea: Add voice message waveform visualizer in chat detail screen.',
      'time': 'Aug 10',
    },
  ];

  void _addNote() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _savedNotes.insert(0, {
        'text': text,
        'time': 'Just now',
      });
      _textController.clear();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved Messages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              '${_savedNotes.length} saved notes',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _savedNotes.length,
              itemBuilder: (context, index) {
                final note = _savedNotes[index];
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TeleTheme.primary.withAlpha(isDark ? 50 : 25),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: const Radius.circular(2),
                      ),
                      border: Border.all(
                        color: TeleTheme.primary.withAlpha(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          note['text'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              note['time'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.bookmark, size: 12, color: TeleTheme.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E242B) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: TeleTheme.primary),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Save a note or message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addNote(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: TeleTheme.primary),
                  onPressed: _addNote,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
