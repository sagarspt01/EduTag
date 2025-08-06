// lib/views/students/student_analysis_page.dart
import 'package:flutter/material.dart';
import '../../../models/student.dart';

class StudentAnalysisPage extends StatelessWidget {
  const StudentAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Student student =
        ModalRoute.of(context)!.settings.arguments as Student;

    // Dummy data for now
    final int total = 20;
    final int present = 16;
    final double percentage = (present / total) * 100;

    return Scaffold(
      appBar: AppBar(title: Text("Analysis: ${student.name}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: student.profilePic != null
                  ? NetworkImage(student.profilePic!)
                  : null,
              child: student.profilePic == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              student.name ?? "",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text("Reg No: ${student.regNo}"),
            const SizedBox(height: 24),
            Text(
              "Attendance Summary",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text("Present: $present / $total"),
            Text("Percentage: ${percentage.toStringAsFixed(2)}%"),
          ],
        ),
      ),
    );
  }
}
