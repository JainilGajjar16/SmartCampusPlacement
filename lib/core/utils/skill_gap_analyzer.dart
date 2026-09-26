import '../../models/job.dart';
import '../../models/student_profile.dart';
import '../../models/skill_gap_result.dart';

/// Conservative, research-valid deterministic Skill Gap Analysis engine.
/// Compares a target job's required skills against a student's profile competencies.
abstract class SkillGapAnalyzer {
  /// Canonical synonym map strictly for literal naming variations.
  /// Does NOT merge distinct related technologies (e.g. Flutter & Dart remain separate).
  static const Map<String, String> _literalSynonyms = {
    'js': 'javascript',
    'javascript': 'javascript',
    'ecmascript': 'javascript',
    'react': 'react',
    'reactjs': 'react',
    'react.js': 'react',
    'node': 'nodejs',
    'nodejs': 'nodejs',
    'node.js': 'nodejs',
    'py': 'python',
    'python': 'python',
    'cpp': 'c++',
    'c++': 'c++',
    'cs': 'c#',
    'c#': 'c#',
    'csharp': 'c#',
  };

  /// Normalizes a skill string to its canonical key.
  /// Only literal synonyms are mapped; distinct technologies remain separate.
  static String normalizeSkill(String rawSkill) {
    final cleaned = rawSkill.trim().toLowerCase();
    return _literalSynonyms[cleaned] ?? cleaned;
  }

  /// Splits a raw skills string by common delimiters (commas, slashes, semicolons, pipe, newlines).
  static List<String> extractSkills(String rawText) {
    if (rawText.trim().isEmpty) return [];

    final splitTokens = rawText.split(RegExp(r'[,/;\n|]'));
    final List<String> result = [];

    for (var token in splitTokens) {
      final trimmed = token.trim();
      if (trimmed.isNotEmpty) {
        result.add(trimmed);
      }
    }

    return result;
  }

  /// Performs a Job-Aware Skill Gap Analysis.
  static SkillGapResult analyze({
    required Job job,
    required StudentProfile profile,
  }) {
    final rawJobSkills = extractSkills(job.skills);
    final rawProfileSkills = extractSkills(profile.skills);

    // Map normalized canonical keys to original labels for job required skills
    final Map<String, String> jobSkillsMap = {};
    for (var skill in rawJobSkills) {
      final canonical = normalizeSkill(skill);
      if (!jobSkillsMap.containsKey(canonical)) {
        jobSkillsMap[canonical] = skill;
      }
    }

    // Map normalized canonical keys to original labels for student profile skills
    final Map<String, String> profileSkillsMap = {};
    for (var skill in rawProfileSkills) {
      final canonical = normalizeSkill(skill);
      if (!profileSkillsMap.containsKey(canonical)) {
        profileSkillsMap[canonical] = skill;
      }
    }

    final List<String> matchedSkills = [];
    final List<String> missingSkills = [];
    final List<String> extraSkills = [];

    // Evaluate job required skills against student profile skills
    jobSkillsMap.forEach((canonicalKey, originalLabel) {
      if (profileSkillsMap.containsKey(canonicalKey)) {
        matchedSkills.add(originalLabel);
      } else {
        missingSkills.add(originalLabel);
      }
    });

    // Evaluate additional student skills not requested by job
    profileSkillsMap.forEach((canonicalKey, originalLabel) {
      if (!jobSkillsMap.containsKey(canonicalKey)) {
        extraSkills.add(originalLabel);
      }
    });

    // Match percentage formula: (matched required skills / total required skills) * 100
    final int totalRequired = jobSkillsMap.length;
    final double matchPercentage = totalRequired > 0
        ? ((matchedSkills.length / totalRequired) * 100).clamp(0.0, 100.0)
        : 100.0;

    // Generate personalized learning recommendations for missing skills
    final List<SkillRecommendation> recommendations = missingSkills
        .map((missingSkill) => _generateRecommendation(missingSkill))
        .toList();

    return SkillGapResult(
      jobId: job.jobId,
      jobTitle: job.title,
      company: job.company,
      matchPercentage: double.parse(matchPercentage.toStringAsFixed(1)),
      matchedSkills: matchedSkills,
      missingSkills: missingSkills,
      extraSkills: extraSkills,
      totalRequiredSkills: totalRequired,
      recommendations: recommendations,
    );
  }

