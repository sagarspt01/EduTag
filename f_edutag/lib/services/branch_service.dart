// services/branch_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../models/branch.dart';

class BranchService {
  static Future<List<Branch>> getBranches() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      throw Exception('Unauthorized: No token found');
    }

    final url = Uri.parse('$baseUrl/branches/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> json = jsonDecode(response.body);

        // Try 'branches' or 'results' field depending on your API response
        final List<dynamic> data = json['branches'] ?? json['results'] ?? [];

        return data.map((json) => Branch.fromJson(json)).toList();
      } catch (e) {
        throw Exception('Error parsing branches: $e');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid or expired token');
    } else if (response.statusCode == 404) {
      throw Exception('Endpoint not found: $url');
    } else {
      throw Exception('Failed to load branches: ${response.statusCode}');
    }
  }
}
