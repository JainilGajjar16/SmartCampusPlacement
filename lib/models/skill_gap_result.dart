// Data models representing the output of a Job-Aware Skill Gap Analysis.

class SkillRecommendation {
  final String skillName;
  final List<String> keyTopics;
  final String learningResources;
  final String projectIdea;

  const SkillRecommendation({
    required this.skillName,
    required this.keyTopics,
    required this.learningResources,
    required this.projectIdea,
  });
}

class SkillGapResult {
  final String jobId;
  final String jobTitle;
  final String company;
  final double matchPercentage;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> extraSkills;
  final int totalRequiredSkills;
  final List<SkillRecommendation> recommendations;

  const SkillGapResult({
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.matchPercentage,
    required this.matchedSkills,
    required this.missingSkills,
    required this.extraSkills,
    required this.totalRequiredSkills,
    required this.recommendations,
  });
}
