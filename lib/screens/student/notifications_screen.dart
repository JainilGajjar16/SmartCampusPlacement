import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_snackbar.dart';
import '../../main.dart';
import '../../models/notification_item.dart';
import '../../models/user_session.dart';
import '../../services/google_sheets_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/theme_toggle_button.dart';

/// Screen displaying notifications for the logged-in student (Phase 8).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _apiService = GoogleSheetsService();

  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  String _selectedFilter = AppStrings.filterAll;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final userId = UserSession().userId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppStrings.errSessionRequired;
      });
      return;
    }

    if (_isLoading && _notifications.isNotEmpty) return;

    if (_notifications.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }

    final result = await _apiService.getNotifications(userId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _notifications = result['notifications'] is List<NotificationItem>
            ? result['notifications'] as List<NotificationItem>
            : <NotificationItem>[];
        _unreadCount = result['unreadCount'] is int
            ? result['unreadCount'] as int
            : 0;
      } else {
        if (_notifications.isEmpty) {
          _errorMessage = result['message']?.toString() ?? 'Failed to load notifications.';
        } else {
          AppSnackBar.show(
            context,
            message: result['message']?.toString() ?? 'Failed to refresh notifications.',
          );
        }
      }
    });
  }

  Future<void> _markAsRead(NotificationItem item) async {
    if (item.isRead) return;

    final userId = UserSession().userId;
    if (userId == null || userId.isEmpty) return;

    // Optimistic UI update
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == item.id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        if (_unreadCount > 0) _unreadCount--;
      }
    });

    final response = await _apiService.markNotificationAsRead(
      notificationId: item.id,
      userId: userId,
    );

    if (!mounted) return;

    if (response['success'] != true) {
      // Revert if request failed
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == item.id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: false);
          _unreadCount++;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = UserSession().userId;
    if (userId == null || userId.isEmpty || _unreadCount == 0) return;

    // Optimistic UI update
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
    });

    final response = await _apiService.markAllNotificationsAsRead(userId);

    if (!mounted) return;

    if (response['success'] == true) {
      AppSnackBar.show(
        context,
        message: AppStrings.allNotificationsRead,
      );
    } else {
      _fetchNotifications(); // Refresh on failure to ensure data integrity
    }
  }

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilter == AppStrings.filterUnread) {
      return _notifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == AppStrings.filterApplications) {
      return _notifications.where((n) => n.type.toLowerCase() == 'application').toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.getTextPrimary(context)),
          onPressed: () => Navigator.pop(context, _unreadCount),
        ),
        title: Row(
          children: [
            Text(
              AppStrings.notificationsTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ThemeToggleButton(themeProvider: globalThemeProvider),
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
              label: const Text(
                AppStrings.markAllAsRead,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: FadeSlideTransition(
          child: RefreshIndicator(
            onRefresh: _fetchNotifications,
            color: AppColors.primary,
            child: _buildBody(),
          ),
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
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
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: AppStrings.retry,
                    icon: Icons.refresh_rounded,
                    onPressed: _fetchNotifications,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final filteredList = _filteredNotifications;

    return Column(
      children: [
        // Filter Chips Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            children: [
              _FilterChip(
                label: AppStrings.filterAll,
                count: _notifications.length,
                isSelected: _selectedFilter == AppStrings.filterAll,
                onSelected: () {
                  setState(() => _selectedFilter = AppStrings.filterAll);
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppStrings.filterUnread,
                count: _unreadCount,
                isSelected: _selectedFilter == AppStrings.filterUnread,
                onSelected: () {
                  setState(() => _selectedFilter = AppStrings.filterUnread);
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: AppStrings.filterApplications,
                count: _notifications.where((n) => n.type.toLowerCase() == 'application').length,
                isSelected: _selectedFilter == AppStrings.filterApplications,
                onSelected: () {
                  setState(() => _selectedFilter = AppStrings.filterApplications);
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: filteredList.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.primary,
                                size: 56,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              AppStrings.noNotifications,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              AppStrings.noNotificationsSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return _NotificationCard(
                      item: item,
                      onTap: () => _markAsRead(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'application':
        return Icons.send_rounded;
      case 'job_alert':
        return Icons.business_center_rounded;
      case 'status_update':
        return Icons.update_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'application':
        return const Color(0xFF8B5CF6); // Purple
      case 'job_alert':
        return const Color(0xFFF59E0B); // Amber
      case 'status_update':
        return const Color(0xFF10B981); // Emerald
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(item.type);
    final typeIcon = _getTypeIcon(item.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: item.isRead
            ? Colors.white
            : AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead
              ? AppColors.textSecondary.withValues(alpha: 0.12)
              : AppColors.primary.withValues(alpha: 0.3),
          width: item.isRead ? 1.0 : 1.5,
        ),
        boxShadow: item.isRead
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Icon Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: item.isRead
                                    ? FontWeight.bold
                                    : FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!item.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      if (item.date.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.date,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
