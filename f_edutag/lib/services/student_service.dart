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

    final url = Uri.parse(
      '$baseUrl/students/?branch=$branchId&semester=$semester',
    );

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

        final List<dynamic> data = json['students'] ?? json['results'] ?? [];

        return data.map((json) => Student.fromJson(json)).toList();
      } catch (e) {
        throw Exception('Error parsing student data: $e');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid or expired token');
    } else if (response.statusCode == 404) {
      throw Exception('Endpoint not found: $url');
    } else {
      throw Exception('Failed to fetch students: ${response.statusCode}');
    }
  }
}
