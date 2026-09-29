import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/google_sheets_service.dart';

/// Admin Analytics & Reports Widget (Phase 15).
/// Contains four main analytics using real backend data:
/// 1. Most Demanded Skills (Bar Chart)
/// 2. Student Readiness Distribution (Pie Chart / Bar Chart)
/// 3. Top Recommended Jobs (Bar Chart + Compact List)
/// 4. Placement Trends Charts (Line Chart)
class AnalyticsReportsWidget extends StatefulWidget {
  const AnalyticsReportsWidget({super.key});

  @override
  State<AnalyticsReportsWidget> createState() => _AnalyticsReportsWidgetState();
}

class _AnalyticsReportsWidgetState extends State<AnalyticsReportsWidget> {
  // 1. Most Demanded Skills
  List<Map<String, dynamic>> _demandedSkills = [];
  bool _loadingSkills = true;
  String? _skillsError;

  // 2. Readiness Distribution
  List<Map<String, dynamic>> _readinessCategories = [];
  bool _loadingReadiness = true;
  String? _readinessError;
  bool _hasReadinessData = false;

  // 3. Top Recommended Jobs
  List<Map<String, dynamic>> _topRecommendedJobs = [];
  bool _loadingRecommended = true;
  String? _recommendedError;

  // 4. Placement Trends
  List<Map<String, dynamic>> _placementTrends = [];
  bool _loadingTrends = true;
  String? _trendsError;

  @override
  void initState() {
    super.initState();
    _loadAllAnalytics();
  }

  Future<void> _loadAllAnalytics() async {
    await Future.wait([
      _fetchMostDemandedSkills(),
      _fetchReadinessDistribution(),
      _fetchTopRecommendedJobs(),
      _fetchPlacementTrends(),
    ]);
  }

  Future<void> _fetchMostDemandedSkills() async {
    if (!mounted) return;
    setState(() {
      _loadingSkills = true;
      _skillsError = null;
    });
    try {
      final res = await GoogleSheetsService().getMostDemandedSkills();
      if (!mounted) return;
      if (res['success'] == true && res['skills'] is List) {
        final List raw = res['skills'] as List;
        setState(() {
          _demandedSkills = raw
              .map((e) => Map<String, dynamic>.from(e is Map ? e : {}))
              .toList();
          _loadingSkills = false;
        });
      } else {
        setState(() {
          _demandedSkills = [];
          _loadingSkills = false;
          _skillsError = res['message']?.toString() ?? 'Failed to load skills.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _demandedSkills = [];
          _loadingSkills = false;
          _skillsError = 'Error loading skills data.';
        });
      }
    }
  }

  Future<void> _fetchReadinessDistribution() async {
    if (!mounted) return;
    setState(() {
      _loadingReadiness = true;
      _readinessError = null;
      _hasReadinessData = false;
    });
    try {
      final res = await GoogleSheetsService().getReadinessDistribution();
      if (!mounted) return;

      if (res['success'] == true) {
        int? safeInt(dynamic val) {
          if (val is int) return val;
          if (val is num) return val.toInt();
          if (val != null && val.toString().trim().isNotEmpty) {
            return int.tryParse(val.toString().trim());
          }
          return null;
        }

        int? ready;
        int? almostReady;
        int? needsImp;

        // Check top-level keys
        ready = safeInt(res['ready']);
        almostReady = safeInt(res['almostReady']);
        needsImp = safeInt(res['needsImprovement']);

        // Check response["distribution"] OR response["readinessDistribution"]
        final dist = res['distribution'] ?? res['readinessDistribution'];
        if (dist is Map) {
          ready ??= safeInt(dist['ready']);
          almostReady ??= safeInt(dist['almostReady']);
          needsImp ??= safeInt(dist['needsImprovement']);
        }

        // Check list format under categories, distribution, or readinessDistribution
        final List? listData = (dist is List)
            ? dist
            : (res['categories'] is List ? res['categories'] as List : null);

        if (listData != null) {
          for (var item in listData) {
            if (item is Map) {
              final catName = (item['category'] ?? item['name'] ?? item['label'] ?? '')
                  .toString()
                  .toLowerCase();
              final count = safeInt(item['count'] ?? item['value'] ?? item['total']);
              if (count != null) {
                if (catName.contains('ready') && !catName.contains('almost')) {
                  ready = (ready ?? 0) + count;
                } else if (catName.contains('almost')) {
                  almostReady = (almostReady ?? 0) + count;
                } else if (catName.contains('need') || catName.contains('improvement')) {
                  needsImp = (needsImp ?? 0) + count;
                }
              }
            }
          }
        }

        final bool hasUsableObject = res.containsKey('ready') ||
            res.containsKey('almostReady') ||
            res.containsKey('needsImprovement') ||
            res.containsKey('totalStudents') ||
            res.containsKey('distribution') ||
            res.containsKey('readinessDistribution') ||
            res.containsKey('categories') ||
            (ready != null || almostReady != null || needsImp != null);

        if (hasUsableObject) {
          ready ??= 0;
          almostReady ??= 0;
          needsImp ??= 0;

          setState(() {
            _readinessCategories = [
              {'category': 'Ready', 'count': ready},
              {'category': 'Almost Ready', 'count': almostReady},
              {'category': 'Needs Improvement', 'count': needsImp},
            ];
            _hasReadinessData = true;
            _loadingReadiness = false;
          });
        } else {
          setState(() {
            _readinessCategories = [];
            _hasReadinessData = false;
            _loadingReadiness = false;
            _readinessError = null;
          });
        }
      } else {
        setState(() {
          _readinessCategories = [];
          _hasReadinessData = false;
          _loadingReadiness = false;
          _readinessError = res['message']?.toString() ?? 'Failed to load readiness.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _readinessCategories = [];
          _hasReadinessData = false;
          _loadingReadiness = false;
          _readinessError = 'Error loading readiness distribution.';
        });
      }
    }
  }

