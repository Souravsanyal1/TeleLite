import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';
import 'user_profile_screen.dart';

class ContactsScreen extends StatefulWidget {
  final TelegramDataService dataService;
  final AuthService authService;

  const ContactsScreen({
    super.key,
    required this.dataService,
    required this.authService,
  });

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestContactsPermission();
  }

  Future<void> _requestContactsPermission() async {
    if (kIsWeb) return;
    
    final status = await Permission.contacts.status;
    if (!status.isGranted) {
      final result = await Permission.contacts.request();
      if (!mounted) return;
      if (result.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission granted!')),
        );
      } else if (result.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contacts permission denied'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Dialog: Add Contact by Phone Number
  void _showAddContactDialog() {
    final phoneController = TextEditingController();
    bool isSearchingUser = false;
    String? errorText;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Contact by Number'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter phone number to search for registered TeleLite users.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+8801XXXXXXXXX',
                    prefixIcon: const Icon(Icons.phone),
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                if (isSearchingUser) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(color: TeleTheme.primary),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSearchingUser
                    ? null
                    : () async {
                        final phone = phoneController.text.trim();
                        if (phone.isEmpty) {
                          setDialogState(() {
                            errorText = 'Please enter a phone number.';
                          });
                          return;
                        }

                        setDialogState(() {
                          isSearchingUser = true;
                          errorText = null;
                        });

                        final userDoc = await widget.authService.findUserByPhoneNumber(phone);

                        if (!context.mounted) return;

                        setDialogState(() {
                          isSearchingUser = false;
                        });

                        if (userDoc != null && userDoc.exists) {
                          final data = userDoc.data() as Map<String, dynamic>;
                          final name = data['displayName'] ?? 'TeleLite User';
                          final userPhone = data['phoneNumber'] ?? phone;
                          final photoUrl = data['photoUrl'] ??
                              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';

                          widget.dataService.addContact(
                            Contact(
                              id: userDoc.id,
                              name: name,
                              phone: userPhone,
                              avatarUrl: photoUrl,
                              isOnline: data['isOnline'] ?? true,
                            ),
                          );

                          Get.back();
                          Get.snackbar(
                            'Success',
                            'Added $name ($userPhone) to your Contacts!',
                            backgroundColor: Colors.green.withAlpha(200),
                            colorText: Colors.white,
                          );
                        } else {
                          setDialogState(() {
                            errorText = 'No registered user found with phone $phone on TeleLite.';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: TeleTheme.primary),
                child: const Text('Add Contact', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dialog: Create New Group
  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            hintText: 'e.g. Flutter Devs, Family Group',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final newChat = widget.dataService.createGroupChat(
                  name: name,
                  avatarUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=150',
                );
                Get.back();
                Get.to(() => ChatDetailScreen(
                  chat: newChat,
                  dataService: widget.dataService,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: TeleTheme.primary),
            child: const Text('Create Group', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Dialog: Create New Secret Chat
  void _showCreateSecretChatDialog(List<Contact> contacts) {
    Get.dialog(
      AlertDialog(
        title: const Text('New Secret Chat 🔒'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select a contact to establish an end-to-end encrypted secret chat.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(contact.avatarUrl),
                      ),
                      title: Text(contact.name),
                      subtitle: Text(contact.phone),
                      trailing: const Icon(Icons.lock, color: Colors.green, size: 18),
                      onTap: () {
                        final newChat = widget.dataService.createSecretChat(
                          name: contact.name,
                          avatarUrl: contact.avatarUrl,
                        );
                        Get.back();
                        Get.to(() => ChatDetailScreen(
                          chat: newChat,
                          dataService: widget.dataService,
                        ));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog: Create New Channel
  void _showCreateChannelDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create New Channel 📢'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                hintText: 'e.g. TeleLite Updates',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'What is this channel about?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final newChat = widget.dataService.createChannelChat(
                  name: name,
                  description: descController.text.trim(),
                );
                Get.back();
                Get.to(() => ChatDetailScreen(
                  chat: newChat,
                  dataService: widget.dataService,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: TeleTheme.primary),
            child: const Text('Create Channel', style: TextStyle(color: Colors.white)),
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'Search contacts by name, @username, or phone...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : const Text('Contacts'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            onPressed: _showAddContactDialog,
            tooltip: 'Add Contact by Number',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>?>(
        stream: widget.authService.registeredUsersStream,
        builder: (context, snapshot) {
          final List<Contact> registeredContacts = [];
          final currentUid = widget.authService.currentUser?.uid;

          if (snapshot.hasData && snapshot.data != null) {
            for (var doc in snapshot.data!.docs) {
              if (doc.id == currentUid) continue; // Exclude current user
              final data = doc.data();
              final name = data['displayName'] ?? 'TeleLite User';
              final username = data['username'] != null ? '@${data['username']}' : '';
              final phone = data['phoneNumber'] ?? '';
              final photoUrl = data['photoUrl'] ??
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';
              final isOnline = data['isOnline'] ?? true;
              final isStealthMode = data['stealthMode'] == true;

              registeredContacts.add(
                Contact(
                  id: doc.id,
                  name: username.isNotEmpty ? '$name ($username)' : name,
                  phone: phone,
                  avatarUrl: photoUrl,
                  isOnline: isOnline && !isStealthMode,
                  isStealthMode: isStealthMode,
                  lastSeen: isStealthMode ? 'recently' : 'recently',
                ),
              );
            }
          }

          // Combine with mock contacts if empty
          final allContacts = [
            ...registeredContacts,
            ...widget.dataService.contacts,
          ];

          // Deduplicate by clean phone number
          final Map<String, Contact> uniqueContacts = {};
          for (var c in allContacts) {
            final cleanPhone = c.phone.replaceAll(RegExp(r'\D'), '');
            final key = cleanPhone.isEmpty ? c.id : cleanPhone;
            if (!uniqueContacts.containsKey(key)) {
              uniqueContacts[key] = c;
            }
          }
          final deduplicatedContacts = uniqueContacts.values.toList();

          // Filter by search query
          final filteredContacts = deduplicatedContacts.where((c) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return c.name.toLowerCase().contains(query) ||
                c.phone.toLowerCase().contains(query);
          }).toList();

          return ListView(
            children: [
              // Action Items: New Group, New Secret Chat, New Channel
              _buildActionItem(
                icon: Icons.group_add_outlined,
                title: 'New Group',
                isDark: isDark,
                onTap: _showCreateGroupDialog,
              ),
              _buildActionItem(
                icon: Icons.lock_outline,
                title: 'New Secret Chat',
                isDark: isDark,
                onTap: () => _showCreateSecretChatDialog(filteredContacts),
              ),
              _buildActionItem(
                icon: Icons.campaign_outlined,
                title: 'New Channel',
                isDark: isDark,
                onTap: _showCreateChannelDialog,
              ),

              const Divider(height: 1),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Registered Contacts (${filteredContacts.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    if (registeredContacts.isNotEmpty)
                      const Text(
                        'Live Firestore Sync • Online',
                        style: TextStyle(fontSize: 11, color: TeleTheme.onlineSuccess),
                      ),
                  ],
                ),
              ),

              if (filteredContacts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No contacts found.',
                      style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
                    ),
                  ),
                )
              else
                ...filteredContacts.map((contact) => ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                contact: contact,
                                dataService: widget.dataService,
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(contact.avatarUrl),
                            ),
                            if (contact.isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: TeleTheme.onlineSuccess,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF181C20) : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      title: Text(
                        contact.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Text(
                        contact.phone.isNotEmpty
                            ? '${contact.phone} • ${contact.isOnline ? 'online' : 'last seen ${contact.lastSeen}'}'
                            : (contact.isOnline ? 'online' : 'last seen ${contact.lastSeen}'),
                        style: TextStyle(
                          fontSize: 13,
                          color: contact.isOnline ? TeleTheme.primary : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline, color: TeleTheme.primary, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                contact: contact,
                                dataService: widget.dataService,
                              ),
                            ),
                          );
                        },
                        tooltip: 'View Profile Details',
                      ),
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(
                              contact: contact,
                              dataService: widget.dataService,
                            ),
                          ),
                        );
                      },
                      onTap: () {
                        // Start conversation with contact
                        final chat = widget.dataService.getOrCreateChatForContact(contact);
                        Get.to(() => ChatDetailScreen(
                          chat: chat,
                          dataService: widget.dataService,
                        ));
                      },
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: TeleTheme.primary, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: TeleTheme.primary,
        ),
      ),
      onTap: onTap,
    );
  }
}
