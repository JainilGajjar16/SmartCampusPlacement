import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job.dart';
import '../../services/google_sheets_service.dart';

/// Screen for Admin to view and manage Active/Inactive status of jobs for a specific company.
class AdminManageJobsScreen extends StatefulWidget {
  final String companyId;
  final String companyName;
  final String? companyEmail;

  const AdminManageJobsScreen({
    super.key,
    required this.companyId,
    required this.companyName,
    this.companyEmail,
  });

  @override
  State<AdminManageJobsScreen> createState() => _AdminManageJobsScreenState();
}

class _AdminManageJobsScreenState extends State<AdminManageJobsScreen> {
  final GoogleSheetsService _apiService = GoogleSheetsService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Job> _allJobs = [];
  List<Job> _filteredJobs = [];
  String _selectedFilter = 'All'; // 'All', 'Active', 'Inactive'
  final Map<String, bool> _updatingJobs = {};

  @override
  void initState() {
    super.initState();
    _fetchCompanyJobs();
  }

  Future<void> _fetchCompanyJobs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.getCompanyJobs(
        companyId: widget.companyId,
        companyName: widget.companyName,
      );

      if (!mounted) return;

      if (res['success'] == true && res['jobs'] is List<Job>) {
        final List<Job> rawJobs = res['jobs'] as List<Job>;

        // Client-side filtering ensures strict company isolation
        final targetId = widget.companyId.trim().toLowerCase();
        final targetName = widget.companyName.trim().toLowerCase();

        final companyOnlyJobs = rawJobs.where((job) {
          final c = job.company.trim().toLowerCase();
          if (targetId.isNotEmpty && (c.contains(targetId) || targetId.contains(c))) {
            return true;
          }
          if (targetName.isNotEmpty && (c.contains(targetName) || targetName.contains(c))) {
            return true;
          }
          return false;
        }).toList();

        setState(() {
          _allJobs = companyOnlyJobs;
          _isLoading = false;
          _applyFilter();
        });
      } else {
        setState(() {
          _errorMessage = res['message']?.toString() ?? 'Failed to load company jobs.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred while loading jobs.';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'Active') {
        _filteredJobs = _allJobs.where((j) => j.status.toLowerCase() == 'active').toList();
      } else if (_selectedFilter == 'Inactive') {
        _filteredJobs = _allJobs.where((j) => j.status.toLowerCase() != 'active').toList();
      } else {
        _filteredJobs = List.from(_allJobs);
      }
    });
  }

  Future<void> _toggleJobStatus(Job job) async {
    final bool isCurrentlyActive = job.status.toLowerCase() == 'active';
    final String targetStatus = isCurrentlyActive ? 'Inactive' : 'Active';

    final String confirmationMessage = isCurrentlyActive
        ? 'Are you sure you want to deactivate this job?'
        : 'Are you sure you want to activate this job?';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isCurrentlyActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
              color: isCurrentlyActive ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(isCurrentlyActive ? 'Deactivate Job' : 'Activate Job'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              confirmationMessage,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Job ID: ${job.jobId}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isCurrentlyActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _updatingJobs[job.jobId] = true;
    });

    final res = await _apiService.updateJobStatus(
      jobId: job.jobId,
      status: targetStatus,
    );

    if (!mounted) return;

    setState(() {
      _updatingJobs.remove(job.jobId);
    });

    if (res['success'] == true) {
      // Update local state immediately
      setState(() {
        final index = _allJobs.indexWhere((j) => j.jobId == job.jobId);
        if (index != -1) {
          final existing = _allJobs[index];
          _allJobs[index] = Job(
            jobId: existing.jobId,
            title: existing.title,
            company: existing.company,
            location: existing.location,
            jobType: existing.jobType,
            skills: existing.skills,
            salary: existing.salary,
            description: existing.description,
            status: targetStatus,
            postedDate: existing.postedDate,
            maxHiring: existing.maxHiring,
            applicationCount: existing.applicationCount,
          );
        }
        _applyFilter();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            targetStatus == 'Active'
                ? 'Job "${job.title}" activated successfully.'
                : 'Job "${job.title}" deactivated successfully.',
          ),
          backgroundColor: targetStatus == 'Active' ? Colors.green : Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Failed to update job status.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = AppColors.getBackground(context);
    final Color surfaceColor = AppColors.getSurface(context);
    final Color textColor = AppColors.getTextPrimary(context);
    final Color subtextColor = AppColors.getTextSecondary(context);
    final Color borderColor = AppColors.getCardBorder(context);

    final int activeCount = _allJobs.where((j) => j.status.toLowerCase() == 'active').length;
    final int inactiveCount = _allJobs.length - activeCount;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0.5,
        title: Text(
          '${widget.companyName} - Job Management',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh Jobs',
            onPressed: _fetchCompanyJobs,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Company Info Header Card
            Container(
              padding: const EdgeInsets.all(16),
              color: surfaceColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.companyName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            if (widget.companyEmail != null && widget.companyEmail!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.companyEmail!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', _allJobs.length, isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('Active', activeCount, isDark, activeColor: Colors.green),
                        const SizedBox(width: 8),
                        _buildFilterChip('Inactive', inactiveCount, isDark, activeColor: Colors.orange.shade800),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Main Body: List or States
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.orange),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: subtextColor, fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _fetchCompanyJobs,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _filteredJobs.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.work_off_outlined, size: 48, color: subtextColor),
                                    const SizedBox(height: 12),
                                    Text(
                                      _allJobs.isEmpty
                                          ? 'No jobs found for ${widget.companyName}.'
                                          : 'No $_selectedFilter jobs found.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: subtextColor, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchCompanyJobs,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredJobs.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final job = _filteredJobs[index];
                                  return _buildJobCard(job, surfaceColor, borderColor, textColor, subtextColor);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, bool isDark, {Color? activeColor}) {
    final bool isSelected = _selectedFilter == label;
    final Color tint = activeColor ?? AppColors.primary;

    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
            _applyFilter();
          });
        }
      },
      selectedColor: tint.withValues(alpha: 0.15),
      backgroundColor: isDark ? AppColors.darkCardBorder : Colors.grey.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? tint : null,
      ),
      side: BorderSide(
        color: isSelected ? tint : Colors.transparent,
      ),
    );
  }

  Widget _buildJobCard(
    Job job,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    final bool isActive = job.status.toLowerCase() == 'active';
    final bool isUpdating = _updatingJobs[job.jobId] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${job.jobId}',
                      style: TextStyle(
                        fontSize: 11,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Current Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green.shade700 : Colors.orange.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Details: Location, Salary, Posted Date
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: subtextColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.location.isNotEmpty ? job.location : 'Not specified',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.payments_outlined, size: 14, color: subtextColor),
              const SizedBox(width: 4),
              Text(
                job.salary.isNotEmpty ? job.salary : 'Not specified',
                style: TextStyle(fontSize: 12, color: subtextColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: subtextColor),
              const SizedBox(width: 4),
              Text(
                'Posted: ${job.postedDate.isNotEmpty ? job.postedDate : 'N/A'}',
                style: TextStyle(fontSize: 12, color: subtextColor),
              ),
              const SizedBox(width: 12),
              Icon(Icons.work_outline, size: 14, color: subtextColor),
              const SizedBox(width: 4),
              Text(
                job.jobType.isNotEmpty ? job.jobType : 'Full-time',
                style: TextStyle(fontSize: 12, color: subtextColor),
              ),
            ],
          ),

          // Required Skills
          if (job.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Required Skills:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              job.skills,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Status Explanation Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withValues(alpha: 0.07)
                  : Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle_outline : Icons.info_outline,
                  size: 16,
                  color: isActive ? Colors.green : Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? 'Status: ACTIVE' : 'Status: INACTIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green.shade800 : Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isActive
                            ? 'Students can view and apply for this job.'
                            : 'Students cannot view or apply for this job.',
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Button: [ Make Inactive ] or [ Make Active ]
          SizedBox(
            width: double.infinity,
            child: isUpdating
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _toggleJobStatus(job),
                    icon: Icon(
                      isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      size: 16,
                    ),
                    label: Text(isActive ? 'Make Inactive' : 'Make Active'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive ? Colors.red : Colors.green,
                      side: BorderSide(
                        color: (isActive ? Colors.red : Colors.green).withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