  Future<void> _fetchTopRecommendedJobs() async {
    if (!mounted) return;
    setState(() {
      _loadingRecommended = true;
      _recommendedError = null;
    });
    try {
      final res = await GoogleSheetsService().getTopRecommendedJobs();
      if (!mounted) return;
      final jobsList = res['recommendedJobs'] ?? res['jobs'];
      if (res['success'] == true && jobsList is List) {
        setState(() {
          _topRecommendedJobs = jobsList
              .map((e) => Map<String, dynamic>.from(e is Map ? e : {}))
              .toList();
          _loadingRecommended = false;
        });
      } else {
        setState(() {
          _topRecommendedJobs = [];
          _loadingRecommended = false;
          _recommendedError = res['message']?.toString() ?? 'Failed to load recommendations.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _topRecommendedJobs = [];
          _loadingRecommended = false;
          _recommendedError = 'Error loading recommended jobs.';
        });
      }
    }
  }

  Future<void> _fetchPlacementTrends() async {
    if (!mounted) return;
    setState(() {
      _loadingTrends = true;
      _trendsError = null;
    });
    try {
      final res = await GoogleSheetsService().getPlacementTrends();
      if (!mounted) return;
      if (res['success'] == true && res['trends'] is List) {
        final List raw = res['trends'] as List;
        setState(() {
          _placementTrends = raw
              .map((e) => Map<String, dynamic>.from(e is Map ? e : {}))
              .toList();
          _loadingTrends = false;
        });
      } else {
        setState(() {
          _placementTrends = [];
          _loadingTrends = false;
          _trendsError = res['message']?.toString() ?? 'Failed to load trends.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _placementTrends = [];
          _loadingTrends = false;
          _trendsError = 'Error loading placement trends.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Analytics & Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              tooltip: 'Refresh Analytics Data',
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
              onPressed: _loadAllAnalytics,
            ),
          ],
        ),
        const Text(
          'Real-time campus placement analytics powered by Google Sheets data.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // 1. Most Demanded Skills
        _buildSectionCard(
          title: '1. Most Demanded Skills',
          subtitle: 'Skills required across available active job postings',
          icon: Icons.bar_chart_rounded,
          isLoading: _loadingSkills,
          errorMessage: _skillsError,
          isEmpty: _demandedSkills.isEmpty,
          emptyMessage: 'No skill data available from current job postings.',
          child: _buildDemandedSkillsChart(),
        ),

        const SizedBox(height: 20),

        // 2. Student Readiness Distribution
        _buildSectionCard(
          title: '2. Student Readiness Distribution',
          subtitle: 'Student breakdown based on Phase 12 Placement Readiness criteria',
          icon: Icons.pie_chart_rounded,
          isLoading: _loadingReadiness,
          errorMessage: _readinessError,
          isEmpty: !_hasReadinessData,
          emptyMessage: 'No student readiness statistics available.',
          child: _buildReadinessDistributionChart(),
        ),

        const SizedBox(height: 20),

        // 3. Top Recommended Jobs
        _buildSectionCard(
          title: '3. Top Recommended Jobs',
          subtitle: 'Jobs recommended most frequently to registered students',
          icon: Icons.recommend_rounded,
          isLoading: _loadingRecommended,
          errorMessage: _recommendedError,
          isEmpty: _topRecommendedJobs.isEmpty,
          emptyMessage: 'No job recommendation data available.',
          child: _buildTopRecommendedJobsSection(),
        ),

        const SizedBox(height: 20),

        // 4. Placement Trends Charts
        _buildSectionCard(
          title: '4. Placement Trends',
          subtitle: 'Monthly tracking of applications, shortlists, and placements',
          icon: Icons.show_chart_rounded,
          isLoading: _loadingTrends,
          errorMessage: _trendsError,
          isEmpty: _placementTrends.isEmpty,
          emptyMessage: 'Insufficient date data available to plot placement trends.',
          child: _buildPlacementTrendsChart(),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isLoading,
    required String? errorMessage,
    required bool isEmpty,
    required String emptyMessage,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 32),
                    const SizedBox(height: 6),
                    Text(
                      errorMessage,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined, color: AppColors.textSecondary, size: 36),
                    const SizedBox(height: 6),
                    Text(
                      emptyMessage,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            child,
        ],
      ),
    );
  }

