import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sunday_school_app/l10n/app_localizations.dart';

import '../../../../core/refresh/app_refresh_configurator.dart';
import 'servant_analytics_calculations.dart';
import 'servant_analytics_repository.dart';
import 'servant_analytics_widgets.dart';

class ServantAnalyticsScreen extends StatefulWidget {
  const ServantAnalyticsScreen({super.key});

  @override
  State<ServantAnalyticsScreen> createState() => _ServantAnalyticsScreenState();
}

class _ServantAnalyticsScreenState extends State<ServantAnalyticsScreen> {
  final _repository = ServantAnalyticsRepository();
  late Future<ServantAnalyticsSnapshot> _future;
  final _tooltip = TooltipController();

  AnalyticsView _selectedView = AnalyticsView.overview;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadActiveYearForCurrentServantGrade();
  }

  @override
  void dispose() {
    _tooltip.hide();
    super.dispose();
  }

  void _setView(AnalyticsView view) {
    setState(() {
      _tooltip.hide();
      _selectedView = view;
      if (view != AnalyticsView.subjects) {
        _selectedSubjectId = null;
      }
    });
  }

  Future<void> _handleRefresh() async {
    final future = _repository.loadActiveYearForCurrentServantGrade();
    setState(() {
      _future = future;
    });

    try {
      await future;
    } catch (_) {
      // Surface the failure via FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return AppRefreshConfigurator(
      onRefresh: _handleRefresh,
      child: FutureBuilder<ServantAnalyticsSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            debugPrint('Servant analytics load failed: ${snapshot.error}');
            return Scaffold(
              appBar: AppBar(title: Text(l10n.servantAnalyticsTitle)),
              body: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 120),
                  Text(
                    l10n.servantAnalyticsLoadFailed,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _handleRefresh,
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            );
          }

          final data = calculateAnalyticsData(snapshot.requireData);

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 170,
                    backgroundColor: cs.primary,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [cs.primary, cs.primary.withAlpha(230)],
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          context.go('/servant/dashboard'),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(51),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.servantAnalyticsTitle,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            l10n.servantAnalyticsSubtitle,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withAlpha(
                                                217,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                AnalyticsHeaderTabs(
                                  selected: _selectedView,
                                  onSelected: _setView,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                children: [
                  if (_selectedView == AnalyticsView.overview)
                    _OverviewView(data: data, tooltip: _tooltip),
                  if (_selectedView == AnalyticsView.subjects)
                    _SubjectsView(
                      data: data,
                      selectedSubjectId: _selectedSubjectId,
                      onSelectSubject: (id) {
                        setState(() {
                          _tooltip.hide();
                          _selectedSubjectId = id;
                        });
                      },
                      onBack: () {
                        setState(() {
                          _tooltip.hide();
                          _selectedSubjectId = null;
                        });
                      },
                      tooltip: _tooltip,
                    ),
                  if (_selectedView == AnalyticsView.students)
                    _StudentsView(data: data),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverviewView extends StatelessWidget {
  const _OverviewView({required this.data, required this.tooltip});

  final ServantAnalyticsData data;
  final TooltipController tooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final atRiskPercent = data.totalStudents <= 0
        ? 0
        : ((data.atRiskStudents.length / data.totalStudents) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            MetricCard(
              icon: Icons.my_location_rounded,
              iconColor: Colors.lightBlue.shade600,
              label: l10n.servantAnalyticsMetricClassAverage,
              value: '${data.classAverage}%',
              subLabel: l10n.servantAnalyticsStudentsWithGradesLabel(
                data.studentsWithGrades,
                data.totalStudents,
              ),
              valueColor: const Color(0xFF0F172A),
            ),
            MetricCard(
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.amber.shade700,
              label: l10n.servantAnalyticsMetricAtRisk,
              value: '${data.atRiskStudents.length}',
              subLabel: l10n.servantAnalyticsAtRiskPercentOfClass(
                atRiskPercent,
              ),
              valueColor: Colors.amber.shade700,
            ),
            MetricCard(
              icon: Icons.emoji_events_rounded,
              iconColor: Colors.green.shade700,
              label: l10n.servantAnalyticsMetricTopPerformers,
              value: '${data.topPerformers.length}',
              subLabel: l10n.servantAnalyticsTopPerformersThreshold,
              valueColor: Colors.green.shade700,
            ),
            MetricCard(
              icon: Icons.menu_book_rounded,
              iconColor: Colors.red.shade600,
              label: l10n.servantAnalyticsMetricMissingWork,
              value: '${data.studentsWithMissing.length}',
              subLabel: l10n.servantAnalyticsMissingWorkSubtitle,
              valueColor: Colors.red.shade600,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnalyticsSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, color: Color(0xFF334155)),
                  const SizedBox(width: 8),
                  Text(
                    l10n.servantAnalyticsGradeDistributionTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GradeDistributionBarChart(
                data: data.gradeDistribution,
                tooltipController: tooltip,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnalyticsSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.servantAnalyticsSubjectPerformanceTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ...data.subjectAverages.map((s) {
                final barColor = Colors.lightBlue.shade500;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ProgressBar(value: s.average, color: barColor),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${s.average}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        if (data.assessmentPerformance.isNotEmpty) ...[
          const SizedBox(height: 16),
          AnalyticsSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.servantAnalyticsPerformanceByAssessmentTypeTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                SimpleLineChart(
                  data: data.assessmentPerformance,
                  tooltipController: tooltip,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.amber.shade50, Colors.amber.shade100],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.amber.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _InsightsList(data: data)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightsList extends StatelessWidget {
  const _InsightsList({required this.data});

  final ServantAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <Widget>[];

    if (data.classAverage >= 80) {
      items.add(
        _InsightLine(
          leading: '✓',
          leadingColor: Colors.green,
          text: l10n.servantAnalyticsInsightClassPerformingWell,
        ),
      );
    }

    if (data.atRiskStudents.isNotEmpty) {
      items.add(
        _InsightLine(
          leading: '⚠',
          leadingColor: Colors.amber.shade800,
          text: l10n.servantAnalyticsInsightAtRiskStudents(
            data.atRiskStudents.length,
          ),
        ),
      );
    }

    if (data.studentsWithMissing.isNotEmpty) {
      items.add(
        _InsightLine(
          leading: '!',
          leadingColor: Colors.red.shade700,
          text: l10n.servantAnalyticsInsightIncompleteAssessments(
            data.studentsWithMissing.length,
          ),
        ),
      );
    }

    if (data.topPerformers.isNotEmpty) {
      items.add(
        _InsightLine(
          leading: '⭐',
          leadingColor: Colors.green.shade700,
          text: l10n.servantAnalyticsInsightTopPerformers(
            data.topPerformers.length,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.servantAnalyticsKeyInsightsTitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(
            l10n.servantAnalyticsNoInsightsYet,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          )
        else
          ...items.expand((w) sync* {
            yield w;
            yield const SizedBox(height: 8);
          }).toList()..removeLast(),
      ],
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({
    required this.leading,
    required this.leadingColor,
    required this.text,
  });

  final String leading;
  final Color leadingColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          leading,
          style: TextStyle(color: leadingColor, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }
}

class _SubjectsView extends StatelessWidget {
  const _SubjectsView({
    required this.data,
    required this.selectedSubjectId,
    required this.onSelectSubject,
    required this.onBack,
    required this.tooltip,
  });

  final ServantAnalyticsData data;
  final String? selectedSubjectId;
  final ValueChanged<String> onSelectSubject;
  final VoidCallback onBack;
  final TooltipController tooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (selectedSubjectId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.servantAnalyticsSelectSubjectTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...data.subjectAverages.map((s) {
            Color scoreColor(int avg) {
              if (avg >= 80) return Colors.green.shade700;
              if (avg >= 70) return Colors.lightBlue.shade600;
              return Colors.amber.shade700;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onSelectSubject(s.subjectId),
                borderRadius: BorderRadius.circular(18),
                child: AnalyticsSectionCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            '${s.average}%',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: scoreColor(s.average),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _MiniStat(
                            label: l10n.servantAnalyticsHighestLabel,
                            value: '${s.highest}%',
                            valueColor: Colors.green.shade700,
                          ),
                          _MiniStat(
                            label: l10n.servantAnalyticsLowestLabel,
                            value: '${s.lowest}%',
                            valueColor: Colors.red.shade700,
                          ),
                          _MiniStat(
                            label: l10n.servantAnalyticsIncompleteLabel,
                            value: '${s.incomplete}',
                            valueColor: Colors.amber.shade700,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }

    final detail = data.subjectDetails(selectedSubjectId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                color: Colors.lightBlue.shade600,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.servantAnalyticsBackToSubjects,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.lightBlue.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnalyticsSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.subjectName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.servantAnalyticsGradeDistributionTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              SimplePieChart(
                data: detail.gradeDistribution,
                tooltipController: tooltip,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnalyticsSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.servantAnalyticsAssessmentBreakdownTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ...detail.assessmentBreakdown.map((a) {
                Color avgColor(int avg) {
                  if (avg >= 85) return Colors.green.shade600;
                  if (avg >= 75) return Colors.lightBlue.shade600;
                  if (avg >= 65) return Colors.amber.shade700;
                  return Colors.red.shade600;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        a.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (a.weight > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          '${a.weight}%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.amber.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.servantAnalyticsCompletedOutOf(
                                    a.completed,
                                    a.total,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${a.average}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: avgColor(a.average),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ProgressBar(value: a.average, color: avgColor(a.average)),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentsView extends StatelessWidget {
  const _StudentsView({required this.data});

  final ServantAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StudentListCard(
          title: l10n.servantAnalyticsMetricTopPerformers,
          subtitle: l10n.servantAnalyticsTopPerformersSubtitle,
          icon: Icons.emoji_events_rounded,
          iconColor: Colors.green.shade700,
          headerGradient: LinearGradient(
            colors: [
              Colors.green.shade50,
              Colors.green.shade100.withAlpha(102),
            ],
          ),
          borderColor: Colors.green.shade100,
          rows: [
            for (var i = 0; i < data.topPerformers.length; i++)
              _StudentRow(
                index: i,
                name: data.topPerformers[i].name,
                gradeName: data.topPerformers[i].gradeName,
                value: '${data.topPerformers[i].average}%',
                valueColor: Colors.green.shade700,
                indexStyle: _IndexStyle.forRank(i),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (data.atRiskStudents.isNotEmpty)
          _StudentListCard(
            title: l10n.servantAnalyticsStudentsNeedingSupportTitle,
            subtitle: l10n.servantAnalyticsStudentsNeedingSupportSubtitle,
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.amber.shade800,
            headerGradient: LinearGradient(
              colors: [
                Colors.amber.shade50,
                Colors.amber.shade100.withAlpha(89),
              ],
            ),
            borderColor: Colors.amber.shade100,
            rows: [
              for (final s in data.atRiskStudents)
                _StudentRow(
                  index: null,
                  name: s.name,
                  gradeName: s.gradeName,
                  value: '${s.average}%',
                  valueColor: Colors.amber.shade800,
                  subValue: l10n.servantAnalyticsNeedsHelp,
                ),
            ],
          ),
        if (data.atRiskStudents.isNotEmpty) const SizedBox(height: 16),
        if (data.studentsWithMissing.isNotEmpty)
          _StudentListCard(
            title: l10n.servantAnalyticsIncompleteAssessmentsTitle,
            subtitle: l10n.servantAnalyticsIncompleteAssessmentsSubtitle,
            icon: Icons.menu_book_rounded,
            iconColor: Colors.red.shade700,
            headerGradient: LinearGradient(
              colors: [Colors.red.shade50, Colors.red.shade100.withAlpha(89)],
            ),
            borderColor: Colors.red.shade100,
            rows: [
              for (final s in data.studentsWithMissing.take(10))
                _StudentRow(
                  index: null,
                  name: s.name,
                  gradeName: s.gradeName,
                  value: '${s.missingSubjectCount}',
                  valueColor: Colors.red.shade700,
                  subValue: l10n.servantAnalyticsSubjectsLabel(
                    s.missingSubjectCount,
                  ),
                ),
            ],
            footer: data.studentsWithMissing.length > 10
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                    child: Text(
                      l10n.servantAnalyticsAndMore(
                        data.studentsWithMissing.length - 10,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}

class _StudentListCard extends StatelessWidget {
  const _StudentListCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.headerGradient,
    required this.borderColor,
    required this.rows,
    this.footer,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Gradient headerGradient;
  final Color borderColor;
  final List<Widget> rows;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14374151),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: headerGradient,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.servantAnalyticsNoStudentsToDisplay,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            else
              ...(() {
                final children = rows.expand((w) sync* {
                  yield w;
                  yield const Divider(height: 1, color: Color(0xFFF1F5F9));
                }).toList();
                if (children.isNotEmpty) {
                  children.removeLast();
                }
                return children;
              })(),
            ?footer,
          ],
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.index,
    required this.name,
    required this.gradeName,
    required this.value,
    required this.valueColor,
    this.subValue,
    this.indexStyle,
  });

  final int? index;
  final String name;
  final String gradeName;
  final String value;
  final Color valueColor;
  final String? subValue;
  final _IndexStyle? indexStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (index != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: indexStyle?.background ?? const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index! + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: indexStyle?.foreground ?? const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  gradeName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                ),
              ),
              if (subValue != null)
                Text(
                  subValue!,
                  style: TextStyle(fontSize: 12, color: valueColor),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndexStyle {
  const _IndexStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  static _IndexStyle forRank(int index) {
    if (index == 0) {
      return _IndexStyle(
        background: Colors.amber.shade100,
        foreground: Colors.amber.shade900,
      );
    }
    if (index == 1) {
      return _IndexStyle(
        background: const Color(0xFFE2E8F0),
        foreground: const Color(0xFF334155),
      );
    }
    if (index == 2) {
      return _IndexStyle(
        background: Colors.orange.shade100,
        foreground: Colors.orange.shade900,
      );
    }

    return const _IndexStyle(
      background: Color(0xFFF1F5F9),
      foreground: Color(0xFF475569),
    );
  }
}
