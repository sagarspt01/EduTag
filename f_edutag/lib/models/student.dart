// models/student.dart
class Student {
  final String regNo;
  final String name;
  final int semester;
  final int branch;
  final String email;
  final String? profilePic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.regNo,
    required this.name,
    required this.semester,
    required this.branch,
    required this.email,
    this.profilePic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      regNo: json['reg_no'],
      name: json['name'] ?? '',
      semester: json['semester'],
      branch: json['branch'],
      email: json['email'],
      profilePic: json['profile_pic'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reg_no': regNo,
      'name': name,
      'semester': semester,
      'branch': branch,
      'email': email,
      'profile_pic': profilePic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() => '$name ($regNo)';
}
