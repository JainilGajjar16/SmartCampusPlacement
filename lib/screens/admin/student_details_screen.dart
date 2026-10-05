import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/student_profile.dart';
import '../../services/google_sheets_service.dart';

/// Student Details Screen for Admin to view full profile, edit, or delete student.
class StudentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentDetailsScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final GoogleSheetsService _apiService = GoogleSheetsService();
  bool _isLoadingProfile = true;
  bool _isDeleting = false;
  bool _isUpdating = false;

  late Map<String, dynamic> _studentData;
  StudentProfile? _fullProfile;

  @override
  void initState() {
    super.initState();
    _studentData = Map<String, dynamic>.from(widget.student);
    _loadFullStudentProfile();
  }

  Future<void> _loadFullStudentProfile() async {
    final String userId =
        (_studentData['userId'] ?? _studentData['studentId'] ?? '').toString().trim();
    if (userId.isEmpty) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final res = await _apiService.getStudentProfile(userId: userId);
      if (!mounted) return;

      if (res['success'] == true) {
        final profile = StudentProfile.fromJson(res);
        setState(() {
          _fullProfile = profile;
          _isLoadingProfile = false;
        });
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.trim().isEmpty) return;
    String formattedUrl = urlString.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    try {
      final Uri uri = Uri.parse(formattedUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch URL: $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid link format: $urlString')),
        );
      }
    }
  }

  void _showEditStudentModal() {
    final nameCtrl = TextEditingController(
        text: _studentData['name'] ?? _fullProfile?.name ?? '');
    final emailCtrl = TextEditingController(
        text: _studentData['email'] ?? _fullProfile?.email ?? '');
    final mobileCtrl = TextEditingController(
        text: _studentData['mobile'] ?? _fullProfile?.mobile ?? '');
    final courseCtrl = TextEditingController(
        text: _studentData['course'] ??
            _studentData['education'] ??
            _fullProfile?.education ??
            '');
    final semesterCtrl = TextEditingController(
        text: _studentData['semester'] ?? '');
    final skillsCtrl = TextEditingController(
        text: _studentData['skills'] ?? _fullProfile?.skills ?? '');
    String currentStatus = _studentData['status']?.toString() ?? 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded,
                            color: AppColors.primary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Edit Student Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Form Fields
                    _buildTextField(nameCtrl, 'Full Name', Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildTextField(emailCtrl, 'Email Address', Icons.email_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(mobileCtrl, 'Mobile Number', Icons.phone_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(courseCtrl, 'Course / Education', Icons.school_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(semesterCtrl, 'Semester / Year', Icons.timeline_outlined),
                    const SizedBox(height: 12),
                    _buildTextField(skillsCtrl, 'Skills (comma separated)', Icons.psychology_outlined),
                    const SizedBox(height: 16),

                    // Status selection
                    Text(
                      'Account Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Active', label: Text('Active')),
                        ButtonSegment(value: 'Pending', label: Text('Pending')),
                        ButtonSegment(value: 'Inactive', label: Text('Inactive')),
                      ],
                      selected: {currentStatus},
                      onSelectionChanged: (newSelection) {
                        setModalState(() {
                          currentStatus = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isUpdating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_isUpdating ? 'Saving...' : 'Save Profile Changes'),
                        onPressed: _isUpdating
                            ? null
                            : () async {
                                final userId = (_studentData['userId'] ??
                                        _studentData['studentId'] ??
                                        '')
                                    .toString();

                                setModalState(() => _isUpdating = true);

                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);

                                final res = await _apiService.updateStudent(
                                  userId: userId,
                                  name: nameCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  mobile: mobileCtrl.text.trim(),
                                  education: courseCtrl.text.trim(),
                                  semester: semesterCtrl.text.trim(),
                                  skills: skillsCtrl.text.trim(),
                                  status: currentStatus,
                                );

                                setModalState(() => _isUpdating = false);

                                if (res['success'] == true) {
                                  if (mounted) {
                                    setState(() {
                                      _studentData['name'] = nameCtrl.text.trim();
                                      _studentData['email'] = emailCtrl.text.trim();
                                      _studentData['mobile'] = mobileCtrl.text.trim();
                                      _studentData['course'] = courseCtrl.text.trim();
                                      _studentData['education'] = courseCtrl.text.trim();
                                      _studentData['semester'] = semesterCtrl.text.trim();
                                      _studentData['skills'] = skillsCtrl.text.trim();
                                      _studentData['status'] = currentStatus;
                                    });
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(res['message'] ??
                                            'Student profile updated successfully!'),
                                        backgroundColor: Colors.green.shade700,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(res['message'] ??
                                            'Failed to update profile.'),
                                        backgroundColor: Colors.red.shade700,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.getInputBg(context),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.getCardBorder(context)),
        ),
      ),
    );
  }

  void _confirmDeleteStudent() {
    final String userId =
        (_studentData['userId'] ?? _studentData['studentId'] ?? '').toString();
    final String name = _studentData['name']?.toString() ?? userId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.delete_forever_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 8),
                  Text('Delete Student'),
                ],
              ),
              content: Text(
                'Are you sure you want to delete student record "$name" ($userId)?\n\nThis will remove the student account from the backend system.',
              ),
              actions: [
                TextButton(
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete),
                  label: Text(_isDeleting ? 'Deleting...' : 'Delete Student'),
                  onPressed: _isDeleting
                      ? null
                      : () async {
                          setDialogState(() => _isDeleting = true);

                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);

                          final res = await _apiService.deleteStudent(userId);

                          setDialogState(() => _isDeleting = false);
                          if (mounted) navigator.pop(); // Close dialog

                          if (res['success'] == true) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ??
                                      'Student record deleted successfully.'),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                              navigator.pop(); // Pop back to list
                            }
                          } else {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ??
                                      'Failed to delete student.'),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackground(context);
    final surfaceColor = AppColors.getSurface(context);
    final textColor = AppColors.getTextPrimary(context);
    final subtextColor = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getCardBorder(context);

    final String name = _studentData['name']?.toString() ??
        _fullProfile?.name ??
        'Unnamed Student';
    final String email = _studentData['email']?.toString() ??
        _fullProfile?.email ??
        'No email provided';
    final String userId = (_studentData['userId'] ??
            _studentData['studentId'] ??
            _fullProfile?.userId ??
            '')
        .toString();
    final String mobile = _studentData['mobile']?.toString() ??
        _fullProfile?.mobile ??
        '';
    final String course = _studentData['course']?.toString() ??
        _studentData['education']?.toString() ??
        _fullProfile?.education ??
        'Not specified';
    final String semester =
        _studentData['semester']?.toString() ?? 'Not specified';
    final String cgpa = _studentData['cgpa']?.toString() ?? '';
    final String skills = _studentData['skills']?.toString() ??
        _fullProfile?.skills ??
        '';
    final String status =
        _studentData['status']?.toString() ?? 'Active';
    final String github = _fullProfile?.github ?? '';
    final String linkedin = _fullProfile?.linkedin ?? '';
    final String resumeUrl = _studentData['resumeUrl']?.toString() ?? '';

    final Color statusColor = status.toLowerCase() == 'active'
        ? Colors.green.shade700
        : (status.toLowerCase() == 'pending'
            ? Colors.amber.shade700
            : Colors.red.shade600);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Student Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit Student',
            onPressed: _showEditStudentModal,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Delete Student',
            onPressed: _confirmDeleteStudent,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(fontSize: 14, color: subtextColor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.getInputBg(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            'ID: $userId',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Academic Information Card
              _buildSectionCard(
                context,
                title: 'Academic Profile',
                icon: Icons.school_rounded,
                surfaceColor: surfaceColor,
                textColor: textColor,
                subtextColor: subtextColor,
                borderColor: borderColor,
                children: [
                  _buildDetailRow(
                    context,
                    label: 'Course / Education',
                    value: course,
                    icon: Icons.import_contacts_rounded,
                  ),
                  _buildDetailRow(
                    context,
                    label: 'Semester / Year',
                    value: semester,
                    icon: Icons.calendar_today_rounded,
                  ),
                  if (cgpa.isNotEmpty)
                    _buildDetailRow(
                      context,
                      label: 'CGPA / Marks',
                      value: cgpa,
                      icon: Icons.grade_rounded,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Contact & Links Card
              _buildSectionCard(
                context,
                title: 'Contact & Online Profiles',
                icon: Icons.contact_page_rounded,
                surfaceColor: surfaceColor,
                textColor: textColor,
                subtextColor: subtextColor,
                borderColor: borderColor,
                children: [
                  _buildDetailRow(
                    context,
                    label: 'Mobile Phone',
                    value: mobile.isNotEmpty ? mobile : 'Not provided',
                    icon: Icons.phone_android_rounded,
                    onTap: mobile.isNotEmpty ? () => _launchURL('tel:$mobile') : null,
                  ),
                  _buildDetailRow(
                    context,
                    label: 'GitHub Profile',
                    value: github.isNotEmpty ? github : 'Not linked',
                    icon: Icons.code_rounded,
                    isLink: github.isNotEmpty,
                    onTap: github.isNotEmpty ? () => _launchURL(github) : null,
                  ),
                  _buildDetailRow(
                    context,
                    label: 'LinkedIn Profile',
                    value: linkedin.isNotEmpty ? linkedin : 'Not linked',
                    icon: Icons.link_rounded,
                    isLink: linkedin.isNotEmpty,
                    onTap: linkedin.isNotEmpty ? () => _launchURL(linkedin) : null,
                  ),
                  if (resumeUrl.isNotEmpty)
                    _buildDetailRow(
                      context,
                      label: 'Resume Document',
                      value: 'View Resume PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      isLink: true,
                      onTap: () => _launchURL(resumeUrl),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Skills Card
              if (skills.isNotEmpty || _isLoadingProfile)
                _buildSectionCard(
                  context,
                  title: 'Skills & Competencies',
                  icon: Icons.psychology_rounded,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  borderColor: borderColor,
                  children: [
                    if (_isLoadingProfile)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .map(
                              (skill) => Chip(
                                backgroundColor:
                                    AppColors.getIconChipBg(context),
                                label: Text(
                                  skill,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color surfaceColor,
    required Color textColor,
    required Color subtextColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    final subtextColor = AppColors.getTextSecondary(context);
    final textColor = AppColors.getTextPrimary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: subtextColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isLink ? FontWeight.bold : FontWeight.w500,
                      color: isLink ? AppColors.primary : textColor,
                      decoration:
                          isLink ? TextDecoration.underline : TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            if (isLink || onTap != null)
              const Icon(Icons.open_in_new, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
