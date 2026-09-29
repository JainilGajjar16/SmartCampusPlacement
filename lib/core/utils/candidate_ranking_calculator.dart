import '../../models/recruiter_feedback.dart';

/// Container for a candidate application paired with its feedback and calculated candidate rank score.
class CandidateRankingItem {
  final Map<String, dynamic> application;
  final RecruiterFeedback? feedback;
  final double candidateScore;

  const CandidateRankingItem({
    required this.application,
    this.feedback,
    required this.candidateScore,
  });

  bool get hasFeedback => feedback != null && feedback!.rating > 0;
  double get rating => feedback?.rating ?? 0.0;
  String get feedbackComment => feedback?.feedback ?? '';
}

/// Pure deterministic rule-based candidate ranking calculator for Phase 13.
class CandidateRankingCalculator {
  /// Calculates explainable candidate ranking score (0.0 to 100.0).
  static double calculateCandidateScore({
    RecruiterFeedback? feedback,
    String? status,
    String? cgpaStr,
  }) {
    double score = 0.0;

    // 1. Recruiter Feedback Rating Contribution (Up to 80 points)
    if (feedback != null && feedback.rating > 0) {
      score += (feedback.rating / 5.0) * 80.0;
    }

    // 2. Application Status Weighting (Up to 10 points)
    if (status != null && status.isNotEmpty) {
      final s = status.trim().toLowerCase();
      if (s.contains('selected') || s.contains('hired')) {
        score += 10.0;
      } else if (s.contains('shortlist')) {
        score += 7.5;
      } else if (s.contains('review')) {
        score += 5.0;
      } else if (s.contains('reject') || s.contains('decline')) {
        score -= 10.0;
      } else {
        score += 3.0; // Applied default
      }
    }

    // 3. CGPA Bonus Contribution (Up to 10 points)
    if (cgpaStr != null && cgpaStr.isNotEmpty) {
      final cgpa = double.tryParse(cgpaStr.trim()) ?? 0.0;
      if (cgpa >= 9.0) {
        score += 10.0;
      } else if (cgpa >= 8.0) {
        score += 8.0;
      } else if (cgpa >= 7.0) {
        score += 6.0;
      } else if (cgpa > 0.0) {
        score += 4.0;
      }
    }

    return double.parse(score.clamp(0.0, 100.0).toStringAsFixed(1));
  }

  /// Sorts candidate ranking items descending by candidate score (highest first).
  /// Uses feedback rating and application ID as deterministic tie-breakers.
  static List<CandidateRankingItem> sortCandidatesByRanking(
    List<CandidateRankingItem> items,
  ) {
    final sorted = List<CandidateRankingItem>.from(items);
    sorted.sort((a, b) {
      final scoreCmp = b.candidateScore.compareTo(a.candidateScore);
      if (scoreCmp != 0) return scoreCmp;

      final ratingCmp = b.rating.compareTo(a.rating);
      if (ratingCmp != 0) return ratingCmp;

      final appA = a.application['applicationId']?.toString() ?? '';
      final appB = b.application['applicationId']?.toString() ?? '';
      return appA.compareTo(appB);
    });
    return sorted;
  }
}
