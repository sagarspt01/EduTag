import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../models/subject.dart';

class SubjectService {
  static Future<List<Subject>> getSubjects({
    required int branchId,
    required int semester,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      throw Exception('Unauthorized: No token found');
    }

    final url = Uri.parse(
      '$baseUrl/subjects/?branch=$branchId&semester=$semester',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        // If response is a map (due to pagination), extract 'results'
        final List<dynamic> data = decoded is List
            ? decoded
            : decoded['results'];

        return data.map((json) => Subject.fromJson(json)).toList();
      } catch (e) {
        throw Exception('Error parsing subjects: $e');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid or expired token');
    } else if (response.statusCode == 404) {
      throw Exception('Subjects endpoint not found: $url');
    } else {
      throw Exception(
        'Failed to load subjects: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }
}
