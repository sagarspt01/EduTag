// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../models/branch.dart';
// import '../../models/subject.dart';
// import '../../providers/filter_provider.dart';
// import '../../providers/student_provider.dart';
// import '../../providers/auth_provider.dart';
// import '../../widgets/dropdown_selector.dart';
// import '../../routes/app_routes.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   Branch? _selectedBranch;
//   int? _selectedSemester;
//   Subject? _selectedSubject;
//   bool _isLoading = false;

//   final List<int> _semesters = List.generate(8, (index) => index + 1);

//   @override
//   void initState() {
//     super.initState();
//     _loadBranches();
//   }

//   void _loadBranches() async {
//     setState(() => _isLoading = true);
//     final filterProvider = Provider.of<FilterProvider>(context, listen: false);
//     await filterProvider.loadBranches();
//     setState(() => _isLoading = false);
//   }

//   void _onBranchChanged(Branch? branch) {
//     setState(() {
//       _selectedBranch = branch;
//       _selectedSemester = null;
//       _selectedSubject = null;
//     });
//     if (branch != null) {
//       final filterProvider = Provider.of<FilterProvider>(
//         context,
//         listen: false,
//       );
//       filterProvider.setSelectedBranch(branch);
//     }
//   }

//   void _onSemesterChanged(int? semester) async {
//     setState(() {
//       _selectedSemester = semester;
//       _selectedSubject = null;
//       _isLoading = true;
//     });

//     if (semester != null && _selectedBranch != null) {
//       final filterProvider = Provider.of<FilterProvider>(
//         context,
//         listen: false,
//       );
//       filterProvider.setSelectedSemester(semester);
//       await filterProvider.loadSubjects(_selectedBranch!.id, semester);
//     }
//     setState(() => _isLoading = false);
//   }

//   void _onSubjectChanged(Subject? subject) {
//     setState(() => _selectedSubject = subject);
//     if (subject != null) {
//       final filterProvider = Provider.of<FilterProvider>(
//         context,
//         listen: false,
//       );
//       filterProvider.setSelectedSubject(subject);
//     }
//   }

//   void _navigateToStudentList() async {
//     if (_selectedBranch == null ||
//         _selectedSemester == null ||
//         _selectedSubject == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Please select all fields')));
//       return;
//     }

//     setState(() => _isLoading = true);

//     final studentProvider = Provider.of<StudentProvider>(
//       context,
//       listen: false,
//     );
//     await studentProvider.loadStudents(
//       branchId: _selectedBranch!.id,
//       semester: _selectedSemester!,
//     );

//     setState(() => _isLoading = false);

//     Navigator.pushNamed(
//       context,
//       AppRoutes.studentList,
//       arguments: {
//         'branch': _selectedBranch!,
//         'semester': _selectedSemester!,
//         'subject': _selectedSubject!,
//       },
//     );
//   }

//   void _logout() {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     authProvider.logout();
//     Navigator.pushReplacementNamed(context, AppRoutes.login);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Attendance System'),
//         actions: [
//           IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const Text('Select Class Details', style: TextStyle(fontSize: 20)),
//             const SizedBox(height: 20),
//             Consumer<FilterProvider>(
//               builder: (context, filterProvider, child) {
//                 return DropdownSelector<Branch>(
//                   label: 'Branch',
//                   value: _selectedBranch,
//                   items: filterProvider.branches,
//                   onChanged: _onBranchChanged,
//                   hint: 'Select Branch',
//                   isLoading: filterProvider.isLoadingBranches,
//                 );
//               },
//             ),
//             const SizedBox(height: 16),
//             DropdownSelector<int>(
//               label: 'Semester',
//               value: _selectedSemester,
//               items: _semesters,
//               onChanged: _selectedBranch != null ? _onSemesterChanged : null,
//               hint: 'Select Semester',
//               isLoading: false,
//             ),
//             const SizedBox(height: 16),
//             Consumer<FilterProvider>(
//               builder: (context, filterProvider, child) {
//                 return DropdownSelector<Subject>(
//                   label: 'Subject',
//                   value: _selectedSubject,
//                   items: filterProvider.subjects,
//                   onChanged: _onSubjectChanged,
//                   hint: 'Select Subject',
//                   isLoading: filterProvider.isLoadingSubjects,
//                 );
//               },
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed:
//                     (_selectedBranch != null &&
//                         _selectedSemester != null &&
//                         _selectedSubject != null &&
//                         !_isLoading)
//                     ? _navigateToStudentList
//                     : null,
//                 child: _isLoading
//                     ? const CircularProgressIndicator()
//                     : const Text('View Students'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
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
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoading = true);
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);
    await filterProvider.loadBranches();
    if (mounted) setState(() => _isLoading = false);
  }

  void _onBranchChanged(Branch? branch) {
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
    setState(() {
      _selectedSemester = semester;
      _selectedSubject = null;
      _isLoading = true;
    });

    if (semester != null && _selectedBranch != null) {
      final filterProvider = Provider.of<FilterProvider>(
        context,
        listen: false,
      );
      filterProvider.setSelectedSemester(semester);
      await filterProvider.loadSubjects(_selectedBranch!.id, semester);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _onSubjectChanged(Subject? subject) {
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

    setState(() => _isLoading = true);

    await Provider.of<StudentProvider>(
      context,
      listen: false,
    ).loadStudents(branchId: _selectedBranch!.id, semester: _selectedSemester!);

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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Class Details',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  Consumer<FilterProvider>(
                    builder: (context, filterProvider, child) {
                      return DropdownSelector<Branch>(
                        label: 'Branch',
                        value: _selectedBranch,
                        items: filterProvider.branches,
                        onChanged: _onBranchChanged,
                        hint: 'Select Branch',
                        isLoading: filterProvider.isLoadingBranches,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
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
                  Consumer<FilterProvider>(
                    builder: (context, filterProvider, child) {
                      return DropdownSelector<Subject>(
                        label: 'Subject',
                        value: _selectedSubject,
                        items: filterProvider.subjects,
                        onChanged: _onSubjectChanged,
                        hint: 'Select Subject',
                        isLoading: filterProvider.isLoadingSubjects,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
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
              ),
      ),
    );
  }
}
