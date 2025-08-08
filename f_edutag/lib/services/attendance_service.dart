import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api.dart';
import '../models/attendance.dart';
import '../services/auth_service.dart';

class AttendanceService {
  /// ✅ Toggle attendance for a single student (present <-> absent)
  static Future<bool> markAttendance(String regNo, int subjectId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('🔒 No authentication token found');

    final response = await http.post(
      Uri.parse('$baseUrl/attendance/toggle/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'reg_no': regNo, 'subject_id': subjectId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print('❌ Toggle attendance failed: ${response.body}');
      return false;
    }
  }

  /// ✅ Bulk mark attendance for multiple students with 'P' or 'A' status
  static Future<bool> bulkMarkAttendance(
    List<Map<String, dynamic>> attendanceData,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('🔒 No authentication token found');

    // Use the actual 'status' from each entry ('P' or 'A')
    final formattedData = attendanceData.map((data) {
      return {
        'student': data['reg_no'], // required by backend
        'subject': data['subject'], // subject ID
        'timestamp': data['timestamp'], // attendance time
        'status': data['status'], // 'P' or 'A'
      };
    }).toList();

    final response = await http.post(
      Uri.parse('$baseUrl/attendance/bulk/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(formattedData),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print('❌ Bulk attendance failed: ${response.body}');
      return false;
    }
  }

  /// ✅ Fetch attendance records with optional filters
  static Future<List<AttendanceRecord>> getAttendanceRecords({
    int? subjectId,
    String? regNo,
    String? date,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('🔒 No authentication token found');

    String url = '$baseUrl/attendance/';
    List<String> queryParams = [];

    if (subjectId != null) queryParams.add('subject=$subjectId');
    if (regNo != null) queryParams.add('reg_no=$regNo');
    if (date != null) queryParams.add('date=$date');

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => AttendanceRecord.fromJson(json)).toList();
    } else {
      throw Exception('❌ Failed to load attendance records: ${response.body}');
    }
  }
}
