class Teacher {
  final String username;
  final String email;

  Teacher({required this.username, required this.email});

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(username: json['username'], email: json['email']);
  }
}