  /// Generates tailored learning topics, resource pathways, and project ideas for a missing skill.
  static SkillRecommendation _generateRecommendation(String skillName) {
    final canonical = normalizeSkill(skillName);

    switch (canonical) {
      case 'flutter':
        return const SkillRecommendation(
          skillName: 'Flutter',
          keyTopics: [
            'Widget Tree & State Management (Provider/Riverpod)',
            'Asynchronous Programming & FutureBuilder',
            'REST API Integration & JSON Parsing',
            'Responsive Layouts & Navigation'
          ],
          learningResources:
              'Official Flutter Documentation, Flutter Apprentice Guide, interactive app tutorials.',
          projectIdea:
              'Build a Cross-Platform Mobile News or Weather App consuming a live REST API.',
        );
      case 'dart':
        return const SkillRecommendation(
          skillName: 'Dart',
          keyTopics: [
            'Object-Oriented Programming & Mixins',
            'Null Safety & Type Inference',
            'Streams, Futures, & Async/Await',
            'Collections & Functional Operators'
          ],
          learningResources:
              'dart.dev guides, Tour of Dart language, DartPad interactive exercises.',
          projectIdea:
              'Develop a Dart CLI tool or algorithmic data processor with unit test suites.',
        );
      case 'java':
        return const SkillRecommendation(
          skillName: 'Java',
          keyTopics: [
            'Core OOP Concepts (Inheritance, Polymorphism)',
            'Collections Framework & Generics',
            'Multithreading & Concurrency',
            'JVM Memory Management & Exception Handling'
          ],
          learningResources:
              'Oracle Java Tutorials, Java Core documentation, LeetCode Java track.',
          projectIdea:
              'Build a Console-based Banking System or Student Management Portal using OOP patterns.',
        );
      case 'python':
        return const SkillRecommendation(
          skillName: 'Python',
          keyTopics: [
            'Data Structures (Lists, Dicts, Sets, Tuples)',
            'Object-Oriented Python & Decorators',
            'File Handling & Exception Control',
            'Popular Libraries (Pandas, NumPy, Requests)'
          ],
          learningResources:
              'Python.org Official Tutorial, Automate the Boring Stuff, Real Python.',
          projectIdea:
              'Create a Web Scraping & Data Analysis Automation Script saving CSV reports.',
        );
      case 'sql':
      case 'mysql':
      case 'postgresql':
        return SkillRecommendation(
          skillName: skillName,
          keyTopics: const [
            'DDL/DML Queries & Aggregations (GROUP BY)',
            'INNER/LEFT JOINs & Subqueries',
            'Database Indexing & Query Optimization',
            'Relational Schema Design & Normalization'
          ],
          learningResources:
              'SQLBolt interactive tutorials, W3Schools SQL Guide, LeetCode Database problems.',
          projectIdea:
              'Design an E-Commerce Relational Database Schema with complex query views.',
        );
      case 'react':
        return const SkillRecommendation(
          skillName: 'React',
          keyTopics: [
            'JSX Syntax & Component Lifecycle',
            'React Hooks (useState, useEffect, useMemo)',
            'State Management (Context API / Redux)',
            'Single Page App Routing & Axios Fetch'
          ],
          learningResources:
              'react.dev official documentation, Scrimba React Course.',
          projectIdea:
              'Build a Task Management Dashboard with filter tabs and local storage persistence.',
        );
      case 'node':
        return const SkillRecommendation(
          skillName: 'Node.js',
          keyTopics: [
            'Event Loop & Asynchronous I/O',
            'Express.js Routing & Middleware',
            'REST API Endpoint Design & JWT Auth',
            'NPM Package Management & Env Config'
          ],
          learningResources:
              'Nodejs.org official docs, FreeCodeCamp Backend Development track.',
          projectIdea:
              'Build a RESTful API backend service with User Authentication and CRUD operations.',
        );
      case 'machine learning':
        return const SkillRecommendation(
          skillName: 'Machine Learning',
          keyTopics: [
            'Supervised vs Unsupervised Learning',
            'Scikit-Learn Model Training & Evaluation',
            'Feature Engineering & Data Preprocessing',
            'Model Metrics (Precision, Recall, F1 Score)'
          ],
          learningResources:
              'Kaggle Learn Micro-Courses, Andrew Ng ML Specialization.',
          projectIdea:
              'Build a House Price Prediction or Customer Churn Classification Model.',
        );
      default:
        return SkillRecommendation(
          skillName: skillName,
          keyTopics: [
            'Core Fundamentals & Syntax of $skillName',
            'Best Practices & Industry Coding Standards',
            'Hands-on Implementation & Debugging',
            'Building Real-World Projects with $skillName'
          ],
          learningResources:
              'Official $skillName Documentation, YouTube crash courses, open-source repositories.',
          projectIdea:
              'Build a mini portfolio project showcasing practical usage of $skillName.',
        );
    }
  }
}
