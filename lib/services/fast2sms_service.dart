import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Fast2SmsService {
  static const String uri = 'https://www.fast2sms.com/dev/bulkV2';
  static const String apiKey =
      'gnVDyoufG2WrzqFc9ldKepbMOAt6HZjhT0Qx8N5ai7s1mEXURJZIDTfAlBh4s71eLvRaM3bC9pNxozX0';
  static const String senderId = 'SCALOT';
  static const String messageId = '183084';
  static const String route = 'dlt';

  /// Sends 6-digit OTP via Fast2SMS DLT route to a 10-digit mobile number
  static Future<bool> sendOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      final clean = mobileNumber.replaceAll(RegExp(r'\D'), '');
      final tenDigit = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;

      if (tenDigit.length != 10) {
        debugPrint('[Fast2SMS] Invalid 10-digit phone number: $mobileNumber');
        return false;
      }

      final payload = json.encode({
        'route': route,
        'sender_id': senderId,
        'message': messageId,
        'variables_values': otp.toString(),
        'flash': 0,
        'numbers': tenDigit,
      });

      final response = await http.post(
        Uri.parse(uri),
        headers: {
          'authorization': apiKey,
          'Content-Type': 'application/json',
        },
        body: payload,
      ).timeout(const Duration(seconds: 15));

      debugPrint('[Fast2SMS] Response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['return'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[Fast2SMS] Error sending SMS: $e');
      return false;
    }
  }
}
