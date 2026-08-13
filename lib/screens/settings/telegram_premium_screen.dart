import 'package:flutter/material.dart';
import 'package:telegram_lite/services/auth_service.dart';
import 'package:telegram_lite/services/mock_data.dart';
import 'package:telegram_lite/services/payment_service.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PremiumFeature {
  final String title;
  final String description;
  final IconData? icon;
  final String? svgIconUrl;
  final Widget? customIconWidget;
  final Color iconBgColor;
  final String category;
  final String demoType;

  const PremiumFeature({
    required this.title,
    required this.description,
    this.icon,
    this.svgIconUrl,
    this.customIconWidget,
    required this.iconBgColor,
    required this.category,
    required this.demoType,
  });
}

class TelegramPremiumScreen extends StatefulWidget {
  final TelegramDataService dataService;
  final AuthService authService;

  const TelegramPremiumScreen({
    super.key,
    required this.dataService,
    required this.authService,
  });

  @override
  State<TelegramPremiumScreen> createState() => _TelegramPremiumScreenState();
}

class _TelegramPremiumScreenState extends State<TelegramPremiumScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnnualSelected = true;
  bool _isSubscribing = false;
  late AnimationController _starAnimController;
  late ConfettiController _confettiController;
  late PaymentService _paymentService;

  static const List<PremiumFeature> _features = [
    PremiumFeature(
      title: 'Stealth Mode',
      description:
          'Hide your online status and read receipts from everyone, while still seeing theirs.',
      icon: Icons.visibility_off_rounded,
      iconBgColor: Color(0xFF673AB7),
      category: 'Privacy',
      demoType: 'stealth',
    ),
    PremiumFeature(
      title: 'Advanced Chat Folders',
      description: 'Create up to 30 custom chat folders with unlimited pins.',
      icon: Icons.folder_special_rounded,
      iconBgColor: Color(0xFF009688),
      category: 'Organization',
      demoType: 'folders',
    ),
    PremiumFeature(
      title: 'Stories',
      description:
          'Unlimited posting, priority order, stealth mode, permanent view history and more.',
      icon: Icons.play_circle_fill,
      svgIconUrl: 'https://cdn.simpleicons.org/instagram',
      iconBgColor: Color(0xFFFF9500),
      category: 'Sharing',
      demoType: 'stories',
    ),
    PremiumFeature(
      title: 'Unlimited Cloud Storage',
      description:
          '4 GB per each document, unlimited storage for your chats and media overall.',
      icon: Icons.cloud_upload_rounded,
      svgIconUrl: 'https://cdn.simpleicons.org/googledrive',
      iconBgColor: Color(0xFFFF9500),
      category: 'Storage',
      demoType: 'cloud_storage',
    ),
    PremiumFeature(
      title: 'Doubled Limits',
      description:
          'Up to 1000 channels, 30 folders, 10 pins, 20 public links, 4 accounts and more.',
      icon: Icons.numbers_rounded,
      customIconWidget: Text(
        'X2',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
      iconBgColor: Color(0xFFFF6B00),
      category: 'Limits',
      demoType: 'limits',
    ),
    PremiumFeature(
      title: 'Telegram Business',
      description:
          'Upgrade your account with business features such as location, opening hours and quick replies.',
      icon: Icons.storefront_rounded,
      iconBgColor: Color(0xFFFF5252),
      category: 'Business',
      demoType: 'business',
    ),
    PremiumFeature(
      title: 'Last Seen Times',
      description:
          'View the last seen and read times of others even if you hide yours.',
      icon: Icons.visibility_off_rounded,
      iconBgColor: Color(0xFFFF4081),
      category: 'Privacy',
      demoType: 'last_seen',
    ),
    PremiumFeature(
      title: 'Voice-to-Text Conversion',
      description:
          'Ability to read the transcript of any incoming voice message.',
      icon: Icons.mic_rounded,
      svgIconUrl: 'https://cdn.simpleicons.org/googleassistant',
      iconBgColor: Color(0xFFFF4081),
      category: 'Chat',
      demoType: 'voice_to_text',
    ),
    PremiumFeature(
      title: 'Faster Download Speed',
      description:
          'No more limits on the speed with which media and documents are downloaded.',
      icon: Icons.speed_rounded,
      svgIconUrl: 'https://cdn.simpleicons.org/cloudflare',
      iconBgColor: Color(0xFFF50057),
      category: 'Performance',
      demoType: 'speed',
    ),
    PremiumFeature(
      title: 'Real-Time Translation',
      description:
          'Real-time translation of chats and channels into other languages.',
      icon: Icons.translate_rounded,
      svgIconUrl: 'https://cdn.simpleicons.org/googletranslate',
      iconBgColor: Color(0xFFE91E63),
      category: 'Translation',
      demoType: 'translation',
    ),
    PremiumFeature(
      title: 'Animated Emoji',
      description:
          'Include animated emoji from different packs in any message you send.',
      icon: Icons.sentiment_very_satisfied_rounded,
      iconBgColor: Color(0xFFD81B60),
      category: 'Customization',
      demoType: 'animated_emoji',
    ),
    PremiumFeature(
      title: 'Emoji Statuses',
      description:
          'Choose from thousands of emoji to display current activity next to your name.',
      icon: Icons.front_hand_rounded,
      iconBgColor: Color(0xFFC2185B),
      category: 'Customization',
      demoType: 'emoji_status',
    ),
    PremiumFeature(
      title: 'Tags in Saved Messages',
      description: 'Organize your Saved Messages with tags for quicker access.',
      icon: Icons.local_offer_rounded,
      iconBgColor: Color(0xFFAB47BC),
      category: 'Organization',
      demoType: 'tags',
    ),
    PremiumFeature(
      title: 'Name and Profile Colors',
      description:
          'Choose a color and logo for your profile and replies to your messages.',
      icon: Icons.palette_rounded,
      iconBgColor: Color(0xFF8E24AA),
      category: 'Customization',
      demoType: 'profile_colors',
    ),
    PremiumFeature(
      title: 'Wallpaper for Both Sides',
      description: 'Set custom wallpapers for you and your chat partner.',
      icon: Icons.wallpaper_rounded,
      iconBgColor: Color(0xFF7E57C2),
      category: 'Customization',
      demoType: 'wallpaper',
    ),
    PremiumFeature(
      title: 'Profile Badge',
      description:
          'An exclusive badge next to your name showing that you subscribe to Telegram Premium.',
      icon: Icons.star_rounded,
      iconBgColor: Color(0xFF5C6BC0),
      category: 'Badge',
      demoType: 'badge',
    ),
    PremiumFeature(
      title: 'Paid Messages',
      description:
          'Charge a fee for messages from non-contacts or new senders.',
      icon: Icons.attach_money_rounded,
      iconBgColor: Color(0xFF3F51B5),
      category: 'Monetization',
      demoType: 'paid_messages',
    ),
    PremiumFeature(
      title: 'Disable Sharing',
      description:
          'Prevent forwarding, saving and copying content in private chats.',
      icon: Icons.security_rounded,
      iconBgColor: Color(0xFF29B6F6),
      category: 'Security',
      demoType: 'disable_sharing',
    ),
    PremiumFeature(
      title: 'Advanced Chat Management',
      description:
          'Tools to set the default folder, auto-archive and hide new chats from non-contacts.',
      icon: Icons.forum_rounded,
      iconBgColor: Color(0xFF03A9F4),
      category: 'Management',
      demoType: 'chat_management',
    ),
    PremiumFeature(
      title: 'No Ads',
      description:
          'No more ads in public channels where Telegram sometimes shows ads.',
      icon: Icons.volume_off_rounded,
      iconBgColor: Color(0xFF0288D1),
      category: 'Ad-Free',
      demoType: 'no_ads',
    ),
    PremiumFeature(
      title: 'Premium App Icons',
      description:
          'Choose from a selection of Telegram app icons for your homescreen.',
      icon: Icons.apps_rounded,
      iconBgColor: Color(0xFF00ACC1),
      category: 'Icon',
      demoType: 'app_icons',
    ),
    PremiumFeature(
      title: 'Infinite Reactions',
      description:
          'React with thousands of emoji — using multiple reactions per message.',
      icon: Icons.favorite_rounded,
      iconBgColor: Color(0xFF0097A7),
      category: 'Reactions',
      demoType: 'reactions',
    ),
    PremiumFeature(
      title: 'Animated Profile Pictures',
      description:
          'Video avatars animated in chat lists and chats to allow for additional self-expression.',
      icon: Icons.play_circle_outline_rounded,
      iconBgColor: Color(0xFF00897B),
      category: 'Profile',
      demoType: 'animated_avatar',
    ),
    PremiumFeature(
      title: 'Premium Stickers',
      description:
          'Exclusive enlarged stickers featuring additional effects, updated regularly.',
      icon: Icons.face_rounded,
      iconBgColor: Color(0xFF00796B),
      category: 'Stickers',
      demoType: 'stickers',
    ),
    PremiumFeature(
      title: 'Message Effects',
      description: 'Add over 500 animated effects to private messages.',
      icon: Icons.auto_awesome_rounded,
      iconBgColor: Color(0xFF00897B),
      category: 'Effects',
      demoType: 'effects',
    ),
    PremiumFeature(
      title: 'AI Tools',
      description:
          'Transform your messages and entire chats in your preferred style and language.',
      icon: Icons.psychology_rounded,
      customIconWidget: Text(
        'Ai',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      iconBgColor: Color(0xFF4CAF50),
      category: 'AI',
      demoType: 'ai_tools',
    ),
    PremiumFeature(
      title: 'Rich Formatting',
      description:
          'Add headers, tables, lists, AI and inline media to messages.',
      icon: Icons.article_rounded,
      iconBgColor: Color(0xFF66BB6A),
      category: 'Text',
      demoType: 'formatting',
    ),
    PremiumFeature(
      title: 'Checklists',
      description:
          'Plan, assign and complete tasks — seamlessly and efficiently.',
      icon: Icons.checklist_rounded,
      iconBgColor: Color(0xFF81C784),
      category: 'Productivity',
      demoType: 'checklists',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _starAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _paymentService = PaymentService(
      dataService: widget.dataService,
      authService: widget.authService,
    );
    _paymentService.initialize();
    _paymentService.onPurchaseSuccess = () {
      if (!mounted) return;
      setState(() => _isSubscribing = false);
      _showSuccessDialog();
    };
  }

  @override
  void dispose() {
    _starAnimController.dispose();
    _confettiController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  void _handleSubscribe() async {
    setState(() => _isSubscribing = true);
    await _paymentService.buyPremium(context);

    // Fallback if the user cancels payment, we should unset the loading state eventually,
    // but the actual success is handled by _paymentService.onPurchaseSuccess
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isSubscribing) {
        setState(() => _isSubscribing = false);
      }
    });
  }

  void _showSuccessDialog() {
    _confettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2733).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8A2387),
                            Color(0xFFE94057),
                            Color(0xFFF27121)
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE94057).withAlpha(128),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child:
                          const Icon(Icons.star, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome to Telegram Premium!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You have unlocked all exclusive premium features, unlimited storage, custom badges, and high-speed downloads.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2EA6FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          _confettiController.stop();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Awesome!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -50,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: true,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple
                  ],
                  createParticlePath: (size) {
                    final path = Path();
                    path.addOval(
                        Rect.fromCircle(center: Offset.zero, radius: 5));
                    return path;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFeatureDemo(PremiumFeature feature) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17212B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: feature.iconBgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: feature.customIconWidget ??
                              (feature.svgIconUrl != null
                                  ? SvgPicture.network(
                                      feature.svgIconUrl!,
                                      width: 28,
                                      height: 28,
                                      colorFilter: const ColorFilter.mode(
                                          Colors.white, BlendMode.srcIn),
                                      placeholderBuilder:
                                          (BuildContext context) => Container(
                                        padding: const EdgeInsets.all(4),
                                        child: const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      ),
                                    )
                                  : Icon(feature.icon,
                                      color: Colors.white, size: 28)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Premium Feature',
                              style: TextStyle(
                                fontSize: 13,
                                color: feature.iconBgColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    feature.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[300],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInteractiveDemoContent(feature),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8A2387),
                            Color(0xFFE94057),
                            Color(0xFFF27121)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _handleSubscribe();
                        },
                        child: Text(
                          widget.dataService.isPremium
                              ? 'Active Feature ★'
                              : 'Unlock with Subscription',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInteractiveDemoContent(PremiumFeature feature) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1621),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'Interactive Preview',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _getDemoWidget(feature.demoType),
        ],
      ),
    );
  }

  Widget _getDemoWidget(String demoType) {
    switch (demoType) {
      case 'voice_to_text':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2B5278),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('0:14',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.subtitles, color: Color(0xFFFF4081), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transcript: "Hey! Meeting is rescheduled to 4 PM today at main hall."',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'ai_tools':
        return Column(
          children: [
            Row(
              children: [
                Chip(
                  label: const Text('Formal Tone'),
                  backgroundColor: const Color(0xFF4CAF50).withAlpha(50),
                  labelStyle: const TextStyle(
                      color: Colors.lightGreenAccent, fontSize: 11),
                ),
                const SizedBox(width: 6),
                Chip(
                  label: const Text('Summarize'),
                  backgroundColor: Colors.blue.withAlpha(50),
                  labelStyle: const TextStyle(
                      color: Colors.lightBlueAccent, fontSize: 11),
                ),
                const SizedBox(width: 6),
                Chip(
                  label: const Text('Translate'),
                  backgroundColor: Colors.purple.withAlpha(50),
                  labelStyle:
                      const TextStyle(color: Colors.purpleAccent, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'AI Suggestion: "Dear Team, Please be informed that our strategy meeting has been moved to 4:00 PM in Conference Room B."',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        );

      case 'badge':
        return Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
            ),
            const SizedBox(width: 12),
            const Text(
              'User Profile',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF8A2387), Color(0xFFE94057)],
                ),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 14),
            ),
            const Spacer(),
            const Text('PREMIUM',
                style: TextStyle(
                    color: Color(0xFF5C6BC0),
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ],
        );

      default:
        return Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF2EA6FF)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Subscribing grants full unlimited access to this feature without any restrictions.',
                style: TextStyle(color: Colors.grey[300], fontSize: 13),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E1621) : const Color(0xFFF1F5F9);
    final cardColor = isDark ? const Color(0xFF17212B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(20);

    return AnimatedBuilder(
      animation: widget.dataService,
      builder: (context, _) {
        final isPremium = widget.dataService.isPremium;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Telegram Premium',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          body: Stack(
            children: [
              // Main Scroll View
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Hero Header with Glowing Gradient Animated Star
                    Center(
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                          CurvedAnimation(
                            parent: _starAnimController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9C27B0).withAlpha(100),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: const Color(0xFF0088CC).withAlpha(80),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFC2185B),
                                    Color(0xFF8E24AA),
                                    Color(0xFF29B6F6),
                                  ],
                                ).createShader(bounds),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 130,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Title & Subtitle
                    Text(
                      'Telegram Premium',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Go beyond the limits and unlock dozens of exclusive features by subscribing to Telegram Premium.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                          height: 1.35,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Subscription Plan Selection Card
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          // Annual Option
                          InkWell(
                            onTap: () {
                              setState(() => _isAnnualSelected = true);
                            },
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    _isAnnualSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    color: _isAnnualSelected
                                        ? const Color(0xFF2EA6FF)
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Annual',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2EA6FF),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '-29%',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'BDT5,400.00 ',
                                                style: TextStyle(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: subTextColor,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              TextSpan(
                                                text: 'BDT3,800.00/year',
                                                style: TextStyle(
                                                  color: subTextColor,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'BDT316.67/month',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Divider(
                            height: 1,
                            color: borderColor,
                            indent: 16,
                            endIndent: 16,
                          ),

                          // Monthly Option
                          InkWell(
                            onTap: () {
                              setState(() => _isAnnualSelected = false);
                            },
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    !_isAnnualSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    color: !_isAnnualSelected
                                        ? const Color(0xFF2EA6FF)
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Monthly',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'BDT450.00/month',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Premium Features List Card
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _features.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: borderColor,
                          indent: 68,
                        ),
                        itemBuilder: (context, index) {
                          final feat = _features[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: feat.iconBgColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: feat.customIconWidget ??
                                    (feat.svgIconUrl != null
                                        ? SvgPicture.network(
                                            feat.svgIconUrl!,
                                            width: 20,
                                            height: 20,
                                            colorFilter: const ColorFilter.mode(
                                                Colors.white, BlendMode.srcIn),
                                          )
                                        : Icon(
                                            feat.icon,
                                            color: textColor,
                                            size: 20,
                                          )),
                              ),
                            ),
                            title: Text(
                              feat.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              feat.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: subTextColor,
                                height: 1.3,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey[600],
                            ),
                            onTap: () => _openFeatureDemo(feat),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Terms of Service Disclaimer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text.rich(
                        TextSpan(
                          text:
                              'By subscribing to Telegram Premium you agree to the ',
                          style: TextStyle(fontSize: 12, color: subTextColor),
                          children: const [
                            TextSpan(
                              text: 'Telegram Terms of Service',
                              style: TextStyle(
                                color: Color(0xFF2EA6FF),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Color(0xFF2EA6FF),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '. Subscriptions auto-renew unless canceled via your Google Play settings.',
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Bottom Sticky Subscription Button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        bgColor.withAlpha(0),
                        bgColor.withAlpha(230),
                        bgColor,
                      ],
                    ),
                  ),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8A2387),
                          Color(0xFFE94057),
                          Color(0xFFF27121),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE94057).withAlpha(100),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: (_isSubscribing || isPremium)
                          ? null
                          : _handleSubscribe,
                      child: _isSubscribing
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: textColor,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isPremium
                                  ? '★ You are a Telegram Premium Subscriber'
                                  : (_isAnnualSelected
                                      ? 'Subscribe for BDT3,800.00 per year'
                                      : 'Subscribe for BDT450.00 per month'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
