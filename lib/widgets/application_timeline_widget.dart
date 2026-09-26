import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/application_status_helper.dart';

/// Interactive & responsive application status timeline widget.
/// Supports both a compact horizontal preview for cards and an expanded
/// detailed vertical view for modal dialogs/bottom sheets.
class ApplicationTimelineWidget extends StatelessWidget {
  final String status;
  final String appliedDate;
  final bool isCompact;

  const ApplicationTimelineWidget({
    super.key,
    required this.status,
    this.appliedDate = '',
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactHorizontalTimeline(context);
    }
    return _buildDetailedVerticalTimeline(context);
  }

  /// Compact horizontal pipeline bar designed to fit neatly in job application cards.
  Widget _buildCompactHorizontalTimeline(BuildContext context) {
    final currentStep = ApplicationStatusHelper.getStepIndex(status);
    final isRejected = (currentStep == -1);

    final stages = ApplicationStatusHelper.pipelineStages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tracking Pipeline',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isRejected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Declined',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(stages.length, (index) {
              final stageName = stages[index];
              final isCompleted = !isRejected && index <= currentStep;
              final isCurrent = !isRejected && index == currentStep;
              final stageColor = isRejected
                  ? const Color(0xFF94A3B8)
                  : isCompleted
                      ? ApplicationStatusHelper.getStatusColor(stageName)
                      : const Color(0xFFCBD5E1);

              return Expanded(
                child: Row(
                  children: [
                    // Node dot
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? stageColor
                            : isCompleted
                                ? stageColor.withValues(alpha: 0.2)
                                : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: stageColor,
                          width: isCurrent ? 2 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(
                                isCurrent ? Icons.circle : Icons.check_rounded,
                                size: isCurrent ? 8 : 10,
                                color: isCurrent ? Colors.white : stageColor,
                              )
                            : null,
                      ),
                    ),

                    // Connecting Line (except for last item)
                    if (index < stages.length - 1)
                      Expanded(
                        child: Container(
                          height: 2.5,
                          color: (!isRejected && index < currentStep)
                              ? stageColor
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          // Stage Labels Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(stages.length, (index) {
              final stageName = stages[index];
              final isCurrent = !isRejected && index == currentStep;
              final isCompleted = !isRejected && index <= currentStep;

              return Expanded(
                child: Text(
                  stageName == 'Under Review' ? 'Review' : stageName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w500,
                    color: isCurrent
                        ? ApplicationStatusHelper.getStatusColor(stageName)
                        : isCompleted
                            ? AppColors.textPrimary
                            : AppColors.textLight,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Detailed vertical timeline step view designed for modal details sheets.
  Widget _buildDetailedVerticalTimeline(BuildContext context) {
    final currentStep = ApplicationStatusHelper.getStepIndex(status);
    final isRejected = (currentStep == -1);
    final stages = ApplicationStatusHelper.pipelineStages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Application Progress History',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(stages.length, (index) {
          final stageName = stages[index];
          final isCompleted = !isRejected && index <= currentStep;
          final isCurrent = !isRejected && index == currentStep;
          final isLast = index == stages.length - 1;

          final stageColor = isCompleted
              ? ApplicationStatusHelper.getStatusColor(stageName)
              : const Color(0xFFCBD5E1);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Column (Dot + Connector Line)
                Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? stageColor
                            : isCompleted
                                ? stageColor.withValues(alpha: 0.15)
                                : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: stageColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isCompleted
                            ? ApplicationStatusHelper.getStatusIcon(stageName)
                            : Icons.circle_outlined,
                        size: 14,
                        color: isCurrent
                            ? Colors.white
                            : isCompleted
                                ? stageColor
                                : const Color(0xFF94A3B8),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: (!isRejected && index < currentStep)
                              ? stageColor
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Step Details Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stageName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isCurrent ? FontWeight.w900 : FontWeight.bold,
                                color: isCurrent
                                    ? stageColor
                                    : isCompleted
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                              ),
                            ),
                            if (index == 0 && appliedDate.isNotEmpty)
                              Text(
                                appliedDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCurrent
                              ? ApplicationStatusHelper.getStatusDescription(stageName)
                              : isCompleted
                                  ? 'Stage passed successfully.'
                                  : 'Pending progression to this round.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textLight,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // If application is Rejected, add a final Rejected step card
        if (isRejected) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF87171)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Application Status: Declined',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'This application has been closed by the recruiter.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
