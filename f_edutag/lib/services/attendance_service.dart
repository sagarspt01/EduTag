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

  /// ✅ Bulk mark attendance for multiple students as present
  static Future<bool> bulkMarkAttendance(
    List<Map<String, dynamic>> attendanceData,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('🔒 No authentication token found');

    // Backend expects 'student' as reg_no, 'subject', 'timestamp', and status='P'
    final formattedData = attendanceData.map((data) {
      return {
        'student': data['reg_no'], // 👈 Use 'student' for reg_no
        'subject': data['subject'],
        'timestamp': data['timestamp'],
        'status': 'P', // 👈 Use 'P' for Present
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

  /// ✅ Get attendance records with optional filters
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
    if (regNo != null)
      queryParams.add('reg_no=$regNo'); // 🛠️ Consistent with backend
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
