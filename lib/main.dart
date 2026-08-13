import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';
import 'services/mock_data.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TelegramLiteApp());
}

class TelegramLiteApp extends StatefulWidget {
  const TelegramLiteApp({super.key});

  @override
  State<TelegramLiteApp> createState() => _TelegramLiteAppState();
}

class _TelegramLiteAppState extends State<TelegramLiteApp> {
  final TelegramDataService _dataService = TelegramDataService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dataService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Telegram Lite',
          debugShowCheckedModeBanner: false,
          themeMode: _dataService.themeMode,
          theme: TeleTheme.lightTheme(),
          darkTheme: TeleTheme.darkTheme(),
          home: MainNavigationScreen(dataService: _dataService),
        );
      },
    );
  }
}
