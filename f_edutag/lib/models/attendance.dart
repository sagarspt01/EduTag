class AttendanceRecord {
  final String regNo;
  final DateTime timestamp;
  final int subjectId;

  AttendanceRecord({
    required this.regNo,
    required this.timestamp,
    required this.subjectId,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      regNo: json['student_reg_no'],
      timestamp: DateTime.parse(json['timestamp']),
      subjectId: json['subject'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_reg_no': regNo,
      'timestamp': timestamp.toIso8601String(),
      'subject': subjectId,
    };
  }
}
