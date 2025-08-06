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

  // Save attendance for multiple students
  Future<bool> saveAttendance(List<String> presentStudentRegNos) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      for (String regNo in presentStudentRegNos) {
        await AttendanceService.markAttendance(regNo);
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load attendance records with optional filters
  Future<void> loadAttendanceRecords({
    int? subjectId,
    String? studentId,
    String? date,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _attendanceRecords = await AttendanceService.getAttendanceRecords(
        subjectId: subjectId,
        studentId: studentId,
        date: date,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _attendanceRecords = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Mark single student attendance
  Future<bool> markSingleAttendance(String regNo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool success = await AttendanceService.markAttendance(regNo);
      if (success) {
        // Add to local records if successful
        _attendanceRecords.add(
          AttendanceRecord(regNo: regNo, timestamp: DateTime.now()),
        );
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear all attendance records
  void clearAttendanceRecords() {
    _attendanceRecords = [];
    _error = null;
    notifyListeners();
  }

  // Get attendance records for a specific student
  List<AttendanceRecord> getStudentAttendance(String regNo) {
    return _attendanceRecords.where((record) => record.regNo == regNo).toList();
  }

  // Get attendance records for a specific date
  List<AttendanceRecord> getAttendanceByDate(DateTime date) {
    return _attendanceRecords
        .where(
          (record) =>
              record.timestamp.year == date.year &&
              record.timestamp.month == date.month &&
              record.timestamp.day == date.day,
        )
        .toList();
  }

  // Get attendance percentage for a specific student
  double getAttendancePercentage(String regNo, int totalClasses) {
    final studentRecords = getStudentAttendance(regNo);
    if (totalClasses == 0) return 0.0;
    return (studentRecords.length / totalClasses) * 100;
  }

  // Get total attendance count for today
  int getTodayAttendanceCount() {
    final today = DateTime.now();
    return getAttendanceByDate(today).length;
  }

  // Check if student is present today
  bool isStudentPresentToday(String regNo) {
    final today = DateTime.now();
    return _attendanceRecords.any(
      (record) =>
          record.regNo == regNo &&
          record.timestamp.year == today.year &&
          record.timestamp.month == today.month &&
          record.timestamp.day == today.day,
    );
  }

  // Get attendance statistics for a date range
  Map<String, int> getAttendanceStats(DateTime startDate, DateTime endDate) {
    final recordsInRange = _attendanceRecords
        .where(
          (record) =>
              record.timestamp.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              record.timestamp.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();

    Map<String, int> stats = {};
    for (var record in recordsInRange) {
      String dateKey =
          '${record.timestamp.year}-${record.timestamp.month}-${record.timestamp.day}';
      stats[dateKey] = (stats[dateKey] ?? 0) + 1;
    }
    return stats;
  }

  // Get unique students who have attendance records
  List<String> getUniqueStudents() {
    Set<String> uniqueRegNos = _attendanceRecords
        .map((record) => record.regNo)
        .toSet();
    return uniqueRegNos.toList();
  }

  // Get attendance count for a specific student in date range
  int getStudentAttendanceCount(
    String regNo,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _attendanceRecords
        .where(
          (record) =>
              record.regNo == regNo &&
              record.timestamp.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              record.timestamp.isBefore(endDate.add(const Duration(days: 1))),
        )
        .length;
  }

  // Check if attendance exists for a specific date
  bool hasAttendanceForDate(DateTime date) {
    return _attendanceRecords.any(
      (record) =>
          record.timestamp.year == date.year &&
          record.timestamp.month == date.month &&
          record.timestamp.day == date.day,
    );
  }

  // Get the latest attendance record for a student
  AttendanceRecord? getLatestAttendance(String regNo) {
    final studentRecords = getStudentAttendance(regNo);
    if (studentRecords.isEmpty) return null;

    studentRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return studentRecords.first;
  }

  // Reset all data and state
  void reset() {
    _attendanceRecords = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Get attendance summary for display
  Map<String, dynamic> getAttendanceSummary() {
    final today = DateTime.now();
    final todayCount = getTodayAttendanceCount();
    final totalRecords = _attendanceRecords.length;
    final uniqueStudents = getUniqueStudents().length;

    return {
      'todayCount': todayCount,
      'totalRecords': totalRecords,
      'uniqueStudents': uniqueStudents,
      'hasError': _error != null,
      'errorMessage': _error,
      'isLoading': _isLoading,
    };
  }
}
