// models/subject.dart
class Subject {
  final int id;
  final String name;
  final int branch;
  final int semester;
  final int year;

  Subject({
    required this.id,
    required this.name,
    required this.branch,
    required this.semester,
    required this.year,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'] ?? '',
      branch: json['branch'],
      semester: json['semester'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'branch': branch,
      'semester': semester,
      'year': year,
    };
  }

  @override
  String toString() => name;
}
