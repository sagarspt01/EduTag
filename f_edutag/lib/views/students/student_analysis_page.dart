import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api.dart';
import '../../../models/subject.dart';
import '../../../models/student.dart';

class StudentAnalysisPage extends StatefulWidget {
  const StudentAnalysisPage({super.key});

  @override
  State<StudentAnalysisPage> createState() => _StudentAnalysisPageState();
}

class _StudentAnalysisPageState extends State<StudentAnalysisPage> {
  final TextEditingController _regNoController = TextEditingController();

  List<Subject> _subjects = [];
  Subject? _selectedSubject;

  Student? _student;
  int total = 0;
  int present = 0;
  int absent = 0;
  double percentage = 0;

  String errorMessage = '';
  bool loading = false;
  bool subjectLoading = false;

  String? _lastRegNo;
  String? _lastSubjectId;

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    setState(() => subjectLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) throw Exception('Unauthorized. Please login again.');

      final response = await http.get(
        Uri.parse('$baseUrl/subjects/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List subjectsJson = data is List ? data : data['results'] ?? [];

        setState(() {
          _subjects = subjectsJson.map((e) => Subject.fromJson(e)).toList();
        });
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (e) {
      setState(
        () => errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      setState(() => subjectLoading = false);
    }
  }

  Future<void> fetchAttendanceData() async {
    final regNo = _regNoController.text.trim();
    final subjectId = _selectedSubject?.id.toString();

    if (regNo.isEmpty || subjectId == null) {
      setState(
        () => errorMessage =
            'Please enter registration number and select a subject.',
      );
      return;
    }

    if (_lastRegNo == regNo &&
        _lastSubjectId == subjectId &&
        _student != null) {
      return;
    }

    setState(() {
      loading = true;
      errorMessage = '';
      total = present = absent = 0;
      percentage = 0;
      if (_lastRegNo != regNo) {
        _student = null;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) throw Exception('Unauthorized. Please login again.');

      final response = await http.get(
        Uri.parse(
          '$baseUrl/attendance/student-summary/?reg_no=$regNo&subject=$subjectId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _student = Student.fromJson(data['student']);
          final summary = data['attendance_summary'];
          total = summary['total'];
          present = summary['present'];
          absent = summary['absent'];
          percentage = summary['percentage'].toDouble();
        });

        _lastRegNo = regNo;
        _lastSubjectId = subjectId;
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      setState(
        () => errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _buildInputs() {
    return Column(
      children: [
        TextField(
          controller: _regNoController,
          decoration: const InputDecoration(
            labelText: "Enter Registration Number",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            if (_lastRegNo != value.trim()) {
              setState(() {
                _lastRegNo = null;
                _student = null;
                total = present = absent = 0;
                percentage = 0;
                errorMessage = '';
              });
            }
          },
        ),
        const SizedBox(height: 12),
        subjectLoading
            ? const CircularProgressIndicator()
            : DropdownButtonFormField<Subject>(
                value: _selectedSubject,
                items: _subjects.map((subject) {
                  return DropdownMenuItem<Subject>(
                    value: subject,
                    child: Text(subject.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value;
                    if (_lastSubjectId != value?.id.toString()) {
                      _lastSubjectId = null;
                      total = present = absent = 0;
                      percentage = 0;
                      errorMessage = '';
                    }
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Select Subject',
                  border: OutlineInputBorder(),
                ),
              ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: loading ? null : fetchAttendanceData,
          child: loading
              ? const CircularProgressIndicator()
              : const Text("Get Analysis"),
        ),
      ],
    );
  }

  Widget _buildStudentDetails() {
    if (_student == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: _student!.profilePic != null
                  ? NetworkImage(_student!.profilePic!)
                  : null,
              child: _student!.profilePic == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Name: ${_student!.name}"),
                  Text("Reg No: ${_student!.regNo}"),
                  Text("Email: ${_student!.email}"),
                  Text("Semester: ${_student!.semester}"),
                  Text("Branch: ${_student!.branch}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        _buildStudentDetails(),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Attendance Summary"),
                const SizedBox(height: 12),
                Text("Total Classes: $total"),
                Text("Present: $present"),
                Text("Absent: $absent"),
                Text("Percentage: ${percentage.toStringAsFixed(1)}%"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _regNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Analysis")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInputs(),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(errorMessage),
              ),
            if (!loading && total > 0) _buildResults(),
          ],
        ),
      ),
    );
  }
}
