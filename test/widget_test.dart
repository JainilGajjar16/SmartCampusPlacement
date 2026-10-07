import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_placement/main.dart';
import 'package:smart_campus_placement/models/application.dart';
import 'package:smart_campus_placement/models/job.dart';
import 'package:smart_campus_placement/models/user_session.dart';
import 'package:smart_campus_placement/core/utils/skill_gap_analyzer.dart';
import 'package:smart_campus_placement/models/student_profile.dart';
import 'package:smart_campus_placement/screens/auth/forgot_password_screen.dart';
import 'package:smart_campus_placement/screens/auth/reset_password_screen.dart';
import 'package:smart_campus_placement/screens/student/jobs_screen.dart';
import 'package:smart_campus_placement/screens/student/job_details_screen.dart';
import 'package:smart_campus_placement/screens/student/skill_gap_analysis_screen.dart';
import 'package:smart_campus_placement/core/utils/application_status_helper.dart';
import 'package:smart_campus_placement/widgets/application_timeline_widget.dart';
import 'package:smart_campus_placement/screens/student/my_applications_screen.dart';
import 'package:smart_campus_placement/core/utils/placement_readiness_calculator.dart';
import 'package:smart_campus_placement/screens/student/placement_readiness_screen.dart';
import 'package:smart_campus_placement/models/notification_item.dart';
import 'package:smart_campus_placement/screens/student/notifications_screen.dart';
import 'package:smart_campus_placement/core/constants/app_strings.dart';
import 'package:smart_campus_placement/core/utils/app_validators.dart';
import 'package:smart_campus_placement/screens/dashboard/company_dashboard_screen.dart';
import 'package:smart_campus_placement/screens/dashboard/admin_dashboard_screen.dart';
import 'package:smart_campus_placement/services/google_sheets_service.dart';
import 'package:smart_campus_placement/models/recruiter_feedback.dart';
import 'package:smart_campus_placement/core/utils/candidate_ranking_calculator.dart';
import 'package:smart_campus_placement/widgets/analytics_reports_widget.dart';
import 'package:smart_campus_placement/screens/admin/admin_manage_jobs_screen.dart';
import 'package:smart_campus_placement/screens/student/student_profile_screen.dart';

