import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:telegram_lite/controllers/telegram_controller.dart';
import 'package:telegram_lite/firebase_options.dart';
import 'package:telegram_lite/screens/auth/phone_input_screen.dart';
import 'package:telegram_lite/screens/auth/profile_setup_screen.dart';
import 'package:telegram_lite/screens/main_navigation_screen.dart';
import 'package:telegram_lite/services/auth_service.dart';
import 'package:telegram_lite/services/mock_data.dart';
import 'package:telegram_lite/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Get.put(TelegramController(), permanent: true);
  runApp(const TelegramLiteApp());
}

class TelegramLiteApp extends StatefulWidget {
  const TelegramLiteApp({super.key});

  @override
  State<TelegramLiteApp> createState() => _TelegramLiteAppState();
}

class _TelegramLiteAppState extends State<TelegramLiteApp> {
  TelegramController get _controller => TelegramController.to;
  final TelegramDataService _dataService = TelegramDataService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return GetMaterialApp(
        title: 'Telegram Lite',
        debugShowCheckedModeBanner: false,
        themeMode: _controller.themeMode.value,
        theme: TeleTheme.lightTheme(),
        darkTheme: TeleTheme.darkTheme(),
        home: StreamBuilder<User?>(
          stream: _authService.authStateChanges,
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            if (user == null) {
              return PhoneInputScreen(authService: _authService);
            }

            // User is authenticated - check if Firestore profile exists
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
              stream: _authService.userProfileStream,
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child:
                          CircularProgressIndicator(color: TeleTheme.primary),
                    ),
                  );
                }

                if (profileSnapshot.hasError) {
                  debugPrint(
                      'Firestore profileSnapshot error: ${profileSnapshot.error}');
                  return MainNavigationScreen(
                    dataService: _dataService,
                    authService: _authService,
                  );
                }

                final doc = profileSnapshot.data;
                if (!_authService.hasCompletedProfile(doc)) {
                  return ProfileSetupScreen(authService: _authService);
                }

                return MainNavigationScreen(
                  dataService: _dataService,
                  authService: _authService,
                );
              },
            );
          },
        ),
      );
    });
  }
}

