import 'package:flutter/material.dart';
import '../../models/student.dart';

class StudentTile extends StatelessWidget {
  final Student student;
  final bool isPresent;
  final VoidCallback onToggle;

  const StudentTile({
    super.key,
    required this.student,
    required this.isPresent,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(student.name),
      subtitle: Text(student.regNo),
      trailing: Switch(value: isPresent, onChanged: (_) => onToggle()),
      onTap: onToggle,
    );
  }
}
