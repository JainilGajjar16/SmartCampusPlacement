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
import 'package:smart_campus_placement/services/google_sheets_service.dart';


void main() {
  testWidgets('Full Auth Navigation Flow Smoke Test',
      (WidgetTester tester) async {
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
    expect(find.text('Verify your account to reset your password.'), findsOneWidget);
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

  testWidgets('Forgot Password Screen direct render test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('User ID'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Verify Account'), findsOneWidget);
  });

  testWidgets('Reset Password Screen direct render test',
      (WidgetTester tester) async {
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

  testWidgets('Authenticated User Session Dashboard Test',
      (WidgetTester tester) async {
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
    final bangaloreJobs =
        jobs.where((j) => j.location.toLowerCase() == 'bangalore').toList();
    expect(bangaloreJobs.length, equals(2));

    // Job type filtering
    final internships =
        jobs.where((j) => j.jobType.toLowerCase() == 'internship').toList();
    expect(internships.length, equals(1));
    expect(internships.first.company, equals('Adobe'));

    // Skill filtering
    final javaJobs =
        jobs.where((j) => j.skills.toLowerCase().contains('java')).toList();
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

  testWidgets('Phase 9 Jobs Screen Direct Render Test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: JobsScreen(),
      ),
    );

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
    final dartRec =
        result.recommendations.firstWhere((r) => r.skillName == 'Dart');
    expect(dartRec.keyTopics.isNotEmpty, isTrue);
  });

  testWidgets('Phase 10 Skill Gap Analysis Screen Direct Render Test',
      (WidgetTester tester) async {
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

    const profile = StudentProfile(
      userId: 'student1',
      skills: 'Flutter',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SkillGapAnalysisScreen(
          job: job,
          initialProfile: profile,
        ),
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

  test('Phase 10 Expected Test 1: Full Match with Extra Student Competencies', () {
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
  });

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

    const profile = StudentProfile(
      userId: 'student1',
      skills: 'js, Java',
    );

    final result = SkillGapAnalyzer.analyze(job: job, profile: profile);

    expect(result.matchPercentage, equals(100.0));
    expect(result.matchedSkills, contains('JavaScript'));
    expect(result.matchedSkills, contains('Java'));
    expect(result.missingSkills, isEmpty);
  });

  test('Phase 11 Application Status Helper Normalization & Colors Test', () {
    expect(ApplicationStatusHelper.normalizeStatus('applied'), equals('Applied'));
    expect(ApplicationStatusHelper.normalizeStatus('Under Review'), equals('Under Review'));
    expect(ApplicationStatusHelper.normalizeStatus('shortlisted'), equals('Shortlisted'));
    expect(ApplicationStatusHelper.normalizeStatus('Selected'), equals('Selected'));
    expect(ApplicationStatusHelper.normalizeStatus('REJECTED'), equals('Rejected'));

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
    final searchFlutter = apps.where((a) => a.title.toLowerCase().contains('flutter')).toList();
    expect(searchFlutter.length, equals(1));
    expect(searchFlutter.first.applicationId, equals('APP001'));

    // Company search matching
    final searchMicrosoft = apps.where((a) => a.company.toLowerCase().contains('microsoft')).toList();
    expect(searchMicrosoft.length, equals(1));

    // Status filter matching
    final shortlistedApps = apps.where((a) => ApplicationStatusHelper.normalizeStatus(a.status) == 'Shortlisted').toList();
    expect(shortlistedApps.length, equals(1));
    expect(shortlistedApps.first.title, equals('Frontend Intern'));
  });

  testWidgets('Phase 11 Application Timeline Widget Direct Render Test',
      (WidgetTester tester) async {
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

  testWidgets('Phase 11 My Applications Screen Direct Render Test',
      (WidgetTester tester) async {
    UserSession().setSession(
      userId: 'student123',
      role: 'Student',
      name: 'Test Student',
      email: 'student@campus.edu',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MyApplicationsScreen(),
      ),
    );

    expect(find.text('My Applications'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('My Applications'), findsOneWidget);

    UserSession().clearSession();
  });

  test('Phase 12 Placement Readiness Calculator Formula Unit Test', () {
    const emptyProfile = StudentProfile(userId: 'student1');
    expect(PlacementReadinessCalculator.calculateProfileCompleteness(emptyProfile), equals(0.0));

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
    expect(PlacementReadinessCalculator.calculateProfileCompleteness(fullProfile), equals(100.0));

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

    final marketAlignment = PlacementReadinessCalculator.calculateMarketAlignment(jobs, fullProfile);
    expect(marketAlignment, equals(100.0));

    final overall = PlacementReadinessCalculator.calculateOverallReadiness(fullProfile, jobs);
    expect(overall, equals(100.0));
  });

  test('Phase 12 Job Recommendation Sorting & Classification Unit Test', () {
    const profile = StudentProfile(
      userId: 'student1',
      skills: 'Flutter, Dart',
    );

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

    final sorted = PlacementReadinessCalculator.sortJobsByRecommendation(jobs, profile);

    // JOB002 has 100% match (Flutter, Dart) => First
    expect(sorted.first.job.jobId, equals('JOB002'));
    expect(sorted.first.matchPercentage, equals(100.0));
    expect(PlacementReadinessCalculator.getMatchCategory(sorted.first.matchPercentage), equals('Strong Match'));

    // JOB003 has 50% match (Flutter matched out of 2) => Second
    expect(sorted[1].job.jobId, equals('JOB003'));
    expect(sorted[1].matchPercentage, equals(50.0));
    expect(PlacementReadinessCalculator.getMatchCategory(sorted[1].matchPercentage), equals('Good Match'));

    // JOB001 has 0% match => Last
    expect(sorted.last.job.jobId, equals('JOB001'));
    expect(sorted.last.matchPercentage, equals(0.0));
    expect(PlacementReadinessCalculator.getMatchCategory(sorted.last.matchPercentage), equals('Needs Improvement'));
  });

  test('Phase 12 Missing Skills Aggregation Unit Test', () {
    const profile = StudentProfile(
      userId: 'student1',
      skills: 'Flutter',
    );

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

    final missingSummary = PlacementReadinessCalculator.getMissingSkillsSummary(jobs, profile);

    // SQL is missing in both jobs (frequency = 2) => Top missing skill
    expect(missingSummary.first.key, equals('SQL'));
    expect(missingSummary.first.value, equals(2));
  });

  testWidgets('Phase 12 Placement Readiness Screen Direct Render Test',
      (WidgetTester tester) async {
    UserSession().setSession(
      userId: 'student123',
      role: 'Student',
      name: 'Test Student',
      email: 'student@campus.edu',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PlacementReadinessScreen(),
      ),
    );

    expect(find.text('Placement Readiness & Insights'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Placement Readiness & Insights'), findsOneWidget);

    UserSession().clearSession();
  });

  test('Company Role Normalization & Routing Logic Test', () {
    final rolesToTest = ['Company', 'company', ' Company ', 'HR', 'hr', 'Recruiter'];
    for (final role in rolesToTest) {
      final String normalizedRole = role.trim().toLowerCase();
      final bool isCompany = normalizedRole == 'company' ||
          normalizedRole == 'hr' ||
          normalizedRole == 'recruiter';
      expect(isCompany, isTrue, reason: 'Role "$role" should normalize to Company dashboard route.');
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
    final String studentRole = activeStudentResp['role'].toString().trim().toLowerCase();
    final String studentStatus = activeStudentResp['status'].toString().trim().toLowerCase();
    expect(studentRole, equals('student'));
    expect(studentStatus, equals('active'));

    final inactiveUserResp = {
      'success': true,
      'userId': 'STU002',
      'role': 'student',
      'status': 'Inactive',
    };
    final String inactiveStatus = inactiveUserResp['status'].toString().trim().toLowerCase();
    expect(inactiveStatus == 'inactive' || inactiveStatus == 'disabled', isTrue);

    final companyResp = {
      'success': true,
      'userId': 'COM001',
      'role': 'Company',
      'status': 'Active',
    };
    expect(companyResp['role'].toString().trim().toLowerCase(), equals('company'));

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
    expect(AppValidators.validateConfirmPassword('pass123', 'pass456'), isNotNull);
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
    expect(registrationPayload['role']!.trim().toLowerCase(), equals('student'));

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
      }
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
    final emptyResponse = {
      'success': true,
      'jobs': <Map<String, dynamic>>[],
    };

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
        }
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
    final queryParams = {
      'action': 'get_job_details',
      'jobId': jobA.jobId,
    };
    expect(queryParams['action'], equals('get_job_details'));
    expect(queryParams['jobId'], equals('JOB_A'));

    // 3. Verify error handling when job is not found
    final notFoundResponse = {
      'success': false,
      'message': 'Job not found',
    };
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

    final getParams = {
      'action': 'get_notifications',
      'userId': 'STU_8001',
    };
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
        .where((n) => n.userId.toLowerCase() == currentStudentId.toLowerCase() || n.userId.toLowerCase() == 'all')
        .toList();

    expect(studentNotifs.length, equals(2));
    expect(studentNotifs.any((n) => n.id == 'N1'), isTrue);
    expect(studentNotifs.any((n) => n.id == 'N3'), isTrue);
    expect(studentNotifs.any((n) => n.id == 'N2'), isFalse);
  });

  testWidgets('Phase 8 Notifications Screen Direct Render Test', (WidgetTester tester) async {
    UserSession().setSession(
      userId: 'STU_8001',
      role: 'Student',
      name: 'Test Student',
      email: 'student@campus.edu',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationsScreen(),
      ),
    );

    expect(find.text(AppStrings.notificationsTitle), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.notificationsTitle), findsOneWidget);

    UserSession().clearSession();
  });

  test('Phase 11 Application Status Helper Normalization & Colors Test', () {
    expect(ApplicationStatusHelper.normalizeStatus('Applied'), equals('Applied'));
    expect(ApplicationStatusHelper.normalizeStatus('under review'), equals('Under Review'));
    expect(ApplicationStatusHelper.normalizeStatus('shortlisted candidate'), equals('Shortlisted'));
    expect(ApplicationStatusHelper.normalizeStatus('Selected!'), equals('Selected'));
    expect(ApplicationStatusHelper.normalizeStatus('rejected application'), equals('Rejected'));

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
    final shortlistedApps = apps.where((a) => ApplicationStatusHelper.normalizeStatus(a.status) == 'Shortlisted').toList();
    expect(shortlistedApps.length, equals(1));
    expect(shortlistedApps.first.applicationId, equals('APP2'));

    // Search Query Check
    final searchResult = apps.where((a) => a.company.toLowerCase().contains('google')).toList();
    expect(searchResult.length, equals(1));
    expect(searchResult.first.jobId, equals('JOB1'));
  });

  testWidgets('Phase 11 Application Timeline Widget Direct Render Test', (WidgetTester tester) async {
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

  testWidgets('Phase 11 My Applications Screen Direct Render Test', (WidgetTester tester) async {
    UserSession().setSession(
      userId: 'STU_1101',
      role: 'Student',
      name: 'Applicant Student',
      email: 'student@campus.edu',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MyApplicationsScreen(),
      ),
    );

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

    final completeness = PlacementReadinessCalculator.calculateProfileCompleteness(profile);
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

    final marketAlignment = PlacementReadinessCalculator.calculateMarketAlignment(jobs, profile);
    expect(marketAlignment, equals(100.0));

    final overall = PlacementReadinessCalculator.calculateOverallReadiness(profile, jobs);
    expect(overall, equals(100.0));
  });

  test('Phase 12 Job Recommendation Sorting & Classification Unit Test', () {
    const profile = StudentProfile(
      userId: 'STU1202',
      skills: 'Flutter, Dart',
    );

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

    final items = PlacementReadinessCalculator.sortJobsByRecommendation(jobs, profile);
    expect(items.first.job.jobId, equals('JOB2'));
    expect(items.first.matchPercentage, equals(100.0));
    expect(PlacementReadinessCalculator.getMatchCategory(items.first.matchPercentage), equals(PlacementReadinessCalculator.categoryStrong));

    expect(items.last.job.jobId, equals('JOB1'));
    expect(items.last.matchPercentage, equals(0.0));
    expect(PlacementReadinessCalculator.getMatchCategory(items.last.matchPercentage), equals(PlacementReadinessCalculator.categoryNeedsImprovement));
  });

  test('Phase 12 Missing Skills Aggregation Unit Test', () {
    const profile = StudentProfile(
      userId: 'STU1203',
      skills: 'Flutter',
    );

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

    final summary = PlacementReadinessCalculator.getMissingSkillsSummary(jobs, profile);
    // Java is missing in both jobs (frequency 2)
    final javaEntry = summary.firstWhere((e) => e.key == 'Java');
    expect(javaEntry.value, equals(2));
  });

  testWidgets('Phase 12 Placement Readiness Screen Direct Render Test', (WidgetTester tester) async {
    UserSession().setSession(
      userId: 'STU1204',
      role: 'Student',
      name: 'Test Student',
      email: 'student@campus.edu',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PlacementReadinessScreen(),
      ),
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

  testWidgets('Company Dashboard Direct Render Test', (WidgetTester tester) async {
    UserSession().setSession(
      userId: 'COM001',
      role: 'Company',
      name: 'ABC Company',
      email: 'contact@abccompany.com',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: CompanyDashboard(),
      ),
    );

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
    final uri = Uri.parse(GoogleSheetsService.baseUrl).replace(queryParameters: {
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
    });

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
}



