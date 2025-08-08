import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../models/attendance.dart';

class AttendanceProvider with ChangeNotifier {
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;

  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Bulk save attendance for multiple students
  Future<bool> saveAttendance(List<Map<String, dynamic>> attendanceData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await AttendanceService.bulkMarkAttendance(
        attendanceData,
      );

      if (success) {
        for (final data in attendanceData) {
          _attendanceRecords.add(
            AttendanceRecord(
              regNo: data['reg_no'],
              timestamp: DateTime.parse(data['timestamp']),
              subjectId: data['subject'],
            ),
          );
        }
        return true;
      } else {
        _error = 'Failed to save attendance';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark attendance for a single student
  Future<bool> markSingleAttendance(String regNo, int subjectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await AttendanceService.markAttendance(regNo, subjectId);
      if (success) {
        _attendanceRecords.add(
          AttendanceRecord(
            regNo: regNo,
            timestamp: DateTime.now(),
            subjectId: subjectId,
          ),
        );
        return true;
      } else {
        _error = 'Failed to mark attendance';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load attendance records with optional filters
  Future<void> loadAttendanceRecords({
    int? subjectId,
    String? regNo,
    String? date,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _attendanceRecords = await AttendanceService.getAttendanceRecords(
        subjectId: subjectId,
        regNo: regNo,
        date: date,
      );
    } catch (e) {
      _error = e.toString();
      _attendanceRecords = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all attendance records
  void clearAttendanceRecords() {
    _attendanceRecords = [];
    _error = null;
    notifyListeners();
  }

  /// Get all attendance records for a student
  List<AttendanceRecord> getStudentAttendance(String regNo) {
    return _attendanceRecords.where((r) => r.regNo == regNo).toList();
  }

  /// Get attendance records for a specific date
  List<AttendanceRecord> getAttendanceByDate(DateTime date) {
    return _attendanceRecords.where((r) {
      final ts = r.timestamp;
      return ts.year == date.year &&
          ts.month == date.month &&
          ts.day == date.day;
    }).toList();
  }

  /// Calculate attendance percentage
  double getAttendancePercentage(String regNo, int totalClasses) {
    final attended = getStudentAttendance(regNo).length;
    return totalClasses == 0 ? 0.0 : (attended / totalClasses) * 100;
  }

  /// Count of students present today
  int getTodayAttendanceCount() {
    return getAttendanceByDate(DateTime.now()).length;
  }

  /// Check if a student is marked present today
  bool isStudentPresentToday(String regNo) {
    final today = DateTime.now();
    return _attendanceRecords.any((r) {
      final ts = r.timestamp;
      return r.regNo == regNo &&
          ts.year == today.year &&
          ts.month == today.month &&
          ts.day == today.day;
    });
  }

  /// Attendance count by date (for chart/summary)
  Map<String, int> getAttendanceStats(DateTime startDate, DateTime endDate) {
    final stats = <String, int>{};
    for (var r in _attendanceRecords) {
      if (r.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
          r.timestamp.isBefore(endDate.add(const Duration(days: 1)))) {
        final dateKey =
            '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}-${r.timestamp.day.toString().padLeft(2, '0')}';
        stats[dateKey] = (stats[dateKey] ?? 0) + 1;
      }
    }
    return stats;
  }

  /// Get list of unique students marked present
  List<String> getUniqueStudents() {
    return _attendanceRecords.map((r) => r.regNo).toSet().toList();
  }

  /// Count how many times a student attended in range
  int getStudentAttendanceCount(String regNo, DateTime start, DateTime end) {
    return _attendanceRecords.where((r) {
      return r.regNo == regNo &&
          r.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
          r.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).length;
  }

  /// Check if any attendance exists for a specific date
  bool hasAttendanceForDate(DateTime date) {
    return _attendanceRecords.any((r) {
      final ts = r.timestamp;
      return ts.year == date.year &&
          ts.month == date.month &&
          ts.day == date.day;
    });
  }

  /// Get latest attendance for a student
  AttendanceRecord? getLatestAttendance(String regNo) {
    final studentRecords = getStudentAttendance(regNo);
    if (studentRecords.isEmpty) return null;
    studentRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return studentRecords.first;
  }

  /// Reset provider state
  void reset() {
    _attendanceRecords = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Summary for dashboard
  Map<String, dynamic> getAttendanceSummary() {
    return {
      'todayCount': getTodayAttendanceCount(),
      'totalRecords': _attendanceRecords.length,
      'uniqueStudents': getUniqueStudents().length,
      'hasError': _error != null,
      'errorMessage': _error,
      'isLoading': _isLoading,
    };
  }
}
