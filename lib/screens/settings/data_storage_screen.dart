import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DataStorageScreen extends StatefulWidget {
  const DataStorageScreen({super.key});

  @override
  State<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends State<DataStorageScreen> {
  bool _autoPhotosMobile = true;
  bool _autoVideosMobile = false;
  bool _autoPhotosWifi = true;
  bool _autoVideosWifi = true;
  double _cacheSizeMb = 142.5;

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: Text('Free up ${_cacheSizeMb.toStringAsFixed(1)} MB of local media cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _cacheSizeMb = 0.0;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: TeleTheme.primary),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
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
        title: const Text('Data and Storage'),
      ),
      body: ListView(
        children: [
          // Cache Info Card
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1E242B) : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Storage Usage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${_cacheSizeMb.toStringAsFixed(1)} MB used', style: const TextStyle(color: TeleTheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _cacheSizeMb / 500.0,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  color: TeleTheme.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _cacheSizeMb > 0 ? _clearCache : null,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Clear Cache'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _buildHeader('AUTOMATIC MEDIA DOWNLOAD', isDark),
          SwitchListTile(
            title: const Text('Photos over Mobile Data'),
            value: _autoPhotosMobile,
            onChanged: (val) => setState(() => _autoPhotosMobile = val),
            secondary: const Icon(Icons.photo_outlined, color: Colors.blue),
          ),
          SwitchListTile(
            title: const Text('Videos over Mobile Data'),
            value: _autoVideosMobile,
            onChanged: (val) => setState(() => _autoVideosMobile = val),
            secondary: const Icon(Icons.videocam_outlined, color: Colors.purple),
          ),
          SwitchListTile(
            title: const Text('Photos over Wi-Fi'),
            value: _autoPhotosWifi,
            onChanged: (val) => setState(() => _autoPhotosWifi = val),
            secondary: const Icon(Icons.wifi, color: Colors.green),
          ),
          SwitchListTile(
            title: const Text('Videos over Wi-Fi'),
            value: _autoVideosWifi,
            onChanged: (val) => setState(() => _autoVideosWifi = val),
            secondary: const Icon(Icons.wifi_tethering, color: Colors.teal),
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
