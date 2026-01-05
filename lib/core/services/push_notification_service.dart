import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to handle sending push notifications via a proxy (Google Apps Script)
class PushNotificationService {
  static const String _proxyUrl =
      'https://script.google.com/macros/s/AKfycbxTOlFmRf2LXb8g1Y8wYpo2h0R3x2b1uCsCg1B6aBCTtqYww4M5wmYnay-1f6EJuBiG/exec';

  /// Sends a push notification to a specific device token
  static Future<bool> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'payload': payload ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }
}
