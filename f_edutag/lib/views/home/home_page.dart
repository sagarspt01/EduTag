import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/branch.dart';
import '../../models/subject.dart';
import '../../providers/filter_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dropdown_selector.dart';
import '../../routes/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Branch? _selectedBranch;
  int? _selectedSemester;
  Subject? _selectedSubject;
  bool _isLoading = false;

  final List<int> _semesters = List.generate(8, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid "setState called during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBranches();
    });
  }

  Future<void> _loadBranches() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final filterProvider = Provider.of<FilterProvider>(
        context,
        listen: false,
      );
      await filterProvider.loadBranches();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load branches: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onBranchChanged(Branch? branch) {
    if (!mounted) return;

    setState(() {
      _selectedBranch = branch;
      _selectedSemester = null;
      _selectedSubject = null;
    });

    if (branch != null) {
      Provider.of<FilterProvider>(
        context,
        listen: false,
      ).setSelectedBranch(branch);
    }
  }

  Future<void> _onSemesterChanged(int? semester) async {
    if (!mounted) return;

    setState(() {
      _selectedSemester = semester;
      _selectedSubject = null;
      _isLoading = true;
    });

    try {
      if (semester != null && _selectedBranch != null) {
        final filterProvider = Provider.of<FilterProvider>(
          context,
          listen: false,
        );
        filterProvider.setSelectedSemester(semester);
        await filterProvider.loadSubjects(_selectedBranch!.id, semester);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load subjects: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSubjectChanged(Subject? subject) {
    if (!mounted) return;

    setState(() => _selectedSubject = subject);

    if (subject != null) {
      Provider.of<FilterProvider>(
        context,
        listen: false,
      ).setSelectedSubject(subject);
    }
  }

  Future<void> _navigateToStudentList() async {
    if (_selectedBranch == null ||
        _selectedSemester == null ||
        _selectedSubject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select all fields')));
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await Provider.of<StudentProvider>(context, listen: false).loadStudents(
        branchId: _selectedBranch!.id,
        semester: _selectedSemester!,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushNamed(
          context,
          AppRoutes.studentList,
          arguments: {
            'branch': _selectedBranch!,
            'semester': _selectedSemester!,
            'subject': _selectedSubject!,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load students: $e')));
      }
    }
  }

  void _logout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance System'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Consumer<FilterProvider>(
                builder: (context, filterProvider, child) {
                  // Show error if branches failed to load
                  if (filterProvider.branchesError != null &&
                      filterProvider.branches.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${filterProvider.branchesError}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadBranches,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Class Details',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 20),

                      // Branch Dropdown
                      DropdownSelector<Branch>(
                        label: 'Branch',
                        value: _selectedBranch,
                        items: filterProvider.branches,
                        onChanged: _onBranchChanged,
                        hint: 'Select Branch',
                        isLoading: filterProvider.isLoadingBranches,
                      ),

                      const SizedBox(height: 16),

                      // Semester Dropdown
                      DropdownSelector<int>(
                        label: 'Semester',
                        value: _selectedSemester,
                        items: _semesters,
                        onChanged: _selectedBranch != null
                            ? _onSemesterChanged
                            : null,
                        hint: 'Select Semester',
                        isLoading: false,
                      ),

                      const SizedBox(height: 16),

                      // Subject Dropdown
                      DropdownSelector<Subject>(
                        label: 'Subject',
                        value: _selectedSubject,
                        items: filterProvider.subjects,
                        onChanged: _onSubjectChanged,
                        hint: 'Select Subject',
                        isLoading: filterProvider.isLoadingSubjects,
                      ),

                      // Show subject error if any
                      if (filterProvider.subjectsError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            filterProvider.subjectsError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // View Students Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (_selectedBranch != null &&
                                  _selectedSemester != null &&
                                  _selectedSubject != null &&
                                  !_isLoading)
                              ? _navigateToStudentList
                              : null,
                          child: const Text('View Students'),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
