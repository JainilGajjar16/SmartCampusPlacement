import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_snackbar.dart';
import '../../main.dart';
import '../../models/job.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/theme_toggle_button.dart';

/// Screen displaying the list of active campus placement and internship jobs
/// with search, filtering, sorting, and reset capabilities.
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _apiService = GoogleSheetsService();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  List<Job> _allJobs = [];
  List<Job> _filteredJobs = [];

  // Filter & Sort State
  String _selectedLocation = 'All';
  String _selectedJobType = 'All';
  String _selectedSkill = 'All';
  String _sortBy = AppStrings.sortNewest;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applySearchAndFilter();
  }

  Future<void> _fetchJobs() async {
    if (_isLoading && _allJobs.isNotEmpty) return;

    if (_allJobs.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }

    final response = await _apiService.getJobs();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response['success'] == true) {
        _allJobs = (response['jobs'] as List<Job>?) ?? [];
        _applySearchAndFilter();
      } else {
        if (_allJobs.isEmpty) {
          _errorMessage =
              response['message']?.toString() ?? AppStrings.apiServerError;
        } else {
          AppSnackBar.show(
            context,
            message: response['message']?.toString() ?? AppStrings.apiServerError,
          );
        }
      }
    });
  }

  /// Dynamically extracts distinct location options from current job listings.
  List<String> get _distinctLocations {
    final set = <String>{};
    for (final job in _allJobs) {
      final loc = job.location.trim();
      if (loc.isNotEmpty) {
        set.add(loc);
      }
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  /// Dynamically extracts distinct job type options from current job listings.
  List<String> get _distinctJobTypes {
    final set = <String>{};
    for (final job in _allJobs) {
      final type = job.jobType.trim();
      if (type.isNotEmpty) {
        set.add(type);
      }
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  /// Dynamically extracts distinct skill tags from current job listings.
  List<String> get _distinctSkills {
    final set = <String>{};
    for (final job in _allJobs) {
      final raw = job.skills;
      if (raw.isNotEmpty) {
        final split = raw.split(RegExp(r'[,/|]'));
        for (var s in split) {
          final trimmed = s.trim();
          if (trimmed.isNotEmpty) {
            set.add(trimmed);
          }
        }
      }
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  /// Returns the number of active filters.
  int get _activeFilterCount {
    int count = 0;
    if (_searchController.text.trim().isNotEmpty) count++;
    if (_selectedLocation != 'All') count++;
    if (_selectedJobType != 'All') count++;
    if (_selectedSkill != 'All') count++;
    if (_sortBy != AppStrings.sortNewest) count++;
    return count;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedLocation = 'All';
      _selectedJobType = 'All';
      _selectedSkill = 'All';
      _sortBy = AppStrings.sortNewest;
      _applySearchAndFilter();
    });
  }

  /// Helper to convert salary text strings into numeric value for sorting.
  double _parseSalary(String salaryStr) {
    if (salaryStr.isEmpty) return 0;
    final lower = salaryStr.toLowerCase();

    // Check for LPA values (e.g. 12 LPA or 8.5 LPA)
    final lpaMatch = RegExp(r'([\d\.]+)\s*lpa').firstMatch(lower);
    if (lpaMatch != null) {
      final val = double.tryParse(lpaMatch.group(1) ?? '') ?? 0;
      return val * 100000;
    }

    // Extract raw digits
    final cleaned = salaryStr.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  /// Core search, multi-criteria filter, and sort pipeline.
  void _applySearchAndFilter() {
    final query = _searchController.text.trim().toLowerCase();

    List<Job> list = _allJobs.where((job) {
      // 1. Search Query Filter (Title, Company, Location, Skills)
      if (query.isNotEmpty) {
        final title = job.title.toLowerCase();
        final company = job.company.toLowerCase();
        final location = job.location.toLowerCase();
        final skills = job.skills.toLowerCase();
        final matchesQuery = title.contains(query) ||
            company.contains(query) ||
            location.contains(query) ||
            skills.contains(query);
        if (!matchesQuery) return false;
      }

      // 2. Location Filter
      if (_selectedLocation != 'All') {
        if (job.location.toLowerCase() != _selectedLocation.toLowerCase()) {
          return false;
        }
      }

      // 3. Job Type Filter
      if (_selectedJobType != 'All') {
        if (job.jobType.toLowerCase() != _selectedJobType.toLowerCase()) {
          return false;
        }
      }

      // 4. Skill Filter
      if (_selectedSkill != 'All') {
        if (!job.skills.toLowerCase().contains(_selectedSkill.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();

    // 5. Sorting Pipeline
    if (_sortBy == AppStrings.sortSalaryHighToLow) {
      list.sort(
          (a, b) => _parseSalary(b.salary).compareTo(_parseSalary(a.salary)));
    } else if (_sortBy == AppStrings.sortSalaryLowToHigh) {
      list.sort(
          (a, b) => _parseSalary(a.salary).compareTo(_parseSalary(b.salary)));
    } else if (_sortBy == AppStrings.sortTitleAZ) {
      list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    setState(() {
      _filteredJobs = list;
    });
  }

  void _navigateToJobDetails(String jobId) {
    Navigator.pushNamed(
      context,
      AppRoutes.jobDetails,
      arguments: {'jobId': jobId},
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle indicator bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        AppStrings.filterJobs,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_hasActiveFilters)
                        TextButton.icon(
                          onPressed: () {
                            _resetFilters();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.refresh_rounded,
                              size: 16, color: AppColors.primary),
                          label: const Text(
                            AppStrings.resetFilters,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Filter Sections
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Sort By
                          _buildFilterLabel(AppStrings.sortBy),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AppStrings.sortNewest,
                              AppStrings.sortSalaryHighToLow,
                              AppStrings.sortSalaryLowToHigh,
                              AppStrings.sortTitleAZ,
                            ].map((sortOption) {
                              final isSelected = _sortBy == sortOption;
                              return ChoiceChip(
                                label: Text(sortOption),
                                selected: isSelected,
                                selectedColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                backgroundColor: AppColors.inputBg,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() {
                                      _sortBy = sortOption;
                                    });
                                    setState(() {
                                      _sortBy = sortOption;
                                      _applySearchAndFilter();
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),

                          // 2. Location Filter
                          _buildFilterLabel(AppStrings.locationLabel),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedLocation,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              fillColor: AppColors.inputBg,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: _distinctLocations.map((loc) {
                              return DropdownMenuItem(
                                value: loc,
                                child: Text(
                                  loc == 'All' ? AppStrings.allLocations : loc,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  _selectedLocation = val;
                                });
                                setState(() {
                                  _selectedLocation = val;
                                  _applySearchAndFilter();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          // 3. Job Type Filter
                          _buildFilterLabel(AppStrings.jobTypeLabel),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedJobType,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              fillColor: AppColors.inputBg,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: _distinctJobTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type == 'All' ? AppStrings.allJobTypes : type,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  _selectedJobType = val;
                                });
                                setState(() {
                                  _selectedJobType = val;
                                  _applySearchAndFilter();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          // 4. Skills Filter
                          _buildFilterLabel(AppStrings.skillsRequired),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedSkill,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              fillColor: AppColors.inputBg,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: _distinctSkills.map((skill) {
                              return DropdownMenuItem(
                                value: skill,
                                child: Text(
                                  skill == 'All' ? AppStrings.allSkills : skill,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  _selectedSkill = val;
                                });
                                setState(() {
                                  _selectedSkill = val;
                                  _applySearchAndFilter();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Button
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Apply Filters (${_filteredJobs.length} Jobs)',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.getTextPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.availableJobs,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        actions: [
          ThemeToggleButton(themeProvider: globalThemeProvider),
          // Filter Icon Action Button with Active Badge Counter
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.tune_rounded, color: AppColors.getTextPrimary(context)),
                onPressed: _showFilterBottomSheet,
              ),
              if (_hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_activeFilterCount',
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
        ],
      ),
      body: SafeArea(
        child: FadeSlideTransition(
          child: Column(
            children: [
              // Search & Active Filter Bar
              _buildSearchAndFilterHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchJobs,
                  color: AppColors.primary,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        children: [
          // Search TextField Input
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: AppStrings.searchJobsHint,
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.textLight),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.primary, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded,
                          color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Active Filter Chips Summary Row
          if (_hasActiveFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _resetFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.close_rounded,
                              size: 12, color: Colors.redAccent),
                          SizedBox(width: 4),
                          Text(
                            AppStrings.resetFilters,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedLocation != 'All')
                    _buildActiveChip('Loc: $_selectedLocation'),
                  if (_selectedJobType != 'All')
                    _buildActiveChip('Type: $_selectedJobType'),
                  if (_selectedSkill != 'All')
                    _buildActiveChip('Skill: $_selectedSkill'),
                  if (_sortBy != AppStrings.sortNewest)
                    _buildActiveChip('Sort: $_sortBy'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
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

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 48,
                ),
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
                onPressed: _fetchJobs,
              ),
            ],
          ),
        ),
      );
    }

    if (_allJobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.work_off_rounded,
                    color: AppColors.primary,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  AppStrings.noJobsAvailable,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check back later for new campus placement opportunities.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Filter Empty State (Jobs exist in backend, but none match current query/filters)
    if (_filteredJobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      color: AppColors.primary,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    AppStrings.noJobsMatchTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.noJobsMatchSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: AppStrings.resetFilters,
                    icon: Icons.refresh_rounded,
                    onPressed: _resetFilters,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      itemCount: _filteredJobs.length,
      itemBuilder: (context, index) {
        final job = _filteredJobs[index];
        return _JobCard(
          job: job,
          onTap: () => _navigateToJobDetails(job.jobId),
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBgJobs,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company avatar box
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title.isNotEmpty ? job.title : 'Position',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.company.isNotEmpty ? job.company : 'Company',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Location and metadata row
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (job.location.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    if (job.jobType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          job.jobType,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (job.salary.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          job.salary,
                          style: const TextStyle(
                            fontSize: 11,
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
        ),
      ),
    );
  }
}
