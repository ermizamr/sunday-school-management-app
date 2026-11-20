import 'package:flutter/material.dart';
import 'package:sunday_school_app/l10n/app_localizations.dart';

import '../../../../core/dates/ethiopian_date_formatter.dart';
import '../../../../core/errors/app_error_message.dart';
import '../../../../core/refresh/app_refresh_configurator.dart';
import '../../../../core/supabase/supabase_client.dart';
import 'servant_attendance_session_screen.dart';

class ServantAttendanceHomeScreen extends StatefulWidget {
  const ServantAttendanceHomeScreen({super.key});

  @override
  State<ServantAttendanceHomeScreen> createState() =>
      _ServantAttendanceHomeScreenState();
}

class _AttendanceSubject {
  const _AttendanceSubject({required this.id, required this.name});

  final String id;
  final String name;
}

class _AttendanceSession {
  const _AttendanceSession({required this.id, required this.sessionDateIso});

  final String id;
  final String sessionDateIso; // yyyy-mm-dd
}

class _Student {
  const _Student({required this.id, required this.name});

  final String id;
  final String name;
}

class _AbsentSummary {
  const _AbsentSummary({required this.student, required this.absentDays});

  final _Student student;
  final int absentDays;
}

class _ServantAttendanceHomeScreenState
    extends State<ServantAttendanceHomeScreen> {
  String? _activeAcademicYearId;
  String? _myGradeId;
  String? _currentUserId;

  bool _loading = true;
  String? _error;

  // Removed date search feature

  final _minAbsentController = TextEditingController();
  int? _minAbsentApplied;
  bool _loadingMinAbsent = false;
  List<_AbsentSummary> _minAbsentResults = const [];

  List<_AttendanceSubject> _subjects = const [];
  String? _selectedSubjectId;

  bool _loadingSessions = false;
  List<_AttendanceSession> _sessions = const [];

  List<_Student> _studentsCache = const [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _minAbsentController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = SupabaseClientManager.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('not_signed_in');
      }

      final academicYear = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', userId)
          .maybeSingle();

      final academicYearId = academicYear?['id'] as String?;
      final gradeId = profile?['grade_id'] as String?;

      if (academicYearId == null || academicYearId.isEmpty) {
        throw StateError('missing_academic_year');
      }

      if (gradeId == null || gradeId.isEmpty) {
        throw StateError('missing_grade_assignment');
      }

      final subjectRows = await client
          .from('subjects')
          .select('id, name')
          .eq('grade_id', gradeId)
          .eq('active', true)
          .order('name');

      final subjects = subjectRows
          .map(
            (r) => _AttendanceSubject(
              id: (r as Map)['id'] as String,
              name: (r)['name'] as String,
            ),
          )
          .toList();

      final selectedSubjectId = subjects.isEmpty ? null : subjects.first.id;

      if (!mounted) return;
      setState(() {
        _currentUserId = userId;
        _activeAcademicYearId = academicYearId;
        _myGradeId = gradeId;
        _subjects = subjects;
        _selectedSubjectId = selectedSubjectId;
      });

      if (selectedSubjectId != null) {
        await _loadSessionsForSelectedSubject();
      }
    } catch (e) {
      debugPrint('Servant attendance home load failed: $e');
      if (!mounted) return;
      setState(() {
        _error = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.servantAttendanceLoadFailed,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadSessionsForSelectedSubject() async {
    final client = SupabaseClientManager.instance.client;
    final academicYearId = _activeAcademicYearId;
    final gradeId = _myGradeId;
    final subjectId = _selectedSubjectId;

    if (academicYearId == null || gradeId == null || subjectId == null) {
      return;
    }

    setState(() {
      _loadingSessions = true;
    });

    try {
      final rows = await client
          .from('attendance_sessions')
          .select('id, session_date')
          .eq('academic_year_id', academicYearId)
          .eq('grade_id', gradeId)
          .eq('subject_id', subjectId)
          .order('session_date', ascending: false);

      final sessions = rows
          .map(
            (r) => _AttendanceSession(
              id: (r as Map)['id'] as String,
              sessionDateIso: (r)['session_date'] as String,
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _sessions = sessions;
      });
    } catch (_) {
      // Keep old data on any error.
    } finally {
      if (mounted) {
        setState(() {
          _loadingSessions = false;
        });
      }
    }
  }

  Future<List<_Student>> _loadStudentsForMyGrade() async {
    if (_studentsCache.isNotEmpty) return _studentsCache;

    final client = SupabaseClientManager.instance.client;
    final gradeId = _myGradeId;
    if (gradeId == null) return const [];

    final rows = await client
        .from('profiles')
        .select('id, name')
        .eq('role', 'student')
        .eq('grade_id', gradeId)
        .eq('account_status', 'active')
        .order('name');

    final students = rows
        .map(
          (r) => _Student(
            id: (r as Map)['id'] as String,
            name: ((r)['name'] as String?)?.trim() ?? '',
          ),
        )
        .toList();

    _studentsCache = students;
    return students;
  }

  Future<void> _runMinAbsentFilter() async {
    final raw = _minAbsentController.text.trim();
    final minDays = int.tryParse(raw);
    if (minDays == null || minDays < 0) {
      setState(() {
        _minAbsentApplied = null;
        _minAbsentResults = const [];
      });
      return;
    }

    final client = SupabaseClientManager.instance.client;
    final academicYearId = _activeAcademicYearId;
    final subjectId = _selectedSubjectId;

    if (academicYearId == null || subjectId == null) return;

    setState(() {
      _loadingMinAbsent = true;
      _minAbsentApplied = minDays;
      _minAbsentResults = const [];
    });

    try {
      final students = await _loadStudentsForMyGrade();

      final sessionIds = _sessions.map((s) => s.id).toList();
      if (sessionIds.isEmpty || students.isEmpty) {
        if (!mounted) return;
        setState(() {
          _minAbsentResults = const [];
        });
        return;
      }

      // Non-absent records reduce the absent count.
      final rows = await client
          .from('attendance_records')
          .select('student_id')
          .inFilter('session_id', sessionIds)
          .inFilter('status', const ['present', 'late', 'permission']);

      final nonAbsentCounts = <String, int>{};
      for (final r in rows) {
        final map = r as Map;
        final studentId = map['student_id']?.toString();
        if (studentId == null || studentId.isEmpty) continue;
        nonAbsentCounts[studentId] = (nonAbsentCounts[studentId] ?? 0) + 1;
      }

      final totalSessions = _sessions.length;
      final results = <_AbsentSummary>[];
      for (final s in students) {
        final nonAbsent = nonAbsentCounts[s.id] ?? 0;
        final absentDays = (totalSessions - nonAbsent).clamp(0, totalSessions);
        if (absentDays >= minDays) {
          results.add(_AbsentSummary(student: s, absentDays: absentDays));
        }
      }

      results.sort((a, b) {
        final byAbsent = b.absentDays.compareTo(a.absentDays);
        if (byAbsent != 0) return byAbsent;
        return a.student.name.toLowerCase().compareTo(
          b.student.name.toLowerCase(),
        );
      });

      if (!mounted) return;
      setState(() {
        _minAbsentResults = results;
      });
    } catch (_) {
      // Ignore.
    } finally {
      if (mounted) {
        setState(() {
          _loadingMinAbsent = false;
        });
      }
    }
  }

  Future<void> _addOrOpenDate(BuildContext context) async {
    final academicYearId = _activeAcademicYearId;
    final gradeId = _myGradeId;
    final userId = _currentUserId;
    final subjectId = _selectedSubjectId;

    if (academicYearId == null ||
        gradeId == null ||
        userId == null ||
        subjectId == null) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked == null) return;

    final iso = DateTime(
      picked.year,
      picked.month,
      picked.day,
    ).toIso8601String().substring(0, 10);

    final client = SupabaseClientManager.instance.client;

    try {
      final existing = await client
          .from('attendance_sessions')
          .select('id, session_date')
          .eq('academic_year_id', academicYearId)
          .eq('subject_id', subjectId)
          .eq('session_date', iso)
          .maybeSingle();

      final sessionId = existing?['id'] as String?;

      String finalSessionId;
      if (sessionId != null) {
        finalSessionId = sessionId;
      } else {
        final inserted = await client
            .from('attendance_sessions')
            .insert({
              'academic_year_id': academicYearId,
              'grade_id': gradeId,
              'subject_id': subjectId,
              'session_date': iso,
              'created_by': userId,
            })
            .select('id')
            .single();
        finalSessionId = inserted['id'] as String;
      }

      await _loadSessionsForSelectedSubject();

      if (!context.mounted) return;
      final subjectName = _subjects.firstWhere((s) => s.id == subjectId).name;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ServantAttendanceSessionScreen(
            sessionId: finalSessionId,
            academicYearId: academicYearId,
            gradeId: gradeId,
            subjectId: subjectId,
            subjectName: subjectName,
            sessionDateIso: iso,
          ),
        ),
      );

      // Refresh after returning from session screen.
      await _loadSessionsForSelectedSubject();
    } catch (_) {
      // Ignore.
    }
  }

  // Removed date search feature

  List<_AttendanceSession> _filteredSessions() {
    // No date search, just return all sessions
    return _sessions;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: AppRefreshConfigurator(
            onRefresh: _loadInitial,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 180),
                Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navAttendance)),
        body: SafeArea(
          child: AppRefreshConfigurator(
            onRefresh: _loadInitial,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadInitial,
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final selectedSubjectId = _selectedSubjectId;
    final sessions = _filteredSessions();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AppRefreshConfigurator(
          onRefresh: _loadInitial,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navAttendance,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.servantAttendanceChooseSubjectAndDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFBAE6FD),
                      ),
                    ),
                  ],
                ),
              ),
              if (_subjects.isEmpty)
                Expanded(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(l10n.commonNoSubjectsForGrade)),
                    ],
                  ),
                )
              else ...[
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _subjects.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final s = _subjects[index];
                      final selected = s.id == selectedSubjectId;
                      return InkWell(
                        onTap: () async {
                          setState(() {
                            _selectedSubjectId = s.id;
                            _minAbsentController.clear();
                            _minAbsentApplied = null;
                            _minAbsentResults = const [];
                          });
                          await _loadSessionsForSelectedSubject();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF0EA5E9)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: selected
                                ? const [
                                    BoxShadow(
                                      color: Color(0x260EA5E9),
                                      blurRadius: 14,
                                      offset: Offset(0, 8),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              s.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Removed search dates feature

                        // Min absent filter (outer screen)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14374151),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.servantAttendanceMinimumDaysAbsent,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _minAbsentController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText:
                                            l10n.servantAttendanceMinAbsentHint,
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onSubmitted: (_) => _runMinAbsentFilter(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: _loadingMinAbsent
                                        ? null
                                        : _runMinAbsentFilter,
                                    child: _loadingMinAbsent
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(l10n.commonSearch),
                                  ),
                                ],
                              ),
                              if (_minAbsentApplied != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  l10n.servantAttendanceStudentsAbsentAtLeast(
                                    _minAbsentApplied!,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_minAbsentResults.isEmpty)
                                  Text(
                                    l10n.servantAttendanceNoStudentsMatch,
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _minAbsentResults.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final r = _minAbsentResults[index];
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              r.student.name.isNotEmpty
                                                  ? r.student.name
                                                  : l10n.roleStudent,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            l10n.servantAttendanceAbsentDays(
                                              r.absentDays,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFDC2626),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Add date
                        ElevatedButton.icon(
                          onPressed: () => _addOrOpenDate(context),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.commonAddDate),
                        ),
                        const SizedBox(height: 12),

                        // Previous dates
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.servantAttendancePreviousDates,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (_loadingSessions)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (selectedSubjectId == null)
                          const SizedBox.shrink()
                        else if (sessions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(l10n.servantAttendanceNoDatesYet),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14374151),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sessions.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final s = sessions[index];
                                final subjectName = _subjects
                                    .firstWhere(
                                      (x) => x.id == selectedSubjectId,
                                    )
                                    .name;
                                return ListTile(
                                  title: Text(
                                    EthiopianDateFormatter.formatFlexible(
                                      s.sessionDateIso,
                                    ),
                                  ),
                                  subtitle: Text(s.sessionDateIso),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    final academicYearId =
                                        _activeAcademicYearId;
                                    final gradeId = _myGradeId;
                                    if (academicYearId == null ||
                                        gradeId == null) {
                                      return;
                                    }

                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (context) =>
                                            ServantAttendanceSessionScreen(
                                              sessionId: s.id,
                                              academicYearId: academicYearId,
                                              gradeId: gradeId,
                                              subjectId: selectedSubjectId,
                                              subjectName: subjectName,
                                              sessionDateIso: s.sessionDateIso,
                                            ),
                                      ),
                                    );

                                    await _loadSessionsForSelectedSubject();
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
