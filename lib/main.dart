import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';
import 'services/mock_data.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TelegramLiteApp());
}

class TelegramLiteApp extends StatefulWidget {
  const TelegramLiteApp({super.key});

  @override
  State<TelegramLiteApp> createState() => _TelegramLiteAppState();
}

class _TelegramLiteAppState extends State<TelegramLiteApp> {
  final TelegramDataService _dataService = TelegramDataService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_dataService, _authService]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Telegram Lite',
          debugShowCheckedModeBanner: false,
          themeMode: _dataService.themeMode,
          theme: TeleTheme.lightTheme(),
          darkTheme: TeleTheme.darkTheme(),
          home: StreamBuilder<User?>(
            stream: _authService.authStateChanges,
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null || _authService.isGuestMode) {
                return MainNavigationScreen(
                  dataService: _dataService,
                  authService: _authService,
                );
              }
              return LoginScreen(authService: _authService);
            },
          ),
        );
      },
    );
  }
}

