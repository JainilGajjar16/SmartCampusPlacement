import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/placement_readiness_calculator.dart';
import '../../models/job.dart';
import '../../models/student_profile.dart';
import '../../models/user_session.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';
import '../../widgets/custom_button.dart';

/// Screen displaying Student Placement Readiness & Job Recommendation Insights (Phase 12).
class PlacementReadinessScreen extends StatefulWidget {
  const PlacementReadinessScreen({super.key});

  @override
  State<PlacementReadinessScreen> createState() =>
      _PlacementReadinessScreenState();
}

class _PlacementReadinessScreenState
    extends State<PlacementReadinessScreen> {
  final _apiService = GoogleSheetsService();

  bool _isLoading = true;
  String? _errorMessage;
  StudentProfile _profile = const StudentProfile(userId: '');
  List<Job> _jobs = [];
  String _selectedFilter = AppStrings.filterAllMatches;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading && _jobs.isNotEmpty) return;

    final userId = UserSession().userId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppStrings.errSessionRequired;
      });
      return;
    }

    if (_jobs.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      final profileFuture = _apiService.getStudentProfile(userId: userId);
      final jobsFuture = _apiService.getJobs();

      final results = await Future.wait([profileFuture, jobsFuture]);

      if (!mounted) return;

      final profileRes = results[0];
      final jobsRes = results[1];

      StudentProfile profile = StudentProfile(userId: userId);
      if (profileRes['success'] == true) {
        profile = StudentProfile.fromJson(profileRes);
      }

      List<Job> jobs = [];
      if (jobsRes['success'] == true && jobsRes['jobs'] is List<Job>) {
        jobs = jobsRes['jobs'] as List<Job>;
      }

      setState(() {
        _isLoading = false;
        _profile = profile;
        _jobs = jobs;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_jobs.isEmpty) {
          _errorMessage = 'Failed to load readiness data. Please try again.';
        } else {
          AppSnackBar.show(
            context,
            message: 'Failed to refresh readiness data.',
          );
        }
      });
    }
  }

  List<JobRecommendationItem> get _filteredRecommendations {
    final sorted = PlacementReadinessCalculator.sortJobsByRecommendation(
      _jobs,
      _profile,
    );

    if (_selectedFilter == AppStrings.filterStrongMatch) {
      return sorted.where((item) => item.matchPercentage >= 80.0).toList();
    } else if (_selectedFilter == AppStrings.filterGoodMatch) {
      return sorted
          .where((item) => item.matchPercentage >= 50.0 && item.matchPercentage < 80.0)
          .toList();
    } else if (_selectedFilter == AppStrings.filterNeedsImprovement) {
      return sorted.where((item) => item.matchPercentage < 50.0).toList();
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          AppStrings.placementReadinessTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: AppStrings.retry,
                    icon: Icons.refresh_rounded,
                    onPressed: _loadData,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final overallReadiness =
        PlacementReadinessCalculator.calculateOverallReadiness(_profile, _jobs);
    final profileCompleteness =
        PlacementReadinessCalculator.calculateProfileCompleteness(_profile);
    final marketAlignment =
        PlacementReadinessCalculator.calculateMarketAlignment(_jobs, _profile);

    final allRecommendations =
        PlacementReadinessCalculator.sortJobsByRecommendation(_jobs, _profile);

    final strongCount =
        allRecommendations.where((i) => i.matchPercentage >= 80.0).length;
    final goodCount = allRecommendations
        .where((i) => i.matchPercentage >= 50.0 && i.matchPercentage < 80.0)
        .length;
    final improvementCount =
        allRecommendations.where((i) => i.matchPercentage < 50.0).length;

    final topMissingSkills =
        PlacementReadinessCalculator.getMissingSkillsSummary(_jobs, _profile);

    final filteredList = _filteredRecommendations;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero Readiness Score Overview Card
          _buildHeroScoreCard(
            overallReadiness: overallReadiness,
            profileCompleteness: profileCompleteness,
            marketAlignment: marketAlignment,
          ),
          const SizedBox(height: 20),

          // 2. Placement Insights & Top Skills to Improve Summary Card
          _buildInsightsSummaryCard(
            strongCount: strongCount,
            goodCount: goodCount,
            improvementCount: improvementCount,
            topMissingSkills: topMissingSkills,
          ),
          const SizedBox(height: 24),

          // 3. Section Title & Filter Chips Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                AppStrings.recommendedJobsHeader,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: AppStrings.filterAllMatches,
                  count: allRecommendations.length,
                  isSelected: _selectedFilter == AppStrings.filterAllMatches,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: AppStrings.filterStrongMatch,
                  count: strongCount,
                  isSelected: _selectedFilter == AppStrings.filterStrongMatch,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: AppStrings.filterGoodMatch,
                  count: goodCount,
                  isSelected: _selectedFilter == AppStrings.filterGoodMatch,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: AppStrings.filterNeedsImprovement,
                  count: improvementCount,
                  isSelected: _selectedFilter == AppStrings.filterNeedsImprovement,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Recommended Jobs List OR Empty State
          if (filteredList.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.dashboard_customize_outlined,
                    size: 48,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No jobs matching selected filter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select a different filter chip to view available job match insights.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return _buildRecommendedJobCard(item);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroScoreCard({
    required double overallReadiness,
    required double profileCompleteness,
    required double marketAlignment,
  }) {
    final overallColor = overallReadiness >= 80.0
        ? const Color(0xFF10B981)
        : overallReadiness >= 50.0
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroCardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Placement Readiness Score',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Campus Career Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: overallColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: overallColor.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      color: overallColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$overallReadiness%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: overallColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // Sub-metrics breakdown row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: AppStrings.profileCompletenessLabel,
                  value: '$profileCompleteness%',
                  icon: Icons.person_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: AppStrings.marketAlignmentLabel,
                  value: '$marketAlignment%',
                  icon: Icons.fact_check_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSummaryCard({
    required int strongCount,
    required int goodCount,
    required int improvementCount,
    required List<MapEntry<String, int>> topMissingSkills,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                AppStrings.placementInsightsHeader,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Aggregate Match Pills
          Row(
            children: [
              Expanded(
                child: _buildCategoryPill(
                  label: AppStrings.strongMatchesLabel,
                  count: strongCount,
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFD1FAE5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryPill(
                  label: AppStrings.goodMatchesLabel,
                  count: goodCount,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryPill(
                  label: 'Needs Imp.',
                  count: improvementCount,
                  color: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEE2E2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Top Missing Skills Section
          if (topMissingSkills.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            const Text(
              AppStrings.topSkillsToImproveHeader,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: topMissingSkills.take(5).map((entry) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  label: Text(entry.key),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedJobCard(JobRecommendationItem item) {
    final match = item.matchPercentage;
    final matchColor = match >= 80.0
        ? const Color(0xFF059669)
        : match >= 50.0
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);

    final matchBgColor = match >= 80.0
        ? const Color(0xFFD1FAE5)
        : match >= 50.0
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFFEE2E2);

    final matchBorderColor = match >= 80.0
        ? const Color(0xFF34D399)
        : match >= 50.0
            ? const Color(0xFFFBBF24)
            : const Color(0xFFF87171);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: matchBorderColor.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title, Company, Match % Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: matchBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business_center_rounded,
                  color: matchColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.job.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.job.company,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: matchBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: matchBorderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      '$match%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: matchColor,
                      ),
                    ),
                    Text(
                      'Skill Match',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: matchColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Metadata Row
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              if (item.job.location.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      item.job.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              if (item.job.jobType.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.job.jobType,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (item.job.salary.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.job.salary,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),

          // Matched vs Missing Skills Overview
          if (item.matchedSkills.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 14, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Matched: ${item.matchedSkills.join(", ")}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          if (item.missingSkills.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.remove_circle_outline_rounded,
                    size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Missing: ${item.missingSkills.join(", ")}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
            const SizedBox(height: 8),
          ],

          // Button to Navigate to Skill Gap Analysis & Apply Flow
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.skillGapAnalysis,
                  arguments: {
                    'job': item.job,
                    'profile': _profile,
                  },
                );
              },
              icon: const Icon(Icons.analytics_outlined, size: 16),
              label: const Text(
                AppStrings.viewSkillGapAndApply,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
