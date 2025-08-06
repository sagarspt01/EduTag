import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../models/student.dart';

class StudentService {
  static Future<List<Student>> getStudents({
    required int branchId,
    required int semester,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      throw Exception('Unauthorized: No token found');
    }

    final uri = Uri.parse(
      '$baseUrl/students/?branch=$branchId&semester=$semester',
    );

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Student.fromJson(json)).toList();
      } catch (e) {
        throw Exception('Error parsing students: $e');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid or expired token');
    } else if (response.statusCode == 404) {
      throw Exception('Students endpoint not found: $uri');
    } else {
      throw Exception(
        'Failed to load students: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }
}
