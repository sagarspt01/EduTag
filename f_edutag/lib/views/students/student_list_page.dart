import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/branch.dart';
import '../../models/subject.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';

class StudentListPage extends StatefulWidget {
  final Branch branch;
  final int semester;
  final Subject subject;

  const StudentListPage({
    super.key,
    required this.branch,
    required this.semester,
    required this.subject,
  });

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final Set<String> _presentStudents = {};

  void _toggleAttendance(String regNo) {
    setState(() {
      if (_presentStudents.contains(regNo)) {
        _presentStudents.remove(regNo);
      } else {
        _presentStudents.add(regNo);
      }
    });
  }

  void _saveAttendance() async {
    if (_presentStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark attendance for at least one student'),
        ),
      );
      return;
    }

    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    bool success = await attendanceProvider.saveAttendance(
      _presentStudents.toList(),
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save attendance')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        actions: [
          IconButton(onPressed: _saveAttendance, icon: const Icon(Icons.save)),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          if (studentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (studentProvider.error != null) {
            return Center(child: Text('Error: ${studentProvider.error}'));
          }

          final students = studentProvider.students;
          if (students.isEmpty) {
            return const Center(child: Text('No students found'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Total: ${students.length}'),
                    Text('Present: ${_presentStudents.length}'),
                    Text(
                      'Absent: ${students.length - _presentStudents.length}',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isPresent = _presentStudents.contains(student.regNo);

                    return ListTile(
                      title: Text(student.name),
                      subtitle: Text(student.regNo),
                      trailing: Switch(
                        value: isPresent,
                        onChanged: (_) => _toggleAttendance(student.regNo),
                      ),
                      onTap: () => _toggleAttendance(student.regNo),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveAttendance,
        child: const Icon(Icons.save),
      ),
    );
  }
}
