import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/student_profile.dart';
import '../../models/user_session.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';
import '../../widgets/app_logo.dart';

/// Student Campus Placement Dashboard Screen matching Image 3 design.
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _apiService = GoogleSheetsService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadNotifications();
    _fetchStudentProfile();
  }

  Future<void> _fetchStudentProfile() async {
    final session = UserSession();
    final userId = session.userId;
    if (userId == null || userId.isEmpty) return;

    if (session.name == null || session.name!.trim().isEmpty) {
      final result = await _apiService.getStudentProfile(userId: userId);
      if (!mounted) return;

      if (result['success'] == true) {
        final profile = StudentProfile.fromJson(result);
        if (profile.name.trim().isNotEmpty) {
          session.setSession(
            userId: userId,
            role: session.role ?? 'Student',
            name: profile.name.trim(),
            email: profile.email.isNotEmpty ? profile.email : session.email,
          );
          setState(() {});
        }
      }
    }
  }

  Future<void> _fetchUnreadNotifications() async {
    final userId = UserSession().userId;
    if (userId == null || userId.isEmpty) return;

    final result = await _apiService.getNotifications(userId);
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _unreadCount = (result['unreadCount'] is int)
            ? result['unreadCount'] as int
            : 0;
      });
    }
  }

  Future<void> _navigateToNotifications() async {
    final result = await Navigator.pushNamed(context, AppRoutes.notifications);
    if (!mounted) return;
    if (result is int) {
      setState(() {
        _unreadCount = result;
      });
    } else {
      _fetchUnreadNotifications();
    }
  }

  void _onLogoutPressed(BuildContext context) {
    UserSession().clearSession();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _navigateToProfile(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.profile);
    if (!mounted) return;
    setState(() {});
  }

  void _navigateToResume(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.resume);
  }

  void _navigateToJobs(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.jobs);
  }

  void _navigateToApplications(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.myApplications);
  }

  void _navigateToPlacementReadiness(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.placementReadiness);
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSession();
    final String userId = session.userId ?? 'K001';
    final String displayName = (session.name != null && session.name!.trim().isNotEmpty)
        ? '${session.name!.trim()} ($userId)'
        : userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: const [
            AppLogo(size: 34),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                AppStrings.appName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Notification Bell with Badge Counter
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                tooltip: AppStrings.notificationsTitle,
                onPressed: _navigateToNotifications,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: AppStrings.logout,
            onPressed: () => _onLogoutPressed(context),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Welcome Card (Deep Navy Slate Gradient matching Image 3)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;

                  final avatarWidget = Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  );

                  final welcomeColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _BadgeChip(
                            icon: Icons.badge_outlined,
                            label: 'ID: ${session.userId ?? "K001"}',
                          ),
                          _BadgeChip(
                            icon: Icons.verified_user_outlined,
                            label: 'Role: ${session.role ?? "Student"}',
                          ),
                          const _BadgeChip(
                            icon: Icons.check_circle_outline,
                            label: 'Status: Active',
                          ),
                        ],
                      ),
                    ],
                  );

                  final metricsBox = GestureDetector(
                    onTap: () => _navigateToPlacementReadiness(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Placement Readiness',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: const [
                              _MetricPill(
                                val: 'Insights',
                                label: 'Readiness',
                                color: Color(0xFF10B981),
                              ),
                              _MetricPill(
                                val: 'Ready',
                                label: 'Resume',
                                color: Color(0xFF3B82F6),
                              ),
                              _MetricPill(
                                val: 'Analytics',
                                label: 'Jobs Match',
                                color: Color(0xFFEAB308),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroCardGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              avatarWidget,
                              const SizedBox(width: 16),
                              Expanded(child: welcomeColumn),
                              const SizedBox(width: 16),
                              metricsBox,
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  avatarWidget,
                                  const SizedBox(width: 14),
                                  Expanded(child: welcomeColumn),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: metricsBox,
                              ),
                            ],
                          ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Section Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Campus Placement Hub',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4 Grid/Row Cards matching Image 3 layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final items = [
                    _DashboardMenuItem(
                      title: AppStrings.menuMyProfile,
                      subtitle: AppStrings.menuMyProfileSubtitle,
                      icon: Icons.person_pin_rounded,
                      iconBgColor: AppColors.primary,
                      cardBgColor: AppColors.cardBgProfile,
                      borderColor: AppColors.primary.withValues(alpha: 0.2),
                      onTap: () => _navigateToProfile(context),
                    ),
                    _DashboardMenuItem(
                      title: AppStrings.menuResume,
                      subtitle: AppStrings.menuResumeSubtitle,
                      icon: Icons.description_rounded,
                      iconBgColor: AppColors.accent,
                      cardBgColor: AppColors.cardBgResume,
                      borderColor: AppColors.accent.withValues(alpha: 0.2),
                      onTap: () => _navigateToResume(context),
                    ),
                    _DashboardMenuItem(
                      title: AppStrings.menuJobs,
                      subtitle: AppStrings.menuJobsSubtitle,
                      icon: Icons.business_center_rounded,
                      iconBgColor: const Color(0xFFF59E0B),
                      cardBgColor: AppColors.cardBgJobs,
                      borderColor:
                          const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      onTap: () => _navigateToJobs(context),
                    ),
                    _DashboardMenuItem(
                      title: AppStrings.menuApplications,
                      subtitle: AppStrings.menuApplicationsSubtitle,
                      icon: Icons.verified_rounded,
                      iconBgColor: const Color(0xFF8B5CF6),
                      cardBgColor: AppColors.cardBgApplications,
                      borderColor:
                          const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      onTap: () => _navigateToApplications(context),
                    ),
                  ];

                  if (constraints.maxWidth >= 720) {
                    return Row(
                      children: items
                          .map((item) => Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: SizedBox(
                                    height: 140,
                                    child: item,
                                  ),
                                ),
                              ))
                          .toList(),
                    );
                  }

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                    children: items,
                  );
                },
              ),

              const SizedBox(height: 24),

              // Bottom Placement Tip Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.tipBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
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
                        Icons.lightbulb_rounded,
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
                            'Placement Tip',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Keep your profile & resume updated to improve visibility for upcoming campus recruiters.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

}

class _MetricPill extends StatelessWidget {
  final String val;
  final String label;
  final Color color;

  const _MetricPill({
    required this.val,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BadgeChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color cardBgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _DashboardMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.cardBgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardBgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

