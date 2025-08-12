import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/branch.dart';
import '../../models/subject.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../services/nfc_service.dart';

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
  final NFCService _nfcService = NFCService();

  late String _formattedDateTime;
  Timer? _clockTimer;
  bool _isNfcScanning = false;

  @override
  void initState() {
    super.initState();
    _startClock();
    _loadInitialData();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // ------------------------------
  // Initialization
  // ------------------------------
  void _startClock() {
    _updateDateTime();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDateTime(),
    );
  }

  void _updateDateTime() {
    if (!mounted) return;
    setState(() {
      _formattedDateTime = DateFormat(
        'EEEE, dd MMMM yyyy • hh:mm:ss a',
      ).format(DateTime.now());
    });
  }

  void _loadInitialData() {
    Future.microtask(() {
      Provider.of<StudentProvider>(
        context,
        listen: false,
      ).loadStudents(branchId: widget.branch.id, semester: widget.semester);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTodayAttendance());
  }

  Future<void> _syncTodayAttendance() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).loadAttendanceRecords(subjectId: widget.subject.id, date: today);

      final records = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).attendanceRecords;

      if (!mounted) return;
      setState(() {
        _presentStudents
          ..clear()
          ..addAll(records.map((r) => r.regNo));
      });
    } catch (e) {
      _showSnackBar('Failed to load existing attendance');
    }
  }

  // ------------------------------
  // NFC Handling
  // ------------------------------
  Future<void> _handleNfcScan() async {
    if (_isNfcScanning) return;
    setState(() => _isNfcScanning = true);

    try {
      final tagData = await _nfcService.readTag();
      final regNo = tagData['content']?.trim();

      if (regNo == null || regNo.isEmpty) {
        _showSnackBar("❌ Invalid NFC tag");
        return;
      }

      final student = Provider.of<StudentProvider>(
        context,
        listen: false,
      ).students.where((s) => s.regNo == regNo).cast<Student?>().firstOrNull;

      if (student != null) {
        _toggleAttendance(student.regNo);
        final status = _presentStudents.contains(student.regNo)
            ? "Present"
            : "Absent";
        _showSnackBar("📱 ${student.name} marked as $status (Local)");
      } else {
        _showSnackBar("❌ No student found with RegNo: $regNo");
      }
    } catch (e) {
      _showSnackBar("❌ NFC Error: $e");
    } finally {
      if (mounted) setState(() => _isNfcScanning = false);
    }
  }

  // ------------------------------
  // Attendance Management
  // ------------------------------
  void _toggleAttendance(String regNo) {
    setState(() {
      _presentStudents.contains(regNo)
          ? _presentStudents.remove(regNo)
          : _presentStudents.add(regNo);
    });
  }

  Future<void> _saveAttendance() async {
    final students = Provider.of<StudentProvider>(
      context,
      listen: false,
    ).students;

    if (students.isEmpty) {
      _showSnackBar('No students to save attendance for');
      return;
    }

    _showLoadingDialog();

    final data = students.map((student) {
      return {
        'reg_no': student.regNo,
        'subject': widget.subject.id,
        'timestamp': DateTime.now().toIso8601String(),
        'status': _presentStudents.contains(student.regNo) ? 'P' : 'A',
      };
    }).toList();

    try {
      final success = await Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).saveAttendance(data);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        _showSnackBar('✅ Attendance saved successfully');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showSnackBar('❌ Failed to save attendance');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar('❌ Error saving attendance: $e');
    }
  }

  // ------------------------------
  // UI Helpers
  // ------------------------------
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
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
            _buildProfileImage(student.profilePic),
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

  Widget _buildProfileImage(String? url) {
    return CachedNetworkImage(
      imageUrl: url ?? '',
      imageBuilder: (_, img) => CircleAvatar(radius: 40, backgroundImage: img),
      placeholder: (_, __) => const CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, size: 40, color: Colors.white),
      ),
      errorWidget: (_, __, ___) => const CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, size: 40, color: Colors.white),
      ),
    );
  }

  // ------------------------------
  // Build
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                '${_presentStudents.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Attendance',
            onPressed: _saveAttendance,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleNfcScan,
        tooltip: 'Scan NFC',
        child: _isNfcScanning
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.nfc),
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, _) {
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
                _formattedDateTime,
                style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              _buildStatsRow(students.length),
              const SizedBox(height: 8),
              if (_presentStudents.isNotEmpty) _buildSaveReminder(),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (_, i) => _buildStudentTile(students[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('👥 Total: $total'),
          Text('✅ Present: ${_presentStudents.length}'),
          Text('❌ Absent: ${total - _presentStudents.length}'),
        ],
      ),
    );
  }

  Widget _buildSaveReminder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Changes are local. Click Save to update the database.',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(Student student) {
    final isPresent = _presentStudents.contains(student.regNo);
    return ListTile(
      leading: GestureDetector(
        onTap: () => _showStudentDetails(student),
        child: _buildProfileImage(student.profilePic),
      ),
      title: Text(student.name),
      subtitle: Text(student.regNo),
      trailing: Switch(
        value: isPresent,
        onChanged: (_) => _toggleAttendance(student.regNo),
      ),
      tileColor: isPresent ? Colors.green.shade50 : null,
      onTap: () => _toggleAttendance(student.regNo),
    );
  }
}

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