  // --- 1. MOST DEMANDED SKILLS BAR CHART ---
  Widget _buildDemandedSkillsChart() {
    final topSkills = _demandedSkills.take(7).toList();
    final double maxCount = topSkills.fold<double>(
      0,
      (max, item) {
        final c = (item['count'] ?? 0) is num ? (item['count'] as num).toDouble() : 0.0;
        return c > max ? c : max;
      },
    );

    final double maxY = maxCount > 0 ? (maxCount + 2) : 5.0;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final skill = topSkills[groupIndex]['skill'] ?? '';
                    return BarTooltipItem(
                      '$skill\n${rod.toY.toInt()} Jobs',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: (maxY / 4).clamp(1.0, 10.0),
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < topSkills.length) {
                        final label = (topSkills[idx]['skill'] ?? '').toString();
                        final display = label.length > 7 ? '${label.substring(0, 6)}..' : label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            display,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.cardBorder.withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(topSkills.length, (index) {
                final count = ((topSkills[index]['count'] ?? 0) as num).toDouble();
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: count,
                      color: AppColors.primary,
                      width: 18,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: topSkills.map((item) {
            return Chip(
              backgroundColor: AppColors.iconChipBg,
              side: BorderSide.none,
              label: Text(
                '${item['skill']}: ${item['count']} jobs',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- 2. STUDENT READINESS DISTRIBUTION PIE CHART ---
  Widget _buildReadinessDistributionChart() {
    int readyCount = 0;
    int almostReadyCount = 0;
    int needsImpCount = 0;

    for (var cat in _readinessCategories) {
      final name = (cat['category'] ?? '').toString().toLowerCase();
      final count = (cat['count'] ?? 0) is num ? (cat['count'] as num).toInt() : 0;
      if (name.contains('ready') && !name.contains('almost')) {
        readyCount += count;
      } else if (name.contains('almost')) {
        almostReadyCount += count;
      } else {
        needsImpCount += count;
      }
    }

    final int total = readyCount + almostReadyCount + needsImpCount;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 36,
              sections: total > 0
                  ? [
                      if (readyCount > 0)
                        PieChartSectionData(
                          color: const Color(0xFF10B981),
                          value: readyCount.toDouble(),
                          title: '${((readyCount / total) * 100).toStringAsFixed(0)}%',
                          radius: 45,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      if (almostReadyCount > 0)
                        PieChartSectionData(
                          color: const Color(0xFFF59E0B),
                          value: almostReadyCount.toDouble(),
                          title: '${((almostReadyCount / total) * 100).toStringAsFixed(0)}%',
                          radius: 45,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      if (needsImpCount > 0)
                        PieChartSectionData(
                          color: const Color(0xFFEF4444),
                          value: needsImpCount.toDouble(),
                          title: '${((needsImpCount / total) * 100).toStringAsFixed(0)}%',
                          radius: 45,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                    ]
                  : [
                      PieChartSectionData(
                        color: AppColors.cardBorder,
                        value: 1,
                        title: '0',
                        radius: 45,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Ready', readyCount, const Color(0xFF10B981)),
            _buildLegendItem('Almost Ready', almostReadyCount, const Color(0xFFF59E0B)),
            _buildLegendItem('Needs Improvement', needsImpCount, const Color(0xFFEF4444)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $count',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  // --- 3. TOP RECOMMENDED JOBS BAR CHART & LIST ---
  Widget _buildTopRecommendedJobsSection() {
    final topJobs = _topRecommendedJobs.take(5).toList();
    final double maxRec = topJobs.fold<double>(
      0,
      (max, item) {
        final c = (item['recommendationCount'] ?? 0) is num ? (item['recommendationCount'] as num).toDouble() : 0.0;
        return c > max ? c : max;
      },
    );

    final double maxY = maxRec > 0 ? (maxRec + 2) : 5.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = topJobs[groupIndex];
                    return BarTooltipItem(
                      '${item['jobTitle'] ?? ''}\n${rod.toY.toInt()} Recommendations',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: (maxY / 4).clamp(1.0, 10.0),
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < topJobs.length) {
                        final comp = (topJobs[idx]['company'] ?? topJobs[idx]['jobTitle'] ?? '').toString();
                        final display = comp.length > 7 ? '${comp.substring(0, 6)}..' : comp;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            display,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.cardBorder.withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(topJobs.length, (index) {
                final rec = ((topJobs[index]['recommendationCount'] ?? 0) as num).toDouble();
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: rec,
                      color: const Color(0xFF6366F1),
                      width: 18,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.cardBorder),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topJobs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final job = topJobs[index];
            final title = (job['jobTitle'] ?? job['title'] ?? 'Job Opening').toString();
            final company = (job['company'] ?? '').toString();
            final recCount = job['recommendationCount'] ?? 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (company.isNotEmpty)
                          Text(
                            company,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$recCount matches',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --- 4. PLACEMENT TRENDS LINE CHART ---
  Widget _buildPlacementTrendsChart() {
    if (_placementTrends.isEmpty) {
      return const SizedBox.shrink();
    }

    final double maxVal = _placementTrends.fold<double>(
      0,
      (max, item) {
        final app = ((item['applications'] ?? 0) as num).toDouble();
        return app > max ? app : max;
      },
    );

    final double maxY = maxVal > 0 ? (maxVal + 2) : 5.0;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final month = _placementTrends[spot.spotIndex]['month'] ?? '';
                      String label = 'Apps';
                      if (spot.barIndex == 1) label = 'Shortlisted';
                      if (spot.barIndex == 2) label = 'Placed';
                      return LineTooltipItem(
                        '$month\n$label: ${spot.y.toInt()}',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.cardBorder.withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: (maxY / 4).clamp(1.0, 10.0),
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < _placementTrends.length) {
                        final m = (_placementTrends[idx]['month'] ?? '').toString();
                        final display = m.length > 6 ? m.substring(0, 6) : m;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            display,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Line 1: Applications
                LineChartBarData(
                  spots: List.generate(_placementTrends.length, (i) {
                    final app = ((_placementTrends[i]['applications'] ?? 0) as num).toDouble();
                    return FlSpot(i.toDouble(), app);
                  }),
                  isCurved: true,
                  color: const Color(0xFF6366F1),
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                // Line 2: Shortlisted
                LineChartBarData(
                  spots: List.generate(_placementTrends.length, (i) {
                    final sl = ((_placementTrends[i]['shortlisted'] ?? 0) as num).toDouble();
                    return FlSpot(i.toDouble(), sl);
                  }),
                  isCurved: true,
                  color: const Color(0xFFF59E0B),
                  barWidth: 2,
                  dotData: const FlDotData(show: true),
                ),
                // Line 3: Selected
                LineChartBarData(
                  spots: List.generate(_placementTrends.length, (i) {
                    final sel = ((_placementTrends[i]['selected'] ?? 0) as num).toDouble();
                    return FlSpot(i.toDouble(), sel);
                  }),
                  isCurved: true,
                  color: const Color(0xFF10B981),
                  barWidth: 2,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Applications', _placementTrends.fold(0, (sum, e) => sum + ((e['applications'] ?? 0) as num).toInt()), const Color(0xFF6366F1)),
            _buildLegendItem('Shortlisted', _placementTrends.fold(0, (sum, e) => sum + ((e['shortlisted'] ?? 0) as num).toInt()), const Color(0xFFF59E0B)),
            _buildLegendItem('Selected', _placementTrends.fold(0, (sum, e) => sum + ((e['selected'] ?? 0) as num).toInt()), const Color(0xFF10B981)),
          ],
        ),
      ],
    );
  }
}
