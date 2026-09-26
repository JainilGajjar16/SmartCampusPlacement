import '../../models/job.dart';
import '../../models/skill_gap_result.dart';
import '../../models/student_profile.dart';
import 'skill_gap_analyzer.dart';

/// Container for a job paired with its calculated skill gap result.
class JobRecommendationItem {
  final Job job;
  final SkillGapResult skillGapResult;

  const JobRecommendationItem({
    required this.job,
    required this.skillGapResult,
  });

  double get matchPercentage => skillGapResult.matchPercentage;
  List<String> get matchedSkills => skillGapResult.matchedSkills;
  List<String> get missingSkills => skillGapResult.missingSkills;
}

/// Pure deterministic Placement Readiness and Recommendation engine.
class PlacementReadinessCalculator {
  static const String categoryStrong = 'Strong Match';
  static const String categoryGood = 'Good Match';
  static const String categoryNeedsImprovement = 'Needs Improvement';

  /// Calculates deterministic profile completeness score (0 - 100%).
  static double calculateProfileCompleteness(StudentProfile profile) {
    double score = 0.0;

    // 1. Personal & Contact Info (20%)
    if (profile.name.trim().isNotEmpty) score += 6.67;
    if (profile.email.trim().isNotEmpty) score += 6.67;
    if (profile.mobile.trim().isNotEmpty) score += 6.66;

    // 2. Education Details (15%)
    if (profile.education.trim().isNotEmpty) score += 15.0;

    // 3. Professional Links (15%)
    if (profile.github.trim().isNotEmpty) score += 7.5;
    if (profile.linkedin.trim().isNotEmpty) score += 7.5;

    // 4. Skills & Competencies (25%)
    final skillList = SkillGapAnalyzer.extractSkills(profile.skills);
    if (skillList.length >= 5) {
      score += 25.0;
    } else if (skillList.length >= 3) {
      score += 18.0;
    } else if (skillList.isNotEmpty) {
      score += 10.0;
    }

    // 5. Key Projects (15%)
    if (profile.projects.trim().isNotEmpty) score += 15.0;

    // 6. Certifications & Achievements (10%)
    if (profile.certifications.trim().isNotEmpty) score += 10.0;

    return double.parse(score.clamp(0.0, 100.0).toStringAsFixed(1));
  }

  /// Calculates average market skill match percentage across all available jobs (0 - 100%).
  static double calculateMarketAlignment(List<Job> jobs, StudentProfile profile) {
    if (jobs.isEmpty) return 100.0;

    double totalMatch = 0.0;
    for (var job in jobs) {
      final result = SkillGapAnalyzer.analyze(job: job, profile: profile);
      totalMatch += result.matchPercentage;
    }

    final avg = totalMatch / jobs.length;
    return double.parse(avg.clamp(0.0, 100.0).toStringAsFixed(1));
  }

  /// Calculates overall placement readiness score weighted equally between profile completeness
  /// and market skill alignment (0 - 100%).
  static double calculateOverallReadiness(StudentProfile profile, List<Job> jobs) {
    final profileScore = calculateProfileCompleteness(profile);
    final marketScore = calculateMarketAlignment(jobs, profile);
    final overall = (profileScore * 0.50) + (marketScore * 0.50);
    return double.parse(overall.clamp(0.0, 100.0).toStringAsFixed(1));
  }

  /// Classifies match percentage into Strong, Good, or Needs Improvement.
  static String getMatchCategory(double matchPercentage) {
    if (matchPercentage >= 80.0) return categoryStrong;
    if (matchPercentage >= 50.0) return categoryGood;
    return categoryNeedsImprovement;
  }

  /// Sorts jobs client-side by skill match percentage (highest first).
  /// Uses job title and jobId as a stable tie-breaker.
  static List<JobRecommendationItem> sortJobsByRecommendation(
    List<Job> jobs,
    StudentProfile profile,
  ) {
    final List<JobRecommendationItem> items = jobs.map((job) {
      final result = SkillGapAnalyzer.analyze(job: job, profile: profile);
      return JobRecommendationItem(job: job, skillGapResult: result);
    }).toList();

    items.sort((a, b) {
      final cmp = b.matchPercentage.compareTo(a.matchPercentage);
      if (cmp != 0) return cmp;
      final titleCmp = a.job.title.compareTo(b.job.title);
      if (titleCmp != 0) return titleCmp;
      return a.job.jobId.compareTo(b.job.jobId);
    });

    return items;
  }

  /// Aggregates frequency of missing skills across all jobs to identify top skills to improve.
  static List<MapEntry<String, int>> getMissingSkillsSummary(
    List<Job> jobs,
    StudentProfile profile,
  ) {
    final Map<String, int> missingCounts = {};

    for (var job in jobs) {
      final result = SkillGapAnalyzer.analyze(job: job, profile: profile);
      for (var missingSkill in result.missingSkills) {
        final displayLabel = missingSkill.trim();
        missingCounts[displayLabel] = (missingCounts[displayLabel] ?? 0) + 1;
      }
    }

    final entries = missingCounts.entries.toList();
    entries.sort((a, b) {
      final countCmp = b.value.compareTo(a.value);
      if (countCmp != 0) return countCmp;
      return a.key.compareTo(b.key);
    });

    return entries;
  }
}
