import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/application_status_helper.dart';
import '../../models/system_broadcast.dart';
import '../../services/google_sheets_service.dart';

/// System Broadcast Screen for Admin to compose and dispatch campus announcements.
class SystemBroadcastScreen extends StatefulWidget {
  const SystemBroadcastScreen({super.key});

  @override
  State<SystemBroadcastScreen> createState() => _SystemBroadcastScreenState();
}

class _SystemBroadcastScreenState extends State<SystemBroadcastScreen> {
  final GoogleSheetsService _apiService = GoogleSheetsService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _selectedAudience = 'all'; // 'all', 'student', 'company'
  bool _isSubmitting = false;
  bool _isLoadingHistory = true;
  String? _historyError;

  List<SystemBroadcastItem> _broadcastHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchBroadcastHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBroadcastHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final res = await _apiService.getBroadcasts();
      if (!mounted) return;

      if (res['success'] == true && res['broadcasts'] is List) {
        final List raw = res['broadcasts'];
        final List<SystemBroadcastItem> broadcasts = raw
            .map((b) => SystemBroadcastItem.fromJson(Map<String, dynamic>.from(b is Map ? b : {})))
            .toList();

        setState(() {
          _broadcastHistory = broadcasts;
          _isLoadingHistory = false;
        });
      } else {
        setState(() {
          _historyError = res['message'] ?? 'Failed to load announcement history.';
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _historyError = 'An error occurred while loading announcements.';
        _isLoadingHistory = false;
      });
    }
  }

  void _showConfirmationDialog() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String title = _titleController.text.trim();
    final String audienceText = _getAudienceLabel(_selectedAudience);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Confirm Broadcast'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to send this broadcast announcement?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.getInputBg(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getCardBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Audience:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                    Text(
                      audienceText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Title:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send Broadcast'),
              onPressed: () {
                Navigator.pop(ctx);
                _sendBroadcast();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendBroadcast() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final res = await _apiService.sendBroadcast(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        audience: _selectedAudience,
        createdBy: 'Campus Admin',
      );

      if (!mounted) return;

      if (res['success'] == true) {
        _titleController.clear();
        _messageController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Broadcast sent successfully!'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );

        _fetchBroadcastHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to send broadcast.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred while sending broadcast.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getAudienceLabel(String code) {
    switch (code) {
      case 'student':
        return 'Students Only';
      case 'company':
        return 'Recruiters / Companies';
      case 'all':
      default:
        return 'All Campus Users';
    }
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
          'System Broadcast',
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
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh Announcements',
            onPressed: _fetchBroadcastHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compose Broadcast Header Card
              Container(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Compose Announcement',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Send placement notifications & news to campus users',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Target Audience Selection
                      Text(
                        'Target Audience',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: SegmentedButton<String>(
                                showSelectedIcon: false,
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                segments: const [
                                  ButtonSegment(
                                    value: 'all',
                                    label: Text(
                                      'All Users',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    icon: Icon(Icons.people_rounded, size: 16),
                                  ),
                                  ButtonSegment(
                                    value: 'student',
                                    label: Text(
                                      'Students',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    icon: Icon(Icons.school_rounded, size: 16),
                                  ),
                                  ButtonSegment(
                                    value: 'company',
                                    label: Text(
                                      'Recruiters',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    icon:
                                        Icon(Icons.business_rounded, size: 16),
                                  ),
                                ],
                                selected: {_selectedAudience},
                                onSelectionChanged: (newSelection) {
                                  setState(() {
                                    _selectedAudience = newSelection.first;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Title Input Field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Announcement Title *',
                          hintText: 'e.g. Drive Alert: TCS Campus Hiring 2026',
                          prefixIcon: const Icon(Icons.title_rounded,
                              color: AppColors.primary),
                          filled: true,
                          fillColor: AppColors.getInputBg(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter announcement title';
                          }
                          if (val.trim().length < 3) {
                            return 'Title must be at least 3 characters long';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Message Body Input Field
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Broadcast Message Body *',
                          hintText:
                              'Write your detailed message, instructions, links, or dates here...',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(Icons.article_outlined,
                                color: AppColors.primary),
                          ),
                          filled: true,
                          fillColor: AppColors.getInputBg(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter message content';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Send Broadcast Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _isSubmitting
                                  ? 'Sending Broadcast...'
                                  : 'Send Broadcast Announcement',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _showConfirmationDialog,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Announcement History Title Section
              Row(
                children: [
                  const Icon(Icons.history_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Announcement History',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_broadcastHistory.length} Sent',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Broadcast History Cards List
              _buildHistorySection(context, surfaceColor, textColor, subtextColor, borderColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    if (_isLoadingHistory) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_historyError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Text(
              _historyError!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _fetchBroadcastHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Loading History'),
            ),
          ],
        ),
      );
    }

    if (_broadcastHistory.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: subtextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No Announcements Sent Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sent system broadcast announcements will appear here.',
              style: TextStyle(fontSize: 13, color: subtextColor),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _broadcastHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _broadcastHistory[index];
        final audienceColor = item.audience.toLowerCase() == 'student'
            ? Colors.blue.shade700
            : (item.audience.toLowerCase() == 'company'
                ? Colors.purple.shade700
                : AppColors.primary);

        return Container(
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: audienceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.audienceLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: audienceColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item.date.isNotEmpty)
                    Expanded(
                      child: Text(
                        ApplicationStatusHelper.formatDisplayDateTime(item.date),
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 11, color: subtextColor),
                        softWrap: true,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                softWrap: true,
              ),
              const SizedBox(height: 6),
              Text(
                item.message,
                style: TextStyle(
                  fontSize: 14,
                  color: subtextColor,
                  height: 1.4,
                ),
                softWrap: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person_pin_rounded,
                      size: 14, color: subtextColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Sent by ${item.createdBy}',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: subtextColor.withValues(alpha: 0.8),
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
