import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/application_status_helper.dart';
import '../../main.dart';
import '../../models/job.dart';
import '../../models/user_session.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';
import '../admin/admin_manage_jobs_screen.dart';
import '../../widgets/analytics_reports_widget.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/theme_toggle_button.dart';

/// Admin Dashboard Screen for System Administrators (ADM001).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  final Color borderColor;

  const _SliverTabBarDelegate(
    this.tabBar, {
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor ||
        borderColor != oldDelegate.borderColor;
  }
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingStats = true;
  int _totalStudents = 0;
  int _totalJobs = 0;
  int _totalApplications = 0;
  int _shortlisted = 0;
  int _selected = 0;
  double _placementPercentage = 0.0;

  List<Job> _placementDrives = [];
  bool _isLoadingDrives = true;
  String? _drivesError;

  List<Map<String, dynamic>> _pendingApprovals = [];
  bool _isLoadingApprovals = true;
  String? _approvalsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAdminStatistics();
    _loadPlacementDrives();
    _loadAdminCompanies();
  }

  Future<void> _fetchAdminStatistics() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);

    try {
      final res = await GoogleSheetsService().getAdminStatistics();
      if (!mounted) return;

      if (res['success'] == true) {
        int parseNum(dynamic raw) {
          if (raw is int) return raw;
          if (raw is num) return raw.toInt();
          return int.tryParse(raw?.toString() ?? '0') ?? 0;
        }

        double parseDouble(dynamic raw) {
          if (raw is double) return raw;
          if (raw is num) return raw.toDouble();
          return double.tryParse(raw?.toString() ?? '0') ?? 0.0;
        }

        setState(() {
          _totalStudents = parseNum(res['totalStudents']);
          _totalJobs = parseNum(res['totalJobs']);
          _totalApplications = parseNum(res['totalApplications']);
          _shortlisted = parseNum(res['shortlisted']);
          _selected = parseNum(res['selected']);
          _placementPercentage = parseDouble(res['placementPercentage']);
          _isLoadingStats = false;
        });
      } else {
        setState(() => _isLoadingStats = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _loadPlacementDrives() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDrives = true;
      _drivesError = null;
    });

    try {
      final res = await GoogleSheetsService().getJobs();
      if (!mounted) return;

      if (res['success'] == true && res['jobs'] is List<Job>) {
        final List<Job> jobs = res['jobs'] as List<Job>;
        setState(() {
          _placementDrives = jobs;
          _isLoadingDrives = false;
        });
      } else {
        setState(() {
          _placementDrives = [];
          _isLoadingDrives = false;
          _drivesError =
              res['message']?.toString() ?? 'Failed to load active drives.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _placementDrives = [];
          _isLoadingDrives = false;
          _drivesError = 'An error occurred while loading drives.';
        });
      }
    }
  }

  Future<void> _loadAdminCompanies() async {
    if (!mounted) return;
    setState(() {
      _isLoadingApprovals = true;
      _approvalsError = null;
    });

    try {
      final res = await GoogleSheetsService().getAdminCompanies();
      if (!mounted) return;

      if (res['success'] == true && res['companies'] is List) {
        final List rawCompanies = res['companies'] as List;
        final List<Map<String, dynamic>> companies = rawCompanies
            .map((c) => Map<String, dynamic>.from(c is Map ? c : {}))
            .toList();
        setState(() {
          _pendingApprovals = companies;
          _isLoadingApprovals = false;
        });
      } else {
        setState(() {
          _pendingApprovals = [];
          _isLoadingApprovals = false;
          _approvalsError =
              res['message']?.toString() ?? 'Failed to load company accounts.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pendingApprovals = [];
          _isLoadingApprovals = false;
          _approvalsError = 'An error occurred while loading companies.';
        });
      }
    }
  }

  void _refreshAllData() {
    _fetchAdminStatistics();
    _loadPlacementDrives();
    _loadAdminCompanies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onLogoutPressed() {
    UserSession().clearSession();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _toggleApprovalStatus(int index) async {
    if (index < 0 || index >= _pendingApprovals.length) return;
    final company = _pendingApprovals[index];
    final String userId = (company['userId'] ?? '').toString().trim();
    if (userId.isEmpty) return;

    final String currentStatus = (company['status'] ?? '').toString().trim();
    final bool isApproved = currentStatus.toLowerCase() == 'active' ||
        currentStatus.toLowerCase() == 'approved';

    final String nextStatus = isApproved ? 'Inactive' : 'Active';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isApproved
              ? 'Revoking approval for ${company['name'] ?? userId}...'
              : 'Approving ${company['name'] ?? userId}...',
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    final res = await GoogleSheetsService().updateCompanyStatus(
      userId: userId,
      status: nextStatus,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApproved
                ? 'Status revoked for ${company['name'] ?? userId}'
                : 'Approved ${company['name'] ?? userId}',
          ),
          backgroundColor: isApproved ? Colors.redAccent : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadAdminCompanies();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Failed to update company status.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildApprovalsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Review and manage company account access',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (!_isLoadingApprovals && _pendingApprovals.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_pendingApprovals.length} Accounts',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSession();
    final String adminName = session.name ?? 'System Administrator';
    final String adminId = session.userId ?? 'ADM001';

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0.5,
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Admin Portal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ID: $adminId',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ThemeToggleButton(themeProvider: globalThemeProvider),
          IconButton(
            tooltip: 'Refresh Statistics',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _refreshAllData,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _onLogoutPressed,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FadeSlideTransition(
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Section: Placement Control Center
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color(0xFF4338CA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Admin • System Administrator',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.shield_outlined,
                            color: Colors.white70, size: 24),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome, $adminName',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Placement Control Center',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor students, jobs, applications and campus placement activity from one dashboard.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Key Metrics Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Key Metrics',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_isLoadingStats)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Compact Metrics Grid (Replaces old 2x2 GridView)
              LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final int crossAxisCount = width >= 600 ? 3 : 2;
                  final double childAspectRatio = width >= 600
                      ? 2.4
                      : (width <= 360 ? 1.75 : (width <= 400 ? 1.85 : 2.1));
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _buildCompactMetricTile(
                        label: 'Students',
                        value: _isLoadingStats ? '...' : '$_totalStudents',
                        icon: Icons.school_rounded,
                        color: const Color(0xFF4F46E5),
                        bgColor: const Color(0xFFEEF2FF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminStudentsDetailScreen(),
                            ),
                          ).then((_) => _refreshAllData());
                        },
                      ),
                      _buildCompactMetricTile(
                        label: 'Active Jobs',
                        value: _isLoadingStats ? '...' : '$_totalJobs',
                        icon: Icons.business_center_rounded,
                        color: const Color(0xFF0EA5E9),
                        bgColor: const Color(0xFFE0F2FE),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminActiveJobsDetailScreen(),
                            ),
                          ).then((_) => _refreshAllData());
                        },
                      ),
                      _buildCompactMetricTile(
                        label: 'Applications',
                        value: _isLoadingStats ? '...' : '$_totalApplications',
                        icon: Icons.description_rounded,
                        color: const Color(0xFF6366F1),
                        bgColor: const Color(0xFFEEF2FF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminApplicationsDetailScreen(),
                            ),
                          ).then((_) => _refreshAllData());
                        },
                      ),
                      _buildCompactMetricTile(
                        label: 'Shortlisted',
                        value: _isLoadingStats ? '...' : '$_shortlisted',
                        icon: Icons.assignment_turned_in_rounded,
                        color: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFFFEF3C7),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminApplicationsDetailScreen(
                                statusFilter: 'Shortlisted',
                              ),
                            ),
                          ).then((_) => _refreshAllData());
                        },
                      ),
                      _buildCompactMetricTile(
                        label: 'Placements',
                        value: _isLoadingStats ? '...' : '$_selected',
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFF10B981),
                        bgColor: const Color(0xFFD1FAE5),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminApplicationsDetailScreen(
                                statusFilter: 'Selected',
                              ),
                            ),
                          ).then((_) => _refreshAllData());
                        },
                      ),
                      _buildCompactMetricTile(
                        label: 'Placement Rate',
                        value: _isLoadingStats
                            ? '...'
                            : '${_placementPercentage.toStringAsFixed(1)}%',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF059669),
                        bgColor: const Color(0xFFD1FAE5),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminPlacementRateDetailScreen(
                                totalApplications: _totalApplications,
                                selectedCount: _selected,
                                placementPercentage: _placementPercentage,
                              ),
                            ),
                          ).then((_) => _refreshAllData());
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Placement Overview Section
              const Text(
                'Placement Overview',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
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
                  children: [
                    _buildProgressRow(
                      label: 'Applications',
                      valueStr: _isLoadingStats ? '...' : '$_totalApplications',
                      progress: _totalStudents > 0
                          ? (_totalApplications / (_totalStudents * 2))
                              .clamp(0.0, 1.0)
                          : 0.5,
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(height: 12),
                    _buildProgressRow(
                      label: 'Shortlisted',
                      valueStr: _isLoadingStats ? '...' : '$_shortlisted',
                      progress: _totalApplications > 0
                          ? (_shortlisted / _totalApplications).clamp(0.0, 1.0)
                          : 0.0,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 12),
                    _buildProgressRow(
                      label: 'Selected (Placed)',
                      valueStr: _isLoadingStats ? '...' : '$_selected',
                      progress: _totalApplications > 0
                          ? (_selected / _totalApplications).clamp(0.0, 1.0)
                          : 0.0,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Overall Placement Rate',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isLoadingStats
                                ? '...'
                                : '${_placementPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Administrative Controls Section
              const Text(
                'Administrative Controls',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
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
                  children: [
                    _buildControlTile(
                      title: 'User Management',
                      subtitle: 'Manage student profiles and permissions',
                      icon: Icons.people_alt_rounded,
                      iconColor: AppColors.primary,
                      bgColor: AppColors.primary.withValues(alpha: 0.1),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.userManagement);
                      },
                    ),
                    const Divider(
                        height: 1, indent: 56, color: AppColors.cardBorder),
                    _buildControlTile(
                      title: 'System Broadcast',
                      subtitle: 'Send announcements to all campus users',
                      icon: Icons.campaign_rounded,
                      iconColor: Colors.orange.shade800,
                      bgColor: Colors.orange.withValues(alpha: 0.1),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.systemBroadcast);
                      },
                    ),
                  ],
                ),
              ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelColor: AppColors.primary,
                      unselectedLabelColor:
                          AppColors.getTextSecondary(context),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Company Approvals'),
                        Tab(text: 'Active Drives'),
                        Tab(text: 'Analytics & Reports'),
                      ],
                    ),
                    backgroundColor: AppColors.getSurface(context),
                    borderColor: AppColors.getCardBorder(context),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                          // Tab 1: Company Approvals (Phase 14B Redesigned UI)
                          _isLoadingApprovals
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  children: [
                                    _buildApprovalsHeader(),
                                    const Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : _approvalsError != null &&
                                      _pendingApprovals.isEmpty
                                  ? ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      children: [
                                        _buildApprovalsHeader(),
                                        Padding(
                                          padding:
                                              const EdgeInsets.all(24.0),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.error_outline_rounded,
                                                  color: Colors.orange,
                                                  size: 36,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _approvalsError!,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextButton.icon(
                                                  onPressed:
                                                      _loadAdminCompanies,
                                                  icon: const Icon(
                                                      Icons.refresh_rounded,
                                                      size: 18),
                                                  label: const Text('Retry'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : _pendingApprovals.isEmpty
                                      ? ListView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          children: [
                                            _buildApprovalsHeader(),
                                            const Padding(
                                              padding: EdgeInsets.all(24.0),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .business_center_outlined,
                                                      color: AppColors
                                                          .textSecondary,
                                                      size: 40,
                                                    ),
                                                    SizedBox(height: 10),
                                                    Text(
                                                      'No company accounts found.',
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .textPrimary,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'Company accounts will appear here when available.',
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : ListView.separated(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 8),
                                          itemCount:
                                              _pendingApprovals.length + 1,
                                          separatorBuilder: (context,
                                                  index) =>
                                              const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            if (index == 0) {
                                              return _buildApprovalsHeader();
                                            }
                                            final item =
                                                _pendingApprovals[index - 1];
                                                  final String rawStatus =
                                                      (item['status'] ?? '')
                                                          .toString()
                                                          .trim();
                                                  final String normStatus =
                                                      rawStatus.toLowerCase();
                                                  final bool isApproved =
                                                      normStatus == 'active' ||
                                                          normStatus ==
                                                              'approved';

                                                  final String nameStr =
                                                      (item['name'] ??
                                                              item['userId'] ??
                                                              'Company')
                                                          .toString()
                                                          .trim();
                                                  final String emailStr =
                                                      (item['email'] ??
                                                              item['userId'] ??
                                                              '')
                                                          .toString()
                                                          .trim();

                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surface,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                      border: Border.all(
                                                          color: AppColors
                                                              .cardBorder
                                                              .withValues(
                                                                  alpha: 0.8)),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0.03),
                                                          blurRadius: 6,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            // Left Avatar Icon
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: isApproved
                                                                    ? Colors.green.withValues(
                                                                        alpha:
                                                                            0.1)
                                                                    : AppColors
                                                                        .primary
                                                                        .withValues(
                                                                            alpha: 0.1),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .business_rounded,
                                                                color: isApproved
                                                                    ? Colors
                                                                        .green
                                                                    : AppColors
                                                                        .primary,
                                                                size: 22,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 12),
                                                            // Center Info
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    nameStr,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: AppColors
                                                                          .textPrimary,
                                                                    ),
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                  if (emailStr
                                                                      .isNotEmpty) ...[
                                                                    const SizedBox(
                                                                        height:
                                                                            2),
                                                                    Text(
                                                                      emailStr,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: AppColors
                                                                            .textSecondary,
                                                                      ),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            // Right Status Pill Badge
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: isApproved
                                                                    ? Colors.green.withValues(
                                                                        alpha:
                                                                            0.1)
                                                                    : Colors.orange.withValues(
                                                                        alpha:
                                                                            0.1),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                                border: Border
                                                                    .all(
                                                                  color: (isApproved
                                                                          ? Colors
                                                                              .green
                                                                          : Colors
                                                                              .orange)
                                                                      .withValues(
                                                                          alpha:
                                                                              0.3),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Container(
                                                                    width: 6,
                                                                    height: 6,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: isApproved
                                                                          ? Colors
                                                                              .green
                                                                          : Colors
                                                                              .orange,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 5),
                                                                  Text(
                                                                    isApproved
                                                                        ? 'ACTIVE'
                                                                        : 'INACTIVE',
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          10,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: isApproved
                                                                          ? Colors
                                                                              .green
                                                                              .shade700
                                                                          : Colors
                                                                              .orange
                                                                              .shade800,
                                                                      letterSpacing:
                                                                          0.5,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 10),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            // Tag
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          3),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: AppColors
                                                                    .cardBorder
                                                                    .withValues(
                                                                        alpha:
                                                                            0.3),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6),
                                                              ),
                                                              child: const Text(
                                                                'Company Account',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: AppColors
                                                                      .textSecondary,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                            // Action Button
                                                            OutlinedButton(
                                                              onPressed: () =>
                                                                  _toggleApprovalStatus(
                                                                      index),
                                                              style: OutlinedButton
                                                                  .styleFrom(
                                                                foregroundColor:
                                                                    isApproved
                                                                        ? Colors
                                                                            .red
                                                                        : Colors
                                                                            .green,
                                                                side: BorderSide(
                                                                  color: (isApproved
                                                                          ? Colors
                                                                              .red
                                                                          : Colors
                                                                              .green)
                                                                      .withValues(
                                                                          alpha:
                                                                              0.5),
                                                                ),
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        14,
                                                                    vertical:
                                                                        6),
                                                                minimumSize:
                                                                    Size.zero,
                                                                tapTargetSize:
                                                                    MaterialTapTargetSize
                                                                        .shrinkWrap,
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                isApproved
                                                                    ? 'Revoke'
                                                                    : 'Approve',
                                                                style:
                                                                    const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 8),
                                                        SizedBox(
                                                          width: double.infinity,
                                                          child: OutlinedButton.icon(
                                                            onPressed: () {
                                                              final String companyId = (item['userId'] ?? '').toString().trim();
                                                              final String companyName = (item['name'] ?? item['userId'] ?? 'Company').toString().trim();
                                                              final String? companyEmail = item['email']?.toString().trim();
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (_) => AdminManageJobsScreen(
                                                                    companyId: companyId,
                                                                    companyName: companyName,
                                                                    companyEmail: companyEmail,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            icon: const Icon(Icons.work_outline_rounded, size: 14),
                                                            label: const Text(
                                                              'Manage Jobs',
                                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                            ),
                                                            style: OutlinedButton.styleFrom(
                                                              foregroundColor: AppColors.primary,
                                                              side: BorderSide(
                                                                color: AppColors.primary.withValues(alpha: 0.5),
                                                              ),
                                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                                              minimumSize: Size.zero,
                                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),

                          // Tab 2: Active Drives (Phase 14A Real Data Integration)
                          _isLoadingDrives
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(14),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : _drivesError != null && _placementDrives.isEmpty
                                  ? ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.all(14),
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.all(24.0),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.error_outline_rounded,
                                                  color: Colors.orange,
                                                  size: 36,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _drivesError!,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextButton.icon(
                                                  onPressed:
                                                      _loadPlacementDrives,
                                                  icon: const Icon(
                                                      Icons.refresh_rounded,
                                                      size: 18),
                                                  label: const Text('Retry'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : _placementDrives.isEmpty
                                      ? ListView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(14),
                                          children: const [
                                            Padding(
                                              padding: EdgeInsets.all(24.0),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .business_center_outlined,
                                                      color: AppColors
                                                          .textSecondary,
                                                      size: 36,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'No active placement drives available.',
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : ListView.separated(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(14),
                                          itemCount: _placementDrives.length,
                                          separatorBuilder:
                                              (context, index) =>
                                                  const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            final drive =
                                                _placementDrives[index];
                                            final String statusText =
                                                drive.status.isNotEmpty
                                                    ? drive.status
                                                    : 'Active';
                                            final String normStatus =
                                                statusText.toLowerCase();
                                            final bool isOngoing =
                                                normStatus == 'active' ||
                                                    normStatus == 'ongoing' ||
                                                    normStatus == 'open';

                                            final String titleText =
                                                drive.company.isNotEmpty
                                                    ? '${drive.company} - ${drive.title}'
                                                    : drive.title;
                                            final String ctcText = drive
                                                    .salary.isNotEmpty
                                                ? 'CTC: ${drive.salary}'
                                                : 'CTC: Not specified';
                                            final String locationText =
                                                drive.location.isNotEmpty
                                                    ? ' • ${drive.location}'
                                                    : '';

                                            return Container(
                                              padding:
                                                  const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                    color: AppColors.cardBorder),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppColors.iconChipBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: const Icon(
                                                        Icons
                                                            .rocket_launch_rounded,
                                                        color:
                                                            AppColors.primary,
                                                        size: 24),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          titleText,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: AppColors
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          '$ctcText$locationText',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isOngoing
                                                          ? Colors.blue.withValues(
                                                              alpha: 0.1)
                                                          : Colors.grey.withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      statusText,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isOngoing
                                                            ? Colors.blue
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                          // Tab 3: Analytics & Reports (Phase 15)
                          const SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.all(14),
                            child: AnalyticsReportsWidget(),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.getSurface(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.getCardBorder(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(context),
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: color.withValues(alpha: 0.7),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required String valueStr,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              valueStr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.cardBorder.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildControlTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onTap: onTap,
      ),
    );
  }
}

/// 1. Admin Students Detail Screen
class AdminStudentsDetailScreen extends StatefulWidget {
  const AdminStudentsDetailScreen({super.key});

  @override
  State<AdminStudentsDetailScreen> createState() =>
      _AdminStudentsDetailScreenState();
}

class _AdminStudentsDetailScreenState
    extends State<AdminStudentsDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await GoogleSheetsService().getAdminStudents();
      if (!mounted) return;

      if (res['success'] == true) {
        final List raw = res['students'] as List? ?? [];
        final List<Map<String, dynamic>> list = raw
            .map((s) => Map<String, dynamic>.from(s is Map ? s : {}))
            .toList();
        setState(() {
          _students = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              res['message']?.toString() ?? 'Failed to load student records.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred while fetching student records.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0.5,
        title: Text(
          'Registered Students',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.redAccent),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadStudents,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _students.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No registered student records found.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStudents,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final item = _students[index];
                          final name = (item['name'] ?? item['userId'] ?? 'Student')
                              .toString()
                              .trim();
                          final studentId =
                              (item['studentId'] ?? item['userId'] ?? '')
                                  .toString()
                                  .trim();
                          final email =
                              (item['email'] ?? '').toString().trim();
                          final mobile =
                              (item['mobile'] ?? '').toString().trim();
                          final course =
                              (item['course'] ?? item['education'] ?? '')
                                  .toString()
                                  .trim();
                          final semester =
                              (item['semester'] ?? '').toString().trim();
                          final skills =
                              (item['skills'] ?? '').toString().trim();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: AppColors.getSurface(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: AppColors.getCardBorder(context),
                              ),
                            ),
                            elevation: 1.5,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.15),
                                        radius: 20,
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'S',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
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
                                              name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.getTextPrimary(
                                                    context),
                                              ),
                                            ),
                                            if (studentId.isNotEmpty)
                                              Text(
                                                'ID: $studentId',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.getTextSecondary(
                                                          context),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Divider(
                                      height: 1,
                                      color: AppColors.getCardBorder(context)),
                                  const SizedBox(height: 10),
                                  if (email.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.email_outlined,
                                              size: 14,
                                              color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              email,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors.getTextPrimary(
                                                    context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (mobile.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone_outlined,
                                              size: 14, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Text(
                                            mobile,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.getTextPrimary(
                                                  context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (course.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.school_outlined,
                                              size: 14, color: Colors.orange),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              course,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors.getTextPrimary(
                                                    context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (semester.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.class_outlined,
                                              size: 14, color: Colors.purple),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Semester / Year: $semester',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.getTextSecondary(
                                                  context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (skills.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.code_outlined,
                                              size: 14, color: Colors.indigo),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Skills: $skills',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.getTextPrimary(
                                                    context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

/// 2. Admin Active Jobs Detail Screen
class AdminActiveJobsDetailScreen extends StatefulWidget {
  const AdminActiveJobsDetailScreen({super.key});

  @override
  State<AdminActiveJobsDetailScreen> createState() =>
      _AdminActiveJobsDetailScreenState();
}

class _AdminActiveJobsDetailScreenState
    extends State<AdminActiveJobsDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Job> _activeJobs = [];

  @override
  void initState() {
    super.initState();
    _loadActiveJobs();
  }

  Future<void> _loadActiveJobs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await GoogleSheetsService().getJobs();
      if (!mounted) return;

      if (res['success'] == true && res['jobs'] is List<Job>) {
        final List<Job> allJobs = res['jobs'] as List<Job>;
        final activeOnly = allJobs.where((j) {
          final s = j.status.toLowerCase();
          return s == 'active' || s == 'open' || s.isEmpty;
        }).toList();

        setState(() {
          _activeJobs = activeOnly;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              res['message']?.toString() ?? 'Failed to load active jobs.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred while loading active jobs.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0.5,
        title: Text(
          'Active Job Postings',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadActiveJobs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.redAccent),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadActiveJobs,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _activeJobs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.business_center_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No active job postings found.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadActiveJobs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _activeJobs.length,
                        itemBuilder: (context, index) {
                          final job = _activeJobs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: AppColors.getSurface(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: AppColors.getCardBorder(context),
                              ),
                            ),
                            elevation: 1.5,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0EA5E9)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.business_center_rounded,
                                          color: Color(0xFF0EA5E9),
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
                                              job.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.getTextPrimary(
                                                    context),
                                              ),
                                            ),
                                            Text(
                                              job.company,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0EA5E9),
                                              ),
                                            ),
                                            if (job.jobId.isNotEmpty)
                                              Text(
                                                'Job ID: ${job.jobId}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.getTextSecondary(
                                                          context),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.green
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: const Text(
                                          'Active',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Divider(
                                      height: 1,
                                      color: AppColors.getCardBorder(context)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        job.location.isNotEmpty
                                            ? job.location
                                            : 'Remote',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.getTextPrimary(
                                              context),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(
                                          Icons.monetization_on_outlined,
                                          size: 14,
                                          color: Colors.green),
                                      const SizedBox(width: 6),
                                      Text(
                                        job.salary.isNotEmpty
                                            ? job.salary
                                            : 'Competitive',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.getTextPrimary(
                                              context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (job.skills.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Skills: ${job.skills}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.getTextSecondary(
                                            context),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

/// 3. Admin Applications Detail Screen (Applications, Shortlisted, Placements)
class AdminApplicationsDetailScreen extends StatefulWidget {
  final String? statusFilter;

  const AdminApplicationsDetailScreen({super.key, this.statusFilter});

  @override
  State<AdminApplicationsDetailScreen> createState() =>
      _AdminApplicationsDetailScreenState();
}

class _AdminApplicationsDetailScreenState
    extends State<AdminApplicationsDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res =
          await GoogleSheetsService().getCompanyApplications(companyId: 'all');
      if (!mounted) return;

      if (res['success'] == true && res['applications'] is List) {
        final List raw = res['applications'] as List;
        List<Map<String, dynamic>> list = raw
            .map((a) => Map<String, dynamic>.from(a is Map ? a : {}))
            .toList();

        if (widget.statusFilter != null &&
            widget.statusFilter!.trim().isNotEmpty) {
          final target = widget.statusFilter!.trim().toLowerCase();
          list = list.where((a) {
            final norm = ApplicationStatusHelper.normalizeStatus(a['status']);
            if (target == 'shortlisted') {
              return norm == ApplicationStatusHelper.statusShortlisted;
            } else if (target == 'selected') {
              return norm == ApplicationStatusHelper.statusSelected;
            } else {
              return norm.toLowerCase() == target;
            }
          }).toList();
        }

        setState(() {
          _applications = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              res['message']?.toString() ?? 'Failed to load applications.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred while loading applications.';
        _isLoading = false;
      });
    }
  }

  void _openResume(String url, String name) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No resume link available for $name')),
      );
      return;
    }
    final Uri uri = Uri.parse(cleanUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resume URL: $cleanUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = 'Platform Applications';
    if (widget.statusFilter != null &&
        widget.statusFilter!.trim().isNotEmpty) {
      final sf = widget.statusFilter!.trim().toLowerCase();
      if (sf == 'shortlisted') {
        pageTitle = 'Shortlisted Applicants';
      } else if (sf == 'selected') {
        pageTitle = 'Placed / Selected Students';
      } else {
        pageTitle = '${widget.statusFilter} Applications';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0.5,
        title: Text(
          pageTitle,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.redAccent),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadApplications,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _applications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.description_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No ${widget.statusFilter ?? 'application'} records found.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final app = _applications[index];
                          final name = (app['studentName'] ??
                                  app['userId'] ??
                                  app['studentId'] ??
                                  'Student')
                              .toString();
                          final studentId =
                              (app['userId'] ?? app['studentId'] ?? '')
                                  .toString();
                          final title =
                              (app['title'] ?? 'Role').toString();
                          final company =
                              (app['company'] ?? 'Company').toString();
                          final rawStatus =
                              (app['status'] ?? 'Applied').toString();
                          final appliedDate = (app['appliedDate'] ??
                                  app['date'] ??
                                  '')
                              .toString();
                          final resumeUrl = (app['resumeUrl'] ?? '').toString();
                          final statusColor =
                              ApplicationStatusHelper.getStatusColor(rawStatus);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: AppColors.getSurface(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: AppColors.getCardBorder(context),
                              ),
                            ),
                            elevation: 1.5,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: statusColor
                                            .withValues(alpha: 0.15),
                                        radius: 20,
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'S',
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
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
                                              name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.getTextPrimary(
                                                    context),
                                              ),
                                            ),
                                            if (studentId.isNotEmpty)
                                              Text(
                                                'ID: $studentId',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.getTextSecondary(
                                                          context),
                                                ),
                                              ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$title • $company',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ApplicationStatusHelper
                                              .getStatusBgColor(rawStatus),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: ApplicationStatusHelper
                                                .getStatusBorderColor(
                                                    rawStatus),
                                          ),
                                        ),
                                        child: Text(
                                          rawStatus,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Divider(
                                      height: 1,
                                      color: AppColors.getCardBorder(context)),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (appliedDate.isNotEmpty)
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_outlined,
                                                size: 13,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Applied: ${ApplicationStatusHelper.formatDisplayDateTime(appliedDate)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.getTextSecondary(
                                                        context),
                                                  ),
                                                  softWrap: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        const Spacer(),
                                      if (resumeUrl.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          icon: const Icon(
                                              Icons.description_outlined,
                                              size: 14,
                                              color: Colors.purple),
                                          label: const Text(
                                            'View Resume',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.purple,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onPressed: () =>
                                              _openResume(resumeUrl, name),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

/// 4. Admin Placement Rate Detail Screen
class AdminPlacementRateDetailScreen extends StatefulWidget {
  final int totalApplications;
  final int selectedCount;
  final double placementPercentage;

  const AdminPlacementRateDetailScreen({
    super.key,
    required this.totalApplications,
    required this.selectedCount,
    required this.placementPercentage,
  });

  @override
  State<AdminPlacementRateDetailScreen> createState() =>
      _AdminPlacementRateDetailScreenState();
}

class _AdminPlacementRateDetailScreenState
    extends State<AdminPlacementRateDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _placedApplications = [];

  @override
  void initState() {
    super.initState();
    _loadPlacedApplications();
  }

  Future<void> _loadPlacedApplications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res =
          await GoogleSheetsService().getCompanyApplications(companyId: 'all');
      if (!mounted) return;

      if (res['success'] == true && res['applications'] is List) {
        final List raw = res['applications'] as List;
        final list = raw
            .map((a) => Map<String, dynamic>.from(a is Map ? a : {}))
            .where((a) =>
                ApplicationStatusHelper.normalizeStatus(a['status']) ==
                ApplicationStatusHelper.statusSelected)
            .toList();

        setState(() {
          _placedApplications = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message']?.toString() ??
              'Failed to load placed application records.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'An error occurred while loading placement details.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0.5,
        title: Text(
          'Placement Rate Breakdown',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadPlacedApplications,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rate Calculation Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Placement Rate',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.placementPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Formula:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Placement Rate = (Placed Applications / Total Applications) × 100',
                          softWrap: true,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '= (${widget.selectedCount} / ${widget.totalApplications}) × 100 = ${widget.placementPercentage.toStringAsFixed(1)}%',
                          softWrap: true,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Underlying Selected Records (${_placedApplications.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              )
            else if (_placedApplications.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getCardBorder(context)),
                ),
                child: const Text(
                  'No selected / placed application records found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _placedApplications.length,
                itemBuilder: (context, index) {
                  final app = _placedApplications[index];
                  final name = (app['studentName'] ?? app['userId'] ?? 'Student')
                      .toString();
                  final title = (app['title'] ?? 'Role').toString();
                  final company = (app['company'] ?? 'Company').toString();
                  final appliedDate = (app['appliedDate'] ?? '').toString();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: AppColors.getSurface(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFD1FAE5),
                            radius: 20,
                            child: Icon(
                              Icons.check_circle,
                              color: Color(0xFF059669),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                  softWrap: true,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$title • $company',
                                  style: TextStyle(
                                    color: AppColors.getTextSecondary(context),
                                    fontSize: 12,
                                  ),
                                  softWrap: true,
                                ),
                                if (appliedDate.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 11,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ApplicationStatusHelper
                                              .formatDisplayDateTime(
                                                  appliedDate),
                                          style: TextStyle(
                                            color: AppColors.getTextSecondary(
                                                context),
                                            fontSize: 11,
                                          ),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF34D399),
                              ),
                            ),
                            child: const Text(
                              'Placed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
