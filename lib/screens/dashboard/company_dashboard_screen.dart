import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/application_status_helper.dart';
import '../../models/job.dart';
import '../../models/user_session.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';

/// Original Company Dashboard implementation using real Google Sheets data backend.
class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

typedef CompanyDashboardScreen = CompanyDashboard;

class _CompanyDashboardState extends State<CompanyDashboard> {
  bool _isLoading = true;
  List<Job> _companyJobs = [];
  List<Map<String, dynamic>> _companyApps = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanyData();
  }

  Future<void> _fetchCompanyData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final session = UserSession();
    final String currentCompanyId = session.userId ?? '';
    final String currentCompanyName = session.name ?? '';

    try {
      // 1. Fetch real jobs from Google Sheets
      final jobsResult = await GoogleSheetsService().getJobs();
      final List<Job> allJobs = jobsResult['jobs'] as List<Job>? ?? [];

      final companyJobs = allJobs.where((job) {
        final c = job.company.toLowerCase();
        final targetId = currentCompanyId.toLowerCase();
        final targetName = currentCompanyName.toLowerCase();
        if (targetId.isNotEmpty && (c.contains(targetId) || targetId.contains(c))) {
          return true;
        }
        if (targetName.isNotEmpty && (c.contains(targetName) || targetName.contains(c))) {
          return true;
        }
        return false;
      }).toList();

      // 2. Fetch real company applications
      final appsResult = await GoogleSheetsService().getCompanyApplications(
        companyId: currentCompanyId.isNotEmpty ? currentCompanyId : currentCompanyName,
      );
      final List<Map<String, dynamic>> companyApps =
          appsResult['applications'] as List<Map<String, dynamic>>? ?? [];

      if (mounted) {
        setState(() {
          _companyJobs = companyJobs;
          _companyApps = companyApps;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Sign out from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              UserSession().clearSession();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSession();
    final String companyName = session.name?.isNotEmpty == true ? session.name! : 'Company';

    final int postedJobsCount = _companyJobs.length;
    final int totalApplicantsCount = _companyApps.length;
    final int pendingAppsCount = _companyApps.where((a) {
      final norm = ApplicationStatusHelper.normalizeStatus(a['status']);
      return norm == ApplicationStatusHelper.statusApplied ||
          norm == ApplicationStatusHelper.statusUnderReview;
    }).length;
    final int selectedStudentsCount = _companyApps.where((a) {
      return ApplicationStatusHelper.normalizeStatus(a['status']) ==
          ApplicationStatusHelper.statusSelected;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text(
          'Company Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchCompanyData,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchCompanyData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, $companyName 🏢',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage jobs and campus recruitment.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions Section
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // Compact & Responsive Quick Actions Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isDesktop = constraints.maxWidth >= 600;
                    return GridView.count(
                      crossAxisCount: isDesktop ? 3 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isDesktop ? 2.0 : 1.6,
                      children: [
                        _buildQuickActionCard(
                          icon: Icons.add_business,
                          color: Colors.green,
                          title: 'Post Job',
                          subtitle: 'Create a new job opening',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PostJobScreen(),
                              ),
                            ).then((_) => _fetchCompanyData());
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.work_outline,
                          color: Colors.orange,
                          title: 'My Jobs',
                          subtitle: 'View your posted jobs',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyJobsScreen(),
                              ),
                            ).then((_) => _fetchCompanyData());
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.people_outline,
                          color: Colors.blue,
                          title: 'Applicants',
                          subtitle: 'View student applications',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ApplicantsScreen(),
                              ),
                            ).then((_) => _fetchCompanyData());
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.description_outlined,
                          color: Colors.purple,
                          title: 'Student Resumes',
                          subtitle: 'View applicant resumes',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CompanyResumesScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.business_outlined,
                          color: Colors.indigo,
                          title: 'Company Profile',
                          subtitle: 'Manage company info',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CompanyProfileScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.logout,
                          color: Colors.red,
                          title: 'Logout',
                          subtitle: 'Sign out from account',
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Recruitment Overview Section
                const Text(
                  'Recruitment Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildOverviewItem(
                          icon: Icons.work,
                          color: Colors.orange,
                          title: 'Posted Jobs',
                          value: '$postedJobsCount',
                        ),
                        const Divider(height: 1),
                        _buildOverviewItem(
                          icon: Icons.people,
                          color: Colors.blue,
                          title: 'Total Applicants',
                          value: '$totalApplicantsCount',
                        ),
                        const Divider(height: 1),
                        _buildOverviewItem(
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                          title: 'Pending Applications',
                          value: '$pendingAppsCount',
                        ),
                        const Divider(height: 1),
                        _buildOverviewItem(
                          icon: Icons.check_circle,
                          color: Colors.green,
                          title: 'Selected Students',
                          value: '$selectedStudentsCount',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
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
        ),
      ),
    );
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 1. POST JOB SCREEN - Connected to Google Sheets Backend
class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _locationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final session = UserSession();
    _companyNameController.text =
        session.name?.isNotEmpty == true ? session.name! : (session.userId ?? 'Company');
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _jobTitleController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitJob() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final res = await GoogleSheetsService().postJob(
        title: _jobTitleController.text.trim(),
        company: _companyNameController.text.trim(),
        location: _locationController.text.trim(),
        skills: _skillsController.text.trim(),
        salary: _salaryController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job opening posted to Google Sheets successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to post job.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.add_business, color: Colors.green),
            SizedBox(width: 8),
            Text('Create Job Opening'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _companyNameController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jobTitleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter job title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Required Skills',
                  hintText: 'e.g. Flutter, Dart, REST API',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter required skills' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Salary',
                  hintText: 'e.g. ₹12 LPA',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter salary' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter job description'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitJob,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.publish, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'POSTING...' : 'POST JOB',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. MY JOBS SCREEN - Real Google Sheets Jobs Data
class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  bool _isLoading = true;
  List<Job> _jobs = [];
  Map<String, int> _applicantCounts = {};

  @override
  void initState() {
    super.initState();
    _loadMyJobs();
  }

  Future<void> _loadMyJobs() async {
    setState(() => _isLoading = true);
    final session = UserSession();
    final String cId = session.userId?.toLowerCase() ?? '';
    final String cName = session.name?.toLowerCase() ?? '';

    try {
      final res = await GoogleSheetsService().getJobs();
      final List<Job> allJobs = res['jobs'] as List<Job>? ?? [];

      final myJobs = allJobs.where((j) {
        final comp = j.company.toLowerCase();
        if (cId.isNotEmpty && (comp.contains(cId) || cId.contains(comp))) return true;
        if (cName.isNotEmpty && (comp.contains(cName) || cName.contains(comp))) return true;
        return false;
      }).toList();

      // Fetch applications to get accurate applicant count per job
      final appsRes = await GoogleSheetsService().getCompanyApplications(
        companyId: session.userId ?? '',
      );
      final List apps = appsRes['applications'] as List? ?? [];
      final Map<String, int> counts = {};
      for (final a in apps) {
        final jId = (a['jobId'] ?? '').toString();
        counts[jId] = (counts[jId] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _jobs = myJobs;
          _applicantCounts = counts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyJobs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No job openings posted yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMyJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _jobs.length,
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      final count = _applicantCounts[job.jobId] ?? 0;
                      return CompanyJobCard(
                        job: {
                          'id': job.jobId,
                          'title': job.title,
                          'company': job.company,
                          'location': job.location,
                          'skills': job.skills,
                          'salary': job.salary,
                          'description': job.description,
                          'status': job.status,
                          'postedDate': job.postedDate,
                          'applicants': count,
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

/// COMPANY JOB CARD IMPLEMENTATION
class CompanyJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback? onDelete;

  const CompanyJobCard({
    super.key,
    required this.job,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = job['status'] ?? 'Active';
    final isInactive = status.toString().toLowerCase() != 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job['title'] ?? 'Job Title',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInactive
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isInactive ? Colors.grey[700] : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              job['company'] ?? 'Company Name',
              style: TextStyle(
                  color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(job['location'] ?? 'Location'),
                const SizedBox(width: 16),
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(job['salary'] ?? 'Salary'),
              ],
            ),
            if (job['skills'] != null &&
                job['skills'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Skills: ${job['skills']}',
                style:
                    const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${job['applicants'] ?? 0} Applicants',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. APPLICANTS SCREEN - Real Google Sheets Applications
class ApplicantsScreen extends StatefulWidget {
  const ApplicantsScreen({super.key});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _applicants = [];

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    setState(() => _isLoading = true);
    final session = UserSession();
    try {
      final res = await GoogleSheetsService().getCompanyApplications(
        companyId: session.userId ?? '',
      );
      final List<Map<String, dynamic>> apps =
          res['applications'] as List<Map<String, dynamic>>? ?? [];

      if (mounted) {
        setState(() {
          _applicants = apps;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String appId, String newStatus) async {
    final res = await GoogleSheetsService().updateApplicationStatus(
      applicationId: appId,
      status: newStatus,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadApplicants();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatusDialog(Map<String, dynamic> app) {
    final currentStatus = ApplicationStatusHelper.normalizeStatus(app['status']);
    final statuses = [
      ApplicationStatusHelper.statusUnderReview,
      ApplicationStatusHelper.statusShortlisted,
      ApplicationStatusHelper.statusSelected,
      ApplicationStatusHelper.statusRejected,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status: ${app['studentName'] ?? app['userId']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            final isCurrent = currentStatus == status;
            return ListTile(
              title: Text(status),
              leading: Icon(
                ApplicationStatusHelper.getStatusIcon(status),
                color: ApplicationStatusHelper.getStatusColor(status),
              ),
              trailing: isCurrent ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                Navigator.pop(context);
                _updateStatus(app['applicationId'].toString(), status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplicants,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applicants.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No student applications received yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApplicants,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _applicants.length,
                    itemBuilder: (context, index) {
                      final app = _applicants[index];
                      final name = (app['studentName'] ?? '').toString().isNotEmpty
                          ? app['studentName'].toString()
                          : (app['userId'] ?? 'Student');
                      final rawStatus = (app['status'] ?? 'Applied').toString();
                      final statusColor = ApplicationStatusHelper.getStatusColor(rawStatus);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.1),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'S',
                              style: TextStyle(
                                  color: statusColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Role: ${app['title'] ?? app['jobId'] ?? 'Applied Position'}'),
                              Text(
                                'CGPA: ${app['cgpa']?.toString().isNotEmpty == true ? app['cgpa'] : 'N/A'} | Status: $rawStatus',
                              ),
                            ],
                          ),
                          trailing: ActionChip(
                            avatar: Icon(
                              ApplicationStatusHelper.getStatusIcon(rawStatus),
                              size: 16,
                              color: statusColor,
                            ),
                            label: Text(
                              rawStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: ApplicationStatusHelper.getStatusBgColor(rawStatus),
                            side: BorderSide(
                              color: ApplicationStatusHelper.getStatusBorderColor(rawStatus),
                            ),
                            onPressed: () => _showStatusDialog(app),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

/// 4. STUDENT RESUMES SCREEN - Real Student Resumes
class CompanyResumesScreen extends StatefulWidget {
  const CompanyResumesScreen({super.key});

  @override
  State<CompanyResumesScreen> createState() => _CompanyResumesScreenState();
}

class _CompanyResumesScreenState extends State<CompanyResumesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _resumes = [];

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    setState(() => _isLoading = true);
    final session = UserSession();
    try {
      final res = await GoogleSheetsService().getCompanyApplications(
        companyId: session.userId ?? '',
      );
      final List<Map<String, dynamic>> apps =
          res['applications'] as List<Map<String, dynamic>>? ?? [];

      // Filter applicants who have filled education/skills or uploaded resumes
      final resumes = apps.where((a) {
        final rUrl = (a['resumeUrl'] ?? '').toString();
        final name = (a['studentName'] ?? '').toString();
        final userId = (a['userId'] ?? '').toString();
        return rUrl.isNotEmpty || name.isNotEmpty || userId.isNotEmpty;
      }).toList();

      if (mounted) {
        setState(() {
          _resumes = resumes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openResume(String url, String name) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No resume link available for $name')),
      );
      return;
    }
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resume URL: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Resumes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResumes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _resumes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No student resumes available.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadResumes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resumes.length,
                    itemBuilder: (context, index) {
                      final res = _resumes[index];
                      final name = (res['studentName'] ?? res['userId'] ?? 'Student').toString();
                      final education = (res['education'] ?? 'Computer Science').toString();
                      final skills = (res['skills'] ?? 'Flutter, Software Engineering').toString();
                      final resumeUrl = (res['resumeUrl'] ?? '').toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.purpleAccent,
                            child: Icon(Icons.description, color: Colors.white),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('$education • $skills'),
                          trailing: ElevatedButton(
                            onPressed: () => _openResume(resumeUrl, name),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                            child: const Text(
                              'View',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

/// 5. COMPANY PROFILE SCREEN - Real UserSession Data
class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final session = UserSession();
    final companyName = session.name?.isNotEmpty == true ? session.name! : 'Company Profile';
    final companyId = session.userId?.isNotEmpty == true ? session.userId! : 'COM001';
    final email = session.email?.isNotEmpty == true ? session.email! : 'contact@campus.edu';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.indigo,
              child: Icon(Icons.business, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              companyName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              'Company ID: $companyId',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email_outlined, color: Colors.indigo),
                      title: const Text('Email'),
                      subtitle: Text(email),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined, color: Colors.indigo),
                      title: const Text('User ID'),
                      subtitle: Text(companyId),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.security_outlined, color: Colors.indigo),
                      title: const Text('Role'),
                      subtitle: Text(session.role ?? 'Company / Recruiter'),
                    ),
                    const Divider(),
                    const ListTile(
                      leading: Icon(Icons.info_outline, color: Colors.indigo),
                      title: Text('Account Status'),
                      subtitle: Text('Active (Verified Partner)'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
