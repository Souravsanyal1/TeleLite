import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _botNoticeController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _botNoticeController.dispose();
    super.dispose();
  }

  void _showBotNoticeDialog(String userId, String userName) {
    _botNoticeController.clear();
    Get.dialog(
      AlertDialog(
        title: Text('Send Telegram Bot Notice to $userName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This message will be dispatched via Telegram Bot (@TeleLiteGuardianBot):',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _botNoticeController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter notice details...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (_botNoticeController.text.trim().isNotEmpty) {
                AdminService.to.sendTelegramBotNotice(
                  userId,
                  _botNoticeController.text.trim(),
                );
                Get.back();
              }
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send Notice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeleTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = AdminService.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final query = service.searchQuery.value.toLowerCase();
      final filteredUsers = service.users.where((u) {
        return u.name.toLowerCase().contains(query) ||
            u.username.toLowerCase().contains(query) ||
            u.phone.contains(query);
      }).toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage registered TeleLite users, status, and permissions',
                      style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar & Filter Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => service.searchQuery.value = val,
                    decoration: InputDecoration(
                      hintText: 'Search user by name, @username or phone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1A2330) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Users Table Container
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2330) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('User')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Joined')),
                    DataColumn(label: Text('Stories')),
                    DataColumn(label: Text('Telegram Chat ID')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: filteredUsers.map((user) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(user.avatarUrl),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(user.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('@${user.username}',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(user.phone)),
                        DataCell(Text(user.joinedTime)),
                        DataCell(Text('${user.storiesCount}')),
                        DataCell(Text(user.telegramChatId ?? 'Not Linked')),
                        DataCell(
                          Chip(
                            label: Text(
                              user.isBlocked ? 'Blocked' : 'Active',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                            backgroundColor:
                                user.isBlocked ? Colors.red : Colors.green,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  user.isBlocked ? Icons.lock_open : Icons.block,
                                  color:
                                      user.isBlocked ? Colors.green : Colors.red,
                                ),
                                tooltip: user.isBlocked
                                    ? 'Unblock User'
                                    : 'Block User',
                                onPressed: () =>
                                    service.toggleUserBlock(user.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.smart_toy,
                                    color: TeleTheme.primary),
                                tooltip: 'Send Telegram Bot Notice',
                                onPressed: () =>
                                    _showBotNoticeDialog(user.id, user.name),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
