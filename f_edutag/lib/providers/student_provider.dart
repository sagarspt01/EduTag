import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_service.dart';

class StudentProvider with ChangeNotifier {
  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStudents({
    required int branchId,
    required int semester,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _students = await StudentService.getStudents(
        branchId: branchId,
        semester: semester,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _students = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearStudents() {
    _students = [];
    _error = null;
    notifyListeners();
  }
}
