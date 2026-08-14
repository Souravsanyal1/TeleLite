import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:telegram_lite/services/auth_service.dart';
import 'package:telegram_lite/services/mock_data.dart';
import 'package:telegram_lite/theme/app_theme.dart';
import 'package:telegram_lite/screens/settings/chat_folders_screen.dart';
import 'package:telegram_lite/screens/settings/data_storage_screen.dart';
import 'package:telegram_lite/screens/settings/devices_screen.dart';
import 'package:telegram_lite/screens/settings/language_screen.dart';
import 'package:telegram_lite/screens/settings/notifications_screen.dart';
import 'package:telegram_lite/screens/settings/privacy_screen.dart';
import 'package:telegram_lite/screens/settings/proxy_screen.dart';
import 'package:telegram_lite/screens/settings/telegram_premium_screen.dart';
import 'package:telegram_lite/screens/settings/saved_messages_screen.dart';
import 'package:telegram_lite/screens/settings/story_settings_page.dart';
import 'package:telegram_lite/screens/user_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  final TelegramDataService dataService;
  final AuthService authService;

  const SettingsScreen({
    super.key,
    required this.dataService,
    required this.authService,
  });

  void _openCurrentUserProfile(BuildContext context) {
    Get.to(() => UserProfileScreen(
          isCurrentUser: true,
          authService: authService,
          dataService: dataService,
        ));
  }

  void _showQrCodeModal(BuildContext context, String name, String username) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2732) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                username,
                style: const TextStyle(fontSize: 14, color: TeleTheme.primary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 180,
                  color: Color(0xFF1E2732),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scan this QR code with camera to add contact',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'https://t.me/${username.replaceAll('@', '')}'));
                  Navigator.pop(ctx);
                  Get.snackbar('Link Copied!', 'Profile link copied to clipboard',
                      backgroundColor: TeleTheme.primary,
                      colorText: Colors.white);
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Profile Link'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: TeleTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
    final currentUser = authService.currentUser;

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0F1722)
              : const Color(0xFFF3F5F9),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark
                ? const Color(0xFF151D2A)
                : Colors.white,
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? Colors.amber : const Color(0xFF5B6B82),
                ),
                onPressed: () => dataService.toggleTheme(),
                tooltip: 'Toggle Theme',
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, size: 26),
                onPressed: () => _openCurrentUserProfile(context),
                tooltip: 'Edit Profile',
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                children: [
                  // 1. HERO USER PROFILE CARD
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                    stream: authService.userProfileStream,
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data();
                      final name = data?['displayName'] ??
                          currentUser?.displayName ??
                          'TeleLite User';
                      final phone = data?['phoneNumber'] ??
                          currentUser?.phoneNumber ??
                          '+880 1XXXXXXXXX';
                      final rawUsername = (data?['username'] ?? 'user').toString();
                      final username = rawUsername.startsWith('@')
                          ? rawUsername
                          : '@$rawUsername';
                      final bio = data?['bio'] ??
                          'Building Telegram Lite in Flutter 🚀';
                      final photoUrl = data?['photoUrl'] ??
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';
                      final isUserPremium = dataService.isPremium ||
                          data?['isPremium'] == true;

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A2330)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isUserPremium
                                ? Colors.amber.withAlpha(80)
                                : (isDark ? Colors.white10 : Colors.black12),
                            width: isUserPremium ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isUserPremium
                                  ? Colors.amber.withAlpha(25)
                                  : Colors.black.withAlpha(isDark ? 50 : 10),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _openCurrentUserProfile(context),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Avatar with glowing ring
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 82,
                                            height: 82,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: isUserPremium
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(0xFF8A2387),
                                                        Color(0xFFE94057),
                                                        Color(0xFFF27121),
                                                      ],
                                                    )
                                                  : const LinearGradient(
                                                      colors: [
                                                        TeleTheme.primary,
                                                        Color(0xFF00C6FF),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                          CircleAvatar(
                                            radius: 37,
                                            backgroundColor: isDark
                                                ? const Color(0xFF1A2330)
                                                : Colors.white,
                                            child: CircleAvatar(
                                              radius: 34,
                                              backgroundImage:
                                                  NetworkImage(photoUrl),
                                            ),
                                          ),
                                          if (isUserPremium)
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: const Color(0xFFE94057),
                                                  border: Border.all(
                                                    color: isDark
                                                        ? const Color(0xFF1A2330)
                                                        : Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.star_rounded,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 18),
                                      // Name, Phone, Username
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 19,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: -0.2,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isUserPremium) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                        colors: [
                                                          Color(0xFF8A2387),
                                                          Color(0xFFE94057),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.star_rounded,
                                                            color: Colors.white,
                                                            size: 11),
                                                        SizedBox(width: 2),
                                                        Text(
                                                          'PRO',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              phone,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.grey[300]
                                                    : Colors.grey[800],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              username,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: TeleTheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _showQrCodeModal(
                                            context, name, username),
                                        icon: const Icon(Icons.qr_code_rounded,
                                            color: TeleTheme.primary),
                                        tooltip: 'Show QR Code',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  // Bio box
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withAlpha(8)
                                          : Colors.black.withAlpha(6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline_rounded,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            bio,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded,
                                            size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // 2. VIP TELEGRAM PREMIUM BANNER
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF654EA3),
                          Color(0xFFEAAFC8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF654EA3).withAlpha(60),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Get.to(() => TelegramPremiumScreen(
                                dataService: dataService,
                                authService: authService,
                              ));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'TeleLite Premium',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            dataService.isPremium
                                                ? 'ACTIVE ⭐'
                                                : '-29%',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF654EA3),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      dataService.isPremium
                                          ? 'All 26 VIP features unlocked & active'
                                          : 'Exclusive story durations, fast media & badges',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withAlpha(220),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 3. GENERAL SETTINGS CARD
                  _buildSectionTitle('GENERAL SETTINGS', isDark),
                  _buildCardGroup(
                    isDark: isDark,
                    children: [
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.bookmark_added_rounded,
                        iconColor: const Color(0xFF0088CC),
                        title: 'Saved Messages',
                        subtitle: 'Cloud notes, files & links',
                        isDark: isDark,
                        page: const SavedMessagesScreen(),
                      ),
                      _buildDivider(isDark),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.auto_stories_rounded,
                        iconColor: const Color(0xFFE91E63),
                        title: 'Story Settings',
                        subtitle: 'Duration, view privacy & weekly stats',
                        isDark: isDark,
                        page: StorySettingsPage(
                            dataService: dataService,
                            authService: authService),
                      ),
                      _buildDivider(isDark),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.folder_copy_rounded,
                        iconColor: const Color(0xFF00BCD4),
                        title: 'Chat Folders',
                        subtitle: 'Organize chats into custom tabs',
                        isDark: isDark,
                        page: const ChatFoldersScreen(),
                      ),
                      _buildDivider(isDark),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.devices_other_rounded,
                        iconColor: const Color(0xFFFF9800),
                        title: 'Devices & Active Sessions',
                        subtitle: 'Web, Android & Desktop logins',
                        isDark: isDark,
                        page: const DevicesScreen(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 4. PRIVACY & SECURITY CARD
                  _buildSectionTitle('PRIVACY & CLOUD DATA', isDark),
                  _buildCardGroup(
                    isDark: isDark,
                    children: [
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFFF5252),
                        title: 'Notifications and Sounds',
                        subtitle: 'Force push, message alerts & badges',
                        isDark: isDark,
                        page: const NotificationsScreen(),
                      ),
                      _buildDivider(isDark),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.security_rounded,
                        iconColor: const Color(0xFF4CAF50),
                        title: 'Privacy and Security',
                        subtitle: '2-Step Verification, Passcode & Block list',
                        isDark: isDark,
                        page: const PrivacyScreen(),
                      ),
                      _buildDivider(isDark),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.cloud_sync_rounded,
                        iconColor: const Color(0xFF9C27B0),
                        title: 'Data and Storage',
                        subtitle: 'Network usage, cache & media download',
                        isDark: isDark,
                        page: const DataStorageScreen(),
                      ),
                      _buildDivider(isDark),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.vpn_lock_rounded,
                        iconColor: const Color(0xFF795548),
                        title: 'Proxy Settings',
                        subtitle: 'MTProto & SOCKS5 configuration',
                        isDark: isDark,
                        page: const ProxyScreen(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 5. APPEARANCE & SYSTEM CARD
                  _buildSectionTitle('APPEARANCE & LANGUAGE', isDark),
                  _buildCardGroup(
                    isDark: isDark,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? Colors.amber
                                        : TeleTheme.primary)
                                    .withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                color: isDark
                                    ? Colors.amber
                                    : TeleTheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dark Mode',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    isDark ? 'OLED Dark Active' : 'Light Clean Mode',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isDark,
                              activeColor: TeleTheme.primary,
                              onChanged: (_) => dataService.toggleTheme(),
                            ),
                          ],
                        ),
                      ),
                      _buildDivider(isDark),
                      _buildSettingsTile(
                        context: context,
                        icon: Icons.translate_rounded,
                        iconColor: const Color(0xFF009688),
                        title: 'Language',
                        subtitle: 'English (US)',
                        isDark: isDark,
                        page: const LanguageScreen(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 6. ACCOUNT CARD
                  _buildSectionTitle('ACCOUNT', isDark),
                  _buildCardGroup(
                    isDark: isDark,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _confirmLogout(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withAlpha(30),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Log Out',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      Text(
                                        'Sign out from this session',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 7. FOOTER
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'TeleLite v1.0.8 • Cloud Realtime Connected',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Powered by Telegram Lite + Firebase Cloud',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2330) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withAlpha(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 54,
      endIndent: 16,
      color: isDark ? Colors.white10 : Colors.black.withAlpha(12),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool isDark,
    required Widget page,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.to(() => page),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2732) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Log Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out from TeleLite?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authService.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
