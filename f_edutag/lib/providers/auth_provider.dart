import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;

  bool get isAuthenticated => _accessToken != null;
  String? get token => _accessToken;

  /// Called on login button
  Future<bool> login(String username, String password) async {
    final result = await AuthService.login(username, password);

    if (result['success']) {
      _accessToken = result['access'];
      _refreshToken = result['refresh'];

      // ✅ Optional: Save tokens in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _accessToken!);
      await prefs.setString('refreshToken', _refreshToken!);

      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  /// Logout and clear everything
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');

    notifyListeners();
  }

  /// Optional: Load saved token on app start (call in main.dart)
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');
    notifyListeners();
  }
}
