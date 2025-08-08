import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _accessToken != null;
  String? get token => _accessToken;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Called on login button
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    final result = await AuthService.login(username, password);

    if (result['success']) {
      _accessToken = result['access'];
      _refreshToken = result['refresh'];

      // Save tokens in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _accessToken!);
      await prefs.setString('refreshToken', _refreshToken!);

      _setLoading(false);
      return true;
    } else {
      _setError(result['message'] ?? 'Login failed');
      _setLoading(false);
      return false;
    }
  }

  /// Logout and clear everything
  Future<void> logout() async {
    _setLoading(true);

    _accessToken = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');

    _setLoading(false);
  }

  /// Load saved token on app start - MUST be called before MaterialApp
  Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('accessToken');
      _refreshToken = prefs.getString('refreshToken');

      // Don't call notifyListeners here - this should be called before widget tree
      // If you need to call this after widget tree is built, use loadTokenSafely()
    } catch (e) {
      _error = 'Failed to load saved token';
      print('Error loading token: $e');
    }
  }

  /// Safe method to load token after widget tree is built
  void loadTokenSafely() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadToken();
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
