import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/app_validators.dart';
import '../../main.dart';
import '../../models/student_profile.dart';
import '../../models/user_session.dart';
import '../../services/google_sheets_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/theme_toggle_button.dart';

/// Student Profile Screen matching exact design styling from screenshots (Images 4 & 5).
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = GoogleSheetsService();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _projectsController = TextEditingController();
  final _certificationsController = TextEditingController();

  bool _isLoadingProfile = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isNewProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    _projectsController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
      _isNewProfile = false;
    });

    final String userId = UserSession().userId ?? '';
    if (userId.isEmpty) {
      setState(() {
        _isLoadingProfile = false;
        _errorMessage = 'No active user session found. Please log in again.';
      });
      return;
    }

    final response = await _apiService.getStudentProfile(userId: userId);

    if (!mounted) return;

    if (response['success'] == true) {
      final profile = StudentProfile.fromJson(response);
      _populateFields(profile);
      if (profile.name.isNotEmpty) {
        UserSession().setSession(
          userId: userId,
          role: UserSession().role ?? 'Student',
          name: profile.name,
          email: profile.email.isNotEmpty ? profile.email : UserSession().email,
        );
      }
      setState(() {
        _isLoadingProfile = false;
      });
    } else {
      final String msg = response['message']?.toString() ?? '';
      if (msg.toLowerCase().contains('not found')) {
        // Profile does not exist yet for new user -> show clean empty form
        _populateFields(StudentProfile(
          userId: userId,
          name: UserSession().name ?? '',
          email: UserSession().email ?? '',
        ));
        setState(() {
          _isLoadingProfile = false;
          _isNewProfile = true;
        });
      } else {
        // Network or system error -> show error state with retry
        setState(() {
          _isLoadingProfile = false;
          _errorMessage = msg.isNotEmpty ? msg : AppStrings.apiServerError;
        });
      }
    }
  }

  void _populateFields(StudentProfile profile) {
    _fullNameController.text = profile.name;
    _emailController.text = profile.email;
    _mobileController.text = profile.mobile;
    _githubController.text = profile.github;
    _linkedinController.text = profile.linkedin;
    _educationController.text = profile.education;
    _skillsController.text = profile.skills;
    _projectsController.text = profile.projects;
    _certificationsController.text = profile.certifications;
  }

  Future<void> _onSavePressed() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      final String currentUserId = UserSession().userId ?? '';
      final profileToSave = StudentProfile(
        userId: currentUserId,
        name: _fullNameController.text,
        email: _emailController.text,
        mobile: _mobileController.text,
        github: _githubController.text,
        linkedin: _linkedinController.text,
        education: _educationController.text,
        skills: _skillsController.text,
        projects: _projectsController.text,
        certifications: _certificationsController.text,
      );

      final response = await _apiService.saveStudentProfile(profileToSave);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (response['success'] == true) {
        UserSession().setSession(
          userId: currentUserId,
          role: UserSession().role ?? 'Student',
          name: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
        );
        setState(() {
          _isNewProfile = false;
        });
        AppSnackBar.show(
          context,
          message: AppStrings.profileSavedSuccess,
        );
      } else {
        AppSnackBar.show(
          context,
          message: response['message']?.toString() ?? AppStrings.apiServerError,
          isError: true,
        );
      }
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
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.getTextPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.profileTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        actions: [
          ThemeToggleButton(themeProvider: globalThemeProvider),
        ],
        centerTitle: false,
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
              'Fetching student profile...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Colors.redAccent,
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
                width: 160,
                onPressed: _loadProfile,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Notice Banner for new profiles
                if (_isNewProfile) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.newProfileNotice,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Section 1: Personal Information
                _ProfileSectionCard(
                  title: AppStrings.sectionPersonalInfo,
                  icon: Icons.person_rounded,
                  children: [
                    CustomTextField(
                      controller: _fullNameController,
                      labelText: AppStrings.fullNameLabel,
                      hintText: AppStrings.fullNameHint,
                      prefixIcon: Icons.badge_rounded,
                      validator: AppValidators.validateFullName,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      labelText: AppStrings.emailLabel,
                      hintText: AppStrings.emailHint,
                      prefixIcon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: AppValidators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _mobileController,
                      labelText: AppStrings.mobileLabel,
                      hintText: AppStrings.mobileHint,
                      prefixIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          return AppValidators.validateMobile(val);
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 2: Professional Links
                _ProfileSectionCard(
                  title: AppStrings.sectionProfessionalLinks,
                  icon: Icons.link_rounded,
                  children: [
                    CustomTextField(
                      controller: _githubController,
                      labelText: AppStrings.githubLabel,
                      hintText: AppStrings.githubHint,
                      prefixIcon: Icons.code_rounded,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _linkedinController,
                      labelText: AppStrings.linkedinLabel,
                      hintText: AppStrings.linkedinHint,
                      prefixIcon: Icons.work_outline_rounded,
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 3: Education
                _ProfileSectionCard(
                  title: AppStrings.sectionEducation,
                  icon: Icons.school_rounded,
                  children: [
                    CustomTextField(
                      controller: _educationController,
                      labelText: AppStrings.educationLabel,
                      hintText: AppStrings.educationHint,
                      prefixIcon: Icons.school_outlined,
                      textInputAction: TextInputAction.newline,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 4: Skills & Competencies
                _ProfileSectionCard(
                  title: AppStrings.sectionSkills,
                  icon: Icons.psychology_rounded,
                  children: [
                    CustomTextField(
                      controller: _skillsController,
                      labelText: AppStrings.skillsLabel,
                      hintText: AppStrings.skillsHint,
                      prefixIcon: Icons.star_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 5: Key Projects
                _ProfileSectionCard(
                  title: AppStrings.sectionProjects,
                  icon: Icons.folder_rounded,
                  children: [
                    CustomTextField(
                      controller: _projectsController,
                      labelText: AppStrings.projectsLabel,
                      hintText: AppStrings.projectsHint,
                      prefixIcon: Icons.desktop_windows_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 6: Certifications & Achievements
                _ProfileSectionCard(
                  title: AppStrings.sectionCertifications,
                  icon: Icons.workspace_premium_rounded,
                  children: [
                    CustomTextField(
                      controller: _certificationsController,
                      labelText: AppStrings.certificationsLabel,
                      hintText: AppStrings.certificationsHint,
                      prefixIcon: Icons.verified_rounded,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Save Profile Gradient Button
                CustomButton(
                  text: AppStrings.saveProfile,
                  icon: Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _onSavePressed,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

/// Helper card container for grouping profile sections matching Image 4 & 5 layout.
class _ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ProfileSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.iconChipBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

