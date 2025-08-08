import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api.dart';
import '../../../models/subject.dart';

class StudentAnalysisPage extends StatefulWidget {
  const StudentAnalysisPage({super.key});

  @override
  State<StudentAnalysisPage> createState() => _StudentAnalysisPageState();
}

class _StudentAnalysisPageState extends State<StudentAnalysisPage> {
  final TextEditingController _regNoController = TextEditingController();

  List<Subject> _subjects = [];
  Subject? _selectedSubject;

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
    setState(() {
      subjectLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse('$baseUrl/subjects/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final subjectList = responseData is List
            ? responseData
            : responseData['results'] ?? [];

        setState(() {
          _subjects = subjectList
              .map<Subject>((json) => Subject.fromJson(json))
              .toList();
        });
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        subjectLoading = false;
      });
    }
  }

  Future<void> fetchAttendanceData() async {
    final regNo = _regNoController.text.trim();
    final subjectId = _selectedSubject?.id;

    if (regNo.isEmpty || subjectId == null) {
      setState(() {
        errorMessage = 'Please enter registration number and select a subject.';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = '';
      total = present = absent = 0;
      percentage = 0;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null || token.isEmpty) {
        throw Exception('Unauthorized. Please login again.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/attendance/?subject=$subjectId&reg_no=$regNo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final data = responseData is List
            ? responseData
            : responseData['results'] ?? [];

        total = data.length;
        present = data.where((entry) => entry['status'] == 'P').length;
        absent = total - present;
        percentage = total > 0 ? (present / total) * 100 : 0;
      } else {
        throw Exception('Failed to fetch attendance data.');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        loading = false;
      });
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
                items: _subjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject.name),
                      ),
                    )
                    .toList(),
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

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text("Total Classes: $total"),
        Text("Present: $present"),
        Text("Absent: $absent"),
        Text("Percentage: ${percentage.toStringAsFixed(1)}%"),
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
