import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/skill_gap_analyzer.dart';
import '../../main.dart';
import '../../models/job.dart';
import '../../models/skill_gap_result.dart';
import '../../models/student_profile.dart';
import '../../models/user_session.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/theme_toggle_button.dart';

/// Screen displaying the Job-Aware Skill Gap Analysis report comparing
/// a target job's required skills against a student's profile competencies.
class SkillGapAnalysisScreen extends StatefulWidget {
  final Job job;
  final StudentProfile? initialProfile;

  const SkillGapAnalysisScreen({
    super.key,
    required this.job,
    this.initialProfile,
  });

  @override
  State<SkillGapAnalysisScreen> createState() => _SkillGapAnalysisScreenState();
}

class _SkillGapAnalysisScreenState extends State<SkillGapAnalysisScreen> {
  final _apiService = GoogleSheetsService();

  bool _isLoadingProfile = false;
  bool _isSubmittingApp = false;
  String? _errorMessage;

  StudentProfile? _profile;
  SkillGapResult? _analysisResult;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _profile = widget.initialProfile;
      _runAnalysis();
    } else {
      _fetchProfileAndAnalyze();
    }
  }

  Future<void> _fetchProfileAndAnalyze() async {
    final userId = UserSession().userId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _errorMessage = AppStrings.errSessionRequired;
      });
      return;
    }

    if (_isLoadingProfile) return;

    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });

    final response = await _apiService.getStudentProfile(userId: userId);

    if (!mounted) return;

    setState(() {
      _isLoadingProfile = false;
      if (response['success'] == true) {
        _profile = StudentProfile.fromJson(response);
        _runAnalysis();
      } else {
        // Fallback to minimal profile if not yet created in backend
        _profile = StudentProfile(
          userId: userId,
          skills: '',
        );
        _runAnalysis();
      }
    });
  }

  void _runAnalysis() {
    if (_profile == null) return;
    setState(() {
      _analysisResult = SkillGapAnalyzer.analyze(
        job: widget.job,
        profile: _profile!,
      );
    });
  }

  Future<void> _onApplyPressed() async {
    if (_isSubmittingApp) return;

    final userId = UserSession().userId;
    if (userId == null || userId.isEmpty) {
      AppSnackBar.show(
        context,
        message: AppStrings.errSessionRequired,
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmittingApp = true;
    });

    final response = await _apiService.applyJob(
      userId: userId,
      jobId: widget.job.jobId,
    );

    if (!mounted) return;

    setState(() {
      _isSubmittingApp = false;
    });

    if (response['success'] == true) {
      AppSnackBar.show(
        context,
        message: response['message']?.toString() ??
            AppStrings.applicationSubmittedSuccess,
      );
    } else {
      AppSnackBar.show(
        context,
        message: response['message']?.toString() ??
            AppStrings.alreadyAppliedForJob,
        isError: true,
      );
    }
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, AppRoutes.profile).then((_) {
      _fetchProfileAndAnalyze();
    });
  }

  Color _getScoreColor(double score) {
    if (score >= 80.0) return const Color(0xFF10B981); // Green
    if (score >= 50.0) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red/Orange
  }

  String _getScoreBadgeText(double score) {
    if (score >= 80.0) return 'Strong Job Match';
    if (score >= 50.0) return 'Moderate Match - Minor Gaps';
    return 'Target Skills Required';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.getTextPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.skillGapAnalysisTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        actions: [
          ThemeToggleButton(themeProvider: globalThemeProvider),
        ],
      ),
      body: SafeArea(
        child: FadeSlideTransition(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingProfile) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Analyzing job requirements & student skills...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: AppStrings.retry,
                onPressed: _fetchProfileAndAnalyze,
              ),
            ],
          ),
        ),
      );
    }

    final result = _analysisResult;
    final profileSkillsEmpty = _profile?.skills.trim().isEmpty ?? true;

    if (result == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Job & Score Overview Card
                _buildHeaderScoreCard(result),
                const SizedBox(height: 20),

                // Empty Profile State Warning
                if (profileSkillsEmpty) ...[
                  _buildEmptyProfileCard(),
                  const SizedBox(height: 20),
                ],

                // 2. Matched Skills Section
                if (result.matchedSkills.isNotEmpty) ...[
                  _buildSectionTitle(
                    title: AppStrings.matchedSkillsLabel,
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.matchedSkills.map((skill) {
                      return Chip(
                        avatar: const Icon(Icons.check_rounded,
                            size: 14, color: Color(0xFF059669)),
                        label: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                        backgroundColor: const Color(0xFFD1FAE5),
                        side: const BorderSide(color: Color(0xFFA7F3D0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Missing Skills Section
                if (result.missingSkills.isNotEmpty) ...[
                  _buildSectionTitle(
                    title: AppStrings.missingSkillsLabel,
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.missingSkills.map((skill) {
                      return Chip(
                        avatar: const Icon(Icons.add_rounded,
                            size: 14, color: Color(0xFFD97706)),
                        label: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        backgroundColor: const Color(0xFFFEF3C7),
                        side: const BorderSide(color: Color(0xFFFDE68A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. Additional Student Profile Competencies
                if (result.extraSkills.isNotEmpty) ...[
                  _buildSectionTitle(
                    title: AppStrings.extraSkillsLabel,
                    icon: Icons.stars_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.extraSkills.map((skill) {
                      return Chip(
                        avatar: const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.primary),
                        label: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // 5. Recommended Learning Roadmaps
                if (result.recommendations.isNotEmpty) ...[
                  _buildSectionTitle(
                    title: AppStrings.recommendedLearningPath,
                    icon: Icons.school_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 10),
                  ...result.recommendations.map((rec) => _buildRecommendationCard(rec)),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),

        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToProfile,
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: AppStrings.applyForJob,
                  icon: Icons.send_rounded,
                  isLoading: _isSubmittingApp,
                  onPressed: _isSubmittingApp ? null : _onApplyPressed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderScoreCard(SkillGapResult result) {
    final scoreColor = _getScoreColor(result.matchPercentage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.jobTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.company,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Circular Score Gauge
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: result.matchPercentage / 100,
                      strokeWidth: 6,
                      backgroundColor: scoreColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                  Text(
                    '${result.matchPercentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getScoreBadgeText(result.matchPercentage),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
              Text(
                'Matched ${result.matchedSkills.length} of ${result.totalRequiredSkills} Skills',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_alt_rounded,
              color: Color(0xFFD97706), size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  AppStrings.noSkillsInProfileTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  AppStrings.noSkillsInProfileSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(SkillRecommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getCardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Target Skill: ${rec.skillName}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Key Topics
          Text(
            'Key Concepts to Learn:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          ...rec.keyTopics.map((topic) => Padding(
                padding: const EdgeInsets.only(bottom: 3.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        topic,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.getTextPrimary(context)),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 10),

          // Learning Resource & Project Idea
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getInputBg(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded,
                        size: 14, color: AppColors.getTextSecondary(context)),
                    const SizedBox(width: 6),
                    Text(
                      'Resources:',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextSecondary(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  rec.learningResources,
                  style: TextStyle(
                      fontSize: 11, color: AppColors.getTextPrimary(context)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.rocket_launch_rounded,
                        size: 14, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Text(
                      'Portfolio Project Idea:',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  rec.projectIdea,
                  style: TextStyle(
                      fontSize: 11, color: AppColors.getTextPrimary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
