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

  // Error states
  String? _branchesError;
  String? _subjectsError;

  // Getters
  List<Branch> get branches => _branches;
  List<Subject> get subjects => _subjects;

  Branch? get selectedBranch => _selectedBranch;
  int? get selectedSemester => _selectedSemester;
  Subject? get selectedSubject => _selectedSubject;

  bool get isLoadingBranches => _isLoadingBranches;
  bool get isLoadingSubjects => _isLoadingSubjects;

  String? get branchesError => _branchesError;
  String? get subjectsError => _subjectsError;

  /// Load branches from backend
  Future<void> loadBranches() async {
    if (_isLoadingBranches) return; // Prevent multiple calls

    _isLoadingBranches = true;
    _branchesError = null;

    // Use addPostFrameCallback to ensure we're not in build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      _branches = await BranchService.getBranches();
      _branchesError = null;
    } catch (e) {
      _branches = [];
      _branchesError = 'Error loading branches: $e';
      print('Error loading branches: $e');
    } finally {
      _isLoadingBranches = false;

      // Schedule notification after current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Load subjects based on selected branch and semester
  Future<void> loadSubjects(int branchId, int semester) async {
    if (_isLoadingSubjects) return; // Prevent multiple calls

    _isLoadingSubjects = true;
    _subjectsError = null;

    // Use addPostFrameCallback to ensure we're not in build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      _subjects = await SubjectService.getSubjects(
        branchId: branchId,
        semester: semester,
      );
      _subjectsError = null;
    } catch (e) {
      _subjects = [];
      _subjectsError = 'Error loading subjects: $e';
      print('Error loading subjects: $e');
    } finally {
      _isLoadingSubjects = false;

      // Schedule notification after current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Set selected branch and reset dependent selections
  void setSelectedBranch(Branch branch) {
    _selectedBranch = branch;
    _selectedSemester = null;
    _selectedSubject = null;
    _subjects = [];
    _subjectsError = null;
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
    _branchesError = null;
    _subjectsError = null;
    notifyListeners();
  }

  /// Clear error messages
  void clearBranchesError() {
    if (_branchesError != null) {
      _branchesError = null;
      notifyListeners();
    }
  }

  void clearSubjectsError() {
    if (_subjectsError != null) {
      _subjectsError = null;
      notifyListeners();
    }
  }
}
