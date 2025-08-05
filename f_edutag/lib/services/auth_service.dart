import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'access': data['access'],
        'refresh': data['refresh'],
      };
    } else {
      return {'success': false, 'message': 'Invalid credentials'};
    }
  }
}
