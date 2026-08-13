import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SmsNetBdResult {
  final bool isSuccess;
  final int errorCode;
  final String message;
  final String? otpCode;
  final int? requestId;

  SmsNetBdResult({
    required this.isSuccess,
    required this.errorCode,
    required this.message,
    this.otpCode,
    this.requestId,
  });
}

class SmsNetBdService {
  static const String _apiKey = 'DgB7DKL9PfBX1BcN1R5nyLS1HmreF46q1z3HZzKx';
  static const String _sendSmsUrl = 'https://api.sms.net.bd/sendsms';
  static const String _balanceUrl = 'https://api.sms.net.bd/user/balance/';

  // Format phone number to 8801XXXXXXXXX required by sms.net.bd
  static String formatPhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('880')) {
      return clean;
    }
    if (clean.startsWith('0')) {
      return '88$clean';
    }
    if (clean.length == 10 && clean.startsWith('1')) {
      return '880$clean';
    }
    return clean;
  }

  // Generate a 6-digit OTP code
  static String generate6DigitOtp() {
    final random = Random();
    final code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  // Dispatch SMS via POST request to sms.net.bd
  static Future<SmsNetBdResult> sendSms({
    required String to,
    required String message,
  }) async {
    final formattedTo = formatPhoneNumber(to);

    try {
      final response = await http.post(
        Uri.parse(_sendSmsUrl),
        body: {
          'api_key': _apiKey,
          'msg': message,
          'to': formattedTo,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final int error = json['error'] ?? -1;
        final String msg = json['msg'] ?? 'Response received';

        if (error == 0) {
          final int? reqId = json['data'] != null ? json['data']['request_id'] : null;
          return SmsNetBdResult(
            isSuccess: true,
            errorCode: 0,
            message: msg,
            requestId: reqId,
          );
        } else {
          return SmsNetBdResult(
            isSuccess: false,
            errorCode: error,
            message: _getErrorMessage(error, msg),
          );
        }
      } else {
        return SmsNetBdResult(
          isSuccess: false,
          errorCode: response.statusCode,
          message: 'Server HTTP Error (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('SmsNetBd Exception: $e');
      return SmsNetBdResult(
        isSuccess: false,
        errorCode: 500,
        message: 'Network request failed: ${e.toString()}',
      );
    }
  }

  // Generate 6-digit OTP and send via SMS Gateway
  static Future<SmsNetBdResult> sendOtpSms({
    required String phoneNumber,
  }) async {
    final otpCode = generate6DigitOtp();
    final smsContent = 'Your TeleLite verification code is: $otpCode. Valid for 5 minutes.';

    final result = await sendSms(
      to: phoneNumber,
      message: smsContent,
    );

    if (result.errorCode == 421) {
      // sms.net.bd trial restriction: allow dev testing with generated OTP code
      debugPrint('SmsNetBd Error 421 restriction. Generated test OTP: $otpCode');
      return SmsNetBdResult(
        isSuccess: true,
        errorCode: 421,
        message: 'Notice (sms.net.bd Error 421): SMS restricted to registered number until account recharge. Testing OTP: $otpCode',
        otpCode: otpCode,
        requestId: result.requestId,
      );
    }

    return SmsNetBdResult(
      isSuccess: result.isSuccess,
      errorCode: result.errorCode,
      message: result.message,
      otpCode: otpCode,
      requestId: result.requestId,
    );
  }

  // Check SMS account balance
  static Future<String?> checkBalance() async {
    try {
      const url = '$_balanceUrl?api_key=$_apiKey';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['error'] == 0 && json['data'] != null) {
          return json['data']['balance']?.toString();
        }
      }
    } catch (e) {
      debugPrint('Check balance error: $e');
    }
    return null;
  }

  // Map API Error Codes according to documentation
  static String _getErrorMessage(int errorCode, String defaultMsg) {
    switch (errorCode) {
      case 400:
        return 'Missing or invalid parameters.';
      case 403:
        return 'Permission denied. Invalid API key.';
      case 410:
        return 'SMS Account expired.';
      case 413:
        return 'Invalid Sender ID.';
      case 414:
        return 'Message is empty.';
      case 415:
        return 'Message is too long.';
      case 416:
        return 'No valid phone number found.';
      case 417:
        return 'Insufficient SMS balance in sms.net.bd account.';
      case 420:
        return 'Content blocked by SMS provider.';
      case 421:
        return 'SMS sending restricted to registered phone number only.';
      default:
        return defaultMsg;
    }
  }
}
