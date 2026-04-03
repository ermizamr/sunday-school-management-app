import 'package:flutter/material.dart';
import 'package:sunday_school_app/l10n/app_localizations.dart';

import '../../../../core/dates/ethiopian_date_formatter.dart';
import '../../../../core/supabase/supabase_client.dart';

class ServantAttendanceSessionScreen extends StatefulWidget {
  const ServantAttendanceSessionScreen({
    super.key,
    required this.sessionId,
    required this.academicYearId,
    required this.gradeId,
    required this.subjectId,
    required this.subjectName,
    required this.sessionDateIso,
  });

  final String sessionId;
  final String academicYearId;
  final String gradeId;
  final String subjectId;
  final String subjectName;
  final String sessionDateIso;

  @override
  State<ServantAttendanceSessionScreen> createState() =>
      _ServantAttendanceSessionScreenState();
}

class _Student {
  const _Student({required this.id, required this.name});

  final String id;
  final String name;
}

class _ServantAttendanceSessionScreenState
    extends State<ServantAttendanceSessionScreen> {
  final _studentSearchController = TextEditingController();
  String _studentSearchApplied = '';

  bool _loading = true;
  String? _error;

  bool _saving = false;

  List<_Student> _students = const [];
  final Map<String, String> _statusByStudentId = <String, String>{};

  static const List<String> _statuses = <String>[
    'present',
    'late',
    'permission',
    'absent',
  ];

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'present':
        return l10n.attendancePresent;
      case 'late':
        return l10n.attendanceLate;
      case 'permission':
        return l10n.attendancePermission;
      case 'absent':
      default:
        return l10n.attendanceAbsent;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _studentSearchController.dispose();
    super.dispose();
  }

  void _applyStudentSearch() {
    setState(() {
      _studentSearchApplied = _studentSearchController.text.trim();
    });
  }

  List<_Student> _filteredStudents() {
    final q = _studentSearchApplied.trim().toLowerCase();
    if (q.isEmpty) return _students;
    return _students.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = SupabaseClientManager.instance.client;
      final gradeId = widget.gradeId;
      final sessionId = widget.sessionId;

      final studentRows = await client
          .from('profiles')
          .select('id, name')
          .eq('role', 'student')
          .eq('grade_id', gradeId)
          .eq('account_status', 'active')
          .order('name');

      final students = studentRows
          .map(
            (r) => _Student(
              id: (r as Map)['id'] as String,
              name: ((r)['name'] as String?)?.trim() ?? '',
            ),
          )
          .toList();

      final recordRows = await client
          .from('attendance_records')
          .select('student_id, status')
          .eq('session_id', sessionId);

      final statusByStudent = <String, String>{};
      for (final r in recordRows) {
        final map = r as Map;
        final studentId = map['student_id']?.toString();
        final status = map['status']?.toString();
        if (studentId == null || studentId.isEmpty) continue;
        if (status == null || status.isEmpty) continue;
        statusByStudent[studentId] = status;
      }

      // Default missing records to "present" to speed up marking.
      for (final s in students) {
        statusByStudent.putIfAbsent(s.id, () => 'present');
      }

      if (!mounted) return;
      setState(() {
        _students = students;
        _statusByStudentId
          ..clear()
          ..addAll(statusByStudent);
      });
    } catch (e) {
      debugPrint('Servant attendance session load failed: $e');
      if (!mounted) return;
      setState(() {
        _error = 'load_failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final client = SupabaseClientManager.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _saving = true;
    });

    try {
      final nowIso = DateTime.now().toIso8601String();

      final payload = _students
          .map(
            (s) => <String, dynamic>{
              'session_id': widget.sessionId,
              'student_id': s.id,
              'status': _statusByStudentId[s.id] ?? 'present',
              'updated_by': userId,
              'updated_at': nowIso,
            },
          )
          .toList();

      await client
          .from('attendance_records')
          .upsert(payload, onConflict: 'session_id,student_id');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).servantAttendanceSaved),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).servantAttendanceSaveFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateLabel = EthiopianDateFormatter.formatFlexible(
      widget.sessionDateIso,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectName} • $dateLabel'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.commonSave),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.servantAttendanceLoadFailed,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _load,
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _studentSearchController,
                            decoration: InputDecoration(
                              hintText:
                                  l10n.servantAttendanceSearchStudentsHint,
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _applyStudentSearch(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _applyStudentSearch,
                          child: Text(l10n.commonSearch),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _filteredStudents().length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final student = _filteredStudents()[index];
                        final current =
                            _statusByStudentId[student.id] ?? 'present';

                        return ListTile(
                          title: Text(
                            student.name.isNotEmpty
                                ? student.name
                                : l10n.roleStudent,
                          ),
                          trailing: DropdownButton<String>(
                            value: _statuses.contains(current)
                                ? current
                                : 'present',
                            items: _statuses
                                .map(
                                  (s) => DropdownMenuItem<String>(
                                    value: s,
                                    child: Text(_statusLabel(l10n, s)),
                                  ),
                                )
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setState(() {
                                      _statusByStudentId[student.id] = v;
                                    });
                                  },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
