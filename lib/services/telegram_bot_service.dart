import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TelegramBotService {
  static final TelegramBotService _instance = TelegramBotService._internal();
  factory TelegramBotService() => _instance;
  TelegramBotService._internal();

  static const String botToken =
      '8553809069:AAHmbtMKsyLp0lT8oppp3kW5EVH4NsHvCeE';
  static const String botUsername = '@TeleLiteGuardianBot';
  static const String _baseUrl = 'https://api.telegram.org/bot$botToken';

  // Registered Admin Chat IDs for Telegram Alerts
  final Set<String> _subscribedAdminChatIds = {'8553809069'};

  void addAdminChatId(String chatId) {
    if (chatId.trim().isNotEmpty) {
      _subscribedAdminChatIds.add(chatId.trim());
    }
  }

  // Send Direct Message via Telegram Bot API
  Future<bool> sendBotMessage({
    required String chatId,
    required String text,
    String parseMode = 'Markdown',
  }) async {
    final url = Uri.parse('$_baseUrl/sendMessage');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': text,
          'parse_mode': parseMode,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Telegram Bot Message sent to $chatId successfully.');
        return true;
      } else {
        debugPrint(
            'Telegram Bot Error [${response.statusCode}]: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('TelegramBotService sendBotMessage exception: $e');
      return false;
    }
  }

  // Broadcast Alert to All Subscribed Admins
  Future<int> broadcastAdminAlert({
    required String title,
    required String details,
  }) async {
    final messageText = '🚨 *$title*\n\n$details\n\n_Sent via ${botUsername}_';
    int successCount = 0;

    for (final chatId in _subscribedAdminChatIds) {
      final success = await sendBotMessage(chatId: chatId, text: messageText);
      if (success) successCount++;
    }

    return successCount;
  }

  // Test Bot Connectivity / Webhook Status
  Future<Map<String, dynamic>?> getBotMe() async {
    final url = Uri.parse('$_baseUrl/getMe');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('getBotMe exception: $e');
    }
    return null;
  }
}
