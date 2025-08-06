import 'package:flutter/material.dart';
import '../models/branch.dart';
import '../models/subject.dart';
import '../services/branch_service.dart';
import '../services/subject_service.dart';

class FilterProvider with ChangeNotifier {
  // Data lists
  List<Branch> _branches = [];
  List<Subject> _subjects = [];

  // Selected filters
  Branch? _selectedBranch;
  int? _selectedSemester;
  Subject? _selectedSubject;

  // Loading states
  bool _isLoadingBranches = false;
  bool _isLoadingSubjects = false;

  // Getters
  List<Branch> get branches => _branches;
  List<Subject> get subjects => _subjects;

  Branch? get selectedBranch => _selectedBranch;
  int? get selectedSemester => _selectedSemester;
  Subject? get selectedSubject => _selectedSubject;

  bool get isLoadingBranches => _isLoadingBranches;
  bool get isLoadingSubjects => _isLoadingSubjects;

  /// Load branches from backend
  Future<void> loadBranches() async {
    _isLoadingBranches = true;
    notifyListeners();

    try {
      _branches = await BranchService.getBranches();
    } catch (e) {
      _branches = [];
      print('Error loading branches: $e');
    } finally {
      _isLoadingBranches = false;
      notifyListeners();
    }
  }

  /// Load subjects based on selected branch and semester
  Future<void> loadSubjects(int branchId, int semester) async {
    _isLoadingSubjects = true;
    notifyListeners();

    try {
      _subjects = await SubjectService.getSubjects(
        branchId: branchId,
        semester: semester,
      );
    } catch (e) {
      _subjects = [];
      print('Error loading subjects: $e');
    } finally {
      _isLoadingSubjects = false;
      notifyListeners();
    }
  }

  /// Set selected branch and reset dependent selections
  void setSelectedBranch(Branch branch) {
    _selectedBranch = branch;
    _selectedSemester = null;
    _selectedSubject = null;
    _subjects = [];
    notifyListeners();
  }

  /// Set selected semester and reset subject
  void setSelectedSemester(int semester) {
    _selectedSemester = semester;
    _selectedSubject = null;
    notifyListeners();
  }

  /// Set selected subject
  void setSelectedSubject(Subject subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  /// Clear all filters and subjects
  void clearSelections() {
    _selectedBranch = null;
    _selectedSemester = null;
    _selectedSubject = null;
    _subjects = [];
    notifyListeners();
  }
}
