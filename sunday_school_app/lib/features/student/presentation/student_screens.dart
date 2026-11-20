import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunday_school_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_providers.dart';
import '../../../core/dates/ethiopian_date_formatter.dart';
import '../../../core/errors/app_error_message.dart';
import '../../../core/text/text_encoding.dart';
import '../../../core/promotions/promotion_criteria_set.dart';
import '../../../core/refresh/app_refresh_configurator.dart';
import '../../../core/push/push_notifications_service.dart';

const Color accent = Color(0xFF0284C7); // sky-600

class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0284C7), // sky-600
        unselectedItemColor: const Color(0xFF64748B), // slate-500
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_rounded),
            label: l10n.navAttendance,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_stories_rounded),
            label: l10n.navGrades,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.forum_rounded),
            label: l10n.navCommunication,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}

class StudentLoginScreen extends ConsumerStatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  ConsumerState<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends ConsumerState<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      String? role;
      try {
        role = (await authRepository.fetchCurrentUserRole())
            ?.trim()
            .toLowerCase();
      } catch (_) {
        role = null;
      }

      if (role != 'student') {
        try {
          await authRepository.signOut();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _error = role == null
                ? l10n.authRoleVerificationFailed
                : l10n.authRoleMismatchStudent;
          });
        }
        return;
      }

      if (mounted) {
        context.go('/student/dashboard');
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      final looksLikeInvalidCredentials =
          msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials') ||
          msg.contains('invalid_grant');
      if (!mounted) return;
      setState(() {
        _error = looksLikeInvalidCredentials
            ? l10n.authInvalidCredentialsError
            : l10n.authLoginFailedGeneric;
      });
    } catch (e) {
      debugPrint('Student login failed: $e');
      setState(() {
        _error = l10n.authLoginFailedGeneric;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F2FE), // sky-50
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button
                    TextButton.icon(
                      onPressed: () => context.go('/'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF475569), // slate-600
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: Text(
                        l10n.commonBackToHome,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14374151),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header avatar + title
                          Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF0284C7),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.authStudentLoginTitle,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.authLoginSubtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.authEmailLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _IconTextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  hintText: l10n.authEmailHint,
                                  icon: Icons.person_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.authEmailRequiredError;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.authPasswordLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _IconTextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  hintText: l10n.authPasswordHint,
                                  icon: Icons.lock_rounded,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.authPasswordRequiredError;
                                    }
                                    if (value.length < 6) {
                                      return l10n.authPasswordMinLengthError(6);
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                if (_error != null) ...[
                                  Text(
                                    _error!,
                                    style: TextStyle(
                                      color: colorScheme.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                SizedBox(
                                  height: 48,
                                  child: FilledButton.icon(
                                    onPressed: _submitting ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF0EA5E9),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: _submitting
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                    label: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(l10n.authLoginButton),
                                        if (!_submitting) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      l10n.authForgotPasswordDialogTitle,
                                    ),
                                    content: Text(
                                      l10n.authForgotPasswordDialogBody,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text(l10n.commonOk),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0EA5E9),
                              ),
                              child: Text(
                                l10n.authForgotPassword,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconTextField extends StatelessWidget {
  const _IconTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFCBD5E1), // slate-300
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF0EA5E9), // sky-500
            width: 2,
          ),
        ),
      ),
    );
  }
}

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _loading = true;
  String? _error;
  _StudentDashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStatsFromBackend();
  }

  Future<String?> _activeAcademicYearId(SupabaseClient client) async {
    try {
      final id = await client.rpc('active_academic_year_id');
      final asString = id?.toString();
      if (asString != null && asString.isNotEmpty) return asString;
    } catch (_) {}

    try {
      final row = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return (row as Map?)?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  static int _asRoundedInt(Object? value, {int fallback = 0}) {
    if (value is num) return value.round();
    final parsed = num.tryParse(value?.toString() ?? '');
    return parsed?.round() ?? fallback;
  }

  Future<void> _loadStatsFromBackend() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      final userId = user?.id;
      if (userId == null) {
        throw StateError('Not signed in');
      }

      final academicYearId = await _activeAcademicYearId(client);
      final profile = await client
          .from('profiles')
          .select('name, grade_id')
          .eq('id', userId)
          .maybeSingle();

      final profileMap = (profile as Map?) ?? const <String, Object?>{};
      final gradeId = profileMap['grade_id']?.toString();
      final name = (profileMap['name'] as String?)?.trim();

      int attendancePercent = 0;
      int academicAvg = 0;

      if (academicYearId != null && academicYearId.isNotEmpty) {
        try {
          final raw = await client.rpc(
            'compute_attendance_percent',
            params: {
              'p_academic_year_id': academicYearId,
              'p_student_id': userId,
            },
          );
          attendancePercent = _asRoundedInt(raw, fallback: 0);
        } catch (_) {}

        if (gradeId != null && gradeId.isNotEmpty) {
          try {
            final raw = await client.rpc(
              'compute_overall_average',
              params: {
                'p_academic_year_id': academicYearId,
                'p_grade_id': gradeId,
                'p_student_id': userId,
              },
            );
            academicAvg = _asRoundedInt(raw, fallback: 0);
          } catch (_) {}
        }
      }

      var pendingQuestions = 0;
      var openComplaints = 0;
      if (academicYearId != null && academicYearId.isNotEmpty) {
        try {
          final rows = await client
              .from('questions')
              .select('id')
              .eq('student_id', userId)
              .eq('academic_year_id', academicYearId)
              .eq('answered', false);
          pendingQuestions = rows.length;
        } catch (_) {}

        try {
          final rows = await client
              .from('complaints')
              .select('id, status')
              .eq('student_id', userId)
              .eq('academic_year_id', academicYearId)
              .inFilter('status', const ['pending', 'in_review']);
          openComplaints = rows.length;
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _stats = _StudentDashboardStats(
          name: name,
          gradeId: gradeId,
          academicYearId: academicYearId,
          attendancePercent: attendancePercent.clamp(0, 100),
          academicAvg: academicAvg.clamp(0, 100),
          pendingQuestions: pendingQuestions,
          openComplaints: openComplaints,
        );
      });
    } catch (e) {
      debugPrint('Student dashboard load failed: $e');
      if (!mounted) return;
      setState(() {
        _error = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.studentDashboardLoadFailed,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    final displayName =
        (_stats?.name != null && _stats!.name!.trim().isNotEmpty)
        ? _stats!.name!.trim()
        : user?.email ?? l10n.roleStudent;

    final attendancePercent = _stats?.attendancePercent ?? 0;
    final academicAvg = _stats?.academicAvg ?? 0;
    final pendingQuestions = _stats?.pendingQuestions ?? 0;
    final openComplaints = _stats?.openComplaints ?? 0;
    final pendingTotal = pendingQuestions + openComplaints;

    final attendanceValue = _loading ? '—' : '$attendancePercent%';
    final avgValue = _loading ? '—' : '$academicAvg%';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: SafeArea(
        child: AppRefreshConfigurator(
          onRefresh: _loadStatsFromBackend,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF0284C7), // sky-600
                        Color(0xFF0EA5E9), // sky-500
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dashboardWelcome,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFBAE6FD), // sky-200
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFB91C1C),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF7F1D1D),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : _loadStatsFromBackend,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFB91C1C),
                                  ),
                                  child: Text(l10n.commonRetry),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: _DashboardStatCard(
                                iconBackground: const Color(0xFFE0F2FE),
                                iconColor: const Color(0xFF0284C7),
                                icon: Icons.calendar_month_rounded,
                                value: attendanceValue,
                                label: l10n.dashboardAttendanceStat,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _DashboardStatCard(
                                iconBackground: const Color(0xFFFEF3C7),
                                iconColor: const Color(0xFFD97706),
                                icon: Icons.emoji_events_rounded,
                                value: avgValue,
                                label: l10n.dashboardAverageScoreStat,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Communication overview
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFF1F5F9),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.notifications_rounded,
                                      size: 20,
                                      color: Color(0xFF475569),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.dashboardCommunicationTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    if (!_loading && pendingTotal > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0EA5E9),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          l10n.dashboardPendingCount(
                                            pendingTotal,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _KeyValueRow(
                                      label: l10n.dashboardPendingQuestions,
                                      value: _loading
                                          ? '—'
                                          : '$pendingQuestions',
                                    ),
                                    const SizedBox(height: 10),
                                    _KeyValueRow(
                                      label: l10n.dashboardOpenComplaints,
                                      value: _loading ? '—' : '$openComplaints',
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(18),
                                    bottomRight: Radius.circular(18),
                                  ),
                                ),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () =>
                                        context.go('/student/communication'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF0EA5E9),
                                    ),
                                    child: Text(
                                      l10n.dashboardGoToCommunication,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick actions
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.dashboardQuickActions,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _QuickActionTile(
                                      icon: Icons.trending_up_rounded,
                                      label: l10n.dashboardViewGrades,
                                      onTap: () =>
                                          context.go('/student/grades'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _QuickActionTile(
                                      icon: Icons.calendar_month_rounded,
                                      label: l10n.navAttendance,
                                      onTap: () =>
                                          context.go('/student/attendance'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentDashboardStats {
  const _StudentDashboardStats({
    required this.attendancePercent,
    required this.academicAvg,
    required this.pendingQuestions,
    required this.openComplaints,
    this.name,
    this.gradeId,
    this.academicYearId,
  });

  final String? name;
  final String? gradeId;
  final String? academicYearId;
  final int attendancePercent;
  final int academicAvg;
  final int pendingQuestions;
  final int openComplaints;
}

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool _loadingAttendance = true;
  String? _attendanceError;

  List<_AttendanceSubject> _attendanceSubjects = const [];
  List<_AttendanceRecord> _attendanceRecords = const [];
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _loadAttendanceFromBackend();
  }

  static _AttendanceStatus _attendanceStatusFromDb(String raw) {
    switch (raw) {
      case 'present':
        return _AttendanceStatus.present;
      case 'late':
        return _AttendanceStatus.late;
      case 'permission':
        return _AttendanceStatus.permission;
      case 'absent':
      default:
        return _AttendanceStatus.absent;
    }
  }

  Future<void> _loadAttendanceFromBackend() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loadingAttendance = true;
      _attendanceError = null;
    });

    try {
      final client = Supabase.instance.client;
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
              name: (r)['name'] as String? ?? l10n.commSubjectLabel,
            ),
          )
          .toList();

      final subjectIds = subjects.map((s) => s.id).toList();

      final Map<String, ({String subjectId, DateTime date})> sessionMeta = {};
      if (subjectIds.isNotEmpty) {
        final sessionRows = await client
            .from('attendance_sessions')
            .select('id, subject_id, session_date')
            .eq('academic_year_id', academicYearId)
            .eq('grade_id', gradeId)
            .inFilter('subject_id', subjectIds)
            .order('session_date', ascending: false);

        for (final row in sessionRows) {
          final map = row as Map;
          final id = map['id']?.toString();
          final subjectId = map['subject_id']?.toString();
          final dateRaw = map['session_date']?.toString();
          if (id == null || subjectId == null || dateRaw == null) continue;
          final dt = DateTime.tryParse(dateRaw);
          if (dt == null) continue;
          sessionMeta[id] = (subjectId: subjectId, date: dt);
        }
      }

      final sessionIds = sessionMeta.keys.toList();
      final records = <_AttendanceRecord>[];
      if (sessionIds.isNotEmpty) {
        final recordRows = await client
            .from('attendance_records')
            .select('session_id, status')
            .eq('student_id', userId)
            .inFilter('session_id', sessionIds);

        for (final row in recordRows) {
          final map = row as Map;
          final sessionId = map['session_id']?.toString();
          final statusRaw = map['status']?.toString();
          if (sessionId == null || statusRaw == null) continue;
          final meta = sessionMeta[sessionId];
          if (meta == null) continue;
          records.add(
            _AttendanceRecord(
              subjectId: meta.subjectId,
              date: meta.date,
              status: _attendanceStatusFromDb(statusRaw),
            ),
          );
        }
      }

      records.sort((a, b) => b.date.compareTo(a.date));

      final prevSelected = _selectedSubjectId;
      String? nextSelected = prevSelected;
      if (nextSelected == null || !subjects.any((s) => s.id == nextSelected)) {
        nextSelected = subjects.isEmpty ? null : subjects.first.id;
      }

      if (!mounted) return;
      setState(() {
        _attendanceSubjects = subjects;
        _attendanceRecords = records;
        _selectedSubjectId = nextSelected;
      });
    } catch (e) {
      debugPrint('Student attendance load failed: $e');
      if (!mounted) return;
      setState(() {
        _attendanceError = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.attendanceLoadFailed,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingAttendance = false;
        });
      }
    }
  }

  int _subjectPercentage(String subjectId) {
    final records = _attendanceRecords
        .where((r) => r.subjectId == subjectId)
        .toList();
    if (records.isEmpty) return 0;
    final attended = records
        .where((r) => r.status != _AttendanceStatus.absent)
        .length;
    return ((attended / records.length) * 100).round();
  }

  int _overallPercentage() {
    if (_attendanceRecords.isEmpty) return 0;
    final attended = _attendanceRecords
        .where((r) => r.status != _AttendanceStatus.absent)
        .length;
    return ((attended / _attendanceRecords.length) * 100).round();
  }

  ({int present, int late, int absent, int total}) _statusStats(
    String subjectId,
  ) {
    final records = _attendanceRecords
        .where((r) => r.subjectId == subjectId)
        .toList();
    final present = records
        .where(
          (r) =>
              r.status == _AttendanceStatus.present ||
              r.status == _AttendanceStatus.permission,
        )
        .length;
    final late = records
        .where((r) => r.status == _AttendanceStatus.late)
        .length;
    final absent = records
        .where((r) => r.status == _AttendanceStatus.absent)
        .length;
    return (
      present: present,
      late: late,
      absent: absent,
      total: records.length,
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ', 'እሁድ'];
    final wd = weekdays[(date.weekday - 1).clamp(0, 6)];
    return '$wd, ${EthiopianDateFormatter.formatDateTime(date)}';
  }

  ({String text, Color color, IconData icon}) _performance(
    AppLocalizations l10n,
    int percentage,
  ) {
    if (percentage >= 95) {
      return (
        text: l10n.attendancePerformanceExcellent,
        color: const Color(0xFF16A34A),
        icon: Icons.trending_up_rounded,
      );
    }
    if (percentage >= 85) {
      return (
        text: l10n.attendancePerformanceGreat,
        color: const Color(0xFF16A34A),
        icon: Icons.trending_up_rounded,
      );
    }
    if (percentage >= 75) {
      return (
        text: l10n.attendancePerformanceGood,
        color: const Color(0xFFD97706),
        icon: Icons.info_outline_rounded,
      );
    }
    return (
      text: l10n.attendancePerformanceNeedsImprovement,
      color: const Color(0xFFDC2626),
      icon: Icons.info_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loadingAttendance) {
      return Scaffold(
        body: SafeArea(
          child: AppRefreshConfigurator(
            onRefresh: _loadAttendanceFromBackend,
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

    if (_attendanceError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navAttendance)),
        body: SafeArea(
          child: AppRefreshConfigurator(
            onRefresh: _loadAttendanceFromBackend,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _attendanceError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadAttendanceFromBackend,
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_attendanceSubjects.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: AppRefreshConfigurator(
            onRefresh: _loadAttendanceFromBackend,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 160),
                Center(child: Text(l10n.commonNoSubjectsForGrade)),
              ],
            ),
          ),
        ),
      );
    }

    final selectedSubjectId =
        _selectedSubjectId ?? _attendanceSubjects.first.id;

    final overall = _overallPercentage();
    final subject = _attendanceSubjects.firstWhere(
      (s) => s.id == selectedSubjectId,
      orElse: () => _attendanceSubjects.first,
    );
    final subjectPercentage = _subjectPercentage(selectedSubjectId);
    final stats = _statusStats(selectedSubjectId);
    final performance = _performance(l10n, subjectPercentage);

    final subjectRecords =
        _attendanceRecords
            .where((r) => r.subjectId == selectedSubjectId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    Color percentageColor(int p) {
      if (p >= 90) return const Color(0xFF16A34A);
      if (p >= 75) return const Color(0xFFD97706);
      return const Color(0xFFDC2626);
    }

    ({Color text, Color bg, Color border, IconData icon}) statusStyle(
      _AttendanceStatus s,
    ) {
      switch (s) {
        case _AttendanceStatus.present:
          return (
            text: const Color(0xFF16A34A),
            bg: const Color(0xFFDCFCE7),
            border: const Color(0xFFBBF7D0),
            icon: Icons.check_circle_rounded,
          );
        case _AttendanceStatus.permission:
          return (
            text: const Color(0xFF16A34A),
            bg: const Color(0xFFDCFCE7),
            border: const Color(0xFFBBF7D0),
            icon: Icons.check_circle_rounded,
          );
        case _AttendanceStatus.late:
          return (
            text: const Color(0xFFD97706),
            bg: const Color(0xFFFEF3C7),
            border: const Color(0xFFFDE68A),
            icon: Icons.schedule_rounded,
          );
        case _AttendanceStatus.absent:
          return (
            text: const Color(0xFFDC2626),
            bg: const Color(0xFFFEE2E2),
            border: const Color(0xFFFECACA),
            icon: Icons.cancel_rounded,
          );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AppRefreshConfigurator(
          onRefresh: _loadAttendanceFromBackend,
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
                      l10n.attendanceTrackSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFBAE6FD),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Overall stats
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14374151),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.attendanceOverallTitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 20,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$overall%',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: percentageColor(overall),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    l10n.attendanceAcrossAllSubjects,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subject tabs
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attendanceSubjects.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final s = _attendanceSubjects[index];
                            final selected = s.id == selectedSubjectId;
                            final p = _subjectPercentage(s.id);
                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedSubjectId = s.id),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      s.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFF334155),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.attendancePercentLabel(p),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: selected
                                            ? const Color(0xFFBAE6FD)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subject stats
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subject.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Text(
                                  '$subjectPercentage%',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: percentageColor(subjectPercentage),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    performance.icon,
                                    size: 18,
                                    color: performance.color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    performance.text,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: performance.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniStat(
                                    bg: const Color(0xFFDCFCE7),
                                    icon: Icons.check_circle_rounded,
                                    iconColor: const Color(0xFF16A34A),
                                    value: '${stats.present}',
                                    label: l10n.attendancePresent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MiniStat(
                                    bg: const Color(0xFFFEF3C7),
                                    icon: Icons.schedule_rounded,
                                    iconColor: const Color(0xFFD97706),
                                    value: '${stats.late}',
                                    label: l10n.attendanceLate,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MiniStat(
                                    bg: const Color(0xFFFEE2E2),
                                    icon: Icons.cancel_rounded,
                                    iconColor: const Color(0xFFDC2626),
                                    value: '${stats.absent}',
                                    label: l10n.attendanceAbsent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // History
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                12,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.attendanceHistoryTitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.attendanceSessionsRecorded(
                                      stats.total,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (subjectRecords.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 52,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.attendanceNoRecordsYet,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Column(
                                children: subjectRecords.map((r) {
                                  final s = statusStyle(r.status);
                                  final statusText = switch (r.status) {
                                    _AttendanceStatus.present =>
                                      l10n.attendancePresent,
                                    _AttendanceStatus.late =>
                                      l10n.attendanceLate,
                                    _AttendanceStatus.absent =>
                                      l10n.attendanceAbsent,
                                    _AttendanceStatus.permission =>
                                      l10n.attendancePermission,
                                  };
                                  return Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () {},
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: s.bg,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: s.border,
                                                ),
                                              ),
                                              child: Icon(
                                                s.icon,
                                                color: s.text,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _formatDate(r.date),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    subject.name,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: s.bg,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: s.border,
                                                ),
                                              ),
                                              child: Text(
                                                statusText,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: s.text,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      if (subjectPercentage < 85) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFFD97706),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.attendanceImproveTitle,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.attendanceImproveBody,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.iconBackground,
    required this.iconColor,
    required this.icon,
    required this.value,
    required this.label,
  });

  final Color iconBackground;
  final Color iconColor;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF0284C7)),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final Color bg;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

enum _AttendanceStatus { present, late, permission, absent }

class _AttendanceSubject {
  const _AttendanceSubject({required this.id, required this.name});
  final String id;
  final String name;
}

class _AttendanceRecord {
  const _AttendanceRecord({
    required this.subjectId,
    required this.date,
    required this.status,
  });

  final String subjectId;
  final DateTime date;
  final _AttendanceStatus status;
}

class StudentGradesScreen extends StatefulWidget {
  const StudentGradesScreen({super.key});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  String? _expandedSubjectId;
  PromotionCriteriaSet _criteria = PromotionCriteriaSet.defaults;

  _AcademicYearPeriod _displayPeriod = _AcademicYearPeriod.semester1;

  bool _loadingGrades = true;
  String? _gradesError;

  _GradesAcademicYear _academicYear = const _GradesAcademicYear(
    name: '',
    status: _AcademicYearStatus.active,
    period: _AcademicYearPeriod.semester1,
  );

  _GradesStudent _currentStudent = const _GradesStudent(
    id: '',
    name: '',
    promotionStatus: _PromotionStatus.eligible,
    accountStatus: _AccountStatus.active,
  );

  List<_GradesSubject> _subjects = const [];
  List<_GradesEntry> _gradeEntries = const [];

  int? _semester1Average;
  int? _semester2Average;
  int? _yearAverage;
  final Map<String, int?> _subjectAverages = {};

  bool get _isYearActive => _academicYear.status == _AcademicYearStatus.active;
  bool get _isActiveAccount =>
      _currentStudent.accountStatus == _AccountStatus.active;

  @override
  void initState() {
    super.initState();
    _loadGradesFromBackend();
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _asDate(Object? value) {
    if (value is DateTime) return value;
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static _AccountStatus _accountStatusFromDb(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'active':
        return _AccountStatus.active;
      case 'inactive_pending_admin':
        return _AccountStatus.inactivePendingAdmin;
      case 'graduated':
        return _AccountStatus.graduated;
    }
    return _AccountStatus.unknown;
  }

  static _AcademicYearPeriod _academicYearPeriodFromDb(
    String? raw, {
    _AcademicYearPeriod fallback = _AcademicYearPeriod.semester1,
  }) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'semester1':
        return _AcademicYearPeriod.semester1;
      case 'semester2':
        return _AcademicYearPeriod.semester2;
      case 'break':
        return _AcademicYearPeriod.breakPeriod;
    }
    return fallback;
  }

  static ({DateTime start, DateTime end})? _dateRangeForPeriod({
    required _AcademicYearPeriod period,
    required DateTime? startDate,
    required DateTime? endDate,
    required DateTime? semester1EndDate,
    required DateTime? semester2StartDate,
  }) {
    final today = DateTime.now();

    DateTime? rangeStart;
    DateTime? rangeEnd;

    if (period == _AcademicYearPeriod.semester1) {
      rangeStart = startDate;
      rangeEnd = semester1EndDate ?? today;
    } else if (period == _AcademicYearPeriod.semester2) {
      rangeStart = semester2StartDate;
      if (rangeStart == null && startDate != null && endDate != null) {
        final midOffset = (endDate.difference(startDate).inDays / 2).floor();
        rangeStart = startDate.add(Duration(days: midOffset + 1));
      }
      rangeEnd = today;
    }

    if (rangeStart == null || rangeEnd == null) return null;

    if (endDate != null && rangeEnd.isAfter(endDate)) {
      rangeEnd = endDate;
    }

    if (rangeStart.isAfter(rangeEnd)) return null;
    return (start: rangeStart, end: rangeEnd);
  }

  static _PromotionStatus _promotionStatusFromDb(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'eligible':
        return _PromotionStatus.eligible;
      case 'at_risk':
        return _PromotionStatus.atRisk;
      case 'not_eligible':
        return _PromotionStatus.notEligible;
    }
    return _PromotionStatus.eligible;
  }

  Future<void> _loadGradesFromBackend() async {
    setState(() {
      _loadingGrades = true;
      _gradesError = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      final userId = user?.id;
      if (userId == null) {
        throw StateError('Not signed in');
      }

      final profile = await client
          .from('profiles')
          .select('name, grade_id, account_status')
          .eq('id', userId)
          .maybeSingle();
      final profileMap = (profile as Map?) ?? const <String, Object?>{};
      final gradeId = profileMap['grade_id']?.toString();
      if (gradeId == null || gradeId.isEmpty) {
        throw StateError('Missing grade assignment');
      }

      final studentName =
          (profileMap['name'] as String?)?.trim() ?? (user?.email ?? '');

      final accountStatus = _accountStatusFromDb(
        profileMap['account_status']?.toString(),
      );

      if (accountStatus != _AccountStatus.active) {
        if (!mounted) return;
        setState(() {
          _currentStudent = _GradesStudent(
            id: userId,
            name: studentName,
            promotionStatus: _PromotionStatus.eligible,
            accountStatus: accountStatus,
          );
          _subjects = const [];
          _gradeEntries = const [];
          _semester1Average = null;
          _semester2Average = null;
          _yearAverage = null;
          _subjectAverages.clear();
        });
        return;
      }

      Map<String, dynamic>? yearRow;
      yearRow = await client
          .from('academic_years')
          .select(
            'id, name, status, current_period, start_date, end_date, semester1_end_date, semester2_start_date',
          )
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      yearRow ??= await client
          .from('academic_years')
          .select(
            'id, name, status, current_period, start_date, end_date, semester1_end_date, semester2_start_date',
          )
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final academicYearId = yearRow?['id']?.toString();
      final academicYearName = yearRow?['name']?.toString() ?? '';
      final yearStatusRaw = yearRow?['status']?.toString() ?? 'active';
      final yearPeriodRaw = yearRow?['current_period']?.toString();
      final startDate = _asDate(yearRow?['start_date']);
      final endDate = _asDate(yearRow?['end_date']);
      final semester1EndDate = _asDate(yearRow?['semester1_end_date']);
      final semester2StartDate = _asDate(yearRow?['semester2_start_date']);

      if (academicYearId == null || academicYearId.isEmpty) {
        throw StateError('Missing academic year');
      }

      final yearStatus = yearStatusRaw == 'active'
          ? _AcademicYearStatus.active
          : _AcademicYearStatus.ended;

      final yearPeriod = _academicYearPeriodFromDb(
        yearPeriodRaw,
        fallback: yearStatus == _AcademicYearStatus.active
            ? _AcademicYearPeriod.semester1
            : _AcademicYearPeriod.breakPeriod,
      );

      var displayPeriod = yearPeriod;
      if (yearStatus == _AcademicYearStatus.active &&
          yearPeriod == _AcademicYearPeriod.breakPeriod) {
        final today = DateTime.now();
        if (semester2StartDate != null && !today.isBefore(semester2StartDate)) {
          displayPeriod = _AcademicYearPeriod.semester2;
        } else {
          displayPeriod = _AcademicYearPeriod.semester1;
        }
      }

      final assessmentRange = yearStatus == _AcademicYearStatus.active
          ? _dateRangeForPeriod(
              period: displayPeriod,
              startDate: startDate,
              endDate: endDate,
              semester1EndDate: semester1EndDate,
              semester2StartDate: semester2StartDate,
            )
          : null;

      PromotionCriteriaSet? criteria;
      try {
        final repo = PromotionCriteriaRepository(client);
        criteria = await repo.fetchForGradeYear(
          academicYearId: academicYearId,
          gradeId: gradeId,
        );
      } catch (_) {
        // Keep defaults.
      }

      final subjectRows = await client
          .from('subjects')
          .select('id, name, active')
          .eq('grade_id', gradeId)
          .order('name');

      final allSubjects = subjectRows
          .map(
            (r) => _GradesSubject(
              id: (r as Map)['id'] as String,
              name: (r)['name'] as String? ?? 'Subject',
              active: (r)['active'] as bool? ?? true,
            ),
          )
          .toList();

      final entries = <_GradesEntry>[];
      final assessmentRows = await client
          .from('assessments')
          .select(
            'id, subject_id, grade_type, max_score, weight, assessment_date',
          )
          .eq('academic_year_id', academicYearId)
          .eq('grade_id', gradeId)
          .order('assessment_date', ascending: false);

      final assessedSubjectIdsAllYear = <String>{};
      final assessedSubjectIdsView = <String>{};
      final assessmentIds = <String>[];
      final viewAssessmentRows = <Map<String, Object?>>[];

      bool isInRange(DateTime? dt) {
        if (assessmentRange == null) return true;
        if (dt == null) return false;
        if (dt.isBefore(assessmentRange.start)) return false;
        if (dt.isAfter(assessmentRange.end)) return false;
        return true;
      }

      for (final r in assessmentRows) {
        final map = (r as Map).cast<String, Object?>();
        final subjectId = map['subject_id']?.toString();
        if (subjectId != null && subjectId.isNotEmpty) {
          assessedSubjectIdsAllYear.add(subjectId);
        }

        final date = DateTime.tryParse(
          map['assessment_date']?.toString() ?? '',
        );
        if (!isInRange(date)) continue;

        final id = map['id']?.toString();
        if (id != null && id.isNotEmpty) assessmentIds.add(id);
        if (subjectId != null && subjectId.isNotEmpty) {
          assessedSubjectIdsView.add(subjectId);
        }
        viewAssessmentRows.add(map);
      }

      var subjects = yearStatus == _AcademicYearStatus.ended
          ? allSubjects
                .where((s) => assessedSubjectIdsAllYear.contains(s.id))
                .toList()
          : (yearPeriod == _AcademicYearPeriod.breakPeriod
                ? allSubjects
                      .where((s) => assessedSubjectIdsView.contains(s.id))
                      .toList()
                : allSubjects
                      .where(
                        (s) =>
                            s.active || assessedSubjectIdsView.contains(s.id),
                      )
                      .toList());

      if (subjects.isEmpty && allSubjects.isNotEmpty) {
        subjects = allSubjects;
      }

      final scoreByAssessmentId = <String, int?>{};
      if (assessmentIds.isNotEmpty) {
        final scoreRows = await client
            .from('assessment_scores')
            .select('assessment_id, score')
            .eq('student_id', userId)
            .inFilter('assessment_id', assessmentIds);

        for (final r in scoreRows) {
          final map = r as Map;
          final aid = map['assessment_id']?.toString();
          if (aid == null || aid.isEmpty) continue;
          final score = map['score'];
          scoreByAssessmentId[aid] = score == null ? null : _asInt(score);
        }
      }

      final displayedSubjectIds = subjects.map((s) => s.id).toSet();
      for (final map in viewAssessmentRows) {
        final id = map['id']?.toString();
        final subjectId = map['subject_id']?.toString();
        if (id == null || subjectId == null) continue;
        if (!displayedSubjectIds.contains(subjectId)) continue;

        final dateRaw = map['assessment_date']?.toString() ?? '';
        final date = DateTime.tryParse(dateRaw) ?? DateTime.now();

        final maxScore = _asInt(map['max_score'], fallback: 1);
        final maxScoreSafe = maxScore <= 0 ? 1 : maxScore;

        final weight = _asInt(map['weight']);
        final weightValue = weight <= 0 ? null : weight;

        entries.add(
          _GradesEntry(
            id: id,
            subjectId: subjectId,
            gradeType: map['grade_type']?.toString() ?? '',
            maxScore: maxScoreSafe,
            weight: weightValue,
            date: date,
            scores: {userId: scoreByAssessmentId[id]},
          ),
        );
      }

      int? semester1Average;
      int? semester2Average;
      int? yearAverage;
      final subjectAverages = <String, int?>{};
      var promotionStatus = _PromotionStatus.eligible;
      var gotAcademicAssessment = false;

      try {
        final raw = await client.rpc(
          'get_my_academic_assessment',
          params: {'p_grade_id': gradeId, 'p_academic_year_id': academicYearId},
        );

        if (raw is Map) {
          gotAcademicAssessment = true;
          final sem1Raw = raw['semester1_average'];
          final sem2Raw = raw['semester2_average'];
          final yearRaw = raw['year_average'];
          semester1Average = sem1Raw == null ? null : _asInt(sem1Raw);
          semester2Average = sem2Raw == null ? null : _asInt(sem2Raw);
          yearAverage = yearRaw == null ? null : _asInt(yearRaw);
          promotionStatus = _promotionStatusFromDb(
            raw['promotion_status']?.toString(),
          );
        }
      } catch (_) {}

      if (!gotAcademicAssessment) {
        try {
          final sem1Raw = await client.rpc(
            'get_my_semester_report',
            params: {
              'p_grade_id': gradeId,
              'p_academic_year_id': academicYearId,
              'p_semester': 'semester1',
            },
          );
          if (sem1Raw is Map) {
            semester1Average = sem1Raw['overall_average'] == null
                ? null
                : _asInt(sem1Raw['overall_average']);
          }
        } catch (_) {}

        try {
          final sem2Raw = await client.rpc(
            'get_my_semester_report',
            params: {
              'p_grade_id': gradeId,
              'p_academic_year_id': academicYearId,
              'p_semester': 'semester2',
            },
          );
          if (sem2Raw is Map) {
            semester2Average = sem2Raw['overall_average'] == null
                ? null
                : _asInt(sem2Raw['overall_average']);
          }
        } catch (_) {}

        if (semester1Average != null && semester2Average != null) {
          yearAverage = ((semester1Average + semester2Average) / 2).round();
        }

        try {
          final snapRaw = await client.rpc(
            'get_my_grading_snapshot',
            params: {
              'p_grade_id': gradeId,
              'p_academic_year_id': academicYearId,
            },
          );
          if (snapRaw is Map) {
            promotionStatus = _promotionStatusFromDb(
              snapRaw['status']?.toString(),
            );
          }
        } catch (_) {}
      }

      try {
        final raw = await client.rpc(
          'get_my_subject_averages',
          params: {'p_grade_id': gradeId, 'p_academic_year_id': academicYearId},
        );
        if (yearStatus != _AcademicYearStatus.active && raw is List) {
          for (final item in raw) {
            if (item is! Map) continue;
            final sid = item['subject_id']?.toString();
            if (sid == null || sid.isEmpty) continue;
            final avg = item['subject_average'];
            subjectAverages[sid] = avg == null ? null : _asInt(avg);
          }
        }
      } catch (_) {}

      if (yearStatus == _AcademicYearStatus.active) {
        try {
          final semesterParam = displayPeriod == _AcademicYearPeriod.semester2
              ? 'semester2'
              : 'semester1';
          final raw = await client.rpc(
            'get_my_semester_report',
            params: {
              'p_grade_id': gradeId,
              'p_academic_year_id': academicYearId,
              'p_semester': semesterParam,
            },
          );

          if (raw is Map) {
            final list = raw['subject_averages'];
            if (list is List) {
              for (final item in list) {
                if (item is! Map) continue;
                final sid = item['subject_id']?.toString();
                if (sid == null || sid.isEmpty) continue;
                final avg = item['average'];
                subjectAverages[sid] = avg == null ? null : _asInt(avg);
              }
            }
          }
        } catch (_) {
          // Ignore; fallback calculation uses loaded assessments.
        }
      }

      if (!mounted) return;
      setState(() {
        _academicYear = _GradesAcademicYear(
          name: academicYearName,
          status: yearStatus,
          period: yearPeriod,
        );
        _displayPeriod = displayPeriod;
        _currentStudent = _GradesStudent(
          id: userId,
          name: studentName,
          promotionStatus: promotionStatus,
          accountStatus: accountStatus,
        );
        _subjects = subjects;
        _gradeEntries = entries;
        _semester1Average = semester1Average;
        _semester2Average = semester2Average;
        _yearAverage = yearAverage;
        _subjectAverages
          ..clear()
          ..addAll(subjectAverages);
        if (criteria != null) {
          _criteria = criteria;
        }
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      debugPrint('Student grades load failed: $e');
      if (!mounted) return;
      setState(() {
        _gradesError = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.gradesLoadFailed,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingGrades = false;
        });
      }
    }
  }

  Color _gradeColor(int grade) {
    final c = _criteria.classify(grade.toDouble());
    switch (c) {
      case GradeClassification.excellent:
        return const Color(0xFF16A34A); // green-600
      case GradeClassification.veryGood:
      case GradeClassification.good:
        return const Color(0xFF0284C7); // sky-600
      case GradeClassification.enough:
        return const Color(0xFFF59E0B); // amber-600
      case GradeClassification.critical:
        return const Color(0xFFDC2626); // red-600
    }
  }

  Color _gradeBgColor(int grade) {
    final c = _criteria.classify(grade.toDouble());
    switch (c) {
      case GradeClassification.excellent:
        return const Color(0xFFDCFCE7); // green-50
      case GradeClassification.veryGood:
      case GradeClassification.good:
        return const Color(0xFFE0F2FE); // sky-50
      case GradeClassification.enough:
        return const Color(0xFFFEF3C7); // amber-50
      case GradeClassification.critical:
        return const Color(0xFFFEE2E2); // red-50
    }
  }

  Color _barColor(int grade) {
    final c = _criteria.classify(grade.toDouble());
    switch (c) {
      case GradeClassification.excellent:
        return const Color(0xFF22C55E); // green-500
      case GradeClassification.veryGood:
      case GradeClassification.good:
        return const Color(0xFF0EA5E9); // sky-500
      case GradeClassification.enough:
        return const Color(0xFFFBBF24); // amber-500
      case GradeClassification.critical:
        return const Color(0xFFEF4444); // red-500
    }
  }

  List<_GradesEntry> _entriesForSubject(String subjectId) {
    final entries = _gradeEntries
        .where((e) => e.subjectId == subjectId)
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  int? _calculateSubjectAverage(String studentId, String subjectId) {
    if (_subjectAverages.containsKey(subjectId)) {
      return _subjectAverages[subjectId];
    }

    final allEntries = _entriesForSubject(subjectId);
    if (allEntries.isEmpty) return 0;

    final hasAllScores = allEntries.every((entry) {
      final score = entry.scores[studentId];
      return score != null;
    });

    if (!hasAllScores) return null;

    final entries = allEntries.where(
      (entry) => entry.scores[studentId] != null,
    );
    if (entries.isEmpty) return 0;

    final totalWeight = entries.fold<int>(0, (sum, e) => sum + (e.weight ?? 0));
    if (totalWeight > 0) {
      var weightedScore = 0.0;
      for (final entry in entries) {
        final percentage = (entry.scores[studentId]! / entry.maxScore) * 100;
        final normalizedWeight = (entry.weight ?? 0) / totalWeight;
        weightedScore += percentage * normalizedWeight;
      }
      return weightedScore.round();
    }

    var totalPercentage = 0.0;
    for (final entry in entries) {
      totalPercentage += (entry.scores[studentId]! / entry.maxScore) * 100;
    }
    return (totalPercentage / entries.length).round();
  }

  int? _calculateOverallAverage(String _) {
    return _yearAverage;
  }

  String _formatMonthDay(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    return DateFormat.MMMd(l10n.localeName).format(date);
  }

  void _toggleSubject(String subjectId) {
    setState(() {
      _expandedSubjectId = _expandedSubjectId == subjectId ? null : subjectId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loadingGrades) {
      return Scaffold(
        body: SafeArea(
          child: AppRefreshConfigurator(
            onRefresh: _loadGradesFromBackend,
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

    if (_gradesError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navGrades)),
        body: SafeArea(
          child: AppRefreshConfigurator(
            onRefresh: _loadGradesFromBackend,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _gradesError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadGradesFromBackend,
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isActiveAccount) {
      return _buildInactiveAccount(context);
    }

    if (_subjects.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: AppRefreshConfigurator(
            onRefresh: _loadGradesFromBackend,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 160),
                Center(child: Text(l10n.commonNoSubjectsForGrade)),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isYearActive) {
      return _buildFinalResults(context);
    }
    return _buildActiveYear(context);
  }

  Widget _buildInactiveAccount(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AppRefreshConfigurator(
          onRefresh: _loadGradesFromBackend,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                width: double.infinity,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.navGrades,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB), // amber-50
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          color: Color(0xFFB45309),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.studentGradesAccountInactiveTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF78350F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.studentGradesAccountInactiveMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalResults(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avgGrade = _calculateOverallAverage(_currentStudent.id);
    final avgGradeText = avgGrade == null ? '—' : '$avgGrade%';
    final sem1Text = _semester1Average == null ? '—' : '${_semester1Average!}%';
    final sem2Text = _semester2Average == null ? '—' : '${_semester2Average!}%';

    Color promotionGradientStart;
    Color promotionGradientEnd;
    IconData promotionIcon;
    String promotionTitle;
    String promotionMessage;

    switch (_currentStudent.promotionStatus) {
      case _PromotionStatus.eligible:
        promotionGradientStart = const Color(0xFF22C55E); // green-500
        promotionGradientEnd = const Color(0xFF16A34A); // green-600
        promotionIcon = Icons.check_circle_rounded;
        promotionTitle = l10n.studentFinalResultsPromotionPromotedTitle;
        promotionMessage = l10n.studentFinalResultsPromotionPromotedMessage;
        break;
      case _PromotionStatus.atRisk:
        promotionGradientStart = const Color(0xFFF59E0B); // amber-500
        promotionGradientEnd = const Color(0xFFEA580C); // amber-600
        promotionIcon = Icons.warning_rounded;
        promotionTitle = l10n.studentFinalResultsPromotionAtRiskTitle;
        promotionMessage = l10n.studentFinalResultsPromotionAtRiskMessage;
        break;
      case _PromotionStatus.notEligible:
        promotionGradientStart = const Color(0xFFEF4444); // red-500
        promotionGradientEnd = const Color(0xFFDC2626); // red-600
        promotionIcon = Icons.warning_rounded;
        promotionTitle = l10n.studentFinalResultsPromotionNotPromotedTitle;
        promotionMessage = l10n.studentFinalResultsPromotionNotPromotedMessage;
        break;
    }

    final subjectAverages = _subjects
        .map((s) => _calculateSubjectAverage(_currentStudent.id, s.id) ?? 0)
        .toList();

    final highest = subjectAverages.isEmpty
        ? 0
        : subjectAverages.reduce((a, b) => a > b ? a : b);
    final lowest = subjectAverages.isEmpty
        ? 0
        : subjectAverages.reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AppRefreshConfigurator(
          onRefresh: _loadGradesFromBackend,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.studentFinalResultsTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.studentGradesAcademicYearLabel(_academicYear.name),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(51),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.emoji_events_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.studentFinalResultsFinalGradeLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFFDE68A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        avgGradeText,
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.studentGradesSemester1AverageLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFEF3C7),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sem1Text,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.studentGradesSemester2AverageLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFEF3C7),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sem2Text,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.studentGradesAcademicYearLabel(
                                _academicYear.name,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFFEF3C7), // amber-100
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              promotionGradientStart,
                              promotionGradientEnd,
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(51),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    promotionIcon,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.studentFinalResultsPromotionStatusLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xEFFFFFFF),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        promotionTitle,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              promotionMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xEFFFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                                ),
                              ),
                              child: Text(
                                l10n.studentFinalResultsFinalSubjectGradesTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            ..._subjects.map((subject) {
                              final subjectAverage =
                                  _calculateSubjectAverage(
                                    _currentStudent.id,
                                    subject.id,
                                  ) ??
                                  0;
                              return Container(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  14,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFF1F5F9),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            subject.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _gradeBgColor(
                                              subjectAverage,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '$subjectAverage%',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: _gradeColor(
                                                subjectAverage,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _PercentBar(
                                      value: subjectAverage,
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      barColor: _barColor(subjectAverage),
                                      height: 8,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.trending_up_rounded,
                                  size: 20,
                                  color: Color(0xFF0284C7), // sky-600
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.studentFinalResultsFinalSummaryTitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _SummaryRow(
                              label: l10n.studentGradesHighestGradeLabel,
                              value: '$highest%',
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              label: l10n.studentGradesLowestGradeLabel,
                              value: '$lowest%',
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 12),
                            _SummaryRow(
                              label: l10n.studentGradesOverallAverageLabel,
                              value: avgGradeText,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE), // sky-50
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          l10n.studentFinalResultsAcademicYearEndedMessage(
                            _academicYear.name,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0C4A6E), // sky-900
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveYear(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayAvg = _displayPeriod == _AcademicYearPeriod.semester2
        ? _semester2Average
        : _semester1Average;
    final displayAvgText = displayAvg == null ? '—' : '$displayAvg%';
    final displayAvgLabel = _displayPeriod == _AcademicYearPeriod.semester2
        ? l10n.studentGradesSemester2AverageLabel
        : l10n.studentGradesSemester1AverageLabel;
    final sem1Text = _semester1Average == null ? '—' : '${_semester1Average!}%';
    final sem2Text = _semester2Average == null ? '—' : '${_semester2Average!}%';

    final highest = _subjects
        .map((s) => _calculateSubjectAverage(_currentStudent.id, s.id) ?? 0)
        .reduce((a, b) => a > b ? a : b);
    final lowest = _subjects
        .map((s) => _calculateSubjectAverage(_currentStudent.id, s.id) ?? 0)
        .reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AppRefreshConfigurator(
          onRefresh: _loadGradesFromBackend,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navGrades,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.studentGradesAcademicYearLabel(_academicYear.name),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_academicYear.period ==
                          _AcademicYearPeriod.breakPeriod)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB), // amber-50
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFDE68A), // amber-200
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            l10n.studentGradesBreakModeMessage,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF78350F),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE), // sky-50
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFBAE6FD), // sky-200
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _academicYear.period ==
                                    _AcademicYearPeriod.semester2
                                ? l10n.studentGradesSemester2ModeMessage
                                : l10n.studentGradesSemester1ModeMessage,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0C4A6E), // sky-900
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(51),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.emoji_events_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayAvgLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFFDE68A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        displayAvgText,
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.studentGradesSemester1AverageLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFEF3C7),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sem1Text,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.studentGradesSemester2AverageLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFEF3C7),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sem2Text,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.studentGradesKeepUpExcellentWork,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFFEF3C7), // amber-100
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: _subjects.map((subject) {
                          final entries = _entriesForSubject(subject.id);
                          final missingCount = entries
                              .where(
                                (e) => e.scores[_currentStudent.id] == null,
                              )
                              .length;
                          final subjectAverage =
                              _calculateSubjectAverage(
                                _currentStudent.id,
                                subject.id,
                              ) ??
                              0;
                          final isExpanded = _expandedSubjectId == subject.id;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () => _toggleSubject(subject.id),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      16,
                                      12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                subject.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _gradeBgColor(
                                                      subjectAverage,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '$subjectAverage%',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _gradeColor(
                                                        subjectAverage,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Icon(
                                                  isExpanded
                                                      ? Icons
                                                            .keyboard_arrow_up_rounded
                                                      : Icons
                                                            .keyboard_arrow_down_rounded,
                                                  color: const Color(
                                                    0xFF94A3B8,
                                                  ), // slate-400
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _PercentBar(
                                          value: subjectAverage,
                                          backgroundColor: const Color(
                                            0xFFF1F5F9,
                                          ),
                                          barColor: _barColor(subjectAverage),
                                          height: 8,
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            l10n.studentGradesAssessmentsCount(
                                              entries.length,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(
                                                0xFF64748B,
                                              ), // slate-500
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isExpanded)
                                  Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Color(0xFFF1F5F9),
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            12,
                                            16,
                                            12,
                                          ),
                                          color: const Color(0xFFF8FAFC),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                l10n.studentGradesAssessmentBreakdownTitle,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(
                                                    0xFF334155,
                                                  ), // slate-700
                                                ),
                                              ),
                                              if (missingCount > 0) ...[
                                                const SizedBox(height: 10),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFFFFBEB,
                                                    ), // amber-50
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFFDE68A,
                                                      ), // amber-200
                                                    ),
                                                  ),
                                                  child: Text(
                                                    l10n.studentGradesMissingAssessmentsWarning(
                                                      missingCount,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(
                                                        0xFF78350F,
                                                      ), // amber-900
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: entries.map((entry) {
                                            final score = entry
                                                .scores[_currentStudent.id];
                                            final hasScore = score != null;
                                            final percentage = hasScore
                                                ? ((score / entry.maxScore) *
                                                          100)
                                                      .round()
                                                : 0;

                                            return Container(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    16,
                                                    12,
                                                    16,
                                                    12,
                                                  ),
                                              decoration: const BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(
                                                    color: Color(0xFFF1F5F9),
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  entry
                                                                      .gradeType,
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Color(
                                                                      0xFF0F172A,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (entry
                                                                        .weight !=
                                                                    null) ...[
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFFEF3C7,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            999,
                                                                          ),
                                                                    ),
                                                                    child: Text(
                                                                      '${entry.weight}%',
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        color: Color(
                                                                          0xFFB45309,
                                                                        ),
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 6,
                                                            ),
                                                            Text(
                                                              _formatMonthDay(
                                                                context,
                                                                entry.date,
                                                              ),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Color(
                                                                      0xFF64748B,
                                                                    ),
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Text(
                                                            hasScore
                                                                ? '$percentage%'
                                                                : l10n.commonPending,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: hasScore
                                                                  ? _gradeColor(
                                                                      percentage,
                                                                    )
                                                                  : const Color(
                                                                      0xFF64748B,
                                                                    ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            hasScore
                                                                ? l10n.studentGradesPointsLabel(
                                                                    score,
                                                                    entry
                                                                        .maxScore,
                                                                  )
                                                                : '—',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                    0xFF64748B,
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  _PercentBar(
                                                    value: percentage,
                                                    backgroundColor:
                                                        const Color(0xFFF1F5F9),
                                                    barColor: hasScore
                                                        ? _barColor(percentage)
                                                        : const Color(
                                                            0xFFE2E8F0,
                                                          ),
                                                    height: 6,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.trending_up_rounded,
                                  size: 20,
                                  color: Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.studentGradesPerformanceSummaryTitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _SummaryRow(
                              label: l10n.studentGradesHighestGradeLabel,
                              value: '$highest%',
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              label: l10n.studentGradesLowestGradeLabel,
                              value: '$lowest%',
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 12),
                            _SummaryRow(
                              label: l10n.studentGradesTotalSubjectsLabel,
                              value: '${_subjects.length}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AcademicYearStatus { active, ended }

enum _AcademicYearPeriod { semester1, semester2, breakPeriod }

enum _AccountStatus { active, inactivePendingAdmin, graduated, unknown }

class _GradesAcademicYear {
  const _GradesAcademicYear({
    required this.name,
    required this.status,
    required this.period,
  });

  final String name;
  final _AcademicYearStatus status;
  final _AcademicYearPeriod period;
}

enum _PromotionStatus { eligible, atRisk, notEligible }

class _GradesStudent {
  const _GradesStudent({
    required this.id,
    required this.name,
    required this.promotionStatus,
    required this.accountStatus,
  });

  final String id;
  final String name;
  final _PromotionStatus promotionStatus;
  final _AccountStatus accountStatus;
}

class _GradesSubject {
  const _GradesSubject({
    required this.id,
    required this.name,
    required this.active,
  });

  final String id;
  final String name;
  final bool active;
}

class _GradesEntry {
  const _GradesEntry({
    required this.id,
    required this.subjectId,
    required this.gradeType,
    required this.maxScore,
    required this.date,
    required this.scores,
    this.weight,
  });

  final String id;
  final String subjectId;
  final String gradeType;
  final int maxScore;
  final int? weight;
  final DateTime date;
  final Map<String, int?> scores;
}

class _PercentBar extends StatelessWidget {
  const _PercentBar({
    required this.value,
    required this.backgroundColor,
    required this.barColor,
    required this.height,
  });

  final int value;
  final Color backgroundColor;
  final Color barColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final normalized = (value.clamp(0, 100)) / 100.0;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: height,
              width: constraints.maxWidth * normalized,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        },
      ),
    );
  }
}

class StudentCommunicationScreen extends StatefulWidget {
  const StudentCommunicationScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  State<StudentCommunicationScreen> createState() =>
      _StudentCommunicationScreenState();
}

enum _CommTab { announcements, questions, complaints, feedback }

class _StudentCommunicationScreenState
    extends State<StudentCommunicationScreen> {
  _CommTab _activeTab = _CommTab.announcements;
  bool _showQuestionForm = false;
  bool _showComplaintForm = false;

  bool _loadingBadges = false;
  int _announcementBadgeCount = 0;
  int _pendingFeedbackBadgeCount = 0;

  final _announcementsKey = GlobalKey<_AnnouncementsSectionState>();
  final _questionsKey = GlobalKey<_QuestionsListState>();
  final _questionFormKey = GlobalKey<_QuestionFormState>();
  final _complaintsKey = GlobalKey<_ComplaintsListState>();
  final _complaintFormKey = GlobalKey<_ComplaintFormState>();
  final _feedbackKey = GlobalKey<_FeedbackSectionState>();

  @override
  void initState() {
    super.initState();
    final parsed = _parseTab(widget.initialTab);
    if (parsed != null) {
      _activeTab = parsed;
    }
    if (_activeTab == _CommTab.questions) {
      _QuestionFormState.preloadContext();
    }

    _loadBadgeCountsFromBackend();
  }

  static String _todayIso() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  Future<String?> _activeAcademicYearId(SupabaseClient client) async {
    try {
      final id = await client.rpc('active_academic_year_id');
      final asString = id?.toString();
      if (asString != null && asString.isNotEmpty) return asString;
    } catch (_) {}

    try {
      final row = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return (row as Map?)?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadBadgeCountsFromBackend() async {
    if (_loadingBadges) return;

    setState(() {
      _loadingBadges = true;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', userId)
          .maybeSingle();
      final gradeId = (profile as Map?)?['grade_id']?.toString();

      final academicYearId = await _activeAcademicYearId(client);

      var announcementCount = 0;
      try {
        var q = client.from('announcements').select('id').eq('active', true);

        if (academicYearId != null && academicYearId.isNotEmpty) {
          q = q.eq('academic_year_id', academicYearId);
        }
        if (gradeId != null && gradeId.isNotEmpty) {
          q = q.or('grade_id.is.null,grade_id.eq.$gradeId');
        }
        final rows = await q;
        announcementCount = (rows as List).length;
      } catch (_) {}

      var pendingFeedbackForms = 0;
      try {
        if (academicYearId != null &&
            academicYearId.isNotEmpty &&
            gradeId != null &&
            gradeId.isNotEmpty) {
          final today = _todayIso();
          final forms = await client
              .from('feedback_forms')
              .select('id')
              .eq('academic_year_id', academicYearId)
              .eq('grade_id', gradeId)
              .lte('start_date', today)
              .gte('end_date', today);

          final formIds = (forms as List)
              .map((r) => (r as Map)['id']?.toString())
              .whereType<String>()
              .toList(growable: false);

          if (formIds.isNotEmpty) {
            final subs = await client
                .from('feedback_submissions')
                .select('form_id')
                .eq('student_id', userId)
                .inFilter('form_id', formIds);

            final submitted = (subs as List)
                .map((r) => (r as Map)['form_id']?.toString())
                .whereType<String>()
                .toSet();
            pendingFeedbackForms = formIds
                .where((id) => !submitted.contains(id))
                .length;
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _announcementBadgeCount = announcementCount;
        _pendingFeedbackBadgeCount = pendingFeedbackForms;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingBadges = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadBadgeCountsFromBackend();

    switch (_activeTab) {
      case _CommTab.announcements:
        final state = _announcementsKey.currentState;
        if (state != null) {
          await state._loadAnnouncementsFromBackend();
        }
        return;
      case _CommTab.questions:
        if (_showQuestionForm) {
          final state = _questionFormKey.currentState;
          if (state != null) {
            await state._loadContextFromBackend();
          }
          return;
        }
        final state = _questionsKey.currentState;
        if (state != null) {
          await state._loadQuestionsFromBackend();
        }
        return;
      case _CommTab.complaints:
        if (_showComplaintForm) {
          final state = _complaintFormKey.currentState;
          if (state != null) {
            await state._loadContextFromBackend();
          }
          return;
        }
        final state = _complaintsKey.currentState;
        if (state != null) {
          await state._loadComplaintsFromBackend();
        }
        return;
      case _CommTab.feedback:
        final state = _feedbackKey.currentState;
        if (state != null) {
          await state._loadFeedbackFormsFromBackend();
        }
        return;
    }
  }

  @override
  void didUpdateWidget(covariant StudentCommunicationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab == widget.initialTab) return;
    final parsed = _parseTab(widget.initialTab);
    if (parsed == null) return;
    setState(() {
      _activeTab = parsed;
      _showQuestionForm = false;
      _showComplaintForm = false;
    });
  }

  static _CommTab? _parseTab(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    switch (v) {
      case 'announcements':
        return _CommTab.announcements;
      case 'questions':
        return _CommTab.questions;
      case 'complaints':
        return _CommTab.complaints;
      case 'feedback':
        return _CommTab.feedback;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unreadAnnouncements = _announcementBadgeCount;
    final pendingFeedbackForms = _pendingFeedbackBadgeCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AppRefreshConfigurator(
          onRefresh: _handleRefresh,
          child: Column(
            children: [
              // Sticky header with tabs
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navCommunication,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CommTabButton(
                            label: l10n.commAnnouncements,
                            icon: Icons.campaign_rounded,
                            selected: _activeTab == _CommTab.announcements,
                            badgeCount: unreadAnnouncements,
                            onTap: () {
                              setState(() {
                                _activeTab = _CommTab.announcements;
                                _showQuestionForm = false;
                                _showComplaintForm = false;
                              });
                              _loadBadgeCountsFromBackend();
                            },
                          ),
                          _CommTabButton(
                            label: l10n.commQuestions,
                            icon: Icons.question_answer_rounded,
                            selected: _activeTab == _CommTab.questions,
                            onTap: () {
                              _QuestionFormState.preloadContext();
                              setState(() {
                                _activeTab = _CommTab.questions;
                                _showQuestionForm = false;
                                _showComplaintForm = false;
                              });
                            },
                          ),
                          _CommTabButton(
                            label: l10n.commComplaints,
                            icon: Icons.report_problem_rounded,
                            selected: _activeTab == _CommTab.complaints,
                            onTap: () {
                              setState(() {
                                _activeTab = _CommTab.complaints;
                                _showQuestionForm = false;
                                _showComplaintForm = false;
                              });
                            },
                          ),
                          _CommTabButton(
                            label: l10n.commFeedback,
                            icon: Icons.fact_check_rounded,
                            selected: _activeTab == _CommTab.feedback,
                            badgeCount: pendingFeedbackForms,
                            onTap: () {
                              setState(() {
                                _activeTab = _CommTab.feedback;
                                _showQuestionForm = false;
                                _showComplaintForm = false;
                              });
                              _loadBadgeCountsFromBackend();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Builder(
                    builder: (context) {
                      switch (_activeTab) {
                        case _CommTab.announcements:
                          return _AnnouncementsSection(key: _announcementsKey);
                        case _CommTab.questions:
                          if (_showQuestionForm) {
                            return _QuestionForm(
                              key: _questionFormKey,
                              onCancel: () {
                                setState(() => _showQuestionForm = false);
                              },
                            );
                          }
                          return _QuestionsList(
                            key: _questionsKey,
                            onAskQuestion: () {
                              setState(() => _showQuestionForm = true);
                            },
                          );
                        case _CommTab.complaints:
                          if (_showComplaintForm) {
                            return _ComplaintForm(
                              key: _complaintFormKey,
                              onCancel: () {
                                setState(() => _showComplaintForm = false);
                              },
                            );
                          }
                          return _ComplaintsList(
                            key: _complaintsKey,
                            onSubmitComplaint: () {
                              setState(() => _showComplaintForm = true);
                            },
                          );
                        case _CommTab.feedback:
                          return _FeedbackSection(
                            key: _feedbackKey,
                            onSubmitted: _loadBadgeCountsFromBackend,
                          );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommTabButton extends StatelessWidget {
  const _CommTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    this.badgeCount,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final int? badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFF0EA5E9)
        : const Color(0xFF64748B); // sky-500 vs slate-500

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF0EA5E9) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444), // red-500
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Communication tab content widgets ---

class _AnnouncementsSection extends StatefulWidget {
  const _AnnouncementsSection({super.key});

  @override
  State<_AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<_AnnouncementsSection> {
  String? _expandedId;

  bool _isLoading = true;
  String? _error;
  final List<_Announcement> _items = [];

  static String _dateOnly(String value) {
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  static String _todayIso() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  @override
  void initState() {
    super.initState();
    _loadAnnouncementsFromBackend();
  }

  Future<void> _loadAnnouncementsFromBackend() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      final l10n = AppLocalizations.of(context);
      if (!mounted) return;
      setState(() {
        _error = l10n.errorAuthRequired;
        _items.clear();
        _expandedId = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', userId)
          .maybeSingle();

      final gradeId = (profile as Map?)?['grade_id']?.toString();

      final activeYear = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .maybeSingle();
      final academicYearId = (activeYear as Map?)?['id']?.toString();

      var query = client
          .from('announcements')
          .select(
            'id, title, message, category, priority, created_by, created_at, expires_on, active, grade_id, academic_year_id',
          )
          .eq('active', true);

      if (academicYearId != null && academicYearId.isNotEmpty) {
        query = query.eq('academic_year_id', academicYearId);
      }

      if (gradeId != null && gradeId.isNotEmpty) {
        query = query.or('grade_id.is.null,grade_id.eq.$gradeId');
      }

      final rows = await query.order('created_at', ascending: false);
      final items = rows.map((r) {
        final map = r as Map;
        final createdAt = map['created_at']?.toString() ?? '';
        final createdById = map['created_by']?.toString() ?? '';
        return _Announcement(
          id: map['id'] as String,
          title: maybeFixMojibake((map['title'] as String?) ?? ''),
          message: maybeFixMojibake((map['message'] as String?) ?? ''),
          createdBy: createdById == userId ? 'you' : 'servant',
          createdDate: createdAt.isNotEmpty
              ? _dateOnly(createdAt)
              : _todayIso(),
          category: (map['category'] as String?) ?? 'general',
          unread: false,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _expandedId = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _error = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.commAnnouncementsLoadFailed,
        );
        _items.clear();
        _expandedId = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      );
    }

    if (_items.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.campaign_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            l10n.commNoAnnouncements,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.commAnnouncementsEmptySubtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      );
    }

    return Column(
      children: _items.map((item) {
        final expanded = _expandedId == item.id;
        final unread = item.unread;

        final categoryLabel = switch (item.category) {
          'urgent' => l10n.commAnnouncementCategoryUrgent,
          'grades' => l10n.commAnnouncementCategoryGrades,
          'schedule' => l10n.commAnnouncementCategorySchedule,
          'event' => l10n.commAnnouncementCategoryEvent,
          _ => l10n.commAnnouncementCategoryGeneral,
        };

        Color badgeBg;
        Color badgeText;
        switch (item.category) {
          case 'urgent':
            badgeBg = const Color(0xFFFEE2E2); // red-100
            badgeText = const Color(0xFFB91C1C); // red-700
            break;
          case 'grades':
            badgeBg = const Color(0xFFFEF3C7); // amber-100
            badgeText = const Color(0xFF92400E); // amber-700
            break;
          case 'schedule':
            badgeBg = const Color(0xFFDBEAFE); // blue-100
            badgeText = const Color(0xFF1D4ED8); // blue-700
            break;
          case 'event':
            badgeBg = const Color(0xFFD1FAE5); // green-100
            badgeText = const Color(0xFF047857); // green-700
            break;
          default:
            badgeBg = const Color(0xFFE2E8F0); // slate-200
            badgeText = const Color(0xFF475569);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread
                  ? const Color(0xFFBAE6FD) // sky-200
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _expandedId = expanded ? null : item.id;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text('📢', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: unread
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                if (unread)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6, top: 4),
                                    child: CircleAvatar(
                                      radius: 3,
                                      backgroundColor: Color(0xFF0EA5E9),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: badgeBg.withAlpha(204),
                                    ),
                                  ),
                                  child: Text(
                                    categoryLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: badgeText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  EthiopianDateFormatter.formatFlexible(
                                    item.createdDate,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                            if (!expanded) ...[
                              const SizedBox(height: 6),
                              Text(
                                item.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (expanded)
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                if (expanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.message,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.commPostedBy(
                                item.createdBy == 'you'
                                    ? l10n.commonYou
                                    : l10n.roleServant,
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              EthiopianDateFormatter.formatFlexible(
                                item.createdDate,
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuestionsList extends StatefulWidget {
  const _QuestionsList({super.key, required this.onAskQuestion});

  final VoidCallback onAskQuestion;

  @override
  State<_QuestionsList> createState() => _QuestionsListState();
}

class _QuestionsListState extends State<_QuestionsList> {
  bool _isLoading = true;
  String? _error;
  final List<_Question> _questions = [];

  static String _dateOnly(String value) {
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  static String _todayIso() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  @override
  void initState() {
    super.initState();
    _QuestionFormState.preloadContext();
    _loadQuestionsFromBackend();
  }

  Future<String?> _activeAcademicYearId(SupabaseClient client) async {
    try {
      final id = await client.rpc('active_academic_year_id');
      final asString = id?.toString();
      if (asString != null && asString.isNotEmpty) return asString;
    } catch (_) {}

    try {
      final row = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return (row as Map?)?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadQuestionsFromBackend() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('Not signed in');
      }

      final academicYearId = await _activeAcademicYearId(client);

      var query = client
          .from('questions')
          .select(
            'id, question, answer, answered, created_at, subject:subjects(name)',
          )
          .eq('student_id', userId);

      if (academicYearId != null && academicYearId.isNotEmpty) {
        query = query.eq('academic_year_id', academicYearId);
      }

      final rows = await query.order('created_at', ascending: false).limit(50);

      final items = (rows as List).map((r) {
        final map = r as Map;
        final createdAt = map['created_at']?.toString() ?? '';
        final subjectRaw = map['subject'];
        final subjectName = subjectRaw is Map
            ? subjectRaw['name']?.toString()
            : null;
        final answered = (map['answered'] as bool?) ?? false;

        return _Question(
          subject: maybeFixMojibake(subjectName?.trim() ?? ''),
          question: maybeFixMojibake((map['question'] as String?) ?? ''),
          status: answered ? 'answered' : 'pending',
          answered: answered,
          answer: maybeFixMojibakeNullable(map['answer'] as String?),
          date: createdAt.isNotEmpty ? _dateOnly(createdAt) : _todayIso(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _questions
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      debugPrint('Student questions load failed: $e');
      if (!mounted) return;
      setState(() {
        _error = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.commLoadQuestionsFailed,
        );
        _questions.clear();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final pending = _questions
        .where((q) => !q.answered)
        .toList(growable: false);
    final answered = _questions
        .where((q) => q.answered)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: widget.onAskQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              l10n.commAskQuestion,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadQuestionsFromBackend,
                child: Text(l10n.commonRetry),
              ),
            ],
          )
        else if (_questions.isEmpty)
          Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.grey.shade300,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.commNoQuestionsYet,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          )
        else ...[
          if (pending.isNotEmpty) ...[
            Text(
              l10n.commPending,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            ...pending.map((q) => _QuestionCard(question: q)),
            const SizedBox(height: 16),
          ],
          if (answered.isNotEmpty) ...[
            Text(
              l10n.commAnswered,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            ...answered.map((q) => _QuestionCard(question: q)),
          ],
        ],
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final _Question question;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subjectLabel = question.subject.trim().isNotEmpty
        ? question.subject
        : l10n.commSubjectGeneral;
    final statusColor = question.answered
        ? const Color(0xFF16A34A)
        : const Color(0xFFFBBF24); // green / amber
    final statusBg = question.answered
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEF3C7);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  subjectLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  question.answered ? l10n.commAnswered : l10n.commPending,
                  style: TextStyle(fontSize: 11, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.question,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
          if (question.answer != null) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.commResponseLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.answer!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            EthiopianDateFormatter.formatFlexible(question.date),
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

class _QuestionForm extends StatefulWidget {
  const _QuestionForm({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
  static const _generalSubjectValue = 'general';

  static List<({String id, String name})>? _cachedSubjects;
  static String? _cachedGradeId;
  static String? _cachedAcademicYearId;
  static String? _cachedUserId;
  static Future<void>? _inFlightPreload;

  static Future<void> preloadContext() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    if (_cachedUserId == userId && _cachedSubjects != null) return;
    if (_inFlightPreload != null) return _inFlightPreload!;

    final future = _fetchContextStatic(client, userId);
    _inFlightPreload = future;
    try {
      await future;
    } finally {
      if (_inFlightPreload == future) {
        _inFlightPreload = null;
      }
    }
  }

  static Future<String?> _activeAcademicYearIdStatic(
    SupabaseClient client,
  ) async {
    try {
      final id = await client.rpc('active_academic_year_id');
      final asString = id?.toString();
      if (asString != null && asString.isNotEmpty) return asString;
    } catch (_) {}

    try {
      final row = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return (row as Map?)?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _fetchContextStatic(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      final results = await Future.wait<dynamic>([
        client
            .from('profiles')
            .select('grade_id')
            .eq('id', userId)
            .maybeSingle(),
        _activeAcademicYearIdStatic(client),
      ]);

      final profile = results[0] as Map?;
      final gradeId = profile?['grade_id']?.toString();
      final academicYearId = results[1] as String?;

      if (gradeId == null ||
          gradeId.isEmpty ||
          academicYearId == null ||
          academicYearId.isEmpty) {
        return;
      }

      final subjectRows = await client
          .from('subjects')
          .select('id, name')
          .eq('grade_id', gradeId)
          .eq('active', true)
          .order('name');

      final subjects = <({String id, String name})>[];
      for (final r in (subjectRows as List)) {
        final map = r as Map;
        final id = map['id']?.toString();
        final name = map['name']?.toString();
        if (id == null || id.isEmpty || name == null || name.isEmpty) continue;
        subjects.add((id: id, name: name));
      }

      _cachedUserId = userId;
      _cachedGradeId = gradeId;
      _cachedAcademicYearId = academicYearId;
      _cachedSubjects = subjects;
    } catch (e) {
      debugPrint('Preload question context failed: $e');
    }
  }

  final _formKey = GlobalKey<FormState>();

  bool _loadingContext = false;
  String? _contextError;
  String? _submitError;
  String? _academicYearId;
  String? _gradeId;
  List<_QuestionSubjectOption> _subjectOptions = const [];

  String _subjectValue = _generalSubjectValue;
  String _question = '';
  bool _submitting = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadContextFromBackend();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subjectOptions.isEmpty) {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null &&
          _cachedUserId == userId &&
          _cachedSubjects != null) {
        final l10n = AppLocalizations.of(context);
        _gradeId = _cachedGradeId;
        _academicYearId = _cachedAcademicYearId;
        _subjectOptions = [
          _QuestionSubjectOption(
            value: _generalSubjectValue,
            label: l10n.commSubjectGeneral,
          ),
          for (final s in _cachedSubjects!)
            _QuestionSubjectOption(value: s.id, label: s.name),
        ];
        _loadingContext = false;
      }
    }
  }

  Future<void> _loadContextFromBackend() async {
    final l10n = AppLocalizations.of(context);
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId != null &&
        _cachedUserId == userId &&
        _cachedSubjects != null) {
      if (mounted) {
        setState(() {
          _gradeId = _cachedGradeId;
          _academicYearId = _cachedAcademicYearId;
          _subjectOptions = [
            _QuestionSubjectOption(
              value: _generalSubjectValue,
              label: l10n.commSubjectGeneral,
            ),
            for (final s in _cachedSubjects!)
              _QuestionSubjectOption(value: s.id, label: s.name),
          ];
          _loadingContext = false;
        });
      }
      return;
    }

    if (_loadingContext) return;

    setState(() {
      _loadingContext = true;
      _contextError = null;
      _submitError = null;
    });

    try {
      if (userId == null) throw StateError('Not signed in');

      if (_inFlightPreload != null) {
        await _inFlightPreload;
      } else {
        await _fetchContextStatic(client, userId);
      }

      final gradeId = _cachedGradeId;
      final academicYearId = _cachedAcademicYearId;
      if (gradeId == null || gradeId.isEmpty) {
        throw StateError('Missing grade assignment');
      }
      if (academicYearId == null || academicYearId.isEmpty) {
        throw StateError('Missing academic year');
      }

      final options = <_QuestionSubjectOption>[
        _QuestionSubjectOption(
          value: _generalSubjectValue,
          label: l10n.commSubjectGeneral,
        ),
        if (_cachedSubjects != null)
          for (final s in _cachedSubjects!)
            _QuestionSubjectOption(value: s.id, label: s.name),
      ];

      if (!mounted) return;
      setState(() {
        _gradeId = gradeId;
        _academicYearId = academicYearId;
        _subjectOptions = options;
        if (_subjectValue.isEmpty) {
          _subjectValue = _generalSubjectValue;
        }
      });
    } catch (e) {
      debugPrint('Student question form context load failed: $e');
      if (!mounted) return;
      setState(() {
        _contextError = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.commLoadContextFailed,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingContext = false;
        });
      }
    }
  }

  Future<void> _submitQuestionToBackend() async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw StateError('Not signed in');

      final gradeId = _gradeId;
      final academicYearId = _academicYearId;
      if (gradeId == null || academicYearId == null) {
        throw StateError('Missing class context');
      }

      final subjectId = _subjectValue == _generalSubjectValue
          ? null
          : _subjectValue;

      await client.from('questions').insert({
        'student_id': userId,
        'grade_id': gradeId,
        'academic_year_id': academicYearId,
        'subject_id': subjectId,
        'question': _question.trim(),
      });

      if (!mounted) return;
      setState(() {
        _showSuccess = true;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _showSuccess = false;
        });
        widget.onCancel();
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      debugPrint('Student question submit failed: $e');
      if (!mounted) return;
      setState(() {
        _submitError = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.commSubmitQuestionFailed,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final subjectOptions = _subjectOptions.isNotEmpty
        ? _subjectOptions
        : [
            _QuestionSubjectOption(
              value: _generalSubjectValue,
              label: l10n.commSubjectGeneral,
            ),
          ];

    final effectiveSubjectValue =
        subjectOptions.any((o) => o.value == _subjectValue)
            ? _subjectValue
            : (subjectOptions.isNotEmpty
                ? subjectOptions.first.value
                : _generalSubjectValue);
    final isLoadingOptions = _loadingContext && _subjectOptions.length <= 1;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.commAskQuestion,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.commSubjectLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'subject_${subjectOptions.length}_$effectiveSubjectValue',
                  ),
                  initialValue: effectiveSubjectValue,
                  items: subjectOptions
                      .map(
                        (o) => DropdownMenuItem(
                          value: o.value,
                          child: Text(o.label),
                        ),
                      )
                      .toList(growable: false),
                  decoration: _dropdownDecoration.copyWith(
                    suffixIcon: isLoadingOptions
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: isLoadingOptions
                      ? null
                      : (value) {
                          setState(
                            () => _subjectValue = value ?? _generalSubjectValue,
                          );
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.commSelectSubjectError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.commYourQuestionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  maxLines: 4,
                  maxLength: 500,
                  decoration: _textareaDecoration.copyWith(
                    hintText: l10n.commQuestionHint,
                    counterText: '${_question.length}/500',
                    counterStyle: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _question = value);
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.commEnterQuestionError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_contextError != null || _submitError != null) ...[
                  Text(
                    _contextError ?? _submitError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            (_submitting ||
                                _loadingContext ||
                                _gradeId == null ||
                                _academicYearId == null)
                            ? null
                            : () {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                _submitQuestionToBackend();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(l10n.commonSend),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(l10n.commonCancel),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_showSuccess)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.commQuestionSubmitted,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          if (_loadingContext)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _QuestionSubjectOption {
  const _QuestionSubjectOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _ComplaintsList extends StatefulWidget {
  const _ComplaintsList({super.key, required this.onSubmitComplaint});

  final VoidCallback onSubmitComplaint;

  @override
  State<_ComplaintsList> createState() => _ComplaintsListState();
}

class _ComplaintsListState extends State<_ComplaintsList> {
  bool _isLoading = true;
  String? _error;
  final List<_Complaint> _complaints = [];

  static String _dateOnly(String value) {
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  static String _todayIso() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  @override
  void initState() {
    super.initState();
    _loadComplaintsFromBackend();
  }

  Future<String?> _activeAcademicYearId(SupabaseClient client) async {
    try {
      final id = await client.rpc('active_academic_year_id');
      final asString = id?.toString();
      if (asString != null && asString.isNotEmpty) return asString;
    } catch (_) {}

    try {
      final row = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return (row as Map?)?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadComplaintsFromBackend() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('Not signed in');
      }

      final academicYearId = await _activeAcademicYearId(client);

      var query = client
          .from('complaints')
          .select('id, category, status, complaint, created_at')
          .eq('student_id', userId);

      if (academicYearId != null && academicYearId.isNotEmpty) {
        query = query.eq('academic_year_id', academicYearId);
      }

      final rows = await query.order('created_at', ascending: false).limit(50);

      final items = (rows as List).map((r) {
        final map = r as Map;
        final createdAt = map['created_at']?.toString() ?? '';
        return _Complaint(
          category: map['category']?.toString() ?? 'other',
          status: map['status']?.toString() ?? 'pending',
          text: maybeFixMojibake(map['complaint']?.toString() ?? ''),
          date: createdAt.isNotEmpty ? _dateOnly(createdAt) : _todayIso(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _complaints
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      debugPrint('Student complaints load failed: $e');
      if (!mounted) return;
      setState(() {
        _error = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.commLoadComplaintsFailed,
        );
        _complaints.clear();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: widget.onSubmitComplaint,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              l10n.commSubmitComplaint,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadComplaintsFromBackend,
                child: Text(l10n.commonRetry),
              ),
            ],
          )
        else if (_complaints.isEmpty)
          Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.report_problem_outlined,
                color: Colors.grey.shade300,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.commNoComplaintsSubmitted,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          )
        else
          ..._complaints.map((c) => _ComplaintCard(complaint: c)),
      ],
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint});

  final _Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color statusColor;
    Color statusBg;
    switch (complaint.status) {
      case 'pending':
        statusBg = const Color(0xFFFEF3C7);
        statusColor = const Color(0xFF92400E);
        break;
      case 'resolved':
        statusBg = const Color(0xFFDCFCE7);
        statusColor = const Color(0xFF166534);
        break;
      default:
        statusBg = const Color(0xFFDBEAFE);
        statusColor = const Color(0xFF1D4ED8);
    }

    final categoryLabel = switch (complaint.category) {
      'teacher' => l10n.commCategoryTeacher,
      'facility' => l10n.commCategoryFacility,
      'course' => l10n.commCategoryCourse,
      'administrative' => l10n.commCategoryAdministrative,
      'other' => l10n.commCategoryOther,
      _ => complaint.category,
    };

    final statusLabel = switch (complaint.status) {
      'pending' => l10n.commPending,
      'in_review' => l10n.commInReview,
      'resolved' => l10n.commResolved,
      _ => complaint.status,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  categoryLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            complaint.text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            EthiopianDateFormatter.formatFlexible(complaint.date),
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

class _ComplaintForm extends StatefulWidget {
  const _ComplaintForm({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  State<_ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<_ComplaintForm> {
  final _formKey = GlobalKey<FormState>();

  bool _loadingContext = false;
  String? _contextError;
  String? _submitError;
  String? _academicYearId;
  String? _gradeId;

  String _category = '';
  String _title = '';
  String _description = '';
  bool _anonymous = false;
  bool _submitting = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadContextFromBackend();
  }

  Future<String?> _activeAcademicYearId(SupabaseClient client) async {
    try {
      final id = await client.rpc('active_academic_year_id');
      final asString = id?.toString();
      if (asString != null && asString.isNotEmpty) return asString;
    } catch (_) {}

    try {
      final row = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return (row as Map?)?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadContextFromBackend() async {
    final l10n = AppLocalizations.of(context);
    if (_loadingContext) return;

    setState(() {
      _loadingContext = true;
      _contextError = null;
      _submitError = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw StateError('Not signed in');

      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', userId)
          .maybeSingle();
      final gradeId = (profile as Map?)?['grade_id']?.toString();
      if (gradeId == null || gradeId.isEmpty) {
        throw StateError('Missing grade assignment');
      }

      final academicYearId = await _activeAcademicYearId(client);
      if (academicYearId == null || academicYearId.isEmpty) {
        throw StateError('Missing academic year');
      }

      if (!mounted) return;
      setState(() {
        _gradeId = gradeId;
        _academicYearId = academicYearId;
      });
    } catch (e) {
      debugPrint('Student complaint form context load failed: $e');
      if (!mounted) return;
      setState(() {
        _contextError = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.commLoadContextFailed,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingContext = false;
        });
      }
    }
  }

  Future<void> _submitComplaintToBackend() async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw StateError('Not signed in');

      final gradeId = _gradeId;
      final academicYearId = _academicYearId;
      if (gradeId == null || academicYearId == null) {
        throw StateError('Missing class context');
      }

      final title = _title.trim();
      final description = _description.trim();
      final complaintText = title.isEmpty
          ? description
          : '$title\n\n$description';

      await client.from('complaints').insert({
        'student_id': userId,
        'grade_id': gradeId,
        'academic_year_id': academicYearId,
        'category': _category.isEmpty ? null : _category,
        'complaint': complaintText,
        'status': 'pending',
      });

      if (!mounted) return;
      setState(() {
        _showSuccess = true;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _showSuccess = false;
        });
        widget.onCancel();
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      debugPrint('Student complaint submit failed: $e');
      if (!mounted) return;
      setState(() {
        _submitError = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.commSubmitComplaintFailed,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.commSubmitComplaint,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.commCategoryLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _category.isEmpty ? null : _category,
                  items: [
                    DropdownMenuItem(
                      value: 'teacher',
                      child: Text(l10n.commCategoryTeacher),
                    ),
                    DropdownMenuItem(
                      value: 'facility',
                      child: Text(l10n.commCategoryFacility),
                    ),
                    DropdownMenuItem(
                      value: 'course',
                      child: Text(l10n.commCategoryCourse),
                    ),
                    DropdownMenuItem(
                      value: 'administrative',
                      child: Text(l10n.commCategoryAdministrative),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text(l10n.commCategoryOther),
                    ),
                  ],
                  decoration: _dropdownDecoration,
                  onChanged: (value) {
                    setState(() => _category = value ?? '');
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.commSelectCategoryError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.commTitleLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  maxLength: 100,
                  decoration: _inputDecoration.copyWith(
                    hintText: l10n.commComplaintTitleHint,
                    counterText: '${_title.length}/100',
                    counterStyle: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _title = value);
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.commEnterTitleError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.commDescriptionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  maxLines: 4,
                  maxLength: 500,
                  decoration: _textareaDecoration.copyWith(
                    hintText: l10n.commComplaintDescriptionHint,
                    counterText: '${_description.length}/500',
                    counterStyle: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _description = value);
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.commEnterDescriptionError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _anonymous,
                      onChanged: (value) {
                        setState(() => _anonymous = value ?? false);
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.commSubmitAnonymously,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            (_submitting ||
                                _loadingContext ||
                                _gradeId == null ||
                                _academicYearId == null)
                            ? null
                            : () {
                                if (!_formKey.currentState!.validate()) return;
                                _submitComplaintToBackend();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(l10n.commonSubmit),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(l10n.commonCancel),
                    ),
                  ],
                ),
                if (_contextError != null || _submitError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _contextError ?? _submitError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          if (_showSuccess)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.commComplaintSubmitted,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          if (_loadingContext)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _FeedbackSection extends StatefulWidget {
  const _FeedbackSection({super.key, required this.onSubmitted});

  final VoidCallback onSubmitted;

  @override
  State<_FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<_FeedbackSection> {
  bool _isLoading = true;
  String? _error;

  final List<_StudentFeedbackForm> _forms = [];
  _StudentFeedbackForm? _activeForm;

  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _submitError;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, Object?> _answers = {};

  static String _todayIso() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  @override
  void initState() {
    super.initState();
    _loadFeedbackFormsFromBackend();
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _activeAcademicYearId(SupabaseClient client) async {
    try {
      final id = await client.rpc('active_academic_year_id');
      final asString = id?.toString();
      if (asString != null && asString.isNotEmpty) return asString;
    } catch (_) {}

    try {
      final row = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return (row as Map?)?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  void _resetAnswerState() {
    _submitError = null;
    _answers.clear();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _textControllers.clear();
  }

  TextEditingController _textControllerFor(String questionId) {
    return _textControllers.putIfAbsent(
      questionId,
      () =>
          TextEditingController(text: (_answers[questionId] as String?) ?? ''),
    );
  }

  Future<void> _loadFeedbackFormsFromBackend() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw StateError('Not signed in');

      final academicYearId = await _activeAcademicYearId(client);
      if (academicYearId == null || academicYearId.isEmpty) {
        throw StateError('Missing academic year');
      }

      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', userId)
          .maybeSingle();
      final gradeId = (profile as Map?)?['grade_id']?.toString();
      if (gradeId == null || gradeId.isEmpty) {
        throw StateError('Missing grade assignment');
      }

      final today = _todayIso();
      final rows = await client
          .from('feedback_forms')
          .select(
            'id, title, description, start_date, end_date, created_at, feedback_questions(id, position, type, question, required, options)',
          )
          .eq('academic_year_id', academicYearId)
          .eq('grade_id', gradeId)
          .lte('start_date', today)
          .gte('end_date', today)
          .order('created_at', ascending: false);

      final forms = <_StudentFeedbackForm>[];
      final formIds = <String>[];

      for (final r in (rows as List)) {
        final map = r as Map;
        final id = map['id']?.toString();
        if (id == null || id.isEmpty) continue;
        formIds.add(id);

        final questionsRaw =
            (map['feedback_questions'] as List<dynamic>? ?? const []);
        questionsRaw.sort((a, b) {
          final pa = (a as Map)['position'] as int? ?? 0;
          final pb = (b as Map)['position'] as int? ?? 0;
          return pa.compareTo(pb);
        });

        final questions = questionsRaw
            .map((q) {
              final qMap = q as Map;
              final optionsRaw = qMap['options'];
              final options = optionsRaw is List
                  ? optionsRaw.whereType<String>().toList()
                  : const <String>[];

              return _StudentFeedbackQuestion(
                id: qMap['id']?.toString() ?? '',
                question: qMap['question']?.toString() ?? '',
                type: qMap['type']?.toString() ?? 'text',
                required: (qMap['required'] as bool?) ?? true,
                options: options,
              );
            })
            .where((q) => q.id.isNotEmpty)
            .toList(growable: false);

        forms.add(
          _StudentFeedbackForm(
            id: id,
            title: map['title']?.toString() ?? '',
            description: map['description']?.toString() ?? '',
            startDate: map['start_date']?.toString() ?? today,
            endDate: map['end_date']?.toString() ?? today,
            questions: questions,
          ),
        );
      }

      final submittedFormIds = <String>{};
      if (formIds.isNotEmpty) {
        try {
          final subs = await client
              .from('feedback_submissions')
              .select('form_id')
              .eq('student_id', userId)
              .inFilter('form_id', formIds);

          for (final s in (subs as List)) {
            final fid = (s as Map)['form_id']?.toString();
            if (fid != null && fid.isNotEmpty) submittedFormIds.add(fid);
          }
        } catch (_) {}
      }

      final pendingForms = forms
          .where((f) => !submittedFormIds.contains(f.id))
          .toList();

      if (!mounted) return;
      setState(() {
        _forms
          ..clear()
          ..addAll(pendingForms);
        _isLoading = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      debugPrint('Student feedback forms load failed: $e');
      if (!mounted) return;
      setState(() {
        _error = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.commLoadFeedbackFormsFailed,
        );
        _forms.clear();
        _isLoading = false;
      });
    }
  }

  void _openForm(_StudentFeedbackForm form) {
    setState(() {
      _activeForm = form;
      _resetAnswerState();
    });
  }

  void _closeForm() {
    setState(() {
      _activeForm = null;
      _resetAnswerState();
    });
  }

  Future<void> _submitActiveForm() async {
    if (_submitting) return;

    final form = _activeForm;
    if (form == null) return;

    final l10n = AppLocalizations.of(context);
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() {
        _submitError = l10n.servantGradesFillRequiredFieldsError;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw StateError('Not signed in');

      final answers = <String, Object?>{};
      for (final q in form.questions) {
        switch (q.type) {
          case 'text':
            final text = _textControllerFor(q.id).text.trim();
            answers[q.id] = text;
            _answers[q.id] = text;
            break;
          case 'rating':
            answers[q.id] = _answers[q.id];
            break;
          case 'multiple_choice':
            answers[q.id] = _answers[q.id];
            break;
          default:
            final text = _textControllerFor(q.id).text.trim();
            answers[q.id] = text;
            _answers[q.id] = text;
        }
      }

      await client.from('feedback_submissions').insert({
        'form_id': form.id,
        'student_id': userId,
        'answers': answers,
      });

      if (!mounted) return;
      _closeForm();
      widget.onSubmitted();
      await _loadFeedbackFormsFromBackend();
    } catch (e) {
      debugPrint('Student feedback submit failed: $e');
      if (!mounted) return;
      setState(() {
        _submitError = presentErrorMessage(
          l10n,
          e,
          fallback: l10n.commSubmitFeedbackFailed,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadFeedbackFormsFromBackend,
            child: Text(l10n.commonRetry),
          ),
        ],
      );
    }

    final activeForm = _activeForm;
    if (activeForm != null) {
      return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fact_check_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activeForm.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (activeForm.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      activeForm.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ...activeForm.questions.map((q) {
                    final label = q.required ? '${q.question} *' : q.question;

                    Widget field;
                    if (q.type == 'rating') {
                      final current = _answers[q.id];
                      field = DropdownButtonFormField<int>(
                        initialValue: current is int ? current : null,
                        decoration: _dropdownDecoration,
                        items: List.generate(
                          5,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          ),
                        ),
                        onChanged: _submitting
                            ? null
                            : (value) {
                                setState(() {
                                  _answers[q.id] = value;
                                });
                              },
                        validator: (value) {
                          if (!q.required) return null;
                          if (value == null) {
                            return l10n.servantFeedbackRequiredLabel;
                          }
                          return null;
                        },
                      );
                    } else if (q.type == 'multiple_choice') {
                      final current = _answers[q.id];
                      final options = q.options;
                      field = DropdownButtonFormField<String>(
                        initialValue: current is String ? current : null,
                        decoration: _dropdownDecoration,
                        items: options
                            .map(
                              (o) => DropdownMenuItem(value: o, child: Text(o)),
                            )
                            .toList(growable: false),
                        onChanged: (_submitting || options.isEmpty)
                            ? null
                            : (value) {
                                setState(() {
                                  _answers[q.id] = value;
                                });
                              },
                        validator: (value) {
                          if (!q.required) return null;
                          if (value == null || value.trim().isEmpty) {
                            return l10n.servantFeedbackRequiredLabel;
                          }
                          return null;
                        },
                      );
                    } else {
                      field = TextFormField(
                        controller: _textControllerFor(q.id),
                        maxLines: 2,
                        decoration: _textareaDecoration,
                        enabled: !_submitting,
                        validator: (value) {
                          if (!q.required) return null;
                          if (value == null || value.trim().isEmpty) {
                            return l10n.servantFeedbackRequiredLabel;
                          }
                          return null;
                        },
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 6),
                          field,
                        ],
                      ),
                    );
                  }),
                  if (_submitError != null) ...[
                    Text(
                      _submitError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submitActiveForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text(l10n.commonSubmit),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _submitting ? null : _closeForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(l10n.commonCancel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_forms.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fact_check_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.commNoActiveFeedbackForms,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.commFeedbackEmptySubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _forms.map((form) {
        final due = EthiopianDateFormatter.formatFlexible(form.endDate);
        final subtitle = l10n.servantFeedbackQuestionsAndDueLine(
          form.questions.length,
          due,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fact_check_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      form.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (form.description.trim().isNotEmpty)
                Text(
                  form.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _openForm(form),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(l10n.commonSubmit),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StudentFeedbackForm {
  const _StudentFeedbackForm({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.questions,
  });

  final String id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final List<_StudentFeedbackQuestion> questions;
}

class _StudentFeedbackQuestion {
  const _StudentFeedbackQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.required,
    required this.options,
  });

  final String id;
  final String question;
  final String type;
  final bool required;
  final List<String> options;
}

// --- Shared helpers and data classes ---

const _inputDecoration = InputDecoration(
  isDense: true,
  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Color(0xFFCBD5E1)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Color(0xFF0EA5E9), width: 2),
  ),
);

final _textareaDecoration = _inputDecoration.copyWith(alignLabelWithHint: true);

const _dropdownDecoration = _inputDecoration;

class _SubjectGrade {
  const _SubjectGrade({required this.name, required this.average});

  final String name;
  final int average;
}

// ignore: unused_element
class _SubjectGradeTile extends StatelessWidget {
  const _SubjectGradeTile({
    required this.subject,
    required this.gradeColor,
    required this.gradeBg,
    required this.barColor,
  });

  final _SubjectGrade subject;
  final Color Function(int) gradeColor;
  final Color Function(int) gradeBg;
  final Color Function(int) barColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: gradeBg(subject.average),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${subject.average}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: gradeColor(subject.average),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 6,
                width: subject.average.toDouble().clamp(0, 100),
                decoration: BoxDecoration(
                  color: barColor(subject.average),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }
}

class _Announcement {
  const _Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdBy,
    required this.createdDate,
    required this.category,
    required this.unread,
  });

  final String id;
  final String title;
  final String message;
  final String createdBy;
  final String createdDate;
  final String category;
  final bool unread;
}

class _Question {
  const _Question({
    required this.subject,
    required this.question,
    required this.status,
    required this.answered,
    required this.date,
    this.answer,
  });

  final String subject;
  final String question;
  final String status;
  final bool answered;
  final String date;
  final String? answer;
}

class _Complaint {
  const _Complaint({
    required this.category,
    required this.status,
    required this.text,
    required this.date,
  });

  final String category;
  final String status;
  final String text;
  final String date;
}

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _ProfileData {
  const _ProfileData({
    required this.academicId,
    required this.role,
    required this.accountStatus,
    this.name,
    this.gradeName,
    this.gradeCode,
    this.email,
  });

  final String academicId;
  final String? name;
  final String role;
  final String accountStatus;
  final String? gradeName;
  final String? gradeCode;
  final String? email;
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with WidgetsBindingObserver {
  late Future<_ProfileData> _profileFuture;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;
  String? _subscribedUserId;
  bool _profileStreamInitialized = false;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profileFuture = _loadProfile();
    _subscribeToProfileUpdates();
  }

  void _subscribeToProfileUpdates() {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    if (_subscribedUserId == userId && _profileSubscription != null) {
      return;
    }

    _profileSubscription?.cancel();
    _subscribedUserId = userId;
    _profileStreamInitialized = false;

    _profileSubscription = client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((_) {
          if (!_profileStreamInitialized) {
            _profileStreamInitialized = true;
            return;
          }

          if (!mounted || !_active) return;
          setState(() {
            _profileFuture = _loadProfile();
          });
        });
  }

  @override
  void deactivate() {
    _active = false;
    _profileSubscription?.cancel();
    _profileSubscription = null;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
    _subscribeToProfileUpdates();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    if (!_active) return;

    _subscribeToProfileUpdates();

    if (!mounted) return;
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  void dispose() {
    _active = false;
    WidgetsBinding.instance.removeObserver(this);
    _profileSubscription?.cancel();
    super.dispose();
  }

  Future<_ProfileData> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }

    final profile = await client
        .from('profiles')
        .select('academic_id, name, role, grade_id, account_status')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      throw StateError('Profile not found');
    }

    final gradeId = (profile as Map)['grade_id']?.toString();
    String? gradeName;
    String? gradeCode;
    if (gradeId != null && gradeId.isNotEmpty) {
      final grade = await client
          .from('grades')
          .select('name, code')
          .eq('id', gradeId)
          .maybeSingle();
      gradeName = (grade as Map?)?['name']?.toString();
      gradeCode = (grade as Map?)?['code']?.toString();
    }

    return _ProfileData(
      academicId: (profile as Map)['academic_id']?.toString() ?? '',
      name: profile['name']?.toString(),
      role: profile['role']?.toString() ?? 'student',
      accountStatus: profile['account_status']?.toString() ?? 'active',
      gradeName: gradeName,
      gradeCode: gradeCode,
      email: user.email,
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _profileFuture = _loadProfile();
    });
    await _profileFuture;
  }

  Future<void> _signOut() async {
    final client = Supabase.instance.client;
    await PushNotificationsService.instance.unregisterBeforeSignOut();
    await client.auth.signOut();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    String friendlyAcademicId(String value) {
      final v = value.trim();
      if (v.isEmpty) return l10n.commonNa;
      final looksLikeUuid = RegExp(
        r'^[0-9a-fA-F]{8}-'
        r'[0-9a-fA-F]{4}-'
        r'[0-9a-fA-F]{4}-'
        r'[0-9a-fA-F]{4}-'
        r'[0-9a-fA-F]{12}$',
      ).hasMatch(v);
      if (looksLikeUuid) return l10n.commonNa;
      return v;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AppRefreshConfigurator(
          onRefresh: _handleRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navProfile,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.profileAccountDetailsSubtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFBAE6FD),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: FutureBuilder<_ProfileData>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      final error = snapshot.error;
                      String errorText;
                      if (error is StateError) {
                        final msg = error.message.toLowerCase().trim();
                        if (msg == 'not signed in' || msg == 'not_signed_in') {
                          errorText = l10n.profileErrorNotSignedIn;
                        } else if (msg == 'profile not found' ||
                            msg == 'profile_not_found') {
                          errorText = l10n.profileErrorNotFound;
                        } else {
                          errorText = presentErrorMessage(l10n, error);
                        }
                      } else if (error != null) {
                        errorText = presentErrorMessage(l10n, error);
                      } else {
                        errorText = l10n.errorSomethingWentWrong;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.profileLoadFailedTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              errorText,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _handleRefresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(l10n.commonRetry),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final data = snapshot.data;
                    if (data == null) {
                      return const SizedBox.shrink();
                    }

                    final displayName =
                        (data.name == null || data.name!.trim().isEmpty)
                        ? l10n.roleStudent
                        : data.name!.trim();
                    final gradeText =
                        (data.gradeName == null || data.gradeName!.isEmpty)
                        ? l10n.profileNotAssigned
                        : (data.gradeCode == null || data.gradeCode!.isEmpty)
                        ? data.gradeName!
                        : '${data.gradeName} (${data.gradeCode})';

                    final roleLabel = switch (data.role.toLowerCase()) {
                      'student' => l10n.roleStudent,
                      'servant' => l10n.roleServant,
                      _ => data.role,
                    };

                    final accountStatusLabel = switch (data.accountStatus
                        .toLowerCase()) {
                      'active' => l10n.accountStatusActive,
                      'inactive_pending_admin' => l10n.accountStatusInactive,
                      'inactive' => l10n.accountStatusInactive,
                      'suspended' => l10n.accountStatusSuspended,
                      'disabled' => l10n.accountStatusDisabled,
                      _ => data.accountStatus,
                    };

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: accent,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          data.email ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.badge_outlined,
                                  color: accent,
                                ),
                                title: Text(l10n.profileAcademicIdLabel),
                                subtitle: Text(
                                  friendlyAcademicId(data.academicId),
                                ),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.class_outlined,
                                  color: accent,
                                ),
                                title: Text(l10n.profileGradeLabel),
                                subtitle: Text(gradeText),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.verified_user_outlined,
                                  color: accent,
                                ),
                                title: Text(l10n.profileAccountStatusLabel),
                                subtitle: Text(accountStatusLabel),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.work_outline,
                                  color: accent,
                                ),
                                title: Text(l10n.profileRoleLabel),
                                subtitle: Text(roleLabel),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/student/profile/change-password'),
                          icon: const Icon(Icons.lock_reset_rounded),
                          label: Text(l10n.profileChangePassword),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: accent),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(l10n.commonSignOut),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentChangePasswordScreen extends StatefulWidget {
  const StudentChangePasswordScreen({super.key});

  @override
  State<StudentChangePasswordScreen> createState() =>
      _StudentChangePasswordScreenState();
}

class _StudentChangePasswordScreenState
    extends State<StudentChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        setState(() {
          _error = l10n.profileErrorNotSignedIn;
        });
        return;
      }

      await client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authPasswordUpdateSuccess)));
      context.pop();
    } on AuthException catch (e) {
      debugPrint('Student password update failed: ${e.message}');
      if (!mounted) return;
      setState(() {
        _error = l10n.authPasswordUpdateFailedGeneric;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = l10n.authPasswordUpdateFailedGeneric;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 24, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.profileChangePassword,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.profileChangePasswordSubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFBAE6FD),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.authNewPasswordLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _IconTextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        hintText: l10n.authNewPasswordHint,
                        icon: Icons.lock_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.authPasswordRequiredError;
                          }
                          if (value.length < 6) {
                            return l10n.authPasswordMinLengthError(6);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.authConfirmPasswordLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _IconTextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        hintText: l10n.authConfirmPasswordHint,
                        icon: Icons.lock_outline_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.authConfirmPasswordRequiredError;
                          }
                          if (value != _newPasswordController.text) {
                            return l10n.authPasswordMismatchError;
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: _submitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          label: Text(l10n.commonUpdate),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
