import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';

/// User Management Screen for Admin to view and manage registered student profiles.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final GoogleSheetsService _apiService = GoogleSheetsService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _applyFilters();
    });
  }

  Future<void> _fetchStudents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.getAdminStudents();
      if (!mounted) return;

      if (res['success'] == true && res['students'] is List) {
        final List raw = res['students'];
        final List<Map<String, dynamic>> students =
            raw.map((s) => Map<String, dynamic>.from(s is Map ? s : {})).toList();

        setState(() {
          _allStudents = students;
          _isLoading = false;
          _applyFilters();
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to retrieve student records.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred while loading student records.';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> results = List.from(_allStudents);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      results = results.where((s) {
        final name = (s['name'] ?? '').toString().toLowerCase();
        final email = (s['email'] ?? '').toString().toLowerCase();
        final userId = (s['userId'] ?? s['studentId'] ?? '').toString().toLowerCase();
        final course = (s['course'] ?? s['education'] ?? '').toString().toLowerCase();

        return name.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            userId.contains(_searchQuery) ||
            course.contains(_searchQuery);
      }).toList();
    }

    // Filter by status dropdown
    if (_selectedStatusFilter != 'All') {
      results = results.where((s) {
        final status = (s['status'] ?? 'Active').toString().toLowerCase();
        return status == _selectedStatusFilter.toLowerCase();
      }).toList();
    }

    _filteredStudents = results;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackground(context);
    final surfaceColor = AppColors.getSurface(context);
    final textColor = AppColors.getTextPrimary(context);
    final subtextColor = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getCardBorder(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'User Management',
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
            icon: Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh Students',
            onPressed: _fetchStudents,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.all(16),
              color: surfaceColor,
              child: Column(
                children: [
                  // Search Bar Input
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by student name, email, ID, course...',
                      hintStyle: TextStyle(color: subtextColor, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.getInputBg(context),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Summary count and status chips row
                  Row(
                    children: [
                      Icon(Icons.people_alt_outlined, size: 18, color: subtextColor),
                      const SizedBox(width: 6),
                      Text(
                        '${_filteredStudents.length} Students Registered',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: subtextColor,
                        ),
                      ),
                      const Spacer(),
                      // Quick Filter Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.getInputBg(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatusFilter,
                            isDense: true,
                            icon: const Icon(Icons.filter_list, size: 16),
                            dropdownColor: surfaceColor,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            items: ['All', 'Active', 'Pending', 'Inactive']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedStatusFilter = val;
                                  _applyFilters();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Main Content Area
            Expanded(
              child: _buildBody(context, surfaceColor, textColor, subtextColor, borderColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Fetching student records...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
              const Icon(Icons.error_outline_rounded, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to Load Students',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: subtextColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchStudents,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredStudents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchStudents,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 40),
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No Students Found'
                  : 'No Registered Students',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No student profile matches "$_searchQuery". Try clearing your search.'
                  : 'There are currently no registered student records in the system.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: subtextColor),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () => _searchController.clear(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Search Filter'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchStudents,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredStudents.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];
          return _buildStudentCard(
            context,
            student,
            surfaceColor,
            textColor,
            subtextColor,
            borderColor,
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    Map<String, dynamic> student,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    final String name = student['name']?.toString() ?? 'Unnamed Student';
    final String email = student['email']?.toString() ?? 'No email provided';
    final String userId = student['userId']?.toString() ?? student['studentId']?.toString() ?? '';
    final String course = student['course']?.toString() ?? student['education']?.toString() ?? '';
    final String semester = student['semester']?.toString() ?? '';
    final String status = student['status']?.toString() ?? 'Active';

    final Color statusColor = status.toLowerCase() == 'active'
        ? Colors.green.shade700
        : (status.toLowerCase() == 'pending' ? Colors.amber.shade700 : Colors.red.shade600);

    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.studentDetails,
              arguments: student,
            ).then((_) => _fetchStudents());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with initial
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Student Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (userId.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.getInputBg(context),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                userId,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (course.isNotEmpty)
                            Expanded(
                              child: Text(
                                course + (semester.isNotEmpty ? ' • $semester' : ''),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: subtextColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