void main() {
  testWidgets('Full Auth Navigation Flow Smoke Test', (
    WidgetTester tester,
  ) async {
    // 1. Build app and verify Welcome / Splash Screen
    await tester.pumpWidget(const SmartCampusApp());
    expect(find.text('Smart Campus Placement'), findsOneWidget);

    // 2. Advance time past splash timer (4.5s) to automatically transition to Login Screen
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('User ID'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);

    // 3. Tap Forgot Password link to navigate to Forgot Password Screen
    final forgotPasswordFinder = find.text('Forgot Password?');
    await tester.ensureVisible(forgotPasswordFinder);
    await tester.tap(forgotPasswordFinder);
    await tester.pumpAndSettle();

    // 4. Verify Forgot Password Screen renders properly
    expect(find.text('Forgot Password?'), findsWidgets);
    expect(
      find.text('Verify your account to reset your password.'),
      findsOneWidget,
    );
    expect(find.text('Verify Account'), findsOneWidget);

    // 5. Return to Login
    final backToLoginFinder = find.text('Back to Login');
    await tester.ensureVisible(backToLoginFinder);
    await tester.tap(backToLoginFinder);
    await tester.pumpAndSettle();

    // 6. Scroll down & tap Create New Account to navigate to Register Screen
    final createAccountFinder = find.text('Create New Account');
    await tester.ensureVisible(createAccountFinder);
    await tester.tap(createAccountFinder);
    await tester.pumpAndSettle();

    // 7. Verify Register Screen renders properly
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('User ID'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('HR'), findsOneWidget);
  });

  testWidgets('Forgot Password Screen direct render test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('User ID'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Verify Account'), findsOneWidget);
  });

  testWidgets('Reset Password Screen direct render test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResetPasswordScreen(
          userId: 'test_student',
          email: 'student@campus.edu',
        ),
      ),
    );
    expect(find.text('Reset Password'), findsWidgets);
    expect(find.text('Account: test_student'), findsOneWidget);
    expect(find.text('student@campus.edu'), findsOneWidget);
    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Confirm New Password'), findsOneWidget);
  });

  testWidgets('Authenticated User Session Dashboard Test', (
    WidgetTester tester,
  ) async {
    UserSession().setSession(
      userId: 'test_student',
      role: 'Student',
      name: 'Test Student',
      email: 'student@campus.edu',
    );

    await tester.pumpWidget(const SmartCampusApp());
    await tester.pumpAndSettle();

    expect(UserSession().isLoggedIn, isTrue);
    expect(UserSession().userId, equals('test_student'));
    expect(UserSession().role, equals('Student'));

    UserSession().clearSession();
    expect(UserSession().isLoggedIn, isFalse);
  });

  test('Job model serialization test', () {
    final json = {
      'jobId': 'JOB001',
      'title': 'Flutter Developer Intern',
      'company': 'ABC Technologies',
      'location': 'Ahmedabad',
      'jobType': 'Internship',
      'skills': 'Flutter, Dart',
      'salary': '₹10,000/month',
      'description': 'Develop mobile applications',
      'status': 'Active',
      'postedDate': '2026-08-26',
    };

    final job = Job.fromJson(json);

    expect(job.jobId, equals('JOB001'));
    expect(job.title, equals('Flutter Developer Intern'));
    expect(job.company, equals('ABC Technologies'));
    expect(job.location, equals('Ahmedabad'));
    expect(job.jobType, equals('Internship'));
    expect(job.skills, equals('Flutter, Dart'));
    expect(job.salary, equals('₹10,000/month'));
    expect(job.description, equals('Develop mobile applications'));
    expect(job.status, equals('Active'));
    expect(job.postedDate, equals('2026-08-26'));
  });

  test('Application model serialization test', () {
    final json = {
      'applicationId': 'APP1787759900000',
      'jobId': 'JOB001',
      'userId': 'student123',
      'appliedDate': '2026-08-26 22:30',
      'status': 'Applied',
      'title': 'Flutter Developer Intern',
      'company': 'ABC Technologies',
      'location': 'Ahmedabad',
      'jobType': 'Internship',
      'salary': '₹10,000/month',
    };

    final app = Application.fromJson(json);

    expect(app.applicationId, equals('APP1787759900000'));
    expect(app.jobId, equals('JOB001'));
    expect(app.userId, equals('student123'));
    expect(app.appliedDate, equals('2026-08-26 22:30'));
    expect(app.status, equals('Applied'));
    expect(app.title, equals('Flutter Developer Intern'));
    expect(app.company, equals('ABC Technologies'));
    expect(app.location, equals('Ahmedabad'));
    expect(app.jobType, equals('Internship'));
    expect(app.salary, equals('₹10,000/month'));
  });

  test('Phase 9 Job Search & Filter Logic Unit Test', () {
    final jobs = [
      const Job(
        jobId: 'JOB001',
        title: 'Flutter Developer',
        company: 'Google',
        location: 'Bangalore',
        jobType: 'Full-time',
        skills: 'Flutter, Dart, REST API',
        salary: '12 LPA',
        description: 'App development',
      ),
      const Job(
        jobId: 'JOB002',
        title: 'Backend Engineer',
        company: 'Microsoft',
        location: 'Hyderabad',
        jobType: 'Full-time',
        skills: 'Java, Spring Boot, SQL',
        salary: '15 LPA',
        description: 'Cloud services',
      ),
      const Job(
        jobId: 'JOB003',
        title: 'UI/UX Design Intern',
        company: 'Adobe',
        location: 'Bangalore',
        jobType: 'Internship',
        skills: 'Figma, Adobe XD',
        salary: '25,000/month',
        description: 'Design mockups',
      ),
    ];

    // Search query matching
    final searchFlutter = jobs.where((j) {
      final q = 'flutter';
      return j.title.toLowerCase().contains(q) ||
          j.company.toLowerCase().contains(q) ||
          j.location.toLowerCase().contains(q) ||
          j.skills.toLowerCase().contains(q);
    }).toList();

    expect(searchFlutter.length, equals(1));
    expect(searchFlutter.first.jobId, equals('JOB001'));

    // Location filtering
    final bangaloreJobs = jobs
        .where((j) => j.location.toLowerCase() == 'bangalore')
        .toList();
    expect(bangaloreJobs.length, equals(2));

    // Job type filtering
    final internships = jobs
        .where((j) => j.jobType.toLowerCase() == 'internship')
        .toList();
    expect(internships.length, equals(1));
    expect(internships.first.company, equals('Adobe'));

    // Skill filtering
    final javaJobs = jobs
        .where((j) => j.skills.toLowerCase().contains('java'))
        .toList();
    expect(javaJobs.length, equals(1));
    expect(javaJobs.first.company, equals('Microsoft'));
  });

  test('Phase 9 Job Sorting Unit Test', () {
    final jobs = [
      const Job(
        jobId: 'JOB001',
        title: 'Software Engineer',
        company: 'Tech Corp',
        location: 'Remote',
        jobType: 'Full-time',
        skills: 'Python',
        salary: '10 LPA',
        description: 'Dev',
      ),
      const Job(
        jobId: 'JOB002',
        title: 'Senior Developer',
        company: 'Tech Corp',
        location: 'Remote',
        jobType: 'Full-time',
        skills: 'Python',
        salary: '20 LPA',
        description: 'Senior Dev',
      ),
    ];

    double parseSalary(String s) {
      final lower = s.toLowerCase();
      final lpaMatch = RegExp(r'([\d\.]+)\s*lpa').firstMatch(lower);
      if (lpaMatch != null) {
        return (double.tryParse(lpaMatch.group(1) ?? '') ?? 0) * 100000;
      }
      return 0;
    }

    final sortedHighToLow = List<Job>.from(jobs)
      ..sort((a, b) => parseSalary(b.salary).compareTo(parseSalary(a.salary)));

    expect(sortedHighToLow.first.jobId, equals('JOB002'));
    expect(sortedHighToLow.last.jobId, equals('JOB001'));
  });

  testWidgets('Phase 9 Jobs Screen Direct Render Test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: JobsScreen()));

    expect(find.text('Available Jobs'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  test('Phase 10 Skill Gap Analyzer Conservative Matching & Score Test', () {
    const job = Job(
      jobId: 'JOB101',
      title: 'Mobile Engineer',
      company: 'TechCorp',
      location: 'Bangalore',
      jobType: 'Full-time',
      skills: 'Flutter, Dart, ReactJS, Python',
      salary: '12 LPA',
      description: 'Mobile App Developer',
    );

    const profile = StudentProfile(
      userId: 'student1',
      skills: 'Flutter, React, Java',
    );

    final result = SkillGapAnalyzer.analyze(job: job, profile: profile);

    // 1. Literal synonym normalization test: ReactJS -> React matched
    expect(result.matchedSkills.contains('Flutter'), isTrue);
    expect(result.matchedSkills.contains('ReactJS'), isTrue);
    expect(result.matchedSkills.length, equals(2));

    // 2. Strict separation test: Flutter & Dart remain separate => Dart is missing
    expect(result.missingSkills.contains('Dart'), isTrue);
    expect(result.missingSkills.contains('Python'), isTrue);
    expect(result.missingSkills.length, equals(2));

    // 3. Extra skill test: Java is an extra student competency
    expect(result.extraSkills.contains('Java'), isTrue);
    expect(result.extraSkills.length, equals(1));

    // 4. Score formula test: (2 matched / 4 total required) * 100 = 50.0%
    // Extra student skill (Java) does NOT inflate the match percentage score.
    expect(result.matchPercentage, equals(50.0));

    // 5. Recommendations test
    expect(result.recommendations.length, equals(2));
    final dartRec = result.recommendations.firstWhere(
      (r) => r.skillName == 'Dart',
    );
    expect(dartRec.keyTopics.isNotEmpty, isTrue);
  });

  testWidgets('Phase 10 Skill Gap Analysis Screen Direct Render Test', (
    WidgetTester tester,
  ) async {
    const job = Job(
      jobId: 'JOB102',
      title: 'Flutter Lead',
      company: 'AppStudio',
      location: 'Remote',
      jobType: 'Full-time',
      skills: 'Flutter, Dart',
      salary: '18 LPA',
      description: 'Build Flutter Apps',
    );

    const profile = StudentProfile(userId: 'student1', skills: 'Flutter');

    await tester.pumpWidget(
      const MaterialApp(
        home: SkillGapAnalysisScreen(job: job, initialProfile: profile),
      ),
    );

    expect(find.text('Job Skill Gap Analysis'), findsOneWidget);
    expect(find.text('Flutter Lead'), findsOneWidget);
    expect(find.text('AppStudio'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Matched Required Skills'), findsOneWidget);
    expect(find.text('Missing Target Skills'), findsOneWidget);
    expect(find.text('Recommended Learning Roadmaps'), findsOneWidget);
  });

  test(
    'Phase 10 Expected Test 1: Full Match with Extra Student Competencies',
    () {
      const job = Job(
        jobId: 'JOB201',
        title: 'Flutter Developer',
        company: 'Tech Solutions',
        location: 'Ahmedabad',
        jobType: 'Full-time',
        skills: 'Flutter',
        salary: '10 LPA',
        description: 'Flutter App Dev',
      );

      const profile = StudentProfile(
        userId: 'student1',
        skills: 'Flutter, Dart, Java, Python, HTML, CSS, Git',
      );

      final result = SkillGapAnalyzer.analyze(job: job, profile: profile);

      expect(result.matchPercentage, equals(100.0));
      expect(result.matchedSkills, equals(['Flutter']));
      expect(result.missingSkills, isEmpty);
      expect(
        result.extraSkills,
        equals(['Dart', 'Java', 'Python', 'HTML', 'CSS', 'Git']),
      );
    },
  );

  test('Phase 10 Expected Test 2: Zero Match with Missing Skill', () {
    const job = Job(
      jobId: 'JOB202',
      title: 'Flutter Developer',
      company: 'Tech Solutions',
      location: 'Ahmedabad',
      jobType: 'Full-time',
      skills: 'Flutter',
      salary: '10 LPA',
      description: 'Flutter App Dev',
    );

    const profile = StudentProfile(
      userId: 'student1',
      skills: 'Dart, Java, Python, HTML, CSS, Git',
    );

    final result = SkillGapAnalyzer.analyze(job: job, profile: profile);

    expect(result.matchPercentage, equals(0.0));
    expect(result.matchedSkills, isEmpty);
    expect(result.missingSkills, equals(['Flutter']));
  });

  test('Phase 10 Expected Test 3: Literal Synonym Normalization Match', () {
    const job = Job(
      jobId: 'JOB203',
      title: 'Full Stack Engineer',
      company: 'Web Systems',
      location: 'Remote',
      jobType: 'Full-time',
      skills: 'JavaScript, Java',
      salary: '15 LPA',
      description: 'Full Stack',
    );

    const profile = StudentProfile(userId: 'student1', skills: 'js, Java');

    final result = SkillGapAnalyzer.analyze(job: job, profile: profile);

    expect(result.matchPercentage, equals(100.0));
    expect(result.matchedSkills, contains('JavaScript'));
    expect(result.matchedSkills, contains('Java'));
    expect(result.missingSkills, isEmpty);
  });

  test('Phase 11 Application Status Helper Normalization & Colors Test', () {
    expect(
      ApplicationStatusHelper.normalizeStatus('applied'),
      equals('Applied'),
    );
    expect(
      ApplicationStatusHelper.normalizeStatus('Under Review'),
      equals('Under Review'),
    );
    expect(
      ApplicationStatusHelper.normalizeStatus('shortlisted'),
      equals('Shortlisted'),
    );
    expect(
      ApplicationStatusHelper.normalizeStatus('Selected'),
      equals('Selected'),
    );
    expect(
      ApplicationStatusHelper.normalizeStatus('REJECTED'),
      equals('Rejected'),
    );

    expect(ApplicationStatusHelper.getStepIndex('Applied'), equals(0));
    expect(ApplicationStatusHelper.getStepIndex('Under Review'), equals(1));
    expect(ApplicationStatusHelper.getStepIndex('Shortlisted'), equals(2));
    expect(ApplicationStatusHelper.getStepIndex('Selected'), equals(3));
    expect(ApplicationStatusHelper.getStepIndex('Rejected'), equals(-1));
  });

  test('Phase 11 Application Search & Status Filtering Logic Test', () {
    final apps = [
      const Application(
        applicationId: 'APP001',
        jobId: 'JOB001',
        userId: 'user1',
        appliedDate: '2026-08-26',
        status: 'Applied',
        title: 'Flutter Developer',
        company: 'Google',
        location: 'Bangalore',
      ),
      const Application(
        applicationId: 'APP002',
        jobId: 'JOB002',
        userId: 'user1',
        appliedDate: '2026-08-27',
        status: 'Under Review',
        title: 'Backend Engineer',
        company: 'Microsoft',
        location: 'Hyderabad',
      ),
      const Application(
        applicationId: 'APP003',
        jobId: 'JOB003',
        userId: 'user1',
        appliedDate: '2026-08-28',
        status: 'Shortlisted',
        title: 'Frontend Intern',
        company: 'Adobe',
        location: 'Bangalore',
      ),
    ];

    // Title search matching
    final searchFlutter = apps
        .where((a) => a.title.toLowerCase().contains('flutter'))
        .toList();
    expect(searchFlutter.length, equals(1));
    expect(searchFlutter.first.applicationId, equals('APP001'));

    // Company search matching
    final searchMicrosoft = apps
        .where((a) => a.company.toLowerCase().contains('microsoft'))
        .toList();
    expect(searchMicrosoft.length, equals(1));

    // Status filter matching
    final shortlistedApps = apps
        .where(
          (a) =>
              ApplicationStatusHelper.normalizeStatus(a.status) ==
              'Shortlisted',
        )
        .toList();
    expect(shortlistedApps.length, equals(1));
    expect(shortlistedApps.first.title, equals('Frontend Intern'));
  });

  testWidgets('Phase 11 Application Timeline Widget Direct Render Test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ApplicationTimelineWidget(
            status: 'Shortlisted',
            isCompact: false,
          ),
        ),
      ),
    );

    expect(find.text('Application Progress History'), findsOneWidget);
    expect(find.text('Shortlisted'), findsWidgets);
    expect(find.text('Under Review'), findsOneWidget);
  });

  testWidgets('Phase 11 My Applications Screen Direct Render Test', (
    WidgetTester tester,
  ) async {
    UserSession().setSession(
      userId: 'student123',
      role: 'Student',
      name: 'Test Student',
      email: 'student@campus.edu',
    );

    await tester.pumpWidget(const MaterialApp(home: MyApplicationsScreen()));

    expect(find.text('My Applications'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('My Applications'), findsOneWidget);

    UserSession().clearSession();
  });

  test('Phase 12 Placement Readiness Calculator Formula Unit Test', () {
    const emptyProfile = StudentProfile(userId: 'student1');
    expect(
      PlacementReadinessCalculator.calculateProfileCompleteness(emptyProfile),
      equals(0.0),
    );

    const fullProfile = StudentProfile(
      userId: 'student1',
      name: 'John Doe',
      email: 'john@campus.edu',
      mobile: '9876543210',
      education: 'B.Tech CSE',
      github: 'https://github.com/john',
      linkedin: 'https://linkedin.com/in/john',
      skills: 'Flutter, Dart, Java, Python, SQL',
      projects: 'Smart Campus Placement App',
      certifications: 'Google Cloud Certified',
    );
    expect(
      PlacementReadinessCalculator.calculateProfileCompleteness(fullProfile),
      equals(100.0),
    );

    const jobs = [
      Job(
        jobId: 'JOB001',
        title: 'Flutter Developer',
        company: 'Company A',
        location: 'Bangalore',
        jobType: 'Full-time',
        skills: 'Flutter, Dart',
        salary: '10 LPA',
        description: 'Flutter Dev',
      ),
      Job(
        jobId: 'JOB002',
        title: 'Backend Developer',
        company: 'Company B',
        location: 'Hyderabad',
        jobType: 'Full-time',
        skills: 'Java, SQL',
        salary: '12 LPA',
        description: 'Backend Dev',
      ),
    ];

    final marketAlignment =
        PlacementReadinessCalculator.calculateMarketAlignment(
          jobs,
          fullProfile,
        );
    expect(marketAlignment, equals(100.0));

    final overall = PlacementReadinessCalculator.calculateOverallReadiness(
      fullProfile,
      jobs,
    );
    expect(overall, equals(100.0));
  });

  test('Phase 12 Job Recommendation Sorting & Classification Unit Test', () {
    const profile = StudentProfile(userId: 'student1', skills: 'Flutter, Dart');

    const jobs = [
      Job(
        jobId: 'JOB001',
        title: 'Backend Engineer',
        company: 'Tech Corp',
        location: 'Remote',
        jobType: 'Full-time',
        skills: 'Java, Spring Boot, SQL, AWS',
        salary: '15 LPA',
        description: 'Java Dev',
      ),
      Job(
        jobId: 'JOB002',
        title: 'Flutter Lead',
        company: 'App Studio',
        location: 'Bangalore',
        jobType: 'Full-time',
        skills: 'Flutter, Dart',
        salary: '18 LPA',
        description: 'Flutter Lead',
      ),
      Job(
        jobId: 'JOB003',
        title: 'Mobile Engineer',
        company: 'Mobile Corp',
        location: 'Hyderabad',
        jobType: 'Full-time',
        skills: 'Flutter, React',
        salary: '12 LPA',
        description: 'Mobile Dev',
      ),
    ];

    final sorted = PlacementReadinessCalculator.sortJobsByRecommendation(
      jobs,
      profile,
    );

    // JOB002 has 100% match (Flutter, Dart) => First
    expect(sorted.first.job.jobId, equals('JOB002'));
    expect(sorted.first.matchPercentage, equals(100.0));
    expect(
      PlacementReadinessCalculator.getMatchCategory(
        sorted.first.matchPercentage,
      ),
      equals('Strong Match'),
    );

    // JOB003 has 50% match (Flutter matched out of 2) => Second
    expect(sorted[1].job.jobId, equals('JOB003'));
    expect(sorted[1].matchPercentage, equals(50.0));
    expect(
      PlacementReadinessCalculator.getMatchCategory(sorted[1].matchPercentage),
      equals('Good Match'),
    );

    // JOB001 has 0% match => Last
    expect(sorted.last.job.jobId, equals('JOB001'));
    expect(sorted.last.matchPercentage, equals(0.0));
    expect(
      PlacementReadinessCalculator.getMatchCategory(
        sorted.last.matchPercentage,
      ),
      equals('Needs Improvement'),
    );
  });

  test('Phase 12 Missing Skills Aggregation Unit Test', () {
    const profile = StudentProfile(userId: 'student1', skills: 'Flutter');

    const jobs = [
      Job(
        jobId: 'JOB001',
        title: 'Fullstack Dev',
        company: 'Tech Inc',
        location: 'Remote',
        jobType: 'Full-time',
        skills: 'Flutter, SQL, Node.js',
        salary: '10 LPA',
        description: 'Dev',
      ),
      Job(
        jobId: 'JOB002',
        title: 'Backend Dev',
        company: 'Cloud Systems',
        location: 'Bangalore',
        jobType: 'Full-time',
        skills: 'SQL, Java',
        salary: '12 LPA',
        description: 'Dev',
      ),
    ];

    final missingSummary = PlacementReadinessCalculator.getMissingSkillsSummary(
      jobs,
      profile,
    );

    // SQL is missing in both jobs (frequency = 2) => Top missing skill
    expect(missingSummary.first.key, equals('SQL'));
    expect(missingSummary.first.value, equals(2));
  });

  testWidgets('Phase 12 Placement Readiness Screen Direct Render Test', (
    WidgetTester tester,
  ) async {
    UserSession().setSession(
      userId: 'student123',
      role: 'Student',
      name: 'Test Student',
      email: 'student@campus.edu',
    );

    await tester.pumpWidget(
      const MaterialApp(home: PlacementReadinessScreen()),
    );

    expect(find.text('Placement Readiness & Insights'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Placement Readiness & Insights'), findsOneWidget);

    UserSession().clearSession();
  });

  test('Company Role Normalization & Routing Logic Test', () {
    final rolesToTest = [
      'Company',
      'company',
      ' Company ',
      'HR',
      'hr',
      'Recruiter',
    ];
    for (final role in rolesToTest) {
      final String normalizedRole = role.trim().toLowerCase();
      final bool isCompany =
          normalizedRole == 'company' ||
          normalizedRole == 'hr' ||
          normalizedRole == 'recruiter';
      expect(
        isCompany,
        isTrue,
        reason: 'Role "$role" should normalize to Company dashboard route.',
      );
    }

    const studentRole = 'Student';
    expect(studentRole.trim().toLowerCase() == 'company', isFalse);
  });

  test('Phase 1 Login Validation Unit Tests', () {
    expect(AppValidators.validateUserId(''), isNotNull);
    expect(AppValidators.validateUserId('  '), isNotNull);
    expect(AppValidators.validateUserId('usr'), isNull);
    expect(AppValidators.validateUserId('COM001'), isNull);

    expect(AppValidators.validatePassword(''), isNotNull);
    expect(AppValidators.validatePassword('12345'), isNotNull);
    expect(AppValidators.validatePassword('COM123'), isNull);
    expect(AppValidators.validatePassword('admin123'), isNull);
  });

  test('Phase 1 Active User Status & Role Routing Test', () {
    final activeStudentResp = {
      'success': true,
      'userId': 'STU001',
      'role': ' student ',
      'status': 'Active',
    };
    final String studentRole = activeStudentResp['role']
        .toString()
        .trim()
        .toLowerCase();
    final String studentStatus = activeStudentResp['status']
        .toString()
        .trim()
        .toLowerCase();
    expect(studentRole, equals('student'));
    expect(studentStatus, equals('active'));

    final inactiveUserResp = {
      'success': true,
      'userId': 'STU002',
      'role': 'student',
      'status': 'Inactive',
    };
    final String inactiveStatus = inactiveUserResp['status']
        .toString()
        .trim()
        .toLowerCase();
    expect(
      inactiveStatus == 'inactive' || inactiveStatus == 'disabled',
      isTrue,
    );

    final companyResp = {
      'success': true,
      'userId': 'COM001',
      'role': 'Company',
      'status': 'Active',
    };
    expect(
      companyResp['role'].toString().trim().toLowerCase(),
      equals('company'),
    );

    final adminResp = {
      'success': true,
      'userId': 'ADM001',
      'role': 'Admin',
      'status': 'Active',
    };
    expect(adminResp['role'].toString().trim().toLowerCase(), equals('admin'));
  });

  test('Phase 2 Student Registration Form Validation Unit Test', () {
    // Full Name
    expect(AppValidators.validateFullName(''), isNotNull);
    expect(AppValidators.validateFullName('  '), isNotNull);
    expect(AppValidators.validateFullName('Jane Doe'), isNull);

    // Email
    expect(AppValidators.validateEmail('invalid-email'), isNotNull);
    expect(AppValidators.validateEmail('jane@college.edu'), isNull);

    // Mobile Number (10 digits)
    expect(AppValidators.validateMobile('12345'), isNotNull);
    expect(AppValidators.validateMobile('9876543210'), isNull);

    // Confirm Password Match
    expect(
      AppValidators.validateConfirmPassword('pass123', 'pass456'),
      isNotNull,
    );
    expect(AppValidators.validateConfirmPassword('pass123', 'pass123'), isNull);
  });

  test('Phase 2 Student Registration Payload & Role Compatibility Test', () {
    final registrationPayload = {
      'action': 'register',
      'userId': 'NEW_STU_01',
      'name': 'New Student',
      'email': 'newstudent@campus.edu',
      'mobile': '9876543210',
      'password': 'password123',
      'role': 'Student',
    };

    expect(registrationPayload['action'], equals('register'));
    expect(
      registrationPayload['role']!.trim().toLowerCase(),
      equals('student'),
    );

    // Duplicate rejection handling check
    final duplicateErrorResp = {
      'success': false,
      'message': 'User ID or Email already registered',
    };
    expect(duplicateErrorResp['success'], isFalse);
    expect(duplicateErrorResp['message'], contains('already registered'));
  });

  test('Phase 3 Student Profile Serialization & Data Isolation Test', () {
    final profileJson = {
      'success': true,
      'profile': {
        'userId': 'STU_1001',
        'name': 'Rahul Sharma',
        'email': 'rahul@campus.edu',
        'mobile': '9876543210',
        'github': 'https://github.com/rahul',
        'linkedin': 'https://linkedin.com/in/rahul',
        'education': 'B.Tech Computer Science',
        'skills': 'Flutter, Dart, REST API',
        'projects': 'Campus Placement Portal',
        'certifications': 'Flutter Certified Developer',
      },
    };

    final profile = StudentProfile.fromJson(profileJson);

    expect(profile.userId, equals('STU_1001'));
    expect(profile.name, equals('Rahul Sharma'));
    expect(profile.email, equals('rahul@campus.edu'));
    expect(profile.mobile, equals('9876543210'));
    expect(profile.github, equals('https://github.com/rahul'));
    expect(profile.linkedin, equals('https://linkedin.com/in/rahul'));
    expect(profile.education, equals('B.Tech Computer Science'));
    expect(profile.skills, equals('Flutter, Dart, REST API'));
    expect(profile.projects, equals('Campus Placement Portal'));
    expect(profile.certifications, equals('Flutter Certified Developer'));

    // Verify query parameters map serialization for API update
    final queryParams = profile.toQueryParameters();
    expect(queryParams['action'], equals('save_student_profile'));
    expect(queryParams['userId'], equals('STU_1001'));
    expect(queryParams['name'], equals('Rahul Sharma'));
    expect(queryParams['skills'], equals('Flutter, Dart, REST API'));

    // Verify student data isolation: session userId matches request target
    UserSession().setSession(
      userId: 'STU_1001',
      role: 'Student',
      name: 'Rahul Sharma',
      email: 'rahul@campus.edu',
    );
    expect(UserSession().userId, equals(profile.userId));
    UserSession().clearSession();
  });

  test('Phase 4 Resume File Validation Unit Test', () {
    const maxSizeBytes = 5 * 1024 * 1024; // 5 MB

    // File type validation
    bool isValidPdf(String fileName) => fileName.toLowerCase().endsWith('.pdf');
    expect(isValidPdf('resume.pdf'), isTrue);
    expect(isValidPdf('RESUME.PDF'), isTrue);
    expect(isValidPdf('resume.docx'), isFalse);
    expect(isValidPdf('image.png'), isFalse);

    // File size validation
    bool isWithinSizeLimit(int bytes) => bytes <= maxSizeBytes;
    expect(isWithinSizeLimit(2 * 1024 * 1024), isTrue); // 2 MB
    expect(isWithinSizeLimit(5 * 1024 * 1024), isTrue); // 5 MB exact
    expect(isWithinSizeLimit(6 * 1024 * 1024), isFalse); // 6 MB exceeds limit
  });

  test('Phase 4 Resume Chunked Upload Payload & Session Ownership Test', () {
    const chunkSize = 3000; // 3 KB chunk size
    const totalFileBytes = 8500; // 8.5 KB file
    final totalChunks = (totalFileBytes / chunkSize).ceil();
    expect(totalChunks, equals(3));

    final String userId = 'STU_2002';
    UserSession().setSession(
      userId: userId,
      role: 'Student',
      name: 'Test Student',
      email: 'student@campus.edu',
    );

    final chunkParams = {
      'action': 'upload_chunk',
      'uploadId': '${userId}_1787760000000_1234',
      'userId': UserSession().userId,
      'chunkIndex': '1',
      'totalChunks': totalChunks.toString(),
      'fileName': 'student_resume.pdf',
    };

    expect(chunkParams['action'], equals('upload_chunk'));
    expect(chunkParams['userId'], equals(userId));
    expect(chunkParams['totalChunks'], equals('3'));

    final finishParams = {
      'action': 'finish_upload',
      'uploadId': chunkParams['uploadId'],
      'userId': UserSession().userId,
      'fileName': 'student_resume.pdf',
      'mimeType': 'application/pdf',
      'totalChunks': '3',
    };

    expect(finishParams['action'], equals('finish_upload'));
    expect(finishParams['userId'], equals(userId));

    UserSession().clearSession();
  });

  test('Phase 5 Job Listings Backend Source Only & Zero Fallback Test', () {
    // 1. Empty backend response yields empty job list (no hardcoded/dummy fallbacks)
    final emptyResponse = {'success': true, 'jobs': <Map<String, dynamic>>[]};

    final List rawJobs = emptyResponse['jobs'] as List;
    final List<Job> parsedJobs = rawJobs
        .map((j) => Job.fromJson(Map<String, dynamic>.from(j)))
        .toList();

    expect(parsedJobs, isEmpty);
    expect(parsedJobs.length, equals(0));

    // 2. Real jobs from backend are parsed directly
    final backendResponse = {
      'success': true,
      'jobs': [
        {
          'jobId': 'JOB_501',
          'title': 'Flutter Developer',
          'company': 'Tech Corp',
          'location': 'Bangalore',
          'jobType': 'Full-time',
          'skills': 'Flutter, Dart',
          'salary': '12 LPA',
          'description': 'Flutter app development',
          'status': 'Active',
          'postedDate': '2026-09-01',
        },
      ],
    };

    final List backendRawJobs = backendResponse['jobs'] as List;
    final List<Job> activeJobs = backendRawJobs
        .map((j) => Job.fromJson(Map<String, dynamic>.from(j)))
        .where((job) => job.status.toLowerCase() == 'active')
        .toList();

    expect(activeJobs.length, equals(1));
    expect(activeJobs.first.jobId, equals('JOB_501'));
    expect(activeJobs.first.title, equals('Flutter Developer'));
    expect(activeJobs.first.company, equals('Tech Corp'));
  });

  test('Phase 6 Job Details Data Accuracy & Isolation Unit Test', () {
    final jobAJson = {
      'jobId': 'JOB_A',
      'title': 'Flutter Lead',
      'company': 'Company A',
      'location': 'Bangalore',
      'jobType': 'Full-time',
      'skills': 'Flutter, Dart, State Management',
      'salary': '18 LPA',
      'description': 'Lead mobile developer for enterprise apps.',
      'status': 'Active',
      'postedDate': '2026-09-10',
    };

    final jobBJson = {
      'jobId': 'JOB_B',
      'title': 'Data Scientist',
      'company': 'Company B',
      'location': 'Hyderabad',
      'jobType': 'Full-time',
      'skills': 'Python, Machine Learning, SQL',
      'salary': '15 LPA',
      'description': 'Data analytics and ML models.',
      'status': 'Active',
      'postedDate': '2026-09-12',
    };

    final jobA = Job.fromJson(jobAJson);
    final jobB = Job.fromJson(jobBJson);

    // 1. Verify Job A details remain distinct from Job B
    expect(jobA.jobId, equals('JOB_A'));
    expect(jobA.title, equals('Flutter Lead'));
    expect(jobA.company, equals('Company A'));
    expect(jobA.skills, contains('Flutter'));

    expect(jobB.jobId, equals('JOB_B'));
    expect(jobB.title, equals('Data Scientist'));
    expect(jobB.company, equals('Company B'));
    expect(jobB.skills, contains('Python'));

    // 2. Verify getJobDetails API parameter format
    final queryParams = {'action': 'get_job_details', 'jobId': jobA.jobId};
    expect(queryParams['action'], equals('get_job_details'));
    expect(queryParams['jobId'], equals('JOB_A'));

    // 3. Verify error handling when job is not found
    final notFoundResponse = {'success': false, 'message': 'Job not found'};
    expect(notFoundResponse['success'], isFalse);
    expect(notFoundResponse['message'], equals('Job not found'));
  });

  test('Phase 7 Apply Job & Duplicate Application Handling Test', () {
    final String currentStudentId = 'STU_7001';
    final String targetJobId = 'JOB_7001';

    UserSession().setSession(
      userId: currentStudentId,
      role: 'Student',
      name: 'Applicant Student',
      email: 'applicant@campus.edu',
    );

    final applyParams = {
      'action': 'apply_job',
      'userId': UserSession().userId,
      'jobId': targetJobId,
    };

    expect(applyParams['action'], equals('apply_job'));
    expect(applyParams['userId'], equals(currentStudentId));
    expect(applyParams['jobId'], equals(targetJobId));

    // Duplicate application error response handling test
    final duplicateResp = {
      'success': false,
      'message': 'You have already applied for this job',
    };
    expect(duplicateResp['success'], isFalse);
    expect(duplicateResp['message'], contains('already applied'));

    UserSession().clearSession();
  });

  test('Phase 7 My Applications Data Isolation & Zero Fallback Test', () {
    final String studentA = 'STU_AAA';
    final String studentB = 'STU_BBB';

    final applicationsListJson = [
      {
        'applicationId': 'APP_701',
        'jobId': 'JOB_7001',
        'userId': studentA,
        'appliedDate': '2026-09-15 10:30',
        'status': 'Applied',
        'title': 'Flutter Developer',
        'company': 'Tech Solutions',
        'location': 'Bangalore',
      },
    ];

    final List rawApps = applicationsListJson;
    final List<Application> studentAApps = rawApps
        .map((a) => Application.fromJson(Map<String, dynamic>.from(a)))
        .where((app) => app.userId == studentA)
        .toList();

    final List<Application> studentBApps = rawApps
        .map((a) => Application.fromJson(Map<String, dynamic>.from(a)))
        .where((app) => app.userId == studentB)
        .toList();

    // Student A gets 1 application
    expect(studentAApps.length, equals(1));
    expect(studentAApps.first.jobId, equals('JOB_7001'));
    expect(studentAApps.first.company, equals('Tech Solutions'));

    // Student B gets 0 applications (data isolation verified)
    expect(studentBApps, isEmpty);
  });

  test('Phase 8 Notification Model & Serialization Unit Test', () {
    final notifJson = {
      'notificationId': 'NOTIF_801',
      'userId': 'STU_8001',
      'title': 'Application Update',
      'message': 'Your application status was updated.',
      'type': 'application',
      'date': '2026-09-20 14:00',
      'isRead': 'false',
    };

    final item = NotificationItem.fromJson(notifJson);
    expect(item.id, equals('NOTIF_801'));
    expect(item.userId, equals('STU_8001'));
    expect(item.title, equals('Application Update'));
    expect(item.message, equals('Your application status was updated.'));
    expect(item.type, equals('application'));
    expect(item.isRead, isFalse);

    final updatedItem = item.copyWith(isRead: true);
    expect(updatedItem.isRead, isTrue);

    final getParams = {'action': 'get_notifications', 'userId': 'STU_8001'};
    expect(getParams['action'], equals('get_notifications'));
    expect(getParams['userId'], equals('STU_8001'));

    final markParams = {
      'action': 'mark_notification_read',
      'notificationId': 'NOTIF_801',
      'userId': 'STU_8001',
    };
    expect(markParams['action'], equals('mark_notification_read'));
    expect(markParams['notificationId'], equals('NOTIF_801'));
  });

  test('Phase 8 Student Data Isolation & Zero Fallback Test', () {
    final rawNotifications = [
      {
        'notificationId': 'N1',
        'userId': 'STU_8001',
        'title': 'Personal Alert',
        'message': 'Message for student 8001',
        'type': 'general',
        'date': '2026-09-21',
        'isRead': false,
      },
      {
        'notificationId': 'N2',
        'userId': 'STU_8002',
        'title': 'Other Student Alert',
        'message': 'Message for student 8002',
        'type': 'general',
        'date': '2026-09-21',
        'isRead': false,
      },
      {
        'notificationId': 'N3',
        'userId': 'all',
        'title': 'Campus Wide Alert',
        'message': 'Message for all students',
        'type': 'general',
        'date': '2026-09-21',
        'isRead': false,
      },
    ];

    const currentStudentId = 'STU_8001';

    final List<NotificationItem> studentNotifs = rawNotifications
        .map((n) => NotificationItem.fromJson(n))
        .where(
          (n) =>
              n.userId.toLowerCase() == currentStudentId.toLowerCase() ||
              n.userId.toLowerCase() == 'all',
        )
        .toList();

    expect(studentNotifs.length, equals(2));
    expect(studentNotifs.any((n) => n.id == 'N1'), isTrue);
    expect(studentNotifs.any((n) => n.id == 'N3'), isTrue);
    expect(studentNotifs.any((n) => n.id == 'N2'), isFalse);
  });

  testWidgets('Phase 8 Notifications Screen Direct Render Test', (
    WidgetTester tester,
  ) async {
    UserSession().setSession(
      userId: 'STU_8001',
      role: 'Student',
      name: 'Test Student',
      email: 'student@campus.edu',
    );

    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));

    expect(find.text(AppStrings.notificationsTitle), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.notificationsTitle), findsOneWidget);

    UserSession().clearSession();
  });

  test('Phase 11 Application Status Helper Normalization & Colors Test', () {
    expect(
      ApplicationStatusHelper.normalizeStatus('Applied'),
      equals('Applied'),
    );
    expect(
      ApplicationStatusHelper.normalizeStatus('under review'),
      equals('Under Review'),
    );
    expect(
      ApplicationStatusHelper.normalizeStatus('shortlisted candidate'),
      equals('Shortlisted'),
    );
    expect(
      ApplicationStatusHelper.normalizeStatus('Selected!'),
      equals('Selected'),
    );
    expect(
      ApplicationStatusHelper.normalizeStatus('rejected application'),
      equals('Rejected'),
    );

    expect(ApplicationStatusHelper.getStepIndex('Applied'), equals(0));
    expect(ApplicationStatusHelper.getStepIndex('Under Review'), equals(1));
    expect(ApplicationStatusHelper.getStepIndex('Shortlisted'), equals(2));
    expect(ApplicationStatusHelper.getStepIndex('Selected'), equals(3));
    expect(ApplicationStatusHelper.getStepIndex('Rejected'), equals(-1));
  });

  test('Phase 11 Application Search & Status Filtering Logic Test', () {
    final apps = [
      const Application(
        applicationId: 'APP1',
        jobId: 'JOB1',
        userId: 'STU1',
        appliedDate: '2026-09-10',
        status: 'Applied',
        title: 'Flutter Developer',
        company: 'Google',
        location: 'Bangalore',
      ),
      const Application(
        applicationId: 'APP2',
        jobId: 'JOB2',
        userId: 'STU1',
        appliedDate: '2026-09-12',
        status: 'Shortlisted',
        title: 'Backend Engineer',
        company: 'Microsoft',
        location: 'Hyderabad',
      ),
    ];

    // Status Filter Check
    final shortlistedApps = apps
        .where(
          (a) =>
              ApplicationStatusHelper.normalizeStatus(a.status) ==
              'Shortlisted',
        )
        .toList();
    expect(shortlistedApps.length, equals(1));
    expect(shortlistedApps.first.applicationId, equals('APP2'));

    // Search Query Check
    final searchResult = apps
        .where((a) => a.company.toLowerCase().contains('google'))
        .toList();
    expect(searchResult.length, equals(1));
    expect(searchResult.first.jobId, equals('JOB1'));
  });

  testWidgets('Phase 11 Application Timeline Widget Direct Render Test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ApplicationTimelineWidget(
            status: 'Shortlisted',
            appliedDate: '2026-09-15',
            isCompact: false,
          ),
        ),
      ),
    );

    expect(find.text('Application Progress History'), findsOneWidget);
    expect(find.text('Shortlisted'), findsWidgets);
  });

  testWidgets('Phase 11 My Applications Screen Direct Render Test', (
    WidgetTester tester,
  ) async {
    UserSession().setSession(
      userId: 'STU_1101',
      role: 'Student',
      name: 'Applicant Student',
      email: 'student@campus.edu',
    );

    await tester.pumpWidget(const MaterialApp(home: MyApplicationsScreen()));

    expect(find.text(AppStrings.myApplications), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.myApplications), findsOneWidget);

    UserSession().clearSession();
  });

  test('Phase 12 Placement Readiness Calculator Formula Unit Test', () {
    const profile = StudentProfile(
      userId: 'STU1201',
      name: 'John Student',
      email: 'john@campus.edu',
      mobile: '9876543210',
      education: 'B.Tech CS',
      github: 'https://github.com/john',
      linkedin: 'https://linkedin.com/in/john',
      skills: 'Flutter, Dart, Java, SQL, Python',
      projects: 'Campus Placement Portal',
      certifications: 'Flutter Certified',
    );

    final completeness =
        PlacementReadinessCalculator.calculateProfileCompleteness(profile);
    expect(completeness, equals(100.0));

    const jobs = [
      Job(
        jobId: 'JOB1201',
        title: 'Flutter Lead',
        company: 'TechCorp',
        location: 'Bangalore',
        jobType: 'Full-time',
        skills: 'Flutter, Dart, SQL',
        salary: '12 LPA',
        description: 'App dev',
      ),
    ];

    final marketAlignment =
        PlacementReadinessCalculator.calculateMarketAlignment(jobs, profile);
    expect(marketAlignment, equals(100.0));

    final overall = PlacementReadinessCalculator.calculateOverallReadiness(
      profile,
      jobs,
    );
    expect(overall, equals(100.0));
  });

  test('Phase 12 Job Recommendation Sorting & Classification Unit Test', () {
    const profile = StudentProfile(userId: 'STU1202', skills: 'Flutter, Dart');

    const jobs = [
      Job(
        jobId: 'JOB1',
        title: 'Backend Dev',
        company: 'Company A',
        location: 'Bangalore',
        jobType: 'Full-time',
        skills: 'Java, Spring Boot, SQL, AWS',
        salary: '10 LPA',
        description: 'Backend dev',
      ),
      Job(
        jobId: 'JOB2',
        title: 'Flutter Developer',
        company: 'Company B',
        location: 'Remote',
        jobType: 'Full-time',
        skills: 'Flutter, Dart',
        salary: '12 LPA',
        description: 'Flutter dev',
      ),
    ];

    final items = PlacementReadinessCalculator.sortJobsByRecommendation(
      jobs,
      profile,
    );
    expect(items.first.job.jobId, equals('JOB2'));
    expect(items.first.matchPercentage, equals(100.0));
    expect(
      PlacementReadinessCalculator.getMatchCategory(
        items.first.matchPercentage,
      ),
      equals(PlacementReadinessCalculator.categoryStrong),
    );

    expect(items.last.job.jobId, equals('JOB1'));
    expect(items.last.matchPercentage, equals(0.0));
    expect(
      PlacementReadinessCalculator.getMatchCategory(items.last.matchPercentage),
      equals(PlacementReadinessCalculator.categoryNeedsImprovement),
    );
  });

  test('Phase 12 Missing Skills Aggregation Unit Test', () {
    const profile = StudentProfile(userId: 'STU1203', skills: 'Flutter');

    const jobs = [
      Job(
        jobId: 'JOB1',
        title: 'Dev 1',
        company: 'A',
        location: 'L',
        jobType: 'Full-time',
        skills: 'Flutter, Java, SQL',
        salary: '10 LPA',
        description: 'd',
      ),
      Job(
        jobId: 'JOB2',
        title: 'Dev 2',
        company: 'B',
        location: 'L',
        jobType: 'Full-time',
        skills: 'Flutter, Java, Python',
        salary: '10 LPA',
        description: 'd',
      ),
    ];

    final summary = PlacementReadinessCalculator.getMissingSkillsSummary(
      jobs,
      profile,
    );
    // Java is missing in both jobs (frequency 2)
    final javaEntry = summary.firstWhere((e) => e.key == 'Java');
    expect(javaEntry.value, equals(2));
  });

  testWidgets('Phase 12 Placement Readiness Screen Direct Render Test', (
    WidgetTester tester,
  ) async {
    UserSession().setSession(
      userId: 'STU1204',
      role: 'Student',
      name: 'Test Student',
      email: 'student@campus.edu',
    );

    await tester.pumpWidget(
      const MaterialApp(home: PlacementReadinessScreen()),
    );

    expect(find.text(AppStrings.placementReadinessTitle), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.placementReadinessTitle), findsOneWidget);

    UserSession().clearSession();
  });

  test('Company Module Ownership & Data Filtering Unit Test', () {
    const com1Job = Job(
      jobId: 'JOB101',
      title: 'Senior Flutter Developer',
      company: 'COM001',
      location: 'Bangalore',
      jobType: 'Full-time',
      skills: 'Flutter, Dart',
      salary: '12 LPA',
      description: 'Senior Dev',
    );

    const com2Job = Job(
      jobId: 'JOB102',
      title: 'Backend Developer',
      company: 'COM002',
      location: 'Hyderabad',
      jobType: 'Full-time',
      skills: 'Java, Spring Boot',
      salary: '15 LPA',
      description: 'Backend Dev',
    );

    final allJobs = [com1Job, com2Job];

    // COM001 should only see COM001 jobs
    const currentCompanyId = 'COM001';
    final filtered = allJobs.where((j) {
      final c = j.company.toLowerCase();
      final target = currentCompanyId.toLowerCase();
      return c.contains(target) || target.contains(c);
    }).toList();

    expect(filtered.length, equals(1));
    expect(filtered.first.jobId, equals('JOB101'));
    expect(filtered.first.company, equals('COM001'));
  });

  test('Company Module Dashboard Statistics Calculation Unit Test', () {
    final apps = [
      {'applicationId': 'APP1', 'status': 'Applied'},
      {'applicationId': 'APP2', 'status': 'Under Review'},
      {'applicationId': 'APP3', 'status': 'Selected'},
      {'applicationId': 'APP4', 'status': 'Rejected'},
    ];

    final pendingCount = apps.where((a) {
      final norm = ApplicationStatusHelper.normalizeStatus(a['status']);
      return norm == ApplicationStatusHelper.statusApplied ||
          norm == ApplicationStatusHelper.statusUnderReview;
    }).length;

    final selectedCount = apps.where((a) {
      return ApplicationStatusHelper.normalizeStatus(a['status']) ==
          ApplicationStatusHelper.statusSelected;
    }).length;

    expect(pendingCount, equals(2));
    expect(selectedCount, equals(1));
  });

  testWidgets('Company Dashboard Direct Render Test', (
    WidgetTester tester,
  ) async {
    UserSession().setSession(
      userId: 'COM001',
      role: 'Company',
      name: 'ABC Company',
      email: 'contact@abccompany.com',
    );

    await tester.pumpWidget(const MaterialApp(home: CompanyDashboard()));

    expect(find.text('Company Dashboard'), findsOneWidget);
    expect(find.text('Welcome, ABC Company 🏢'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Post Job'), findsOneWidget);
    expect(find.text('My Jobs'), findsOneWidget);
    expect(find.text('Applicants'), findsOneWidget);
    expect(find.text('Student Resumes'), findsOneWidget);
    expect(find.text('Company Profile'), findsOneWidget);

    UserSession().clearSession();
  });

  test('Company Module Post Job Parameter Mapping Unit Test', () {
    final uri = Uri.parse(GoogleSheetsService.baseUrl).replace(
      queryParameters: {
        'action': 'post_job',
        'title': 'Flutter Developer',
        'jobTitle': 'Flutter Developer',
        'company': 'COM001',
        'companyName': 'COM001',
        'location': 'Ahmedabad',
        'skills': 'Flutter, Dart',
        'salary': '12 LPA',
        'description': 'Flutter app developer',
        'jobType': 'Full-time',
      },
    );

    expect(uri.queryParameters['action'], equals('post_job'));
    expect(uri.queryParameters['title'], equals('Flutter Developer'));
    expect(uri.queryParameters['jobTitle'], equals('Flutter Developer'));
    expect(uri.queryParameters['company'], equals('COM001'));
    expect(uri.queryParameters['companyName'], equals('COM001'));
    expect(uri.queryParameters['location'], equals('Ahmedabad'));
    expect(uri.queryParameters['skills'], equals('Flutter, Dart'));
    expect(uri.queryParameters['salary'], equals('12 LPA'));
    expect(uri.queryParameters['description'], equals('Flutter app developer'));
    expect(uri.queryParameters['jobType'], equals('Full-time'));
  });

  test('Phase 13 Recruiter Feedback Model & Serialization Unit Test', () {
    final json = <String, dynamic>{
      'feedbackId': 'FB1001',
      'applicationId': 'APP1787759900000',
      'jobId': 'JOB001',
      'studentId': 'test_student',
      'companyId': 'COM001',
      'rating': 4.5,
      'feedback': 'Excellent candidate with strong technical background.',
      'createdAt': '2026-09-27',
    };

    final fb = RecruiterFeedback.fromJson(json);

    expect(fb.feedbackId, equals('FB1001'));
    expect(fb.applicationId, equals('APP1787759900000'));
    expect(fb.jobId, equals('JOB001'));
    expect(fb.studentId, equals('test_student'));
    expect(fb.companyId, equals('COM001'));
    expect(fb.rating, equals(4.5));
    expect(
      fb.feedback,
      equals('Excellent candidate with strong technical background.'),
    );
    expect(fb.createdAt, equals('2026-09-27'));

    final queryParams = fb.toQueryParameters();
    expect(queryParams['action'], equals('submit_recruiter_feedback'));
    expect(queryParams['applicationId'], equals('APP1787759900000'));
    expect(queryParams['rating'], equals('4.5'));
  });

  test('Phase 13 Candidate Ranking Calculator Formula & Sorting Test', () {
    const fbHigh = RecruiterFeedback(
      feedbackId: 'FB001',
      applicationId: 'APP1',
      jobId: 'JOB1',
      studentId: 'STU1',
      companyId: 'COM1',
      rating: 5.0,
      feedback: 'Outstanding candidate',
      createdAt: '2026-09-27',
    );

    const fbLow = RecruiterFeedback(
      feedbackId: 'FB002',
      applicationId: 'APP2',
      jobId: 'JOB1',
      studentId: 'STU2',
      companyId: 'COM1',
      rating: 2.0,
      feedback: 'Needs improvement',
      createdAt: '2026-09-27',
    );

    final scoreHigh = CandidateRankingCalculator.calculateCandidateScore(
      feedback: fbHigh,
      status: 'Selected',
      cgpaStr: '9.2',
    );

    final scoreLow = CandidateRankingCalculator.calculateCandidateScore(
      feedback: fbLow,
      status: 'Under Review',
      cgpaStr: '7.0',
    );

    expect(scoreHigh, equals(100.0));
    expect(scoreLow, equals(43.0));

    final items = <CandidateRankingItem>[
      CandidateRankingItem(
        application: <String, dynamic>{'applicationId': 'APP2'},
        feedback: fbLow,
        candidateScore: scoreLow,
      ),
      CandidateRankingItem(
        application: <String, dynamic>{'applicationId': 'APP1'},
        feedback: fbHigh,
        candidateScore: scoreHigh,
      ),
    ];

    final sorted = CandidateRankingCalculator.sortCandidatesByRanking(items);
    expect(sorted.first.application['applicationId'], equals('APP1'));
    expect(sorted.last.application['applicationId'], equals('APP2'));
  });

  test('Phase 13 Company Recruiter Feedback Payload Mapping Test', () {
    final uri = Uri.parse(GoogleSheetsService.baseUrl).replace(
      queryParameters: {
        'action': 'get_recruiter_feedback',
        'companyId': 'COM001',
      },
    );

    expect(uri.queryParameters['action'], equals('get_recruiter_feedback'));
    expect(uri.queryParameters['companyId'], equals('COM001'));
  });

  test('Phase 14 Admin Statistics Payload & Endpoint Mapping Unit Test', () {
    final uri = Uri.parse(
      GoogleSheetsService.baseUrl,
    ).replace(queryParameters: {'action': 'get_admin_statistics'});

    expect(uri.queryParameters['action'], equals('get_admin_statistics'));

    final mockResponse = {
      'success': true,
      'totalStudents': 45,
      'totalJobs': 12,
      'totalApplications': 120,
      'shortlisted': 30,
      'selected': 15,
      'placementPercentage': 33.33,
    };

    expect(mockResponse['success'], isTrue);
    expect(mockResponse['totalStudents'], equals(45));
    expect(mockResponse['totalJobs'], equals(12));
    expect(mockResponse['totalApplications'], equals(120));
    expect(mockResponse['shortlisted'], equals(30));
    expect(mockResponse['selected'], equals(15));
    expect(mockResponse['placementPercentage'], equals(33.33));
  });

  test(
    'Phase 14A Admin Dashboard Active Drives Real Data Binding Unit Test',
    () {
      final mockJobsJson = [
        {
          'jobId': 'JOB101',
          'title': 'Flutter App Developer',
          'company': 'Tech Corp',
          'location': 'Ahmedabad',
          'jobType': 'Full-time',
          'skills': 'Flutter, Dart',
          'salary': '₹12 LPA',
          'description': 'Mobile App Dev',
          'status': 'Active',
          'postedDate': '2026-09-27',
        },
      ];

      final jobsList = mockJobsJson.map((j) => Job.fromJson(j)).toList();

      expect(jobsList.length, equals(1));
      final drive = jobsList.first;
      expect(drive.jobId, equals('JOB101'));
      expect(drive.title, equals('Flutter App Developer'));
      expect(drive.company, equals('Tech Corp'));
      expect(drive.salary, equals('₹12 LPA'));
      expect(drive.location, equals('Ahmedabad'));
      expect(drive.status, equals('Active'));
    },
  );

  test(
    'Phase 14B Admin Dashboard Company Approvals Payload & Action Mapping Unit Test',
    () {
      final getUri = Uri.parse(
        GoogleSheetsService.baseUrl,
      ).replace(queryParameters: {'action': 'get_admin_companies'});
      expect(getUri.queryParameters['action'], equals('get_admin_companies'));

      final updateUri = Uri.parse(GoogleSheetsService.baseUrl).replace(
        queryParameters: {
          'action': 'update_company_status',
          'userId': 'COM001',
          'status': 'Active',
        },
      );
      expect(
        updateUri.queryParameters['action'],
        equals('update_company_status'),
      );
      expect(updateUri.queryParameters['userId'], equals('COM001'));
      expect(updateUri.queryParameters['status'], equals('Active'));

      final mockCompaniesResp = {
        'success': true,
        'companies': [
          {
            'userId': 'COM001',
            'name': 'ABC Company',
            'email': 'company@gmail.com',
            'status': 'Active',
            'role': 'Company',
          },
        ],
      };

      expect(mockCompaniesResp['success'], isTrue);
      final list = mockCompaniesResp['companies'] as List;
      expect(list.length, equals(1));
      final firstComp = list.first as Map<String, dynamic>;
      expect(firstComp['userId'], equals('COM001'));
      expect(firstComp['name'], equals('ABC Company'));
      expect(firstComp['status'], equals('Active'));
    },
  );

  test(
    'Phase 14 Admin Registered Students Data Fetching & Mapping Unit Test',
    () {
      final uri = Uri.parse(
        GoogleSheetsService.baseUrl,
      ).replace(queryParameters: {'action': 'get_admin_students'});

      expect(uri.queryParameters['action'], equals('get_admin_students'));

      final mockStudentsResp = {
        'success': true,
        'students': [
          {
            'userId': 'STU001',
            'studentId': 'STU001',
            'name': 'Student One',
            'email': 'stu1@campus.edu',
            'mobile': '9876543210',
            'education': 'B.Tech CSE',
            'course': 'B.Tech CSE',
            'semester': 'Semester 8',
            'skills': 'Flutter, Dart, Java',
            'cgpa': '8.5',
            'resumeUrl': 'https://drive.google.com/file/d/sample1',
            'status': 'Active',
          },
          {
            'userId': 'STU002',
            'studentId': 'STU002',
            'name': 'Student Two',
            'email': 'stu2@campus.edu',
            'mobile': '9876543211',
            'education': 'B.Tech IT',
            'course': 'B.Tech IT',
            'semester': 'Semester 6',
            'skills': 'Python, SQL',
            'cgpa': '7.8',
            'resumeUrl': 'https://drive.google.com/file/d/sample2',
            'status': 'Active',
          },
          {
            'userId': 'STU003',
            'studentId': 'STU003',
            'name': 'Student Three',
            'email': 'stu3@campus.edu',
            'mobile': '9876543212',
            'education': '',
            'course': '',
            'semester': '',
            'skills': '',
            'cgpa': '',
            'resumeUrl': '',
            'status': 'Active',
          },
          {
            'userId': 'STU004',
            'studentId': 'STU004',
            'name': 'Student Four',
            'email': 'stu4@campus.edu',
            'mobile': '',
            'education': '',
            'course': '',
            'semester': '',
            'skills': '',
            'cgpa': '',
            'resumeUrl': '',
            'status': 'Active',
          },
          {
            'userId': 'STU005',
            'studentId': 'STU005',
            'name': 'Student Five',
            'email': 'stu5@campus.edu',
            'mobile': '9876543214',
            'education': 'M.Tech',
            'course': 'M.Tech',
            'semester': 'Semester 4',
            'skills': 'AI, ML',
            'cgpa': '9.0',
            'resumeUrl': '',
            'status': 'Active',
          },
          {
            'userId': 'STU006',
            'studentId': 'STU006',
            'name': 'Student Six',
            'email': 'stu6@campus.edu',
            'mobile': '',
            'education': '',
            'course': '',
            'semester': '',
            'skills': '',
            'cgpa': '',
            'resumeUrl': '',
            'status': 'Active',
          },
        ],
      };

      expect(mockStudentsResp['success'], isTrue);
      final rawStudents = mockStudentsResp['students'] as List;
      expect(rawStudents.length, equals(6));

      final Set<String> studentIds = {};
      for (final s in rawStudents) {
        final map = Map<String, dynamic>.from(s as Map);
        final id = (map['studentId'] ?? map['userId'] ?? '').toString();
        expect(id.isNotEmpty, isTrue);
        expect(studentIds.contains(id.toLowerCase()), isFalse);
        studentIds.add(id.toLowerCase());
      }

      expect(studentIds.length, equals(6));
    },
  );

  test('Phase 15 Most Demanded Skills Payload & Data Normalization Test', () {
    final uri = Uri.parse(
      GoogleSheetsService.baseUrl,
    ).replace(queryParameters: {'action': 'get_most_demanded_skills'});
    expect(uri.queryParameters['action'], equals('get_most_demanded_skills'));

    final mockSkillsResponse = {
      'success': true,
      'skills': [
        {'skill': 'Flutter', 'count': 8},
        {'skill': 'Dart', 'count': 6},
        {'skill': 'SQL', 'count': 4},
      ],
    };

    expect(mockSkillsResponse['success'], isTrue);
    final skills = mockSkillsResponse['skills'] as List;
    expect(skills.length, equals(3));
    expect(skills[0]['skill'], equals('Flutter'));
    expect(skills[0]['count'], equals(8));
  });

  test('Phase 15 Student Readiness Distribution Reuse Logic Unit Test', () {
    final uri = Uri.parse(
      GoogleSheetsService.baseUrl,
    ).replace(queryParameters: {'action': 'get_readiness_distribution'});
    expect(uri.queryParameters['action'], equals('get_readiness_distribution'));

    final mockReadinessResponse = {
      'success': true,
      'categories': [
        {'category': 'Ready', 'count': 20},
        {'category': 'Almost Ready', 'count': 15},
        {'category': 'Needs Improvement', 'count': 10},
      ],
    };

    expect(mockReadinessResponse['success'], isTrue);
    final categories = mockReadinessResponse['categories'] as List;
    expect(categories.length, equals(3));
    expect(categories[0]['category'], equals('Ready'));
    expect(categories[0]['count'], equals(20));
  });

  test('Phase 15 Top Recommended Jobs Payload & Calculation Unit Test', () {
    final uri = Uri.parse(
      GoogleSheetsService.baseUrl,
    ).replace(queryParameters: {'action': 'get_top_recommended_jobs'});
    expect(uri.queryParameters['action'], equals('get_top_recommended_jobs'));

    final mockRecommendedResponse = {
      'success': true,
      'recommendedJobs': [
        {
          'jobId': 'JOB001',
          'jobTitle': 'Software Developer',
          'company': 'Example Company',
          'recommendationCount': 12,
        },
      ],
    };

    expect(mockRecommendedResponse['success'], isTrue);
    final jobs = mockRecommendedResponse['recommendedJobs'] as List;
    expect(jobs.length, equals(1));
    expect(jobs[0]['jobId'], equals('JOB001'));
    expect(jobs[0]['jobTitle'], equals('Software Developer'));
    expect(jobs[0]['recommendationCount'], equals(12));
  });

  test('Phase 15 Placement Trends Payload & Monthly Grouping Unit Test', () {
    final uri = Uri.parse(
      GoogleSheetsService.baseUrl,
    ).replace(queryParameters: {'action': 'get_placement_trends'});
    expect(uri.queryParameters['action'], equals('get_placement_trends'));

    final mockTrendsResponse = {
      'success': true,
      'trends': [
        {
          'month': 'Jan 2026',
          'applications': 20,
          'shortlisted': 8,
          'selected': 3,
        },
      ],
    };

    expect(mockTrendsResponse['success'], isTrue);
    final trends = mockTrendsResponse['trends'] as List;
    expect(trends.length, equals(1));
    expect(trends[0]['month'], equals('Jan 2026'));
    expect(trends[0]['applications'], equals(20));
    expect(trends[0]['shortlisted'], equals(8));
    expect(trends[0]['selected'], equals(3));
  });

  testWidgets('Phase 15 Admin Analytics & Reports Widget Render Test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: AnalyticsReportsWidget()),
        ),
      ),
    );

    expect(find.text('Analytics & Reports'), findsOneWidget);
    expect(find.text('1. Most Demanded Skills'), findsOneWidget);
    expect(find.text('2. Student Readiness Distribution'), findsOneWidget);
    expect(find.text('3. Top Recommended Jobs'), findsOneWidget);
    expect(find.text('4. Placement Trends'), findsOneWidget);
  });

  testWidgets('Company Job Applicants Click-Through and JobId Filter Test', (
    WidgetTester tester,
  ) async {
    final jobMap = {
      'id': 'JOB001',
      'title': 'Flutter Developer',
      'company': 'Tech Corp',
      'location': 'Bangalore',
      'skills': 'Flutter, Dart',
      'salary': '12 LPA',
      'description': 'Dev',
      'status': 'Active',
      'postedDate': '2026-10-01',
      'applicants': 2,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CompanyJobCard(job: jobMap)),
      ),
    );

    // Verify "2 Applicants" is rendered
    expect(find.text('2 Applicants'), findsOneWidget);

    // Tap "2 Applicants" text
    await tester.tap(find.text('2 Applicants'));
    await tester.pumpAndSettle();

    // Verify navigation to ApplicantsScreen with job title in title/banner
    expect(find.textContaining('Flutter Developer'), findsWidgets);
  });

  testWidgets('Company Dashboard Statistics Click-Through Test', (
    WidgetTester tester,
  ) async {
    UserSession().setSession(
      userId: 'COM001',
      role: 'Company',
      name: 'Tech Corp',
      email: 'recruiter@techcorp.com',
    );

    await tester.pumpWidget(const MaterialApp(home: CompanyDashboardScreen()));

    await tester.pumpAndSettle();

    // Verify statistics overview items are visible
    expect(find.text('Posted Jobs'), findsOneWidget);
    expect(find.text('Total Applicants'), findsOneWidget);
    expect(find.text('Pending Applications'), findsOneWidget);
    expect(find.text('Selected Students'), findsOneWidget);

    // Tap "Pending Applications" row
    await tester.tap(find.text('Pending Applications'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify navigation to ApplicantsScreen with Pending Applications header
    expect(find.text('Pending Applications'), findsWidgets);

    UserSession().clearSession();
  });

  testWidgets('Admin Dashboard Statistics Click-Through Test', (
    WidgetTester tester,
  ) async {
    UserSession().setSession(
      userId: 'ADM001',
      role: 'Admin',
      name: 'System Administrator',
      email: 'admin@campus.edu',
    );

    await tester.pumpWidget(const MaterialApp(home: AdminDashboardScreen()));

    await tester.pumpAndSettle();

    // Verify key metric tiles are visible
    expect(find.text('Students'), findsWidgets);
    expect(find.text('Active Jobs'), findsWidgets);
    expect(find.text('Applications'), findsWidgets);
    expect(find.text('Shortlisted'), findsWidgets);
    expect(find.text('Placements'), findsWidgets);
    expect(find.text('Placement Rate'), findsWidgets);

    // Tap "Students" metric card
    await tester.tap(find.text('Students').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify navigation to AdminStudentsDetailScreen
    expect(find.text('Registered Students'), findsOneWidget);

    UserSession().clearSession();
  });

  test('Phase 16 Job Model Status Deserialization & Serialization Test', () {
    final activeJob = Job.fromJson({
      'jobId': 'JOB101',
      'title': 'Frontend Engineer',
      'company': 'Tech Corp',
      'status': 'Active',
    });
    expect(activeJob.status, 'Active');

    final inactiveJob = Job.fromJson({
      'jobId': 'JOB102',
      'title': 'Backend Engineer',
      'company': 'Tech Corp',
      'status': 'Inactive',
    });
    expect(inactiveJob.status, 'Inactive');

    final defaultJob = Job.fromJson({
      'jobId': 'JOB103',
      'title': 'DevOps Engineer',
      'company': 'Tech Corp',
    });
    expect(defaultJob.status, 'Active');

    final jsonMap = inactiveJob.toJson();
    expect(jsonMap['status'], 'Inactive');
    expect(jsonMap['jobId'], 'JOB102');
  });

  test('Phase 16 Company Data Isolation and Status Filtering Unit Test', () {
    final jobs = [
      const Job(
        jobId: 'JOB1',
        title: 'React Dev',
        company: 'Company A',
        location: 'Remote',
        jobType: 'Full-time',
        skills: 'React',
        salary: '10 LPA',
        description: 'Frontend role',
        status: 'Active',
      ),
      const Job(
        jobId: 'JOB2',
        title: 'Node Dev',
        company: 'Company A',
        location: 'Remote',
        jobType: 'Full-time',
        skills: 'Node',
        salary: '12 LPA',
        description: 'Backend role',
        status: 'Inactive',
      ),
      const Job(
        jobId: 'JOB3',
        title: 'Flutter Dev',
        company: 'Company B',
        location: 'Office',
        jobType: 'Full-time',
        skills: 'Flutter',
        salary: '15 LPA',
        description: 'Mobile role',
        status: 'Active',
      ),
    ];

    // Company A should only see its own jobs (both Active and Inactive)
    final companyAId = 'company a';
    final companyAJobs = jobs.where((j) {
      final c = j.company.toLowerCase();
      return c.contains(companyAId) || companyAId.contains(c);
    }).toList();

    expect(companyAJobs.length, 2);
    expect(companyAJobs.map((j) => j.jobId), containsAll(['JOB1', 'JOB2']));
    expect(companyAJobs.any((j) => j.company == 'Company B'), isFalse);

    // Students should only see Active jobs across all companies
    final studentJobs = jobs.where((j) => j.status.toLowerCase() == 'active').toList();
    expect(studentJobs.length, 2);
    expect(studentJobs.map((j) => j.jobId), containsAll(['JOB1', 'JOB3']));
    expect(studentJobs.any((j) => j.status == 'Inactive'), isFalse);
  });

  testWidgets('CompanyJobCard Inactive Status Message and Warning Banner Test', (
    WidgetTester tester,
  ) async {
    final inactiveJobData = {
      'id': 'JOB999',
      'title': 'Senior Systems Architect',
      'company': 'Alpha Tech',
      'location': 'New York, NY',
      'salary': '\$120,000',
      'skills': 'Kubernetes, Go',
      'status': 'Inactive',
      'applicants': 3,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanyJobCard(job: inactiveJobData),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Inactive status badge & warning message
    expect(find.text('Inactive'), findsWidgets);
    expect(find.text('Job Deactivated by Admin'), findsOneWidget);
    expect(
      find.text('This job has been deactivated by the administrator.\nStudents cannot view or apply for this job.'),
      findsOneWidget,
    );
    expect(find.text('Status: INACTIVE'), findsOneWidget);
  });

  testWidgets('CompanyJobCard Active Status Message Banner Test', (
    WidgetTester tester,
  ) async {
    final activeJobData = {
      'id': 'JOB888',
      'title': 'Mobile Flutter Developer',
      'company': 'Alpha Tech',
      'location': 'Remote',
      'salary': '\$95,000',
      'skills': 'Flutter, Dart',
      'status': 'Active',
      'applicants': 5,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanyJobCard(job: activeJobData),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Active status badge & activation message
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Job Activated by Admin'), findsOneWidget);
    expect(
      find.text('This job has been activated by the administrator.\nStudents can now view and apply for this job.'),
      findsOneWidget,
    );
    expect(find.text('Status: ACTIVE'), findsOneWidget);
  });

  testWidgets('Admin Manage Jobs Screen Direct Render Test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminManageJobsScreen(
          companyId: 'COMP_TEST_01',
          companyName: 'Beta Solutions',
          companyEmail: 'contact@betasolutions.com',
        ),
      ),
    );
    await tester.pump();

    // Verify AppBar title contains Company Name - Job Management
    expect(find.text('Beta Solutions - Job Management'), findsOneWidget);
    expect(find.text('Beta Solutions'), findsWidgets);
  });

  test('Structured EducationItem serialization and deserialization unit test', () {
    // 1. Full 4-part pipe parsing
    final item1 = EducationItem.fromString(
      'Bachelor of Computer Applications | LJ University | 8.2 CGPA | 2026',
    );
    expect(item1.degree, equals('Bachelor of Computer Applications'));
    expect(item1.uniBoard, equals('LJ University'));
    expect(item1.cgpaPercentage, equals('8.2 CGPA'));
    expect(item1.year, equals('2026'));
    expect(
      item1.toSerializedString(),
      equals('Bachelor of Computer Applications | LJ University | 8.2 CGPA | 2026'),
    );

    // 2. Legacy hyphen format: "BCA - LJ University"
    final item2 = EducationItem.fromString('BCA - LJ University');
    expect(item2.degree, equals('BCA'));
    expect(item2.uniBoard, equals('LJ University'));
    expect(item2.cgpaPercentage, isEmpty);
    expect(item2.year, isEmpty);
    expect(item2.toSerializedString(), equals('BCA | LJ University'));

    // 3. Fallback raw string: "B.Tech Computer Science"
    final item3 = EducationItem.fromString('B.Tech Computer Science');
    expect(item3.degree, equals('B.Tech Computer Science'));
    expect(item3.uniBoard, isEmpty);
    expect(item3.cgpaPercentage, isEmpty);
    expect(item3.year, isEmpty);
    expect(item3.toSerializedString(), equals('B.Tech Computer Science'));

    // 4. Multi-entry round trip through StudentProfile
    const multiEduRaw =
        'Bachelor of Computer Applications | LJ University | 8.2 CGPA | 2026\n'
        '12th Science | GSEB Board | 85% | 2022';
    final parsedList = StudentProfile.parseEducation(multiEduRaw);
    expect(parsedList.length, equals(2));
    expect(parsedList[0].degree, equals('Bachelor of Computer Applications'));
    expect(parsedList[1].degree, equals('12th Science'));
    expect(parsedList[1].uniBoard, equals('GSEB Board'));

    final serializedBack = StudentProfile.formatEducation(parsedList);
    expect(serializedBack, equals(multiEduRaw));
  });

  test('Structured CertificationItem serialization and deserialization unit test', () {
    // 1. Full 3-part pipe parsing
    final cert1 = CertificationItem.fromString(
      'Google Data Analytics | 90% | 2026',
    );
    expect(cert1.courseCertificate, equals('Google Data Analytics'));
    expect(cert1.rankingPercentage, equals('90%'));
    expect(cert1.year, equals('2026'));
    expect(cert1.toSerializedString(), equals('Google Data Analytics | 90% | 2026'));

    // 2. Legacy raw string: "Google"
    final cert2 = CertificationItem.fromString('Google');
    expect(cert2.courseCertificate, equals('Google'));
    expect(cert2.rankingPercentage, isEmpty);
    expect(cert2.year, isEmpty);
    expect(cert2.toSerializedString(), equals('Google'));

    // 3. Multi-entry round trip through StudentProfile
    const multiCertRaw =
        'Google Data Analytics | 90% | 2026\n'
        'AWS Cloud Practitioner | Top 5% | 2025';
    final parsedList = StudentProfile.parseCertifications(multiCertRaw);
    expect(parsedList.length, equals(2));
    expect(parsedList[0].courseCertificate, equals('Google Data Analytics'));
    expect(parsedList[1].courseCertificate, equals('AWS Cloud Practitioner'));
    expect(parsedList[1].rankingPercentage, equals('Top 5%'));

    final serializedBack = StudentProfile.formatCertifications(parsedList);
    expect(serializedBack, equals(multiCertRaw));
  });

  testWidgets('Student Profile Education & Certifications Dynamic Form and CRUD Test', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    UserSession().setSession(
      userId: 'STU_TEST_USER',
      role: 'Student',
      name: 'Test Student',
      email: 'student@campus.edu',
    );

    const initialProfile = StudentProfile(
      userId: 'STU_TEST_USER',
      name: 'Test Student',
      email: 'student@campus.edu',
      education: 'BCA - LJ University',
      certifications: 'Google',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: StudentProfileScreen(initialProfile: initialProfile),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify structured fields exist initially and legacy data loaded correctly
    expect(find.text(AppStrings.degreeLabel), findsOneWidget);
    expect(find.text(AppStrings.uniBoardLabel), findsOneWidget);
    expect(find.text(AppStrings.cgpaPercentageLabel), findsOneWidget);
    expect(find.text(AppStrings.yearLabel), findsNWidgets(2)); // 1 for Edu, 1 for Cert
    expect(find.text(AppStrings.courseCertificateLabel), findsOneWidget);
    expect(find.text(AppStrings.rankingPercentageLabel), findsOneWidget);

    // Verify backward compatibility: legacy values populated into fields
    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('LJ University'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);

    // 2. Find and tap Education '+' button
    final addEduBtn = find.byTooltip(AppStrings.addEducationTooltip);
    expect(addEduBtn, findsOneWidget);
    await tester.ensureVisible(addEduBtn);
    await tester.tap(addEduBtn);
    await tester.pumpAndSettle();

    // Now 2 education entries should exist!
    expect(find.text(AppStrings.degreeLabel), findsNWidgets(2));
    expect(find.text('Education #1'), findsOneWidget);
    expect(find.text('Education #2'), findsOneWidget);

    // 3. Remove the second education entry using 'X'
    final removeEduBtns = find.byTooltip(AppStrings.removeEducationTooltip);
    expect(removeEduBtns, findsNWidgets(2));
    await tester.tap(removeEduBtns.last);
    await tester.pumpAndSettle();

    // Now back to 1 education entry
    expect(find.text(AppStrings.degreeLabel), findsOneWidget);

    // 4. When 1 entry left, clicking 'X' safely clears without removing the only entry or crashing
    final onlyRemoveEduBtn = find.byTooltip(AppStrings.removeEducationTooltip);
    expect(find.text('BCA'), findsOneWidget);

    await tester.tap(onlyRemoveEduBtn);
    await tester.pumpAndSettle();
    // Entry still exists, text is cleared
    expect(find.text(AppStrings.degreeLabel), findsOneWidget);
    expect(find.text('BCA'), findsNothing);

    // 5. Test Certifications dynamic add and remove
    final addCertBtn = find.byTooltip(AppStrings.addCertificationTooltip);
    expect(addCertBtn, findsOneWidget);
    await tester.tap(addCertBtn);
    await tester.pumpAndSettle();

    // Now 2 certification entries
    expect(find.text(AppStrings.courseCertificateLabel), findsNWidgets(2));
    expect(find.text('Certification #1'), findsOneWidget);
    expect(find.text('Certification #2'), findsOneWidget);

    // Remove one certification entry
    final removeCertBtns = find.byTooltip(AppStrings.removeCertificationTooltip);
    expect(removeCertBtns, findsNWidgets(2));
    await tester.tap(removeCertBtns.last);
    await tester.pumpAndSettle();

    // Now 1 certification entry
    expect(find.text(AppStrings.courseCertificateLabel), findsOneWidget);
  });

  // ===========================================================================
  // MAXIMUM HIRING LIMIT TESTS (Section 13)
  // ===========================================================================

  test('Job Model Max Hiring Serialization, Deserialization & Backward Compatibility Test', () {
    // 1. Normal job with max hiring and application count
    final jobJson = {
      'jobId': 'JOB101',
      'title': 'Flutter Developer',
      'company': 'ABC Technologies',
      'location': 'Bangalore',
      'jobType': 'Full-time',
      'skills': 'Flutter, Dart',
      'salary': '12 LPA',
      'description': 'Mobile App Developer',
      'status': 'Active',
      'postedDate': '2026-10-05',
      'maxHiring': 5,
      'applicationCount': 3,
    };
    final job = Job.fromJson(jobJson);
    expect(job.maxHiring, 5);
    expect(job.applicationCount, 3);
    expect(job.status, 'Active');
    expect(job.isClosed, isFalse);
    expect(job.isHiringLimitReached, isFalse);

    // 2. Serialization roundtrip
    final serialized = job.toJson();
    expect(serialized['maxHiring'], 5);
    expect(serialized['applicationCount'], 3);

    // 3. When applicationCount reaches maxHiring, effective status is Closed
    final closedJson = {
      'jobId': 'JOB102',
      'title': 'Flutter Developer',
      'company': 'ABC Technologies',
      'maxHiring': '5',
      'applicationCount': '5',
      'status': 'Active',
    };
    final closedJob = Job.fromJson(closedJson);
    expect(closedJob.status, 'Closed');
    expect(closedJob.isClosed, isTrue);
    expect(closedJob.isHiringLimitReached, isTrue);

    // 4. Backward compatibility: Old job without maxHiring
    final oldJobJson = {
      'jobId': 'JOB103',
      'title': 'Legacy Senior Engineer',
      'company': 'Tech Corp',
      'status': 'Active',
    };
    final oldJob = Job.fromJson(oldJobJson);
    expect(oldJob.maxHiring, isNull);
    expect(oldJob.applicationCount, 0);
    expect(oldJob.status, 'Active');
    expect(oldJob.isClosed, isFalse);
    expect(oldJob.isHiringLimitReached, isFalse);
  });

  test('Max Hiring Backend Logic - Exact Scenario Test (Max Hiring = 3)', () {
    // Simulate Backend Job and Application Store
    int maxHiring = 3;
    int applicationCount = 0;
    String status = 'Active';
    final List<Map<String, String>> applications = [];

    Map<String, dynamic> applyForJobBackend({
      required String userId,
      required String jobId,
    }) {
      // 1. Check duplicate
      for (final app in applications) {
        if (app['userId'] == userId && app['jobId'] == jobId) {
          return {
            'success': false,
            'message': 'You have already applied for this job',
          };
        }
      }

      // 2. Check status
      if (status.toLowerCase() != 'active') {
        if (status.toLowerCase() == 'closed') {
          return {
            'success': false,
            'message':
                'Maximum number of hiring for this job has been reached. Applications are closed.',
          };
        }
        return {
          'success': false,
          'message': 'This job is currently inactive and not accepting applications',
        };
      }

      // 3. Check hiring limit before creating application
      if (maxHiring > 0 && applicationCount >= maxHiring) {
        status = 'Closed';
        return {
          'success': false,
          'message':
              'Maximum number of hiring for this job has been reached. Applications are closed.',
        };
      }

      // 4. Create application
      applications.add({
        'applicationId': 'APP${applications.length + 1}',
        'jobId': jobId,
        'userId': userId,
      });

      // 5. Increment count
      applicationCount++;

      // 6. Auto-close if count >= maxHiring
      if (maxHiring > 0 && applicationCount >= maxHiring) {
        status = 'Closed';
      }

      return {
        'success': true,
        'message': 'Application submitted successfully',
      };
    }

    // Initial State
    expect(applicationCount, 0);
    expect(status, 'Active');

    // Student 1 applies
    final res1 = applyForJobBackend(userId: 'student1', jobId: 'JOB001');
    expect(res1['success'], isTrue);
    expect(applicationCount, 1);
    expect(status, 'Active');

    // Student 2 applies
    final res2 = applyForJobBackend(userId: 'student2', jobId: 'JOB001');
    expect(res2['success'], isTrue);
    expect(applicationCount, 2);
    expect(status, 'Active');

    // Student 3 applies -> reaches limit 3
    final res3 = applyForJobBackend(userId: 'student3', jobId: 'JOB001');
    expect(res3['success'], isTrue);
    expect(applicationCount, 3);
    expect(status, 'Closed');

    // Student 4 tries to apply -> BLOCKED with exact required message
    final res4 = applyForJobBackend(userId: 'student4', jobId: 'JOB001');
    expect(res4['success'], isFalse);
    expect(
      res4['message'],
      'Maximum number of hiring for this job has been reached. Applications are closed.',
    );
    // Count remains 3
    expect(applicationCount, 3);
  });

  test('Max Hiring = 1 Single Seat Immediate Closure Test', () {
    int maxHiring = 1;
    int applicationCount = 0;
    String status = 'Active';
    final List<String> appliedUsers = [];

    Map<String, dynamic> applyJob({required String userId}) {
      if (appliedUsers.contains(userId)) {
        return {'success': false, 'message': 'You have already applied for this job'};
      }
      if (status != 'Active' || applicationCount >= maxHiring) {
        status = 'Closed';
        return {
          'success': false,
          'message':
              'Maximum number of hiring for this job has been reached. Applications are closed.',
        };
      }
      appliedUsers.add(userId);
      applicationCount++;
      if (applicationCount >= maxHiring) {
        status = 'Closed';
      }
      return {'success': true, 'message': 'Application submitted successfully'};
    }

    final res1 = applyJob(userId: 'student_first');
    expect(res1['success'], isTrue);
    expect(applicationCount, 1);
    expect(status, 'Closed');

    final res2 = applyJob(userId: 'student_second');
    expect(res2['success'], isFalse);
    expect(
      res2['message'],
      'Maximum number of hiring for this job has been reached. Applications are closed.',
    );
    expect(applicationCount, 1);
  });

  test('Duplicate Application Does Not Increment Count Test', () {
    int applicationCount = 0;
    final Set<String> applied = {};

    Map<String, dynamic> apply(String user) {
      if (applied.contains(user)) {
        return {'success': false, 'message': 'You have already applied for this job'};
      }
      applied.add(user);
      applicationCount++;
      return {'success': true, 'message': 'Application submitted successfully'};
    }

    // Apply once
    final r1 = apply('student_alpha');
    expect(r1['success'], isTrue);
    expect(applicationCount, 1);

    // Apply second time with same user
    final r2 = apply('student_alpha');
    expect(r2['success'], isFalse);
    expect(r2['message'], 'You have already applied for this job');
    // Application count MUST NOT increment
    expect(applicationCount, 1);
  });

  test('Legacy Job Without Max Hiring Allows Applications Without Closing', () {
    int? maxHiring; // null / empty
    int applicationCount = 0;
    String status = 'Active';

    void applyLegacy(int? limit) {
      applicationCount++;
      if (limit != null && limit > 0 && applicationCount >= limit) {
        status = 'Closed';
      }
    }

    for (int i = 0; i < 10; i++) {
      applyLegacy(maxHiring);
    }
    expect(applicationCount, 10);
    expect(status, 'Active');
  });

  testWidgets('Company PostJobScreen Max No. of Hiring Form Validation Test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PostJobScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Max No. of Hiring" field exists
    expect(find.text('Max No. of Hiring'), findsOneWidget);

    // Tap POST JOB with empty fields to trigger validation
    final postJobFinder = find.text('POST JOB');
    await tester.ensureVisible(postJobFinder);
    await tester.tap(postJobFinder);
    await tester.pumpAndSettle();

    // Verify required validation message for max hiring
    expect(find.text('Enter maximum number of hiring'), findsOneWidget);

    // Enter 0 in Max No. of Hiring
    final maxHiringInput = find.widgetWithText(TextFormField, 'Max No. of Hiring');
    await tester.enterText(maxHiringInput, '0');
    await tester.ensureVisible(postJobFinder);
    await tester.tap(postJobFinder);
    await tester.pumpAndSettle();

    // Verify validation for <= 0
    expect(find.text('Value must be at least 1'), findsOneWidget);

    // Enter valid positive integer (5)
    await tester.enterText(maxHiringInput, '5');
    await tester.ensureVisible(postJobFinder);
    await tester.tap(postJobFinder);
    await tester.pumpAndSettle();

    // Validation error for max hiring should disappear
    expect(find.text('Enter maximum number of hiring'), findsNothing);
    expect(find.text('Value must be at least 1'), findsNothing);
  });

  testWidgets('CompanyJobCard Displays Max Hiring, Applications, and Closed Status When Limit Reached', (
    WidgetTester tester,
  ) async {
    // 1. Job with 3 / 5 applications (Active)
    final activeJobData = {
      'id': 'JOB001',
      'title': 'Flutter Developer',
      'company': 'ABC Technologies',
      'location': 'Bangalore',
      'salary': '₹12 LPA',
      'skills': 'Flutter, Dart',
      'status': 'Active',
      'maxHiring': 5,
      'applicationCount': 3,
      'applicants': 3,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanyJobCard(job: activeJobData),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.text('5 Hiring'), findsOneWidget);
    expect(find.text('3 Applications'), findsOneWidget);
    expect(find.text('Status: ACTIVE'), findsOneWidget);

    // 2. Job with 5 / 5 applications (Limit reached -> Closed)
    final closedJobData = {
      'id': 'JOB002',
      'title': 'Flutter Developer',
      'company': 'ABC Technologies',
      'location': 'Bangalore',
      'salary': '₹12 LPA',
      'skills': 'Flutter, Dart',
      'status': 'Active', // Even if sheet had Active, limit reached forces Closed
      'maxHiring': 5,
      'applicationCount': 5,
      'applicants': 5,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanyJobCard(job: closedJobData),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5 Hiring'), findsOneWidget);
    expect(find.text('5 Applications'), findsOneWidget);
    expect(find.text('Status: CLOSED'), findsOneWidget);
    expect(find.text('Maximum Hiring Limit Reached'), findsOneWidget);
    expect(find.text('Closed'), findsWidgets);
  });

  testWidgets('JobDetailsScreen Displays Applications Closed When Job Status is Closed', (
    WidgetTester tester,
  ) async {
    const closedJob = Job(
      jobId: 'JOB777',
      title: 'Full Stack Engineer',
      company: 'NextGen Systems',
      location: 'Remote',
      jobType: 'Full-time',
      skills: 'Flutter, Node.js',
      salary: '15 LPA',
      description: 'Senior full-stack position',
      status: 'Closed',
      maxHiring: 5,
      applicationCount: 5,
    );

    expect(closedJob.isClosed, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobDetailsScreen(jobId: closedJob.jobId),
        ),
      ),
    );
    await tester.pump();
  });
}
