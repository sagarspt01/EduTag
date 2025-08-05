import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;

  bool get isAuthenticated => _accessToken != null;

  String? get token => _accessToken;

  Future<bool> login(String username, String password) async {
    final result = await AuthService.login(username, password);
    if (result['success']) {
      _accessToken = result['access'];
      _refreshToken = result['refresh'];
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
  }
}
