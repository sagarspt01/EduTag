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

  Future<void> fetchStudent(String regNo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) throw Exception('Unauthorized. Please login again.');

      final response = await http.get(
        Uri.parse('$baseUrl/students/?reg_no=$regNo'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final results = responseData is List
            ? responseData
            : responseData['results'] ?? [];

        if (results.isNotEmpty) {
          setState(() => _student = Student.fromJson(results[0]));
        } else {
          throw Exception('Student not found');
        }
      } else {
        throw Exception('Failed to fetch student data');
      }
    } catch (e) {
      setState(
        () => errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> fetchAttendanceData() async {
    final regNo = _regNoController.text.trim();
    final subjectId = _selectedSubject?.id;

    if (regNo.isEmpty || subjectId == null) {
      setState(
        () => errorMessage =
            'Please enter registration number and select a subject.',
      );
      return;
    }

    setState(() {
      loading = true;
      errorMessage = '';
      total = present = absent = 0;
      percentage = 0;
      _student = null;
    });

    try {
      await fetchStudent(regNo);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) throw Exception('Unauthorized. Please login again.');

      final response = await http.get(
        Uri.parse('$baseUrl/attendance/?subject=$subjectId&reg_no=$regNo'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List records = data is List ? data : data['results'] ?? [];

        total = records.length;
        present = records.where((e) => e['status'] == 'P').length;
        absent = total - present;
        percentage = total > 0 ? (present / total) * 100 : 0;
      } else {
        throw Exception('Failed to fetch attendance data');
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _regNoController,
          decoration: const InputDecoration(
            labelText: "Enter Registration Number",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        subjectLoading
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<Subject>(
                value: _selectedSubject,
                items: _subjects.map((subject) {
                  return DropdownMenuItem<Subject>(
                    value: subject,
                    child: Text(subject.name),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedSubject = value),
                decoration: const InputDecoration(
                  labelText: 'Select Subject',
                  border: OutlineInputBorder(),
                ),
              ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: fetchAttendanceData,
          child: const Text("Get Analysis"),
        ),
      ],
    );
  }

  Widget _buildStudentDetails() {
    if (_student == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👤 Name: ${_student!.name}"),
            Text("🆔 Reg No: ${_student!.regNo}"),
            Text("📧 Email: ${_student!.email}"),
            Text("🎓 Semester: ${_student!.semester}"),
            Text("🏢 Branch: ${_student!.branch}"),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStudentDetails(),
        const SizedBox(height: 20),
        Text("📊 Total Classes: $total"),
        Text("✅ Present: $present"),
        Text("❌ Absent: $absent"),
        Text("📈 Percentage: ${percentage.toStringAsFixed(1)}%"),
      ],
    );
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
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            if (!loading && total > 0) _buildResults(),
          ],
        ),
      ),
    );
  }
}
