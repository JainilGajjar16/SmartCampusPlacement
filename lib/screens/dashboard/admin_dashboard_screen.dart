import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job.dart';
import '../../models/user_session.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';
import '../../widgets/analytics_reports_widget.dart';
import '../../widgets/app_logo.dart';

/// Admin Dashboard Screen for System Administrators (ADM001).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
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

  @override
  Widget build(BuildContext context) {
    final session = UserSession();
    final String adminName = session.name ?? 'System Administrator';
    final String adminId = session.userId ?? 'ADM001';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(size: 34),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Portal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'ID: $adminId',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'Admin • System Administrator',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: width >= 600 ? 2.4 : 2.1,
                    children: [
                      _buildCompactMetricTile(
                        label: 'Students',
                        value: _isLoadingStats ? '...' : '$_totalStudents',
                        icon: Icons.school_rounded,
                        color: const Color(0xFF4F46E5),
                        bgColor: const Color(0xFFEEF2FF),
                      ),
                      _buildCompactMetricTile(
                        label: 'Active Jobs',
                        value: _isLoadingStats ? '...' : '$_totalJobs',
                        icon: Icons.business_center_rounded,
                        color: const Color(0xFF0EA5E9),
                        bgColor: const Color(0xFFE0F2FE),
                      ),
                      _buildCompactMetricTile(
                        label: 'Applications',
                        value: _isLoadingStats ? '...' : '$_totalApplications',
                        icon: Icons.description_rounded,
                        color: const Color(0xFF6366F1),
                        bgColor: const Color(0xFFEEF2FF),
                      ),
                      _buildCompactMetricTile(
                        label: 'Shortlisted',
                        value: _isLoadingStats ? '...' : '$_shortlisted',
                        icon: Icons.assignment_turned_in_rounded,
                        color: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFFFEF3C7),
                      ),
                      _buildCompactMetricTile(
                        label: 'Placements',
                        value: _isLoadingStats ? '...' : '$_selected',
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFF10B981),
                        bgColor: const Color(0xFFD1FAE5),
                      ),
                      _buildCompactMetricTile(
                        label: 'Placement Rate',
                        value: _isLoadingStats
                            ? '...'
                            : '${_placementPercentage.toStringAsFixed(1)}%',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF059669),
                        bgColor: const Color(0xFFD1FAE5),
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
                        const Text(
                          'Overall Placement Rate',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Opening User Management...')),
                        );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Opening Broadcast Alert...')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tab Section: Company Approvals & Campus Drives
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Company Approvals'),
                        Tab(text: 'Active Drives'),
                        Tab(text: 'Analytics & Reports'),
                      ],
                    ),
                    SizedBox(
                      height: 1450,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Company Approvals (Phase 14B Redesigned UI)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Review and manage company account access',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    if (!_isLoadingApprovals &&
                                        _pendingApprovals.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                              ),
                              Expanded(
                                child: _isLoadingApprovals
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(24.0),
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : _approvalsError != null &&
                                            _pendingApprovals.isEmpty
                                        ? Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(24.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
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
                                          )
                                        : _pendingApprovals.isEmpty
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(24.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
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
                                              )
                                            : ListView.separated(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                itemCount:
                                                    _pendingApprovals.length,
                                                separatorBuilder: (context,
                                                        index) =>
                                                    const SizedBox(height: 10),
                                                itemBuilder: (context, index) {
                                                  final item =
                                                      _pendingApprovals[index];
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
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                              ),
                            ],
                          ),

                          // Tab 2: Active Drives (Phase 14A Real Data Integration)
                          _isLoadingDrives
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : _drivesError != null && _placementDrives.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            TextButton.icon(
                                              onPressed: _loadPlacementDrives,
                                              icon: const Icon(
                                                  Icons.refresh_rounded,
                                                  size: 18),
                                              label: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : _placementDrives.isEmpty
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(24.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .business_center_outlined,
                                                  color:
                                                      AppColors.textSecondary,
                                                  size: 36,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'No active placement drives available.',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
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
                            physics: BouncingScrollPhysics(),
                            padding: EdgeInsets.all(14),
                            child: AnalyticsReportsWidget(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
    return ListTile(
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
    );
  }
}
