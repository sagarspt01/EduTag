// services/attendance_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api.dart';
import '../models/attendance.dart';

class AttendanceService {
  static Future<bool> markAttendance(String regNo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reg_no': regNo}),
    );

    return response.statusCode == 201;
  }

  static Future<List<AttendanceRecord>> getAttendanceRecords({
    int? subjectId,
    String? studentId,
    String? date,
  }) async {
    String url = '$baseUrl/attendance/';
    List<String> queryParams = [];

    if (subjectId != null) queryParams.add('subject_id=$subjectId');
    if (studentId != null) queryParams.add('student_id=$studentId');
    if (date != null) queryParams.add('date=$date');

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AttendanceRecord.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load attendance records');
    }
  }
}
