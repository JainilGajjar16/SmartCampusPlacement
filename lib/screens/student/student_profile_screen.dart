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
  final StudentProfile? initialProfile;

  const StudentProfileScreen({
    super.key,
    this.initialProfile,
  });

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
  final _skillsController = TextEditingController();
  final _projectsController = TextEditingController();
  final List<EducationEntryControllers> _educationEntries = [];
  final List<CertificationEntryControllers> _certificationEntries = [];

  bool _isLoadingProfile = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isNewProfile = false;

  @override
  void initState() {
    super.initState();
    _educationEntries.add(EducationEntryControllers());
    _certificationEntries.add(CertificationEntryControllers());
    if (widget.initialProfile != null) {
      _isLoadingProfile = false;
      _populateFields(widget.initialProfile!);
    } else {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    for (final entry in _educationEntries) {
      entry.dispose();
    }
    _educationEntries.clear();
    _skillsController.dispose();
    _projectsController.dispose();
    for (final entry in _certificationEntries) {
      entry.dispose();
    }
    _certificationEntries.clear();
    super.dispose();
  }

  void _addEducationEntry({int? afterIndex}) {
    setState(() {
      final newController = EducationEntryControllers();
      if (afterIndex != null &&
          afterIndex >= 0 &&
          afterIndex < _educationEntries.length) {
        _educationEntries.insert(afterIndex + 1, newController);
      } else {
        _educationEntries.add(newController);
      }
    });
  }

  void _removeEducationEntry(int index) {
    setState(() {
      if (_educationEntries.length > 1) {
        final removed = _educationEntries.removeAt(index);
        removed.dispose();
      } else if (_educationEntries.isNotEmpty) {
        _educationEntries[0].clear();
      }
    });
  }

  void _addCertificationEntry({int? afterIndex}) {
    setState(() {
      final newController = CertificationEntryControllers();
      if (afterIndex != null &&
          afterIndex >= 0 &&
          afterIndex < _certificationEntries.length) {
        _certificationEntries.insert(afterIndex + 1, newController);
      } else {
        _certificationEntries.add(newController);
      }
    });
  }

  void _removeCertificationEntry(int index) {
    setState(() {
      if (_certificationEntries.length > 1) {
        final removed = _certificationEntries.removeAt(index);
        removed.dispose();
      } else if (_certificationEntries.isNotEmpty) {
        _certificationEntries[0].clear();
      }
    });
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
    _skillsController.text = profile.skills;
    _projectsController.text = profile.projects;

    // Populate Education Entries
    for (final entry in _educationEntries) {
      entry.dispose();
    }
    _educationEntries.clear();
    final parsedEdu = StudentProfile.parseEducation(profile.education);
    if (parsedEdu.isEmpty) {
      _educationEntries.add(EducationEntryControllers());
    } else {
      for (final item in parsedEdu) {
        _educationEntries.add(EducationEntryControllers(
          degree: item.degree,
          uniBoard: item.uniBoard,
          cgpaPercentage: item.cgpaPercentage,
          year: item.year,
        ));
      }
    }

    // Populate Certification Entries
    for (final entry in _certificationEntries) {
      entry.dispose();
    }
    _certificationEntries.clear();
    final parsedCerts =
        StudentProfile.parseCertifications(profile.certifications);
    if (parsedCerts.isEmpty) {
      _certificationEntries.add(CertificationEntryControllers());
    } else {
      for (final item in parsedCerts) {
        _certificationEntries.add(CertificationEntryControllers(
          course: item.courseCertificate,
          ranking: item.rankingPercentage,
          year: item.year,
        ));
      }
    }
  }

  Future<void> _onSavePressed() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      final String currentUserId = UserSession().userId ?? '';
      final educationString = StudentProfile.formatEducation(
        _educationEntries.map((e) => e.toItem()).toList(),
      );
      final certificationsString = StudentProfile.formatCertifications(
        _certificationEntries.map((c) => c.toItem()).toList(),
      );

      final profileToSave = StudentProfile(
        userId: currentUserId,
        name: _fullNameController.text,
        email: _emailController.text,
        mobile: _mobileController.text,
        github: _githubController.text,
        linkedin: _linkedinController.text,
        education: educationString,
        skills: _skillsController.text,
        projects: _projectsController.text,
        certifications: certificationsString,
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
                _buildEducationSection(),
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
                _buildCertificationsSection(),

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

  Widget _buildEducationSection() {
    if (_educationEntries.isEmpty) {
      _educationEntries.add(EducationEntryControllers());
    }

    return _ProfileSectionCard(
      title: AppStrings.sectionEducation,
      icon: Icons.school_rounded,
      children: [
        for (int i = 0; i < _educationEntries.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 16),
          ],
          _buildEducationEntry(i, _educationEntries[i]),
        ],
      ],
    );
  }

  Widget _buildEducationEntry(int index, EducationEntryControllers entry) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_educationEntries.length > 1) ...[
              Text(
                'Education #${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Row 1: Degree | Uni / Board
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: entry.degreeController,
                    labelText: AppStrings.degreeLabel,
                    hintText: AppStrings.degreeHint,
                    prefixIcon: Icons.school_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: entry.uniBoardController,
                    labelText: AppStrings.uniBoardLabel,
                    hintText: AppStrings.uniBoardHint,
                    prefixIcon: Icons.account_balance_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Row 2: CGPA / Percentage | Year + X
            if (!isNarrow) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 5,
                    child: CustomTextField(
                      controller: entry.cgpaController,
                      labelText: AppStrings.cgpaPercentageLabel,
                      hintText: AppStrings.cgpaPercentageHint,
                      prefixIcon: Icons.grade_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: CustomTextField(
                      controller: entry.yearController,
                      labelText: AppStrings.yearLabel,
                      hintText: AppStrings.yearHint,
                      prefixIcon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButtons(
                    onAdd: () => _addEducationEntry(afterIndex: index),
                    onRemove: () => _removeEducationEntry(index),
                    addTooltip: AppStrings.addEducationTooltip,
                    removeTooltip: AppStrings.removeEducationTooltip,
                  ),
                ],
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: entry.cgpaController,
                      labelText: AppStrings.cgpaPercentageLabel,
                      hintText: AppStrings.cgpaPercentageHint,
                      prefixIcon: Icons.grade_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      controller: entry.yearController,
                      labelText: AppStrings.yearLabel,
                      hintText: AppStrings.yearHint,
                      prefixIcon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _buildActionButtons(
                  onAdd: () => _addEducationEntry(afterIndex: index),
                  onRemove: () => _removeEducationEntry(index),
                  addTooltip: AppStrings.addEducationTooltip,
                  removeTooltip: AppStrings.removeEducationTooltip,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCertificationsSection() {
    if (_certificationEntries.isEmpty) {
      _certificationEntries.add(CertificationEntryControllers());
    }

    return _ProfileSectionCard(
      title: AppStrings.sectionCertifications,
      icon: Icons.workspace_premium_rounded,
      children: [
        for (int i = 0; i < _certificationEntries.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 16),
          ],
          _buildCertificationEntry(i, _certificationEntries[i]),
        ],
      ],
    );
  }

  Widget _buildCertificationEntry(
      int index, CertificationEntryControllers entry) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_certificationEntries.length > 1) ...[
              Text(
                'Certification #${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Row 1: Course / Certificate (full width)
            CustomTextField(
              controller: entry.courseController,
              labelText: AppStrings.courseCertificateLabel,
              hintText: AppStrings.courseCertificateHint,
              prefixIcon: Icons.workspace_premium_outlined,
            ),
            const SizedBox(height: 14),
            // Row 2: Ranking / Percentage | Year + X
            if (!isNarrow) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 5,
                    child: CustomTextField(
                      controller: entry.rankingController,
                      labelText: AppStrings.rankingPercentageLabel,
                      hintText: AppStrings.rankingPercentageHint,
                      prefixIcon: Icons.emoji_events_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: CustomTextField(
                      controller: entry.yearController,
                      labelText: AppStrings.yearLabel,
                      hintText: AppStrings.yearHint,
                      prefixIcon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButtons(
                    onAdd: () => _addCertificationEntry(afterIndex: index),
                    onRemove: () => _removeCertificationEntry(index),
                    addTooltip: AppStrings.addCertificationTooltip,
                    removeTooltip: AppStrings.removeCertificationTooltip,
                  ),
                ],
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: entry.rankingController,
                      labelText: AppStrings.rankingPercentageLabel,
                      hintText: AppStrings.rankingPercentageHint,
                      prefixIcon: Icons.emoji_events_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      controller: entry.yearController,
                      labelText: AppStrings.yearLabel,
                      hintText: AppStrings.yearHint,
                      prefixIcon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _buildActionButtons(
                  onAdd: () => _addCertificationEntry(afterIndex: index),
                  onRemove: () => _removeCertificationEntry(index),
                  addTooltip: AppStrings.addCertificationTooltip,
                  removeTooltip: AppStrings.removeCertificationTooltip,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActionButtons({
    required VoidCallback onAdd,
    required VoidCallback onRemove,
    required String addTooltip,
    required String removeTooltip,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Add '+' button
        Tooltip(
          message: addTooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(10),
              child: Ink(
                width: 38,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Remove 'X' button
        Builder(
          builder: (context) {
            final isDark = AppColors.isDark(context);
            return Tooltip(
              message: removeTooltip,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    width: 38,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3B181E)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF7F1D1D).withValues(alpha: 0.5)
                            : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFFF87171)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
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

/// Controller holder for a single repeatable education entry.
class EducationEntryControllers {
  final TextEditingController degreeController;
  final TextEditingController uniBoardController;
  final TextEditingController cgpaController;
  final TextEditingController yearController;

  EducationEntryControllers({
    String degree = '',
    String uniBoard = '',
    String cgpaPercentage = '',
    String year = '',
  })  : degreeController = TextEditingController(text: degree),
        uniBoardController = TextEditingController(text: uniBoard),
        cgpaController = TextEditingController(text: cgpaPercentage),
        yearController = TextEditingController(text: year);

  void dispose() {
    degreeController.dispose();
    uniBoardController.dispose();
    cgpaController.dispose();
    yearController.dispose();
  }

  void clear() {
    degreeController.clear();
    uniBoardController.clear();
    cgpaController.clear();
    yearController.clear();
  }

  bool get isEmpty =>
      degreeController.text.trim().isEmpty &&
      uniBoardController.text.trim().isEmpty &&
      cgpaController.text.trim().isEmpty &&
      yearController.text.trim().isEmpty;

  bool get isNotEmpty => !isEmpty;

  EducationItem toItem() => EducationItem(
        degree: degreeController.text.trim(),
        uniBoard: uniBoardController.text.trim(),
        cgpaPercentage: cgpaController.text.trim(),
        year: yearController.text.trim(),
      );
}

/// Controller holder for a single repeatable certification entry.
class CertificationEntryControllers {
  final TextEditingController courseController;
  final TextEditingController rankingController;
  final TextEditingController yearController;

  CertificationEntryControllers({
    String course = '',
    String ranking = '',
    String year = '',
  })  : courseController = TextEditingController(text: course),
        rankingController = TextEditingController(text: ranking),
        yearController = TextEditingController(text: year);

  void dispose() {
    courseController.dispose();
    rankingController.dispose();
    yearController.dispose();
  }

  void clear() {
    courseController.clear();
    rankingController.clear();
    yearController.clear();
  }

  bool get isEmpty =>
      courseController.text.trim().isEmpty &&
      rankingController.text.trim().isEmpty &&
      yearController.text.trim().isEmpty;

  bool get isNotEmpty => !isEmpty;

  CertificationItem toItem() => CertificationItem(
        courseCertificate: courseController.text.trim(),
        rankingPercentage: rankingController.text.trim(),
        year: yearController.text.trim(),
      );
}

