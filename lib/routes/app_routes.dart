import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/student_profile.dart';
import '../screens/admin/student_details_screen.dart';
import '../screens/admin/system_broadcast_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/dashboard/admin_dashboard_screen.dart';
import '../screens/dashboard/company_dashboard_screen.dart';
import '../screens/dashboard/student_dashboard_screen.dart';
import '../screens/student/job_details_screen.dart';
import '../screens/student/jobs_screen.dart';
import '../screens/student/my_applications_screen.dart';
import '../screens/student/notifications_screen.dart';
import '../screens/student/placement_readiness_screen.dart';
import '../screens/student/resume_screen.dart';
import '../screens/student/skill_gap_analysis_screen.dart';
import '../screens/student/student_profile_screen.dart';
import '../screens/welcome_screen.dart';

/// Centralized route definitions for the app.
abstract class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String companyDashboard = '/company-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String profile = '/profile';
  static const String resume = '/resume';
  static const String jobs = '/jobs';
  static const String jobDetails = '/job-details';
  static const String myApplications = '/my-applications';
  static const String notifications = '/notifications';
  static const String skillGapAnalysis = '/skill-gap-analysis';
  static const String placementReadiness = '/placement-readiness';
  static const String userManagement = '/user-management';
  static const String studentDetails = '/student-details';
  static const String systemBroadcast = '/system-broadcast';

  static Map<String, WidgetBuilder> get routes => {
        welcome: (context) => const WelcomeScreen(),
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        resetPassword: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
                  {};
          return ResetPasswordScreen(
            userId: args['userId']?.toString() ?? '',
            email: args['email']?.toString() ?? '',
          );
        },
        dashboard: (context) => const StudentDashboardScreen(),
        companyDashboard: (context) => const CompanyDashboardScreen(),
        adminDashboard: (context) => const AdminDashboardScreen(),
        userManagement: (context) => const UserManagementScreen(),
        studentDetails: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
                  {};
          return StudentDetailsScreen(student: args);
        },
        systemBroadcast: (context) => const SystemBroadcastScreen(),
        profile: (context) => const StudentProfileScreen(),
        resume: (context) => const ResumeScreen(),
        jobs: (context) => const JobsScreen(),
        jobDetails: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
                  {};
          return JobDetailsScreen(
            jobId: args['jobId']?.toString() ?? '',
          );
        },
        myApplications: (context) => const MyApplicationsScreen(),
        notifications: (context) => const NotificationsScreen(),
        placementReadiness: (context) => const PlacementReadinessScreen(),
        skillGapAnalysis: (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
                  {};
          final job = args['job'] as Job? ??
              const Job(
                jobId: '',
                title: 'Position',
                company: 'Company',
                location: '',
                jobType: '',
                skills: '',
                salary: '',
                description: '',
              );
          final profile = args['profile'] as StudentProfile?;
          return SkillGapAnalysisScreen(
            job: job,
            initialProfile: profile,
          );
        },
      };
}



