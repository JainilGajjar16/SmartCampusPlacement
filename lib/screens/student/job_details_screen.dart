import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_snackbar.dart';
import '../../main.dart';
import '../../models/job.dart';
import '../../models/user_session.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/theme_toggle_button.dart';

/// Screen displaying complete details for a selected job posting.
class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final _apiService = GoogleSheetsService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  Job? _job;

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  void _navigateToSkillGapAnalysis() {
    if (_job == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.skillGapAnalysis,
      arguments: {'job': _job},
    );
  }

  Future<void> _fetchJobDetails() async {
    if (_isLoading && _job != null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _apiService.getJobDetails(widget.jobId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response['success'] == true && response['job'] is Job) {
        _job = response['job'] as Job;
      } else {
        _errorMessage = response['message']?.toString() ?? AppStrings.jobNotFound;
      }
    });
  }

  Future<void> _onApplyPressed() async {
    if (_isSubmitting) return;
    final userId = UserSession().userId;
    if (userId == null || userId.isEmpty) {
      AppSnackBar.show(
        context,
        message: AppStrings.errSessionRequired,
        isError: true,
      );
      return;
    }

    if (_job != null &&
        (_job!.isClosed || _job!.status.toLowerCase() != 'active')) {
      final msg = _job!.isClosed
          ? 'Maximum number of hiring for this job has been reached. Applications are closed.'
          : 'This job is currently inactive and not accepting applications.';
      AppSnackBar.show(
        context,
        message: msg,
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final response = await _apiService.applyJob(
      userId: userId,
      jobId: widget.jobId,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (response['success'] == true) {
      AppSnackBar.show(
        context,
        message: response['message']?.toString() ??
            AppStrings.applicationSubmittedSuccess,
      );
      // Refresh job details so the updated status is reflected
      _fetchJobDetails();
    } else {
      final backendMessage = response['message']?.toString();
      AppSnackBar.show(
        context,
        message: (backendMessage != null && backendMessage.isNotEmpty)
            ? backendMessage
            : AppStrings.alreadyAppliedForJob,
        isError: true,
      );
      // Refresh job details in case job has reached maximum hiring limit
      _fetchJobDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.getTextPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.jobDetailsTitle,
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null || _job == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: Colors.amber,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? AppStrings.jobNotFound,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: AppStrings.retry,
                icon: Icons.refresh_rounded,
                onPressed: _fetchJobDetails,
              ),
            ],
          ),
        ),
      );
    }

    final job = _job!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Job Title & Company Banner Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroCardGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.business_center_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  job.company,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (job.jobId.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Job ID: ${job.jobId}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Key Job Attributes Grid
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (job.location.isNotEmpty)
                      _InfoTile(
                        icon: Icons.location_on_rounded,
                        label: AppStrings.locationLabel,
                        value: job.location,
                        iconColor: const Color(0xFFEF4444),
                      ),
                    if (job.jobType.isNotEmpty)
                      _InfoTile(
                        icon: Icons.work_rounded,
                        label: AppStrings.jobTypeLabel,
                        value: job.jobType,
                        iconColor: AppColors.primary,
                      ),
                    if (job.salary.isNotEmpty)
                      _InfoTile(
                        icon: Icons.payments_rounded,
                        label: AppStrings.salaryOrStipend,
                        value: job.salary,
                        iconColor: const Color(0xFF10B981),
                      ),
                    if (job.postedDate.isNotEmpty)
                      _InfoTile(
                        icon: Icons.calendar_today_rounded,
                        label: AppStrings.postedDateLabel,
                        value: job.postedDate,
                        iconColor: const Color(0xFF8B5CF6),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Required Skills Section
                if (job.skills.isNotEmpty) ...[
                  _SectionHeader(
                    title: AppStrings.skillsRequired,
                    icon: Icons.psychology_rounded,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job.skills
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .map((skill) => Chip(
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
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Job-Aware Skill Gap Analysis Action Banner
                  InkWell(
                    onTap: _navigateToSkillGapAnalysis,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.12),
                            const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.psychology_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  AppStrings.analyzeSkillGap,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  AppStrings.skillGapAnalysisSubtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Job Description Section
                _SectionHeader(
                  title: AppStrings.jobDescription,
                  icon: Icons.description_rounded,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    job.description.isNotEmpty
                        ? job.description
                        : 'No detailed description provided.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Bottom CTA Application Button
        Container(
          padding: const EdgeInsets.all(20.0),
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
          child: CustomButton(
            text: (_job != null &&
                    (_job!.isClosed ||
                        _job!.status.toLowerCase() != 'active'))
                ? (_job!.isClosed ? 'Applications Closed' : 'Job Inactive')
                : AppStrings.applyForJob,
            icon: (_job != null &&
                    (_job!.isClosed ||
                        _job!.status.toLowerCase() != 'active'))
                ? Icons.block_rounded
                : Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: (_isSubmitting ||
                    (_job != null &&
                        (_job!.isClosed ||
                            _job!.status.toLowerCase() != 'active')))
                ? null
                : _onApplyPressed,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final double maxTileWidth = MediaQuery.of(context).size.width - 48;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxTileWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
