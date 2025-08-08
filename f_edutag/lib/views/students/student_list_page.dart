import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/branch.dart';
import '../../models/subject.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../students/student_analysis_page.dart';

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
  final Set<String> _presentRegNos = {};
  late String _currentDateTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    // Load students on startup
    Future.microtask(() {
      Provider.of<StudentProvider>(
        context,
        listen: false,
      ).loadStudents(branchId: widget.branch.id, semester: widget.semester);
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentDateTime = DateFormat(
        'EEEE, dd MMMM yyyy • hh:mm:ss a',
      ).format(now);
    });
  }

  void _toggleStudent(String regNo) {
    setState(() {
      if (_presentRegNos.contains(regNo)) {
        _presentRegNos.remove(regNo);
      } else {
        _presentRegNos.add(regNo);
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_presentRegNos.isEmpty) {
      _showSnackBar('Please mark attendance for at least one student');
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final subjectId = widget.subject.id;

    final List<Map<String, dynamic>> data = _presentRegNos.map((regNo) {
      return {'reg_no': regNo, 'subject': subjectId, 'timestamp': timestamp};
    }).toList();

    final success = await Provider.of<AttendanceProvider>(
      context,
      listen: false,
    ).saveAttendance(data);

    if (success) {
      _showSnackBar('✅ Attendance saved successfully');
      Navigator.pop(context);
    } else {
      _showSnackBar('❌ Failed to save attendance');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showStudentDetails(Student student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Student Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text('👤 Name: ${student.name}'),
            Text('🆔 Reg No: ${student.regNo}'),
            Text('📧 Email: ${student.email}'),
            Text('📚 Semester: ${student.semester}'),
            Text('🏫 Branch: ${student.branch}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        actions: [
          IconButton(
            onPressed: _saveAttendance,
            icon: const Icon(Icons.save),
            tooltip: 'Save Attendance',
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final students = provider.students;

          if (students.isEmpty) {
            return const Center(child: Text('No students found'));
          }

          return Column(
            children: [
              const SizedBox(height: 8),
              Text(
                _currentDateTime,
                style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('👥 Total: ${students.length}'),
                    Text('✅ Present: ${_presentRegNos.length}'),
                    Text(
                      '❌ Absent: ${students.length - _presentRegNos.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentAnalysisPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Analysis'),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (_, index) {
                    final student = students[index];
                    final isPresent = _presentRegNos.contains(student.regNo);

                    return ListTile(
                      leading: GestureDetector(
                        onTap: () => _showStudentDetails(student),
                        child: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                      title: Text(student.name),
                      subtitle: Text(student.regNo),
                      trailing: Switch(
                        value: isPresent,
                        onChanged: (_) => _toggleStudent(student.regNo),
                      ),
                      onTap: () => _toggleStudent(student.regNo),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
