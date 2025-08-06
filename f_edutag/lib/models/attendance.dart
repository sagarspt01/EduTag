// models/attendance.dart
class AttendanceRecord {
  final String regNo;
  final DateTime timestamp;

  AttendanceRecord({required this.regNo, required this.timestamp});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      regNo: json['reg_no'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'reg_no': regNo, 'timestamp': timestamp.toIso8601String()};
  }
}
