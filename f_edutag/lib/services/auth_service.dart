import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class AuthService {
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // ✅ Login and save tokens
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final access = data['access'];
        final refresh = data['refresh'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(accessTokenKey, access);
        await prefs.setString(refreshTokenKey, refresh);

        return {'success': true, 'access': access, 'refresh': refresh};
      } else {
        return {
          'success': false,
          'message': 'Invalid credentials',
          'status': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Login error',
        'error': e.toString(),
      };
    }
  }

  // ✅ Get access token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(accessTokenKey);
    } catch (e) {
      print('❌ Failed to retrieve token: $e');
      return null;
    }
  }

  // ✅ Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ✅ Logout by clearing tokens
  static Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(accessTokenKey);
      await prefs.remove(refreshTokenKey);
    } catch (e) {
      print('❌ Failed to clear tokens: $e');
    }
  }
}
